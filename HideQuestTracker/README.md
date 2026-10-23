# Hide Quest Tracker

Fades Blizzard's quest tracker out while you are in combat in **WoW:
Forever**, and back in when the fight is over. While it is faded it takes
no clicks, so you cannot open a quest by accident in the middle of a fight.

## Features

- **Fades rather than hides.** The tracker holds the quest item buttons,
  which the game protects in combat, so the addon changes only how see-through
  the tracker is. That is never blocked.
- **Clicks pass through** the faded tracker, so it does not get in the way of
  what is behind it. Lines the tracker adds during the fight are caught too.
- **Quest item buttons stay** in sight and clickable, since the button beside
  a quest is often the quickest way to its item. `/hqt items` lets them fade
  with the rest.
- **How far and how fast:** the tracker's opacity in combat (0 % = gone, the
  default) and the fade time (0 = at once, up to 2 seconds, 0.3 by default).
- A settings page under *Esc → Options → AddOns*, with a button that tries it
  without a fight.

## Commands

| Command | Does |
|---|---|
| `/hqt` | Show the current settings |
| `/hqt on` / `/hqt off` | Turn it on or off |
| `/hqt alpha <0-1>` | Opacity in combat: 0 hides it, 0.15 dims it |
| `/hqt fade <0-2>` | Seconds to fade over, 0 = at once |
| `/hqt items` | Let quest item buttons stay in sight, or fade with the tracker |
| `/hqt test` | Fade or bring back the tracker now, to try it |
| `/hqt options` | Open the settings page |

Settings are saved per character.

## Installation

Put the `HideQuestTracker` folder in `World of Warcraft/_forever_/Interface/AddOns/`.

## Credits and licence

By Tziera. Licensed under the GNU General Public License v3.0 or later, see
`LICENSE.txt`.
