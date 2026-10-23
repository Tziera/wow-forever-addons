# Turn-In Queue

A turn-in queue for **WoW: Forever**. Blizzard's quest tracker is for work in
progress, so once a quest is complete it leaves the tracker and shows up here
instead, under a header that answers the one question left: if I hand all of
this in, do I level?

Formerly **Pending Quest XP** (`/pqx` still works). The new name starts with
fresh settings: style, size and parked quests are set again once per
character. Remove the old `PendingQuestXP` folder from `Interface/AddOns`.

## Features

- **Header:** your current XP plus the XP waiting in completed quests, out of
  what you need, e.g. `1200+1500/5000`. It says `DING` when the turn-ins are
  enough to level. Quest XP is not affected by rested XP, so the sum is exact.
- **Compact** (`/tiq compact`, or the checkbox in the options): the header
  moves onto Blizzard's own XP bar. The pending XP is drawn as a segment after
  your XP, which changes colour when it is enough to level, and the bar reads
  e.g. `1200 (3000) +1500 / 5000` -- rested XP in blue in brackets. The
  segment covers Blizzard's rested fill; the text still gives the amount.
  Hover the bar and Blizzard's own text shows instead. With no XP bar on
  screen (max level, a reputation in its place, or a UI addon that replaces
  it) the panel keeps its header.
- **Rows:** each completed quest with its own level and its XP reward, sorted
  by level and coloured by difficulty. `+` marks elite and group quests.
- **Only quests you worked for leave the tracker.** A quest has to have had at
  least one objective and been seen incomplete before it is untracked. Pure
  delivery quests are complete the moment you accept them, so they stay in the
  tracker (they still show in the queue). `/tiq deliveries on` untracks them
  too.
- **Right-click parks a quest as "later"**, for turn-ins that are far away. A
  parked quest sinks to the bottom, fades, and is left out of the sum. Its XP
  is shown on its own as `+700 later`. Right-click again to bring it back.
- **Click** points the way to the quest. With `/tiq map` on (or the
  checkbox in the options) it also opens the quest in the quest log -- off
  by default, since a map opened by an addon carries its taint in the pins
  it draws, and opening the map yourself in combat later can then give a
  "blocked from an action" error.
  **Shift-click** links it in chat.
- The tooltip shows the quest level, the XP and, when the client provides it,
  where to hand the quest in.
- Untracking waits until combat ends.
- The −/+ beside the close button folds the panel up to its title bar, like
  Blizzard's quest tracker, and unfolds it to the height it had.
- Seven looks: `warm` (default), `flat`, `blizzard` and `minimal`, plus
  `elvui`, `details` and `pfui` to match those addons.
- A settings page under Esc → Options → AddOns.
- Snaps to Dungeon Level Guide and Zone Level Guide: drop one panel within a
  few pixels of another's edge and they move together.

## Commands

| Command | Does |
|---|---|
| `/tiq` | Show/hide the panel |
| `/tiq later` | List parked quests. `show` or `hide` controls whether they are visible, `clear` unparks all |
| `/tiq map` | Open the quest log on a click, or only point the way (default) |
| `/tiq untrack on\|off` | Untrack completed quests automatically, or not |
| `/tiq compact on\|off` | Put the XP line on Blizzard's XP bar (off by default) |
| `/tiq deliveries on\|off` | Also untrack delivery quests (off by default) |
| `/tiq auto on\|off` | Sets the `autoQuestProgress` CVar |
| `/tiq style <name>` | `warm`, `flat`, `blizzard`, `elvui`, `details`, `pfui` or `minimal` |
| `/tiq font <n>` | Text size, 6–24 |
| `/tiq alpha <n>` | Background opacity, 0–100 |
| `/tiq reset` | Put the panel back in its default position and size |
| `/tiq colors` | Compare the addon's difficulty colours with the client's |
| `/tiq debug` | Show which APIs the client is missing and the XP for each quest |
| `/tiq layout` | Show how the panel measured its header |

Drag the title bar to move the panel, and the bottom-right corner to resize
it. Settings are saved per character.

## Installation

Put the `TurnInQueue` folder in `World of Warcraft/_forever_/Interface/AddOns/`.

## Credits and licence

By Tziera. Licensed under the GNU General Public License v3.0 or later, see
`LICENSE.txt`.

The fonts in `Fonts/` are Alegreya Sans, Barlow Semi Condensed, Cinzel,
PT Sans Narrow and Source Sans 3, under the SIL Open Font License. Their
licence files are included in that folder.
