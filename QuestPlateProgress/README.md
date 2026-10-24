# Quest Plate Progress

Shows your quest progress on the nameplates of the mobs you still need in
**WoW: Forever**: `Kill 5/8` under a mob you are sent to kill, and
`Cirrusfly Wing 3/10` under one that drops what you are collecting.

## Features

- **Only what you still need.** Finished objectives are left out, and a mob
  you don't need for any quest gets no text.
- **Names what to loot.** A kill objective for the mob itself reads
  `Kill 5/8`, since the plate already carries its name; anything else keeps
  its own name, such as `Cirrusfly Wing 3/10`. On an NPC you cannot attack,
  such as one you are sent to speak with, it reads `Talk 0/1` (with friendly
  nameplates turned on).
- **Your progress in a group.** When others in the group do the same quest,
  only your objectives are shown. `/qpp party on` adds theirs after yours,
  greyed and by name: `Brightwell: Kill 2/8`.
- **Stays put.** The text is placed from the middle of the health bar, 16
  pixels below it by default. The first line stays where it is however many
  follow: below the bar they grow downwards, above it upwards.
- **No guessing.** The game already lists in a mob's tooltip which
  objectives it counts towards; the addon reads that list for each plate.
- A settings page under *Esc → Options → AddOns*.

## Commands

| Command | Does |
|---|---|
| `/qpp` | Show the current settings |
| `/qpp on` / `/qpp off` | Show or hide the text |
| `/qpp party on\|off` | Also show party members' progress (off by default) |
| `/qpp size <n>` | Text size, 6–24 |
| `/qpp move <x> <y>` | Move the text from the middle of the health bar, e.g. `/qpp move 0 12` |
| `/qpp x <n>` / `/qpp y <n>` | Change only one of them |
| `/qpp center` | Back to the middle of the bar |
| `/qpp reset` | Default text size and placement |
| `/qpp options` | Open the settings page |
| `/qpp debug` | What the addon sees on your target, in a box you can copy from |

Settings are saved per character.

## Installation

Put the `QuestPlateProgress` folder in `World of Warcraft/_forever_/Interface/AddOns/`.

## Credits and licence

By Tziera. Licensed under the GNU General Public License v3.0 or later, see
`LICENSE.txt`.
