# Forever Secret Tracker

A checklist of WoW Forever's secrets: hidden pets, quest chains with no
quest marker, secret bosses and places, rares, items with a twist, and the
mysteries nobody has solved yet.

`/fst` (or `/secrettracker`, the minimap button, or the addon button by
the minimap) opens the window.

- **Overview tab:** every secret as an icon, grouped by type. Found ones
  are in colour with a gold name, the rest are grey. Each shows how many
  steps you have done. The mouse wheel or the arrows turn the page, and a
  click opens that secret's guide.
- **Guides tab:** the list on the left, the selected guide on the right:
  icon, what it is, the reward, a progress bar and the steps. The step to
  do next is marked in gold. Steps tick themselves off, and a step that is
  done marks every step before it. The pin on a step with a spot sets a
  waypoint (TomTom when installed, otherwise Blizzard's own map pin).
  Right-click a step to mark it by hand, *Mark as done* marks the whole
  secret. Pets show their model, which you can turn with the mouse.
- **Filter:** found, not found, other factions and classes, the types, and
  the sort order. The search box looks through names, zones, rewards and
  step text.
- **Toast:** a "Secret found!" toast with a sound when one is found; click
  it to open the guide. Secrets you already had at login are counted
  silently.
- Mysteries are listed last and do not count towards *x / y secrets found*.

## Commands

| Command | |
|---|---|
| `/fst` | open or close the window |
| `/fst minimap` | show or hide the minimap button |
| `/fst chat` | turn the addon's own chat lines (finds, waypoints) on or off |
| `/fst guild` | post finds in guild chat, on or off (off by default) |
| `/fst options` | open the options page |
| `/fst log [n]` | the last n quests, items, pets and kills it recorded |
| `/fst reset confirm` | forget every mark made by hand |

## How steps are checked

Forever does not flag every quest it hands in, so the addon keeps its own
record per character: quests taken and turned in (by ID and title), items
looted that the data looks for or that are quest items, pets learned, and
kills of the names the data waits for (dungeon encounters, or a watched
name targeted dead). A step's `check` passes when any of its tests does:

| Key | Passes when |
|---|---|
| `quest = id` | the quest is turned in |
| `onQuest = id` | the quest is in the log or turned in |
| `questName = "Title"` | a quest with that title was turned in |
| `questAccepted = "Title"` | a quest with that title is in the log, was taken or was turned in |
| `item = id` / `itemName = "Name"` | the item was looted, or is in the bags or bank |
| `pet = "Name"` | the pet is in the collection |
| `kill = "Name"` | the NPC was seen dead |

Values can be lists. `all = true` makes every test have to pass instead
of any one. Titles and names are compared without case.

Quests are checked by ID where it is known: Forever gives some chains one
title for every part (all four Captain Sander quests are called *Captain
Sander's Hidden Treasure*). When ZoneLevelGuide is loaded, the quests it has
recorded as handed in (`ZoneLevelGuideDB.handedIn`) count too, so what was
done before this addon was installed shows up.

A step with `macro = "/dance"` gets a small button that runs that line
(the Excitable Slime's /target and /dance, the Gustjumper's /sing). Targeting
and emotes are protected, so it is a secure macro button: it only works on
your own click, and does not change during combat.

Steps with the same `pick` are alternatives, and `picks = { name = n }` on
the secret says how many of them are needed. They count as n steps; once n
are done the rest are shown as optional (Blessing of Kalimdor: two of the
three rares).

## Options

Under *Options > AddOns > Forever Secret Tracker*, or with the commands
above: whether finds and waypoints are written in chat (only you see
them), whether finds are posted in guild chat, and the minimap button.
Guild posts say *Found a secret: <name>!* and only go out for finds the
addon saw itself, not for marks made by hand.

The page also says where to send reports: a step that does not tick off, a
wrong spot, or a secret that is missing. Click the address
(wowtziera@gmail.com) to get it in a box to copy; `/fst help` prints it too.

## Secret bosses as encounters

Forever's client has no Encounter Journal tables (wago.tools has no
`JournalInstance` or `JournalEncounter` for 1.60.1.70753), so there is no
journal text for these bosses. They are real encounters in
`DungeonEncounter`, though, so `ENCOUNTER_END` sees them die:

| Encounter | ID | Map |
|---|---|---|
| The Abandoned | 3357 | Ruins of Lordaeron (2999) |
| Viktor the Vile | 3411 | Ruins of Lordaeron (2999) |
| Lyn the Ignored | 3310 | City of Dalaran (2959) |

The rest of Ruins of Lordaeron in the same table: Witherfang, The Butcher,
Lordaeron Captain, Bjork, Rath'mael. Guides call The Butcher "The Baron".

DungeonJournal (`ForeverDungeonJournal`, `/dj`) has all three on its
dungeon maps with their loot, and Lyn's summon with the Tome of Dalaran
(item 275989, which the Lyn guide here checks for too). It does not say
how The Abandoned and Viktor are started; that is what the guide here is
for.

## The account log

Every recorded event also goes into `ForeverSecretTrackerAccountDB.log`
(the last 500), with character, zone, map and coordinates. Most guides give
no quest, item or NPC IDs, so this log is where they come from: do a
secret, and the IDs and spots can be read out of the saved file and put
into `Secrets.lua`.

## Data

`Secrets.lua` holds the secrets, gathered 2026-11-11 from
[wowhandbook.com/secrets](https://wowhandbook.com/secrets/),
[wowclassicforever.info/secrets](https://wowclassicforever.info/secrets/),
[lostwow.com](https://lostwow.com/ForeverSecrets.shtml),
[wowforeverbuilder.com](https://wowforeverbuilder.com/guides/secrets/) and
[conquestcapped.com](https://conquestcapped.com/guides/wow-forever/wow-forever-cozy-sleeping-bag/).
Much of it comes from beta reports and is not confirmed on live servers yet.

The Alcaz Operative Insignia came from a "mystery solved" post on the
[WoW Secret Finding & Collections](https://discord.gg/wowsecrets) Discord,
2026-11-11; both it and Dawn Waker credit that server in the guide, with
the link to copy. It gave no quest IDs, no coordinates
for Rix Xizzix or Renzik, and does not say what Mason Connery's first quest
is called. It names the toy both "Alcaz Operative Disguise" and "Alcaz
Operative Insignia", so the guide checks for both.

Dawn Waker is from a work-in-progress post on the same Discord,
2026-11-11, and is kept as a mystery until the chain is solved. It
replaces the Hidden Blade entry, since the post takes the chain for the
answer to the podcast's blackboard clue, though only as a "possibly". Parts
1-3 are in the guide; part 4 is only in a Discord message. The Night
Watchman's Torch is item 280612 (Wowhead Forever). The Alliance fragments
are written "Mathystral Amulet Fragments" in the post; the guide calls them
Mathystra after the ruins and checks no name for them.

Wit's Edge has two credits: the weapon was first posted by
[Kissta96 on Reddit](https://www.reddit.com/user/Kissta96/), the Scroll of
Wit by the same Discord. A secret's `credit` can be one source or a list,
each with an optional `what` ("Weapon", "Scroll") for its line in the guide.

Not confirmed, or reported differently by different sources:

- **Cozy Sleeping Bag:** the Mound of Dirt is at 39.6, 49.8 (Conquest
  Capped) or 39.6, 46.7 (Lost WoW); the camp at 40.6, 52.4 or 40.7, 53.2.
  The quest IDs 79008/79007 for the first note are from Wowhead via the
  guides.
- **Musical Gustjumper:** 51.5, 72.1 (wowclassicforever) or 51.5, 72.3
  (Lost WoW).
- **Baby Crocolisk:** the drop is from September beta reports, and the
  item was missing from the client's item table then.
- **Silver of the Waves:** no quest title given; it is checked by the
  reward, Repurposed Hair Band.
- **Malignant Root:** where the innards are traded is not documented.
- **Applejack Still:** quests 91736 and 91738, Thunder Applejack 247824,
  the still is object 562131 (wowhandbook).
- **Drunken Dwarf Tavern:** the reward is Aetherstill Spirits
  (wowhandbook) or a slow-fall ale (Lost WoW).
- **Coldflame Saber:** combined with the scroll (wowhandbook) or through
  the Comprehension skill (Lost WoW).
- **The Stone Key:** the trail ends at the Riverglades key (wowhandbook)
  or reaches Blackrock Mountain (Lost WoW).

No coordinates in any source: Lyn the Ignored's rune and the Drunken Dwarf
climb. The account log fills them in once someone does them. The spawns
for Excitable Slime, Sewer Beast, the Whispering Horror and the three
Barrens rares are from QuestieDB's Forever NPC data (2026-11-09).

Embrace of the Viper was taken out on 2026-11-11.

Left out because they are ordinary quests with a quest giver: Among the
Faithful, Meddlesome Mages, the Bloody Map chain (where the map leads is
kept as a mystery) and Wolfsbane.

Left out for now: plain drops without a twist (Rockslicer, Partners in
Crime's first ring is listed only as a mystery), Savory Whimsyfin Delight,
Night Watchman's Torch (it is part of the Stone Key trail), and finds
without steps (Gift of Galloping, Tidal Charm, the Black Market).

## Credits

By Tziera. GPL-3.0-or-later. The finds belong to the people and sites who
wrote them up; the guide names them where a secret was first posted, and
the sites the rest came from are listed under Data.
