# Changelog

## 1.2.1

- changed the release archive to the canonical
  `anytime_rename-1.2.1.zip` name expected by the Gen1Recomp updater
- excluded the development-only regression suite from the install archive
- runtime behavior is unchanged from 1.2.0

## 1.2.0

- fixed trainer renaming after the multi-game launcher/Gen2 update by using
  the naming screen and stack behavior of the active generation
- added a `RIVAL` / `RIVALE` START-menu action
- rival names are stored in the correct Gen1 or Gen2 save field
- trainer renaming continues to update the OT identity of owned party and
  boxed Pokémon in both generations
- expanded the ROM-free regression suite from 35 to 55 checks

## 1.1.1

- clarified the Pokémon submenu labels so nickname removal cannot be
  mistaken for deleting the Pokémon
- English labels are now `NICKNAME` and `NO NICK`
- German labels are now `SPITZNAME` and `SP. WEG`

## 1.1.0

- added a dedicated nickname-removal action that completely clears a
  Pokémon nickname
- changed the default language to English
- automatically switches the custom menu labels to German when a supported
  German translation mod is active
- renamed the package and mod display name to Anytime Rename

## 1.0.0

- trainer name can be changed directly from the START menu
- every party Pokémon can be renamed from its submenu
- traded Pokémon may be renamed
- OT names of owned Pokémon remain consistent across party and PC boxes
- English and German menu support
