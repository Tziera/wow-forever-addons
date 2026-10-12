local _, ns = ...

-- Where the books lie that librarians take straight in, by the title of the
-- quest that hands them in. Either side's quest finds its book here, and a
-- book that lies in several places is listed in each of their zones.
-- { zone, mapID, x, y, hint }
local function at(zone, mapID, x, y, hint)
    return { zone = zone, mapID = mapID, x = x, y = y, hint = hint }
end

ns.BOOKS = {
    ["Nar'thalas Almanac"] = {
        at("Darkshore", 1439, 59.6, 22.2, "Down the stairs of the ruins; the book is Nar'thalas Almanac, Vol. 74"),
        at("The Barrens", 1413, 52.8, 54.7, "Scrolls just past the Wailing Caverns entrance"),
        at("Loch Modan", 1432, 77.4, 14.1, "Scrolls at the back of a cave full of elite ogres"),
        at("Stonetalon Mountains", 1442, 74.4, 85.7, "Scrolls in a tent"),
    },
    ["The Dalaran Digest"] = {
        at("Silverpine Forest", 1421, 63.4, 63.1, "The book is The Dalaran Digest, Vol. 23"),
    },
    ["Bewitchments and Glamours"] = {
        at("Westfall", 1436, 45.4, 70.4, "In a house in Moonbrook"),
        at("Zephras Isle", 2521, 35.6, 24.1),
        at("Zephras Isle", 2521, 37.1, 32.9),
        at("Zephras Isle", 2521, 44.3, 26.7),
        at("Zephras Isle", 2521, 51.8, 67.4),
        at("Zephras Isle", 2521, 55.7, 59.7),
        at("Zephras Isle", 2521, 61.8, 51.5),
        at("Zephras Isle", 2521, 65.0, 36.3),
        at("Zephras Isle", 2521, 65.5, 69.9),
    },
    ["Secrets of the Dreamers"] = {
        at("The Barrens", 1413, 52.8, 54.7, "Just past the Wailing Caverns entrance"),
    },
    ["Arcanic Systems Manual"] = {
        at("The Barrens", 1413, 56.3, 8.8, "Top of the oil rig, in the foreman's room"),
    },
    ["Crimes Against Anatomy"] = {
        at("Duskwood", 1431, 16.4, 28.4, "Underground in the crypt"),
    },
    ["Runes of the Sorcerer-Kings"] = {
        at("Loch Modan", 1432, 77.4, 14.0, "At the back of a cave full of elite ogres"),
    },
    ["Fury of the Land"] = {
        at("Stonetalon Mountains", 1442, 74.4, 85.7, "In a tent"),
    },
    ["Archmage Antonidas: The Unabridged Autobiography"] = {
        at("Ironforge", 1455, 75.4, 11.0, "In the Hall of Explorers"),
        at("Elwynn Forest", 1429, 65.4, 70.1, "Inside the tower, just below the top"),
    },
    ["Archmage Theocritus' Research Journal"] = {
        at("Elwynn Forest", 1429, 65.4, 70.1, "Inside the tower, just below the top"),
    },
    ["Rumi of Gnomeregan: The Collected Works"] = {
        at("Westfall", 1436, 52.7, 53.8, "In the inn"),
        at("Loch Modan", 1432, 35.6, 48.9, "In the inn at Thelsamar"),
    },
    ["Baxtan: On Destructive Magics"] = {
        at("The Barrens", 1413, 62.7, 36.3, "In the engineering building in Ratchet"),
    },
    ["Basilisks: Should Petrification be Feared?"] = {
        at("Stranglethorn Vale", 1434, 41.4, 50.9, "Deep among hostile mobs"),
    },
    ["Geomancy: The Stone-Cold Truth"] = {
        at("Thousand Needles", 1441, 34.4, 40.1, "In a tent on a plateau; the path up starts near (31, 36)"),
    },
    ["Defensive Magics 101"] = {
        at("Alterac Mountains", 1416, 48.4, 57.7, "Angle the camera from outside to reach it"),
    },
    ["A Web of Lies: Debunking Myths and Legends"] = {
        at("Arathi Highlands", 1417, 73.6, 65.2, "In a troll camp tent; reachable through gaps in the roof"),
    },
    ["Demons and You"] = {
        at("Desolace", 1443, 55.1, 26.2, "In a room full of demons; take a group"),
    },
    ["Mummies: A Guide to the Unsavory Undead"] = {
        at("Badlands", 1418, 56.7, 39.9, "Underground in a crypt"),
    },
    ["RwlRwlRwlRwl!"] = {
        at("Dustwallow Marsh", 1445, 57.2, 20.8, "Under a crowd of murlocs; take a group"),
    },
    ["Sanguine Sorcery"] = {
        at("Swamp of Sorrows", 1435, 70.1, 51.8, "On top of the temple"),
    },
    ["Legends of the Tidesages"] = {
        at("Tanaris", 1446, 72.6, 47.8, "Among many ranged mobs; take a group"),
    },
    ["Everyday Etiquette"] = {
        at("Azshara", 1447, 20.8, 62.0, "Near the flight path"),
    },
    ["Stonewrought Design"] = {
        at("Burning Steppes", 1428, 29.1, 28.9,
            "In the tomb by the summoning stone in Blackrock Mountain, next to Franclorn Forgewright; also in the Iron Vault of Blackrock Depths"),
    },
    ["Venomous Journeys"] = {
        at("Hinterlands", 1425, 36.0, 72.8, "Behind a wall in a troll camp; hard alone"),
    },
    ["A Mind of Metal"] = {
        at("Searing Gorge", 1427, 37.8, 49.3, "In a tent where a Dark Iron spawns; take a group"),
    },
    ["Conjurer's Codex"] = {
        at("Blasted Lands", 1419, 55.4, 32.2, "In a burned-down building"),
    },
    ["The Lessons of Ta'zo"] = {
        at("Orgrimmar", 1454, 38.7, 78.4),
    },
    ["The Apothecary's Metaphysical Primer"] = {
        at("Tirisfal Glades", 1420, 59.4, 52.3, "In Brill"),
    },
    -- In the guide, no quest for them recorded yet.
    ["A Study of the Light"] = {
        at("Eastern Plaguelands", 1423, 81.7, 57.8),
    },
    ["The Knight and the Lady"] = {
        at("Eastern Plaguelands", 1423, 54.5, 50.8),
    },
    ["Scourge: Undead Menace or Misunderstood?"] = {
        at("Eastern Plaguelands", 1423, 31.3, 21.0),
    },
    ["Undead Potatoes"] = {
        at("Western Plaguelands", 1422, 38.3, 54.6),
    },
    ["Necromancy 101"] = {
        at("Western Plaguelands", 1422, 69.4, 72.8),
    },
    ["Northern Kalimdor - A Comprehensive Guide"] = {
        at("Felwood", 1448, 65.2, 3.2, "Inside Timbermaw Hold"),
    },
    ["The Liminal and the Arcane"] = {
        at("Feralas", 1444, 50.6, 15.7),
    },
    ["Ataeric: On Arcane Curiosities"] = {
        at("Silverpine Forest", 1421, 43.4, 41.2),
    },
    ["A Luddite's Guide to Caring for Your Demonic Pet"] = {
        at("Swamp of Sorrows", 1435, 61.0, 22.0),
    },
    ["Goaz Scrolls"] = {
        at("Wetlands", 1437, 33.6, 47.9),
    },
    ["Ka-Boom!"] = {
        at("Winterspring", 1452, 60.7, 37.7),
    },
}
