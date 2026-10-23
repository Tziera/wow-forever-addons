# HealerMana

Shows the mana of the healers in your group or raid in **WoW: Forever**, one
bar for each healer, so the tank or raid leader can tell at a glance whether
to wait before the next pull.

## Features

- **Only those who picked the healer role** count, so there is no guessing
  from class. With no healer role in the group, the frame says so.
- **One bar per healer**, the name on the left and the mana in percent on the
  right: red below 30 %, yellow below 60 %, green above. Dead or offline
  healers keep their place, with an empty bar.
- **No average.** Forever hands out mana as protected values that an addon may
  show but not add up, so each healer gets a bar of their own.
- **Grows down or up** as healers join: `/hm grow up` keeps the bottom edge in
  place, for a frame near the bottom of the screen.
- **Seven styles**, the same as Zone Level Guide, Dungeon Level Guide and
  Turn-In Queue: Blizzard, Flat dark, Warm classic (the default), ElvUI,
  Details!, pfUI and Minimal. Text size from 50 to 200 %.
- **Unlocked, it shows outside a group too**, with two sample bars, so it can
  be dragged and sized. Locked, it only shows in a group.
- A settings page under *Esc → Options → AddOns*.

## Commands

| Command | Does |
|---|---|
| `/hm` | Show the current settings and the commands |
| `/hm on` / `/hm off` | Show or hide the frame |
| `/hm unlock` | Show it outside a group, to drag it and drag its corner to resize |
| `/hm lock` | Fix it in place; it then only shows in a group |
| `/hm reset` | Move it back to the top of the screen, at its smallest |
| `/hm grow up` / `/hm grow down` | Which way more healers make the frame grow |
| `/hm style <name>` | `blizzard`, `flat`, `warm`, `elvui`, `details`, `pfui`, `minimal` |
| `/hm size <50-200>` | Text size in percent |

`/healermana` works too. Settings are saved per character.

## Installation

Put the `HealerMana` folder in `World of Warcraft/_forever_/Interface/AddOns/`.

## Credits and licence

By Tziera. Licensed under the GNU General Public License v3.0 or later, see
`LICENSE.txt`.

The fonts in `Fonts/` are under the SIL Open Font License 1.1, each with its
licence beside it: Alegreya Sans, Barlow Semi Condensed, Cinzel, PT Sans
Narrow and Source Sans 3.
