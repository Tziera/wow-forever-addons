-- Mob levels measured inside dungeons, collected from SavedVariables with
-- tools/harvest-levels.lua. The script rewrites this file; edit it by hand
-- only to remove a measurement that turned out to be wrong.
--
-- [instance name as the client gives it] = { min, max, atLow, atHigh }, where
-- atLow/atHigh are your own level at the measurements.
local _, ns = ...

ns.MEASURED_LEVELS = {
    ["Blackfathom Deeps"] = { min = 22, max = 26, atLow = 26, atHigh = 26 },
    ["Deadmines"] = { min = 16, max = 21, atLow = 22, atHigh = 23 },
    ["Ragefire Chasm"] = { min = 13, max = 16, atLow = 13, atHigh = 30 },
    ["Ruins of Lordaeron"] = { min = 15, max = 20, atLow = 21, atHigh = 24 },
    ["Shadowfang Keep"] = { min = 18, max = 25, atLow = 25, atHigh = 25 },
    ["Stormwind Stockade"] = { min = 23, max = 29, atLow = 25, atHigh = 25 },
    ["The Hall of Thanes"] = { min = 13, max = 16, atLow = 14, atHigh = 18 },
    ["Wailing Caverns"] = { min = 17, max = 22, atLow = 20, atHigh = 20 },
}
