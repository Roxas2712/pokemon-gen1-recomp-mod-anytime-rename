-- Rename the player, rival and party Pokémon from the normal menu flow.
--
-- The player rename also rewrites the OT name of Pokémon that still match
-- the player's old OT identity.  Without that step, Gen 1's Name Rater and
-- Yellow's starter-Pikachu identity check would treat the player's own
-- Pokémon as traded after the player name changes.

return function(mod)
  local function translated(game, source)
    local strings = game and game.data and game.data.strings
    local value = type(strings) == "table" and strings[source]
    return type(value) == "string" and value or source
  end

  local function isGerman(game)
    local strings = game and game.data and game.data.strings
    return type(strings) == "table"
      and (strings.CANCEL == "ZURÜCK"
        or strings["YOUR NAME?"] == "DEIN NAME?")
  end

  local function labels(game)
    if isGerman(game) then
      return {
        trainerRename = "NAME ÄNDERN",
        rivalRename = "RIVALE",
        pokemonRename = "SPITZNAME",
        pokemonRemove = "SP. WEG",
      }
    end
      return {
        trainerRename = "RENAME",
        rivalRename = "RIVAL",
        pokemonRename = "NICKNAME",
        pokemonRemove = "NO NICK",
      }
  end

  local function positiveLength(value, fallback)
    value = tonumber(value)
    if not value or value < 1 then return fallback end
    return math.floor(value)
  end

  local function isGen2(game)
    local save = game and game.save
    return type(save) == "table"
      and (save.generation == 2 or type(save.rival) == "table")
  end

  local function speciesName(game, mon)
    local data = game and game.data
    local pokemon = data and (isGen2(game) and data.gen2Pokemon
      or data.pokemon)
    local def = pokemon and mon and pokemon[mon.species]
    return (def and def.name) or (mon and mon.name)
      or (mon and mon.species) or "POKéMON"
  end

  local function forEachStoredPokemon(save, visit)
    local seen = {}
    local function visitList(list)
      if type(list) ~= "table" then return end
      for _, mon in ipairs(list) do
        if type(mon) == "table" and not seen[mon] then
          seen[mon] = true
          visit(mon)
        end
      end
    end

    visitList(save and save.party)
    if type(save and save.boxes) == "table" then
      for _, box in pairs(save.boxes) do visitList(box) end
    end
    -- Compatibility with saves from before Gen1Recomp gained twelve boxes.
    visitList(save and save.box)
  end

  local function belongsToPlayer(mon, player, oldName)
    if mon.traded then return false end
    if mon.ot ~= nil and mon.ot ~= oldName then return false end
    if mon.otId ~= nil and player.id ~= nil and mon.otId ~= player.id then
      return false
    end
    return true
  end

  local function renameTrainer(game, newName)
    if type(game) ~= "table" or type(game.save) ~= "table"
        or type(game.save.player) ~= "table"
        or type(newName) ~= "string" or newName == "" then
      return false, 0
    end

    local player = game.save.player
    local oldName = player.name or "RED"
    if newName == oldName then return true, 0 end

    local updated = 0
    forEachStoredPokemon(game.save, function(mon)
      if belongsToPlayer(mon, player, oldName) then
        mon.ot = newName
        updated = updated + 1
      end
    end)
    player.name = newName
    return true, updated
  end

  local function renamePokemon(game, mon, newName)
    if type(game) ~= "table" or type(mon) ~= "table"
        or type(newName) ~= "string" then
      return false
    end

    local standardName = speciesName(game, mon)
    if newName == "" or newName == standardName then
      mon.nickname = nil
    else
      mon.nickname = newName
    end
    return true
  end

  local function currentRivalName(game)
    local save = game and game.save
    if type(save) ~= "table" then return nil end
    if isGen2(game) then
      return save.rival and save.rival.name
    end
    return save.player and save.player.rival
  end

  local function renameRival(game, newName)
    if type(game) ~= "table" or type(game.save) ~= "table"
        or type(newName) ~= "string" or newName == "" then
      return false
    end
    if isGen2(game) then
      game.save.rival = game.save.rival or {}
      game.save.rival.name = newName
    elseif type(game.save.player) == "table" then
      game.save.player.rival = newName
    else
      return false
    end
    return true
  end

  -- Gen1 and Gen2 expose the same menu hooks but intentionally have distinct
  -- naming screens and option shapes. Using the Gold screen on Gen2 fixes the
  -- trainer row after the multi-game launcher update and keeps its menu stack
  -- intact; Gen1 continues to use its original screen.
  local function openNaming(game, kind, opts)
    if isGen2(game) then
      mod.ui.push(game, "Gen2NamingScreen", {
        type = kind,
        prompt = opts.title,
        maxLength = opts.maxLen,
        initial = opts.default,
        monName = opts.monName,
        onDone = function(name)
          game.stack:pop()
          opts.onDone(name)
        end,
      })
      return
    end
    mod.ui.push(game, "NamingScreen", opts)
  end

  local function openTrainerNaming(game)
    local constants = game.data and game.data.constants or {}
    openNaming(game, "player", {
      title = translated(game, "YOUR NAME?"),
      maxLen = positiveLength(constants.playerNameLength, 7),
      default = game.save.player.name or "RED",
      onDone = function(name)
        renameTrainer(game, name)
        -- Gen1's generic menu pops on select, so rebuild it with the new
        -- trainer-card label. Gold's start menu stays below its child screen.
        if not isGen2(game) then mod.ui.push(game, "StartMenu") end
      end,
    })
  end

  local function openRivalNaming(game)
    local constants = game.data and game.data.constants or {}
    openNaming(game, "rival", {
      title = translated(game, "HIS NAME?"),
      maxLen = positiveLength(constants.rivalNameLength,
        positiveLength(constants.playerNameLength, 7)),
      default = currentRivalName(game) or (isGen2(game) and "SILVER" or "BLUE"),
      onDone = function(name)
        renameRival(game, name)
        if not isGen2(game) then mod.ui.push(game, "StartMenu") end
      end,
    })
  end

  local function openPokemonNaming(game, mon)
    local constants = game.data and game.data.constants or {}
    openNaming(game, "nickname", {
      title = translated(game, "NICKNAME?"),
      maxLen = positiveLength(constants.nicknameLength, 10),
      default = mon.nickname or speciesName(game, mon),
      monName = mon.nickname or speciesName(game, mon),
      onDone = function(name)
        renamePokemon(game, mon, name)
      end,
    })
  end

  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local out = next(game, items)
    if type(out) ~= "table" then return out end

    local text = labels(game)
    mod.ui.insertBefore(out, translated(game, "SAVE"), {
      label = text.trainerRename,
      onSelect = function() openTrainerNaming(game) end,
    })
    return mod.ui.insertBefore(out, translated(game, "SAVE"), {
      label = text.rivalRename,
      onSelect = function() openRivalNaming(game) end,
    })
  end)

  mod.hooks:wrap("ui.party.submenu", function(next, game, items, mon, ctx)
    local out = next(game, items, mon, ctx)
    if type(out) ~= "table" or (ctx and ctx.battle) then return out end

    local text = labels(game)
    out[#out + 1] = {
      label = text.pokemonRename,
      onSelect = function(selected, selectedGame)
        openPokemonNaming(selectedGame or game, selected or mon)
      end,
    }
    if mon and mon.nickname ~= nil then
      out[#out + 1] = {
        label = text.pokemonRemove,
        onSelect = function(selected, selectedGame)
          renamePokemon(selectedGame or game, selected or mon, "")
        end,
      }
    end
    return out
  end)

  -- Small test/debug surface that also gives companion mods a safe way to
  -- invoke the same identity-preserving rename behavior.
  mod.exports.renameTrainer = renameTrainer
  mod.exports.renameRival = renameRival
  mod.exports.renamePokemon = renamePokemon
end
