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
  zone to open the map on it (with `/zlg map` on). Click a quest to put a
  pin where it is picked up. A book that is handed in somewhere else is listed in the zone where
  the book lies, in each zone when it lies in several (`Books.lua`, by the
  quest's title, so either side's quest finds it): click pins the book,
  nearest first, ctrl-click the one who takes it. A book whose quest is not
  recorded yet for your side is listed anyway, handed in to Garion Wendell
  or Owen Thadd. A quest that starts from an item is listed where the item
  drops or lies, by Questie's data, with who drops it in the tooltip; when it
  is in a few places (Chen's Empty Keg, Owatanka), click pins the nearest, and clicking again the next. The
  same goes for quests that only hint at where they are handed in, such as
  a treasure hunt: once the place is known, ctrl-click marks it. Likewise
  for someone a quest sends you to find who has no map marker, such as
  Mankrik's wife for Lost in Battle.
- **The map opens only if you ask for it.** A click sets the pin and the
  arrow; open the map yourself with M. With `/zlg map` (or the checkbox in
  the options) a click opens the map too, but a map opened by an addon
  carries its taint in the pins it draws, and opening the map yourself in
  combat later can then give a "blocked from an action" error.
- **Quests are recorded when you take them.** The quest giver, the quest
  level, the zone, the coordinates and the faction are saved on accept. Quests
  that start from an item are marked as such. Dungeon quests get a dungeon
  icon. A quest shared by another player is not recorded, since it says
  nothing about where the quest is picked up. A quest that is never taken,
  where an NPC takes an item and the quest is done at once, is recorded when
  you hand it in, with that NPC as its giver.
- **Quest data included.** The addon ships with quests recorded in the
  Forever beta, and with quests from [Questie](https://github.com/Questie/QuestieDB)'s
  Forever data not yet recorded. Those are marked `(preliminary)`. A quest you
  record yourself always wins over the shipped data.
- **Only what you can take.** A quest that Questie says needs an earlier
  quest stays hidden until that one is handed in, so the list shows the start
  of each chain and not every step. A chain recorded in play wins over
  Questie's, except that when Questie says several quests are all needed and
  the recording names one of them, the rest are still needed too. With chain
  help on, every quest shows.
- **Chains and requirements.** `(chain)` means another quest must be done
  first, and the tooltip follows the chain back to where it starts.
  `(needs)` means something else is required, such as an item, or that
  handing in another quest (or several) unlocks it without it being a chain. `(either)`
  means only one of two quests can be done. A quest that points you on to
  another, without the other needing it, says so in its tooltip. `(repeatable)` means it
  can be handed in again and again. Class and profession quests are
  labelled, and profession quests fade if you lack the profession.
  Legacy rewards, handed out at innkeepers, are marked `(legacy 15)` and
  stay hidden until your account reaches that level on the Legacy Track.
- **Help find quest chains** (off by default). Every quest shows, also
  those Questie says need an earlier quest; the tooltip names it. When a quest is offered
  straight after you hand in another one, it is probably the next step of a
  chain. Tick "Help find quest chains" under Options → AddOns, or type
  `/zlg chains`, and such quests are marked `(chain?)`. Right-click one to
  answer: "Yes, it comes after …", "No, but … unlocked it" or "Not a chain". Your answers are saved
  with your recorded quests, in
  `WTF/Account/<account>/<realm>/<character>/SavedVariables/ZoneLevelGuide.lua`.
  To have them included in the next release, email that file to
  wowtziera@gmail.com.
- **Search.** Type two letters or more in the box under the level row and
  the list shows every quest whose title, giver, zone, profession, class,
  holiday or needed item matches (`Call of Water`, `Brine`, `Stonetalon`,
  `Leatherworking`), from every zone, with the zone as a tag. Hover the box
  for examples. Quests too high or grey for you are faded, and one
  whose chain you have not reached says `(after …)`. Escape empties the box.
- **Your class quests** are also gathered under your class's name, at the
  top of the list, while one of them is open within your level window. Chains
  such as Call of Water then read in one place; each quest still shows in its
  own zone too. Holidays get the same kind of group while they are on:
  Hallow's End, Feast of Winter Veil, Lunar Festival and Love is in the Air,
  read from the game's calendar (or the usual dates when it does not answer).
- **Your professions' quests** get a group each at the bottom of the list,
  and Cooking, First Aid and Fishing share one, "Secondary Skills". A
  quest that needs more skill than you have is red, with the skill it needs
  after the title (`Thick Hides [105]`); one more than 10 points above you
  is hidden. `/zlg skill` hides all of those above your skill instead. The
  skill requirements come from Questie's data.
- **Cities** appear as their own rows when they have a quest you have not
  handed in, at most five levels above yours. Grey quests count only while
  "Low-Level Quests" is ticked in the minimap's tracking menu.
- **Filters**, all off by default: `/zlg done` hides quests you have handed
  in, or can never take again (otherwise they fade), `/zlg high` hides quests more than five levels
  above you, `/zlg profession` hides quests for a profession you don't
  have (otherwise they fade), and `/zlg steps` shows only the next step of
  each chain even with chain help on: a later step stays hidden until the one before it is handed in. If "Low-Level Quests" is unticked in the minimap's
  tracking menu, grey quests are hidden too, just like on the map, except
  the ones in your quest log.
- The −/+ beside the close button folds the panel up to its title bar, like
  Blizzard's quest tracker, and unfolds it to the height it had.
- Seven looks: `warm` (default), `flat`, `blizzard` and `minimal`, plus
  `elvui`, `details` and `pfui` to match those addons.
- Snaps to Dungeon Level Guide and Turn-In Queue: drop one panel within a
  few pixels of another's edge and they move together.

## Commands

| Command | Does |
|---|---|
| `/zlg` | Show/hide the panel |
| `/zlg range <n>` | Also show zones up to n levels outside their range |
| `/zlg faction` | Show/hide the other faction's zones |
| `/zlg done` | Show/hide quests you have handed in |
| `/zlg map` | Open the map on a click, or only set the pin (default) |
| `/zlg high` | Show/hide quests more than 5 levels above you |
| `/zlg profession` | Show/hide quests for professions you don't have |
| `/zlg skill` | Show/hide profession quests above your skill (otherwise red, up to 10 above) |
| `/zlg steps` | With chain help on: show only the next step of each chain, or every step |
| `/zlg chains` | Turn chain help on or off: show every quest, and mark ones that may follow another |
| `/zlg quests` | List the quests recorded this session, marked new/known/news |
| `/zlg after [id] <quest>` | Note that a quest comes after another one (without an id: the last quest taken) |
| `/zlg needs [id] <text>` | Note what a quest requires, e.g. an item |
| `/zlg style <name>` | `warm`, `flat`, `blizzard`, `elvui`, `details`, `pfui` or `minimal` |
| `/zlg font <n>` / `/zlg alpha <n>` | Text size and background opacity |
| `/zlg reset` | Put the panel back in its default position and size |

Drag the title bar to move the panel, and the bottom-right corner to resize
it. Settings and recorded quests are saved per character.

## Installation

Put the `ZoneLevelGuide` folder in `World of Warcraft/_forever_/Interface/AddOns/`.

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

Special thanks to **Zulakbar the hunter**, who sent in more quests from the
Forever beta than anyone else.
