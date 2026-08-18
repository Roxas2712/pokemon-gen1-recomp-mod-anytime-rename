-- Standalone:
--   luajit ../pokemon-jederzeit-umbenennen/tests/anytime_rename_test.lua
-- Run from the root of a Gen1Recomp checkout.

package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local Runtime = require("src.mods.Runtime")

local source = debug.getinfo(1, "S").source:gsub("^@", "")
local TEST_DIR = source:match("^(.*)/[^/]+$") or "."
local MOD_DIR = os.getenv("ANYTIME_RENAME_MOD_DIR")
  or TEST_DIR:match("^(.*)/tests$") or (TEST_DIR .. "/..")

local run = T.sdk.loadMod(MOD_DIR, {
  data = T.fixtures.fresh(),
  dev = true,
})
T.eq(#run.errors, 0, "mod loads cleanly through the production loader")

local exports = run.loader.exports.anytime_rename
T.check(type(exports) == "table", "mod exports its rename surface")
T.check(type(exports.renameTrainer) == "function",
  "trainer rename function is exported")
T.check(type(exports.renameRival) == "function",
  "rival rename function is exported")
T.check(type(exports.renamePokemon) == "function",
  "Pokémon rename function is exported")

local ownParty = { species = "FIXMON_A", ot = "RED", otId = 123 }
local ownBoxed = { species = "FIXMON_B", ot = "RED", otId = 123 }
local ownLegacy = { species = "FIXMON_C", ot = nil, otId = 123 }
local traded = {
  species = "FIXMON_B", ot = "BLUE", otId = 456, traded = true,
  nickname = "BUDDY",
}
local sameNameForeign = {
  species = "FIXMON_C", ot = "RED", otId = 999, traded = true,
}

local stack = { states = {} }
function stack:push(state) self.states[#self.states + 1] = state end
function stack:pop() return table.remove(self.states) end
function stack:top() return self.states[#self.states] end

local game = {
  data = run.data,
  stack = stack,
  save = {
    player = { name = "RED", rival = "BLUE", id = 123 },
    party = { ownParty, traded },
    boxes = { [1] = { ownBoxed, sameNameForeign } },
    box = { ownLegacy },
  },
}

local ok, updated = exports.renameTrainer(game, "LEAF")
T.check(ok, "trainer rename succeeds")
T.eq(game.save.player.name, "LEAF", "player name changes")
T.eq(updated, 3, "party, modern box and legacy box are all visited")
T.eq(ownParty.ot, "LEAF", "own party Pokémon receives the new OT name")
T.eq(ownBoxed.ot, "LEAF", "own boxed Pokémon receives the new OT name")
T.eq(ownLegacy.ot, "LEAF", "own unstamped Pokémon receives the new OT name")
T.eq(traded.ot, "BLUE", "traded Pokémon keeps its foreign OT")
T.eq(sameNameForeign.ot, "RED",
  "a traded same-name Pokémon is not mistaken for the player's")

T.check(exports.renamePokemon(game, traded, "SPARKY"),
  "a traded Pokémon may be renamed")
T.eq(traded.nickname, "SPARKY", "new nickname is stored")
T.check(exports.renamePokemon(game, traded, run.data.pokemon.FIXMON_B.name),
  "renaming to the species name succeeds")
T.eq(traded.nickname, nil, "species name clears the nickname")

local startItems = Runtime.call("ui.start_menu.items",
  function(_, items) return items end, game, { { label = "SAVE" } })
T.eq(#startItems, 3, "START menu receives trainer and rival rows")
T.eq(startItems[1].label, "RENAME", "English START label is compact")
startItems[1].onSelect()
local trainerNaming = stack:top()
T.eq(trainerNaming.screenId, "NamingScreen",
  "trainer row opens the engine naming screen")
T.eq(trainerNaming.maxLen, 7, "trainer name keeps the Gen-1 length")
T.eq(trainerNaming.default, "LEAF", "current trainer name is the fallback")
stack:pop()

startItems[2].onSelect()
local rivalNaming = stack:top()
T.eq(rivalNaming.screenId, "NamingScreen",
  "rival row opens the Gen-1 naming screen")
T.eq(rivalNaming.default, "BLUE", "current rival name is the fallback")
stack:pop()
rivalNaming.onDone("GREEN")
T.eq(game.save.player.rival, "GREEN",
  "rival naming callback updates Gen-1's rival field")
T.eq(stack:top().screenId, "StartMenu",
  "Gen-1 START menu reopens after changing the rival")
stack:pop()
trainerNaming.onDone("GREEN")
T.eq(game.save.player.name, "GREEN",
  "trainer naming callback applies the entered name")
T.eq(stack:top().screenId, "StartMenu",
  "START menu reopens with the changed trainer-card row")
stack:pop()

local partyItems = Runtime.call("ui.party.submenu",
  function(_, items) return items end, game, { { label = "STATS" } },
  ownParty, { battle = false })
T.eq(#partyItems, 2, "field party submenu receives one rename row")
T.eq(partyItems[2].label, "NICKNAME",
  "English party label explicitly names the nickname")
partyItems[2].onSelect(ownParty, game)
local pokemonNaming = stack:top()
T.eq(pokemonNaming.screenId, "NamingScreen",
  "party row opens the engine naming screen")
T.eq(pokemonNaming.maxLen, 10, "nickname keeps the Gen-1 length")
stack:pop()
pokemonNaming.onDone("SPROUT")
T.eq(ownParty.nickname, "SPROUT",
  "Pokémon naming callback applies the entered nickname")

local namedPartyItems = Runtime.call("ui.party.submenu",
  function(_, items) return items end, game, { { label = "STATS" } },
  ownParty, { battle = false })
T.eq(#namedPartyItems, 3,
  "a nicknamed Pokémon receives a dedicated removal row")
T.eq(namedPartyItems[3].label, "NO NICK",
  "English removal label cannot be mistaken for deleting the Pokémon")
namedPartyItems[3].onSelect(ownParty, game)
T.eq(ownParty.nickname, nil,
  "NO NICK completely clears the stored nickname")

local battleItems = Runtime.call("ui.party.submenu",
  function(_, items) return items end, game, { { label = "STATS" } },
  ownParty, { battle = true })
T.eq(#battleItems, 1, "battle party menu is left untouched")

game.data.strings = {
  CANCEL = "ZURÜCK",
  SAVE = "SICHERN",
  ["YOUR NAME?"] = "DEIN NAME?",
  ["NICKNAME?"] = "SPITZNAME?",
}
local germanStart = Runtime.call("ui.start_menu.items",
  function(_, items) return items end, game, { { label = "SICHERN" } })
T.eq(germanStart[1].label, "NAME ÄNDERN",
  "German START menu receives the German label")
T.eq(germanStart[2].label, "RIVALE",
  "German START menu receives a compact rival label")
local germanParty = Runtime.call("ui.party.submenu",
  function(_, items) return items end, game, {}, ownParty, {})
T.eq(germanParty[1].label, "SPITZNAME",
  "German party submenu explicitly names the nickname")
ownParty.nickname = "KNOSPE"
germanParty = Runtime.call("ui.party.submenu",
  function(_, items) return items end, game, {}, ownParty, {})
T.eq(germanParty[2].label, "SP. WEG",
  "German removal label cannot be mistaken for deleting the Pokémon")

-- The multi-game launcher exposes the same hooks on Gold, but Gold needs its
-- own naming screen and stores the rival at save.rival.name.
local goldStack = { states = {} }
function goldStack:push(state) self.states[#self.states + 1] = state end
function goldStack:pop() return table.remove(self.states) end
function goldStack:top() return self.states[#self.states] end

run.data.gen2Pokemon = {
  CHIKORITA = { name = "CHIKORITA" },
}
local goldMon = {
  species = "CHIKORITA",
  name = "CHIKORITA",
  ot = "GOLD",
  otId = 321,
}
local gold = {
  data = run.data,
  stack = goldStack,
  save = {
    generation = 2,
    player = { name = "GOLD", id = 321 },
    rival = { name = "SILVER" },
    party = { goldMon },
    boxes = {},
  },
}

local goldStart = Runtime.call("ui.start_menu.items",
  function(_, items) return items end, gold, { { label = "SICHERN" } })
T.eq(#goldStart, 3, "Gold START menu receives both rename rows")
goldStart[1].onSelect()
local goldTrainerNaming = goldStack:top()
T.eq(goldTrainerNaming.screenId, "Gen2NamingScreen",
  "Gold trainer rename opens Gold's naming screen")
T.eq(goldTrainerNaming.text, "GOLD",
  "Gold naming screen is initialized with the current trainer name")
goldTrainerNaming.onDone("KRIS")
T.eq(gold.save.player.name, "KRIS",
  "Gold trainer name changes through the current launcher flow")
T.eq(goldMon.ot, "KRIS", "Gold-owned Pokémon keeps matching OT identity")
T.eq(goldStack:top(), nil,
  "Gold naming screen closes without stacking another START menu")

goldStart[2].onSelect()
local goldRivalNaming = goldStack:top()
T.eq(goldRivalNaming.screenId, "Gen2NamingScreen",
  "Gold rival rename opens Gold's naming screen")
T.eq(goldRivalNaming.text, "SILVER",
  "Gold rival screen uses save.rival.name")
goldRivalNaming.onDone("KAMON")
T.eq(gold.save.rival.name, "KAMON",
  "Gold rival name changes in its generation-specific save field")
T.eq(goldStack:top(), nil, "Gold rival naming screen closes cleanly")

local goldParty = Runtime.call("ui.party.submenu",
  function(_, items) return items end, gold, {}, goldMon, {})
goldParty[1].onSelect(goldMon, gold)
local goldPokemonNaming = goldStack:top()
T.eq(goldPokemonNaming.screenId, "Gen2NamingScreen",
  "Gold party rename opens Gold's nickname screen")
T.eq(goldPokemonNaming.maxLength, 10,
  "Gold nickname screen keeps the ten-character limit")
goldPokemonNaming.onDone("LEAFY")
T.eq(goldMon.nickname, "LEAFY", "Gold nickname callback remains functional")
T.eq(goldStack:top(), nil, "Gold nickname screen closes cleanly")

run.release()
T.finish("anytime_rename")
