# Dungeon Level Guide

A movable, resizable list of the dungeons in **WoW: Forever** that suit your
current level, within an adjustable ± margin, with their quests and shortcuts
to the map and the Group Finder.

## Features

- **Dungeons for your level.** Each dungeon's level is read from the Forever
  client's own data. The list shows the dungeons within ± the margin of your
  level (5 by default). Change the margin with the `+`/`−` buttons or
  `/dlg range <n>`.
- **Group Finder aware.** Dungeons that the Group Finder offers you right now
  are marked `[LFG]`. By default only those are shown. `/dlg widen` also
  shows the rest of the dungeons within your margin.
- **Dungeon quests.** `+` in front of a dungeon expands its quests. The
  tooltip shows who gives each quest and where. For a quest in a chain, it
  shows where the chain starts. Click a quest to put a pin on the map where
  it is picked up. Right-click removes the pin. The other faction's quests
  and quests you have already done can be hidden.
- **Learns new dungeon quests** that you pick up in play, either from the
  quest text naming a dungeon or from progress made inside a dungeon. With
  Zone Level Guide installed, learned quests also get their quest giver and
  location.
- **Settings panel** (`/dlg gui`) with all filters in one place, and a count of
  what each filter is hiding right now. Also available under Esc → Options →
  AddOns.
- Seven looks: `warm` (default), `flat`, `blizzard` and `minimal`, plus
  `elvui`, `details` and `pfui` to match those addons.
- Snaps to Zone Level Guide and Pending Quest XP: drop one panel within a few
  pixels of another's edge and they move together.

## Commands

| Command | Does |
|---|---|
| `/dlg` | Show/hide the panel |
| `/dlg gui` | Open the settings panel |
| `/dlg range <n>` | Set the ± level margin (0–15) |
| `/dlg widen` | Also show dungeons in your margin that the Group Finder does not offer, or go back (`/dlg lfgonly` does the same) |
| `/dlg faction` | Show/hide the other faction's quests |
| `/dlg done` | Show/hide quests you have already done |
| `/dlg clear` | Remove the map pin |
| `/dlg learned` | List the dungeon quests learned this session |
| `/dlg style <name>` | `warm`, `flat`, `blizzard`, `elvui`, `details`, `pfui` or `minimal` |
| `/dlg font <n>` | Text size, 6–24 |
| `/dlg alpha <n>` | Background opacity, 0–100 |
| `/dlg reset` | Put the panel back in its default position and size |
| `/dlg lfg` | Report what the client offers of the Group Finder API |
| `/dlg levels` | Mob levels measured this session |
| `/dlg copy` | Reopen the last report in a box you can copy from |
| `/dlg layout` | Show how the panel measured its text |

Drag the title bar to move the panel, and the bottom-right corner to resize
it. Settings are saved per character.

## Installation

Put the `DungeonLevelGuide` folder in
`World of Warcraft/_classic_beta_/Interface/AddOns/` (or the Forever client's
own `Interface/AddOns/` folder once it is released).

## Credits and licence

By Tziera. Licensed under the GNU General Public License v3.0 or later, see
`LICENSE.txt`.

- The dungeon quests, their quest givers, locations and factions come from
  the Classic data of [Questie](https://github.com/Questie/Questie)
  (GPL-3.0), which in turn comes from the cMaNGOS and VMaNGOS projects.
- Some quests and levels come from
  [WoW Forever Builds](https://github.com/Boco10/WoWForeverBuilds-Addon)
  (MIT License, see `LICENSE-WoWForeverBuilds.txt`).
- Dungeon levels are read from the Forever client's `LFGDungeons` and
  `ContentTuning` tables via [wago.tools](https://wago.tools).
- The fonts in `Fonts/` are Alegreya Sans, Barlow Semi Condensed, Cinzel,
  PT Sans Narrow and Source Sans 3, under the SIL Open Font License. Their
  licence files are included in that folder.
