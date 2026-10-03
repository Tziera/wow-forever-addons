# Zone Level Guide

Answers "where do I go next?" in **WoW: Forever**. The panel lists the zones
that suit your level, using the Group Finder's own level ranges, with the
quests that start in each zone: where, from whom, and at what level.

## Features

- **Zones for your level.** Zones and their ranges come from the Group
  Finder's zone category, so a new zone shows up even before the addon knows
  about it. The colour shows where you are in the range: orange near the
  bottom, yellow in the middle, green near the top. `/zlg range <n>` also
  shows zones up to n levels outside their range. The other faction's zones
  are hidden.
- **Quests per zone.** `+` in front of a zone expands its quests. Click a
  zone to open the map on it. Click a quest to put a pin where it is picked
  up. When the quest needs an item that lies somewhere known, such as a book,
  ctrl-click puts the pin on the item instead; the tooltip says where.
- **Quests are recorded when you take them.** The quest giver, the quest
  level, the zone, the coordinates and the faction are saved on accept. Quests
  that start from an item are marked as such. Dungeon quests get a dungeon
  icon. A quest shared by another player is not recorded, since it says
  nothing about where the quest is picked up. A quest that is never taken,
  where an NPC takes an item and the quest is done at once, is recorded when
  you hand it in, with that NPC as its giver.
- **Quest data included.** The addon ships with quests recorded in the
  Forever beta, and with Classic quests not yet seen in Forever. The Classic
  ones are marked `(preliminary)`. A quest you record yourself always wins
  over the shipped data.
- **Chains and requirements.** `(chain)` means another quest must be done
  first, and the tooltip follows the chain back to where it starts.
  `(needs)` means something else is required, such as an item. `(either)`
  means only one of two quests can be done. A quest that points you on to
  another, without the other needing it, says so in its tooltip. `(repeatable)` means it
  can be handed in again and again. Class and profession quests are
  labelled, and profession quests fade if you lack the profession.
- **Help find quest chains** (off by default). When a quest is offered
  straight after you hand in another one, it is probably the next step of a
  chain. Tick "Help find quest chains" under Options → AddOns, or type
  `/zlg chains`, and such quests are marked `(chain?)`. Right-click one to
  answer: "Yes, it comes after …" or "Not a chain". Your answers are saved
  with your recorded quests, in
  `WTF/Account/<account>/<realm>/<character>/SavedVariables/ZoneLevelGuide.lua`.
  To have them included in the next release, email that file to
  wowtziera@gmail.com.
- **Cities** appear as their own rows when they have a quest you have not
  handed in, at most five levels above yours. Grey quests count only while
  "Low-Level Quests" is ticked in the minimap's tracking menu.
- **Filters**, all off by default: `/zlg done` hides quests you have handed
  in (otherwise they fade), `/zlg high` hides quests more than five levels
  above you, and `/zlg profession` hides quests for a profession you don't
  have (otherwise they fade). If "Low-Level Quests" is unticked in the minimap's
  tracking menu, grey quests are hidden too, just like on the map.
- Seven looks: `warm` (default), `flat`, `blizzard` and `minimal`, plus
  `elvui`, `details` and `pfui` to match those addons.
- Snaps to Dungeon Level Guide and Pending Quest XP: drop one panel within a
  few pixels of another's edge and they move together.

## Commands

| Command | Does |
|---|---|
| `/zlg` | Show/hide the panel |
| `/zlg range <n>` | Also show zones up to n levels outside their range |
| `/zlg faction` | Show/hide the other faction's zones |
| `/zlg done` | Show/hide quests you have handed in |
| `/zlg high` | Show/hide quests more than 5 levels above you |
| `/zlg profession` | Show/hide quests for professions you don't have |
| `/zlg chains` | Turn chain help on or off: mark quests that may follow another |
| `/zlg quests` | List the quests recorded this session, marked new/known/news |
| `/zlg after [id] <quest>` | Note that a quest comes after another one (without an id: the last quest taken) |
| `/zlg needs [id] <text>` | Note what a quest requires, e.g. an item |
| `/zlg style <name>` | `warm`, `flat`, `blizzard`, `elvui`, `details`, `pfui` or `minimal` |
| `/zlg font <n>` / `/zlg alpha <n>` | Text size and background opacity |
| `/zlg reset` | Put the panel back in its default position and size |

Drag the title bar to move the panel, and the bottom-right corner to resize
it. Settings and recorded quests are saved per character.

## Installation

Put the `ZoneLevelGuide` folder in
`World of Warcraft/_classic_beta_/Interface/AddOns/` (or the Forever client's
own `Interface/AddOns/` folder once it is released).

## Credits and licence

By Tziera. Licensed under the GNU General Public License v3.0 or later, see
`LICENSE.txt`.

- `ClassicQuests.lua` is generated from the Forever data in
  [QuestieDB](https://github.com/Questie/QuestieDB) by the
  [Questie](https://github.com/Questie/Questie) team (GPL-3.0), using
  Questie's quest blacklist.
- The levels and some of the requirements of the dungeon quests come from
  [WoW Forever Builds](https://github.com/Boco10/WoWForeverBuilds-Addon)
  (MIT License, see `LICENSE-WoWForeverBuilds.txt`).
- The fonts in `Fonts/` are Alegreya Sans, Barlow Semi Condensed, Cinzel,
  PT Sans Narrow and Source Sans 3, under the SIL Open Font License. Their
  licence files are included in that folder.
