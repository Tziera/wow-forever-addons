# Sort Quest Tracker

Orders Blizzard's quest tracker in **WoW: Forever**: the quests with
something to do where you are come first, then the rest, by quest level or
by distance. By default it also watches only the quests where you are, so
the tracker shows what there is to do here.

## Features

- **Where you are first.** In a dungeon, its quests come first, then the zone
  around it, then the rest. Where a quest's objectives are is read from the
  map's own quest markers; a quest the map shows nothing for counts as being
  where you took it.
- **By level or by distance.** Within each group the quests are sorted by
  quest level, or with `/sqt distance` by how far away their nearest
  objective is, re-sorted as you walk.
- **Only what is here** (on by default, `/sqt track`): quests that belong
  where you are are watched, and the ones from other zones leave the tracker
  until you get there. A quest you add yourself stays, wherever it is, and
  one you take off stays off.
- **Watch all quests:** `/sqt all`, or the button on the settings page,
  watches every quest in your log and stops taking any off.
- **Works with Turn-In Queue:** completed quests that Turn-In Queue takes
  off the tracker are left to it.
- Only the quests out of place are moved, and nothing is touched in combat.
  With the Controller UI the tracker is left alone, since it is slow to lay
  itself out there; `/sqt controller` sorts there too.
- A settings page under *Esc → Options → AddOns*.

## Commands

| Command | Does |
|---|---|
| `/sqt` | Turn sorting on or off |
| `/sqt track` | Watch only the quests where you are, or leave the tracker to you |
| `/sqt all` | Watch every quest in the log, and stop taking any off |
| `/sqt level` / `/sqt distance` | Order each group by quest level or by distance |
| `/sqt controller` | Also sort with the Controller UI (can freeze the game for a moment) |
| `/sqt options` | Open the settings page |
| `/sqt status` | Show what the addon can see |

Settings are saved per character.

## Installation

Put the `SortQuestTracker` folder in `World of Warcraft/_forever_/Interface/AddOns/`.

## Credits and licence

By Tziera. Licensed under the GNU General Public License v3.0 or later, see
`LICENSE.txt`.
