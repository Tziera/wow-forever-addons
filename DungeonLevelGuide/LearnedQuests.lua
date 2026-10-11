-- Dungeon quests learned in play, collected from SavedVariables with
-- tools/harvest-learned.lua. The script rewrites this file; edit it by hand
-- only to remove a record that turned out to be wrong.
--
-- [questID] = { dungeon, confirmed, title, level, giver, zone, mapID, x, y, side }
local _, ns = ...

ns.LEARNED_QUESTS = {
    [2928] = { dungeon = "Gnomeregan", title = "Gyrodrillmatic Excavationators", level = 30, giver = "Shoni the Shilent", zone = "Stormwind City", mapID = 1453, x = 62.5, y = 34.1, side = "A" },
    [2931] = { dungeon = "Gnomeregan", title = "Castpipe's Task", level = 28, giver = "Gaxim Rustfizzle", zone = "Stonetalon Mountains", mapID = 1442, x = 59.5, y = 67.1, side = "A" },
}
