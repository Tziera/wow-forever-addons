-- Mob levels measured inside dungeons, collected from SavedVariables with
-- tools/harvest-levels.lua. The script rewrites this file; edit it by hand
-- only to remove a measurement that turned out to be wrong.
--
-- [instance name as the client gives it] = { min, max, atLow, atHigh }, where
-- atLow/atHigh are your own level at the measurements.
local _, ns = ...

ns.MEASURED_LEVELS = {
    ["Ragefire Chasm"] = { min = 13, max = 16, atLow = 17, atHigh = 17 },
    ["The Hall of Thanes"] = { min = 13, max = 16, atLow = 14, atHigh = 18 },
}
