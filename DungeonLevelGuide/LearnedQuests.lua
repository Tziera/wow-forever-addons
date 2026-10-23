-- Dungeon quests learned in play, collected from SavedVariables with
-- tools/harvest-learned.lua. The script rewrites this file; edit it by hand
-- only to remove a record that turned out to be wrong.
--
-- [questID] = { dungeon, confirmed, title, level, giver, zone, mapID, x, y, side }
local _, ns = ...

ns.LEARNED_QUESTS = {
    [96988] = { dungeon = "City of Dalaran", title = "Source of Power", level = 33, giver = "Doctor Martin Felben", zone = "Undercity", mapID = 1458, x = 46.9, y = 74.2, side = "H" },
    [2841] = { dungeon = "Gnomeregan", title = "Rig Wars", level = 35, giver = "Nogg", zone = "Orgrimmar", mapID = 1454, x = 75.9, y = 25.2, side = "H" },
    [2928] = { dungeon = "Gnomeregan", title = "Gyrodrillmatic Excavationators", level = 30, giver = "Shoni the Shilent", zone = "Stormwind City", mapID = 1453, x = 62.5, y = 34.1, side = "A" },
    [2931] = { dungeon = "Gnomeregan", title = "Castpipe's Task", level = 28, giver = "Gaxim Rustfizzle", zone = "Stonetalon Mountains", mapID = 1442, x = 59.5, y = 67.1, side = "A" },
    [1102] = { dungeon = "Razorfen Kraul", title = "A Vengeful Fate", level = 34, giver = "Auld Stonespire", zone = "Thunder Bluff", mapID = 1456, x = 36.5, y = 59.8, side = "H" },
    [1109] = { dungeon = "Razorfen Kraul", title = "Going, Going, Guano!", level = 33, giver = "Master Apothecary Faranell", zone = "Undercity", mapID = 1458, x = 49.2, y = 69.6, side = "H" },
    [96774] = { dungeon = "The Drowned City", title = "Ancient Gurubashi Idol", level = 40, giver = "Mazu'kon", zone = "Mulgore", mapID = 1412, x = 32.6, y = 20.7, side = "H" },
}
