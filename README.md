# Anytime Rename

A small quality-of-life mod for **Gen1Recomp** that lets you rename the
trainer, rival and party Pokémon anywhere outside battle. The Name Rater is no
longer required.

[Download the latest release](https://github.com/Roxas2712/pokemon-gen1-recomp-mod-anytime-rename/releases/latest)

English is the default language. When a supported German translation mod is
active, Anytime Rename automatically uses German menu labels, German naming
prompts and the translation mod's naming grid with umlauts.

## Usage

### Rename the trainer

1. Open `START`.
2. Select `RENAME` (`NAME ÄNDERN` in German).
3. Enter the new name and confirm with `START` or `ED`.

### Rename the rival

1. Open `START`.
2. Select `RIVAL` (`RIVALE` in German).
3. Enter the new name and confirm.

### Rename or clear a Pokémon nickname

1. Open `START → POKéMON`.
2. Select a party Pokémon.
3. Select `NICKNAME` (`SPITZNAME` in German) to enter a new nickname.
4. Select `NO NICK` (`SP. WEG` in German) to completely clear an existing
   nickname and restore the species name.

Traded Pokémon can be renamed too.

Changing the trainer name also updates the OT name of the player's own
Pokémon in the party and all PC boxes. Traded Pokémon keep their original OT.
This prevents Gen 1 identity checks from treating the player's Pokémon as
traded after a trainer rename.

The changes use the game's normal save fields. Save normally after renaming;
the mod can then be disabled without reverting the names.

## Installation

For an installed copy, use **Check for updates** in the Gen1Recomp launcher.
Manual import intentionally does not overwrite a mod with the same ID.

For a first install, select `anytime_rename-1.2.1.zip` in the mod manager. To
update manually, remove the installed copy before importing the new archive.

Alternatively, extract the archive into its own
`mods/anytime_rename/` directory.

## Compatibility

- Pokémon Red, Blue, Yellow and Gold in Gen1Recomp
- Mod API 2
- English game: English labels and the original naming grid
- German translation mods: automatic German labels and localized naming grid
- generation-specific naming screens and save fields in Gen 1 and Gen 2

“Anytime” means whenever the normal `START` menu is available. Renaming stays
disabled during battles, link sessions and scripted scenes.
