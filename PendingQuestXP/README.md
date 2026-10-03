# Pending Quest XP

A turn-in queue for **WoW: Forever**. Blizzard's quest tracker is for work in
progress, so once a quest is complete it leaves the tracker and shows up here
instead, under a header that answers the one question left: if I hand all of
this in, do I level?

## Features

- **Header:** your current XP plus the XP waiting in completed quests, out of
  what you need, e.g. `1200+1500/5000`. It says `DING` when the turn-ins are
  enough to level. Quest XP is not affected by rested XP, so the sum is exact.
- **Rows:** each completed quest with its own level and its XP reward, sorted
  by level and coloured by difficulty. `+` marks elite and group quests.
- **Only quests you worked for leave the tracker.** A quest has to have had at
  least one objective and been seen incomplete before it is untracked. Pure
  delivery quests are complete the moment you accept them, so they stay in the
  tracker (they still show in the queue). `/pqx deliveries on` untracks them
  too.
- **Right-click parks a quest as "later"**, for turn-ins that are far away. A
  parked quest sinks to the bottom, fades, and is left out of the sum. Its XP
  is shown on its own as `+700 later`. Right-click again to bring it back.
- **Click** opens the quest in the quest log and points the way to it.
  **Shift-click** links it in chat.
- The tooltip shows the quest level, the XP and, when the client provides it,
  where to hand the quest in.
- Untracking waits until combat ends.
- Seven looks: `warm` (default), `flat`, `blizzard` and `minimal`, plus
  `elvui`, `details` and `pfui` to match those addons.
- A settings page under Esc → Options → AddOns.
- Snaps to Dungeon Level Guide and Zone Level Guide: drop one panel within a
  few pixels of another's edge and they move together.

## Commands

| Command | Does |
|---|---|
| `/pqx` | Show/hide the panel |
| `/pqx later` | List parked quests. `show` or `hide` controls whether they are visible, `clear` unparks all |
| `/pqx untrack on\|off` | Untrack completed quests automatically, or not |
| `/pqx deliveries on\|off` | Also untrack delivery quests (off by default) |
| `/pqx auto on\|off` | Sets the `autoQuestProgress` CVar |
| `/pqx style <name>` | `warm`, `flat`, `blizzard`, `elvui`, `details`, `pfui` or `minimal` |
| `/pqx font <n>` | Text size, 6–24 |
| `/pqx alpha <n>` | Background opacity, 0–100 |
| `/pqx reset` | Put the panel back in its default position and size |
| `/pqx colors` | Compare the addon's difficulty colours with the client's |
| `/pqx debug` | Show which APIs the client is missing and the XP for each quest |
| `/pqx layout` | Show how the panel measured its header |

Drag the title bar to move the panel, and the bottom-right corner to resize
it. Settings are saved per character.

## Installation

Put the `PendingQuestXP` folder in
`World of Warcraft/_classic_beta_/Interface/AddOns/` (or the Forever client's
own `Interface/AddOns/` folder once it is released).

## Credits and licence

By Tziera. Licensed under the GNU General Public License v3.0 or later, see
`LICENSE.txt`.

The fonts in `Fonts/` are Alegreya Sans, Barlow Semi Condensed, Cinzel,
PT Sans Narrow and Source Sans 3, under the SIL Open Font License. Their
licence files are included in that folder.
