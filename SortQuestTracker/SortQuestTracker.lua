-- SortQuestTracker -- orders the quests in Blizzard's tracker: the ones with
-- something to do in the zone you are in first, then the rest, and by quest
-- level within each group -- or by distance, nearest first, if you choose.
--
-- The tracker shows quests in the order they were watched, so sorting means
-- taking every watch off and putting them back in the wanted order.

local PREFIX = "|cff00ff00SortQuestTracker|r: "
local DEFAULTS = { enabled = true, trackHere = true, withController = false, sortBy = "level" }
local CONTINENT_MAP_TYPE, ZONE_MAP_TYPE, DUNGEON_MAP_TYPE = 2, 3, 4
local THROTTLE = 0.5
-- By distance: how often to look whether you have moved, how far counts as
-- moved (map share), and how close two distances may be and still count as
-- the same, so two quests side by side do not trade places at every step.
local WALK_CHECK, WALK_MOVED = 3, 0.01
local SAME_YARDS, SAME_SHARE = 25, 0.02

local db
local sorting, pending, queued = false, false, false
local lastSpot
-- questID -> GetTime() it was taken, so the client's own watch on a new quest
-- is not taken for one you added yourself.
local acceptedAt = {}
local ACCEPT_WATCH = 2

-- ------------------------------------------------------------
-- Where you are
-- ------------------------------------------------------------

local function MapInfo(mapID)
    if not (mapID and C_Map and C_Map.GetMapInfo) then return nil end
    local ok, info = pcall(C_Map.GetMapInfo, mapID)
    return ok and info or nil
end

-- Where you stand: the dungeon you are in, if any, the zone (not the cave or
-- town map, and for a dungeon the zone it hangs under) and the continent.
local function CurrentPlace()
    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local info = MapInfo(mapID)
    local place = { chain = {} }
    for _ = 1, 8 do
        if not info then break end
        table.insert(place.chain, ("%s:%s"):format(tostring(info.mapID), tostring(info.mapType)))
        if info.mapType == DUNGEON_MAP_TYPE and not place.dungeon and not place.zone then place.dungeon = info end
        if info.mapType == ZONE_MAP_TYPE and not place.zone then place.zone = info end
        if info.mapType == CONTINENT_MAP_TYPE then
            place.continent = info
            break
        end
        if not (info.parentMapID and info.parentMapID > 0) then break end
        info = MapInfo(info.parentMapID)
    end
    -- Some caves hang straight under the continent: ask the continent which
    -- zone you are standing in.
    if place.continent and not place.zone and C_Map.GetPlayerMapPosition and C_Map.GetMapInfoAtPosition then
        local okPos, pos = pcall(C_Map.GetPlayerMapPosition, place.continent.mapID, "player")
        local x, y
        if okPos and pos and pos.GetXY then x, y = pos:GetXY() end
        if x and y then
            local okAt, at = pcall(C_Map.GetMapInfoAtPosition, place.continent.mapID, x, y)
            if okAt and at and at.mapType == ZONE_MAP_TYPE then place.zone = at end
        end
    end
    -- Inside a dungeon Forever's map is the continent's, so ask the instance.
    if not place.dungeon and IsInInstance and GetInstanceInfo then
        local inside, kind = IsInInstance()
        if inside and (kind == "party" or kind == "raid") then
            local name = GetInstanceInfo()
            if name then place.dungeon = { name = name } end
        end
    end
    return place
end

-- The Controller UI has no API of its own to ask; its frames give it away:
-- the gamepad action bar shows, and the cinematic skip button only exists
-- there. Its tracker lays itself out slowly enough that every watch change
-- is felt, so sorting there is a choice (withController).
local function ControllerUI()
    local bar = GamepadMainActionBarFrame
    return (GamepadCinematicSkipButton or (bar and bar.IsShown and bar:IsShown())) and true or false
end

local function Paused()
    return not db.withController and ControllerUI()
end

-- Quest log headers and map names do not always agree on a leading "The".
local function SameName(a, b)
    if not (a and b) then return false end
    local function norm(name) return (name:lower():gsub("^the ", "")) end
    return norm(a) == norm(b)
end

-- ------------------------------------------------------------
-- The quest log
-- ------------------------------------------------------------

-- Done: ready to hand in. Asked the way TurnInQueue asks, since the log
-- entry's own isComplete is missing in Forever; Classic's -1 means failed.
local function IsDone(questID, logValue)
    if C_QuestLog and C_QuestLog.ReadyForTurnIn then
        local ok, ready = pcall(C_QuestLog.ReadyForTurnIn, questID)
        if ok then return ready and true or false end
    end
    if C_QuestLog and C_QuestLog.IsComplete then
        local ok, complete = pcall(C_QuestLog.IsComplete, questID)
        if ok then return complete and true or false end
    end
    return logValue == true or logValue == 1
end

-- TurnInQueue takes a done quest off the tracker when you worked for it
-- (its `earned`), or any done quest if told to. Those are left to it; every
-- other done quest, a delivery such as one that was done when you took it,
-- is placed like the rest, so the two addons do not undo each other.
local function TIQTakes(questID)
    local tiq = TurnInQueueDB
    if not (type(tiq) == "table" and tiq.autoUntrack) then return false end
    return (tiq.untrackDeliveries or (type(tiq.earned) == "table" and tiq.earned[questID])) and true or false
end

-- questID -> { level, title, header } for every quest in the log. A quest
-- under a collapsed header is not listed by the client, so it has no header.
local function ReadLog()
    local log = {}
    local header
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
        for index = 1, C_QuestLog.GetNumQuestLogEntries() or 0 do
            local info = C_QuestLog.GetInfo(index)
            if info and info.isHeader then
                header = info.title
            elseif info and info.questID then
                log[info.questID] = { level = info.difficultyLevel or info.level or 0, title = info.title or "",
                    header = header, index = index, complete = IsDone(info.questID, info.isComplete) }
            end
        end
    elseif GetNumQuestLogEntries and GetQuestLogTitle then
        for index = 1, (GetNumQuestLogEntries()) or 0 do
            local title, level, _, isHeader, _, isComplete, _, questID = GetQuestLogTitle(index)
            if isHeader then
                header = title
            elseif questID then
                log[questID] = { level = level or 0, title = title or "", header = header, index = index,
                    complete = IsDone(questID, isComplete) }
            end
        end
    end
    return log
end

-- ------------------------------------------------------------
-- Where a quest's objectives are
-- ------------------------------------------------------------

local function ZonesOf(continentID)
    if not (continentID and C_Map and C_Map.GetMapChildrenInfo) then return {} end
    local ok, children = pcall(C_Map.GetMapChildrenInfo, continentID, ZONE_MAP_TYPE, true)
    return ok and type(children) == "table" and children or {}
end

-- questID -> set of mapIDs where the map shows something to do for it, over
-- every zone on your continent and the dungeon you are in. A done quest, or
-- one under this zone's header, with nothing here is looked for on the other
-- continents too, so one done there is not taken for one from here. Nil when
-- the client cannot tell.
local function ObjectiveZones(place, log)
    if not (C_QuestLog and C_QuestLog.GetQuestsOnMap) then return nil end
    local maps = {}
    if place.dungeon and place.dungeon.mapID then table.insert(maps, place.dungeon.mapID) end
    if place.zone then table.insert(maps, place.zone.mapID) end
    for _, child in ipairs(ZonesOf(place.continent and place.continent.mapID)) do table.insert(maps, child.mapID) end
    if #maps == 0 then return nil end
    local zones = {}
    local function Read(mapID, only)
        local okOn, onMap = pcall(C_QuestLog.GetQuestsOnMap, mapID)
        if not (okOn and type(onMap) == "table") then return end
        -- A map also lists its neighbours' quests; each says which map it is
        -- on, but its spot is on the map that listed it. The listing from
        -- the quest's own map wins, whichever was asked first.
        for _, quest in ipairs(onMap) do
            if quest.questID and (not only or only[quest.questID]) then
                local on = quest.mapID or mapID
                zones[quest.questID] = zones[quest.questID] or {}
                local had = zones[quest.questID][on]
                if not had or (had.from ~= on and (mapID == on or not had.x)) then
                    zones[quest.questID][on] = { x = quest.x, y = quest.y, from = mapID }
                end
            end
        end
    end
    for _, mapID in ipairs(maps) do Read(mapID) end
    local missing
    for questID, q in pairs(log or {}) do
        -- Also one under this zone's header: a chain started in a city has
        -- the city as its header, though it is done somewhere else.
        local underHere = (place.zone and SameName(q.header, place.zone.name))
            or (place.dungeon and SameName(q.header, place.dungeon.name))
        if (q.complete or underHere) and not zones[questID] then
            missing = missing or {}
            missing[questID] = true
        end
    end
    local world = missing and place.continent and MapInfo(place.continent.parentMapID)
    if world then
        local ok, continents = pcall(C_Map.GetMapChildrenInfo, world.mapID, CONTINENT_MAP_TYPE, true)
        for _, continent in ipairs(ok and type(continents) == "table" and continents or {}) do
            if continent.mapID ~= place.continent.mapID then
                for _, child in ipairs(ZonesOf(continent.mapID)) do Read(child.mapID, missing) end
            end
        end
    end
    return zones
end

-- ------------------------------------------------------------
-- How far away
-- ------------------------------------------------------------

-- A spot on a map in world yards, so spots on different zones compare.
local function WorldPos(mapID, x, y)
    if not (mapID and x and y and C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
    local ok, continent, pos = pcall(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(x, y))
    if not (ok and continent and pos and pos.GetXY) then return nil end
    local wx, wy = pos:GetXY()
    if not (wx and wy) then return nil end
    return continent, wx, wy
end

-- Whether a spot the map puts in another zone still lies on this zone's map.
-- Zone maps overlap at their edges: The Swarm Grows (1147) is marked in the
-- north of Tanaris, which is the south-east corner of Thousand Needles.
local function OnZoneMap(zoneMapID, maps)
    local c0, x0, y0 = WorldPos(zoneMapID, 0, 0)
    local c1, x1, y1 = WorldPos(zoneMapID, 1, 1)
    if not (c0 and c0 == c1 and x1 ~= x0 and y1 ~= y0) then return false end
    for mapID, quest in pairs(maps) do
        local continent, wx, wy = WorldPos(quest.from or mapID, quest.x, quest.y)
        if continent == c0 then
            local zx, zy = (wx - x0) / (x1 - x0), (wy - y0) / (y1 - y0)
            if zx >= 0 and zx <= 1 and zy >= 0 and zy <= 1 then return true end
        end
    end
    return false
end

-- Where you stand, on the zone's map rather than a town's when there is one.
local function PlayerSpot(place)
    local mapID = (place.zone and place.zone.mapID)
        or (C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"))
    if not (mapID and C_Map.GetPlayerMapPosition) then return nil end
    local ok, pos = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
    local x, y
    if ok and pos and pos.GetXY then x, y = pos:GetXY() end
    if not (x and y) then return nil end
    local continent, wx, wy = WorldPos(mapID, x, y)
    return { mapID = mapID, x = x, y = y, continent = continent, wx = wx, wy = wy }
end

-- How far to the nearest spot the map shows for the quest, in steps of
-- SAME_YARDS (or SAME_SHARE of the map when the client cannot place spots in
-- the world; then only spots on your own map count). Nil when there is none.
local function Distance(maps, me)
    if not (maps and me) then return nil end
    local best
    for mapID, quest in pairs(maps) do
        local d
        mapID = quest.from or mapID
        if quest.x and quest.y then
            if me.continent then
                local continent, wx, wy = WorldPos(mapID, quest.x, quest.y)
                if continent == me.continent then
                    d = math.floor(math.sqrt((wx - me.wx) ^ 2 + (wy - me.wy) ^ 2) / SAME_YARDS)
                end
            elseif mapID == me.mapID then
                d = math.floor(math.sqrt((quest.x - me.x) ^ 2 + (quest.y - me.y) ^ 2) / SAME_SHARE)
            end
        end
        if d and (not best or d < best) then best = d end
    end
    return best
end

-- ------------------------------------------------------------
-- The tracker
-- ------------------------------------------------------------

-- The watched quests in the order the tracker shows them, by the modern
-- C_QuestLog calls or else the classic ones by log index.
local Watch = {}

function Watch.Modern()
    return C_QuestLog and C_QuestLog.GetNumQuestWatches and C_QuestLog.GetQuestIDForQuestWatchIndex
        and C_QuestLog.AddQuestWatch and C_QuestLog.RemoveQuestWatch and true or false
end

function Watch.Classic()
    return GetNumQuestWatches and GetQuestIndexForWatch and AddQuestWatch and RemoveQuestWatch and true or false
end

function Watch.List(log)
    local list = {}
    if Watch.Modern() then
        for i = 1, C_QuestLog.GetNumQuestWatches() or 0 do
            local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
            if questID then
                local watchType = C_QuestLog.GetQuestWatchType and C_QuestLog.GetQuestWatchType(questID)
                table.insert(list, { questID = questID, watchType = watchType })
            end
        end
    elseif Watch.Classic() then
        local byIndex = {}
        for questID, q in pairs(log) do byIndex[q.index] = questID end
        for i = 1, GetNumQuestWatches() or 0 do
            local questID = byIndex[GetQuestIndexForWatch(i) or 0]
            if questID then table.insert(list, { questID = questID }) end
        end
    end
    return list
end

-- Puts the watches back so the tracker shows them in `list` order. A tracker
-- that shows the newest watch on top gets them added last to first.
function Watch.IsWatched(questID, q)
    if Watch.Modern() then
        return C_QuestLog.GetQuestWatchType and C_QuestLog.GetQuestWatchType(questID) ~= nil
    end
    return IsQuestWatched and q and IsQuestWatched(q.index) and true or false
end

function Watch.Add(questID, q)
    if Watch.Modern() then return C_QuestLog.AddQuestWatch(questID) end
    if Watch.Classic() and q then return AddQuestWatch(q.index) end
end

function Watch.Remove(questID, q)
    if Watch.Modern() then return C_QuestLog.RemoveQuestWatch(questID) end
    if Watch.Classic() and q then return RemoveQuestWatch(q.index) end
end

-- Every watch change makes the tracker lay itself out again, which is slow
-- with the controller UI, so only the quests out of place are moved. A
-- re-added watch lands at one end, so the ones left alone must already be
-- in order at the other end: the longest such run of `list` is kept.
function Watch.Set(current, list, log, newestFirst, all)
    local n, keep = #list, 0
    if not all then
        if newestFirst then
            for i = #current, 1, -1 do
                if list[n - keep] and current[i] == list[n - keep].questID then keep = keep + 1 end
            end
        else
            for _, questID in ipairs(current) do
                if list[keep + 1] and questID == list[keep + 1].questID then keep = keep + 1 end
            end
        end
    end
    local moves = {}
    if newestFirst then
        for i = n - keep, 1, -1 do table.insert(moves, list[i]) end
    else
        for i = keep + 1, n do table.insert(moves, list[i]) end
    end
    if Watch.Modern() then
        for _, w in ipairs(moves) do C_QuestLog.RemoveQuestWatch(w.questID) end
        for _, w in ipairs(moves) do C_QuestLog.AddQuestWatch(w.questID, w.watchType) end
    else
        for _, w in ipairs(moves) do RemoveQuestWatch(log[w.questID].index) end
        for _, w in ipairs(moves) do AddQuestWatch(log[w.questID].index) end
    end
end

-- ------------------------------------------------------------
-- Sorting
-- ------------------------------------------------------------

-- 0 for the dungeon you are in, 1 for the zone (0 when not in a dungeon), 2
-- for elsewhere. A quest under the dungeon's header is the dungeon's: its
-- map marker is only the entrance. Otherwise where the map shows something
-- to do decides, and a quest it shows nothing for counts as being where it
-- was picked up, which is the header it is under.
local function Rank(questID, q, place, objectiveZones)
    local dungeon, zone = place.dungeon, place.zone
    local zoneRank = dungeon and 1 or 0
    if dungeon and SameName(q.header, dungeon.name) then return 0 end
    local maps = objectiveZones and objectiveZones[questID]
    if maps and next(maps) then
        if dungeon and dungeon.mapID and maps[dungeon.mapID] then return 0 end
        if zone and maps[zone.mapID] then return zoneRank end
        -- One under this zone's header, marked just over the border.
        if zone and not q.complete and SameName(q.header, zone.name) and OnZoneMap(zone.mapID, maps) then
            return zoneRank
        end
        return 2
    end
    if zone and SameName(q.header, zone.name) then return zoneRank end
    return 2
end

local function Sort()
    if not (db and db.enabled) or sorting or Paused() then return end
    if InCombatLockdown and InCombatLockdown() then
        queued = true
        return
    end
    local log = ReadLog()
    local place = CurrentPlace()
    local objectiveZones = ObjectiveZones(place, log)
    -- No zone inside a dungeon: the one its quests' entrance markers are in.
    if place.dungeon and not place.zone and objectiveZones then
        for questID, q in pairs(log) do
            local maps = SameName(q.header, place.dungeon.name) and objectiveZones[questID]
            local mapID = maps and next(maps)
            local info = mapID and MapInfo(mapID)
            if info and info.mapType == ZONE_MAP_TYPE then
                place.zone = info
                break
            end
        end
    end
    -- The quests where you are that are not done are watched, and the ones
    -- elsewhere are not, so the tracker counts what there is to do here.
    -- Done quests TurnInQueue takes are left to it, and so is one you
    -- stopped watching yourself. Nothing changes while it is unclear
    -- where you are.
    db.untracked = db.untracked or {}
    db.kept = db.kept or {}
    for questID in pairs(db.untracked) do
        if not log[questID] then db.untracked[questID] = nil end
    end
    for questID in pairs(db.kept) do
        if not log[questID] then db.kept[questID] = nil end
    end
    local refused, away = {}, {}
    if db.trackHere and (place.zone or place.dungeon) then
        sorting = true
        for questID, q in pairs(log) do
            if not (q.complete and TIQTakes(questID)) and not db.untracked[questID] then
                local here = Rank(questID, q, place, objectiveZones) < 2
                local watched = Watch.IsWatched(questID, q)
                if here and not watched then
                    pcall(Watch.Add, questID, q)
                    if not Watch.IsWatched(questID, q) then table.insert(refused, questID) end
                elseif watched and not here and not db.kept[questID] then
                    pcall(Watch.Remove, questID, q)
                end
                if not here then
                    local maps = objectiveZones and objectiveZones[questID] or {}
                    local mapIDs = {}
                    for mapID in pairs(maps) do table.insert(mapIDs, mapID) end
                    table.sort(mapIDs)
                    local spots = {}
                    for _, mapID in ipairs(mapIDs) do
                        local quest = maps[mapID]
                        if quest.x and quest.y then
                            table.insert(spots, ("%d@%d %.3f,%.3f"):format(mapID, quest.from or mapID, quest.x, quest.y))
                        end
                    end
                    table.insert(away, ("%d %s [%s] %s%s"):format(questID, q.header or "-", table.concat(mapIDs, ","),
                        table.concat(spots, " "), db.kept[questID] and " kept" or ""))
                end
            end
        end
        sorting = false
    end
    local list = Watch.List(log)
    -- What the last sort saw, for finding out from the saved file what went wrong.
    local trackers = {}
    for _, name in ipairs({ "QuestWatchFrame", "WatchFrame", "ObjectiveTrackerFrame" }) do
        if _G[name] then table.insert(trackers, name) end
    end
    db.probe = {
        zone = place.zone and place.zone.name, dungeon = place.dungeon and place.dungeon.name,
        mapChain = table.concat(place.chain, " > "),
        mapMarkers = objectiveZones ~= nil,
        watchAPI = Watch.Modern() and "modern" or (Watch.Classic() and "classic" or "none"),
        trackers = table.concat(trackers, ", "),
        sorts = ((db.probe and db.probe.sorts) or 0) + 1,
        refused = #refused > 0 and table.concat(refused, " ") or nil,
        -- Each quest taken for one from elsewhere: its header and the maps that showed it.
        away = #away > 0 and away or nil,
    }
    local byDistance = db.sortBy == "distance"
    local me = byDistance and PlayerSpot(place) or nil
    -- False: sorted, but with no position to walk away from (in a dungeon).
    lastSpot = me or false
    if #list < 2 then return end
    local key, ids, dists = {}, {}, {}
    for _, w in ipairs(list) do
        local q = log[w.questID] or { level = 0, title = "" }
        key[w.questID] = { here = Rank(w.questID, q, place, objectiveZones),
            level = q.level or 0, title = q.title or "",
            dist = byDistance and Distance(objectiveZones and objectiveZones[w.questID], me) or nil }
        table.insert(ids, ("%d:%d"):format(w.questID, key[w.questID].here))
        if key[w.questID].dist then table.insert(dists, ("%d:%d"):format(w.questID, key[w.questID].dist)) end
    end
    db.probe.before = table.concat(ids, " ")
    db.probe.sortBy = db.sortBy
    db.probe.distances = byDistance and (me and table.concat(dists, " ") or "no position") or nil
    db.probe.me = me and ("%d %.3f,%.3f"):format(me.mapID, me.x, me.y) or nil
    -- Which maps showed each watched quest.
    local markers = {}
    for _, w in ipairs(list) do
        local maps = objectiveZones and objectiveZones[w.questID]
        if maps then
            local mapIDs = {}
            for mapID in pairs(maps) do table.insert(mapIDs, mapID) end
            table.sort(mapIDs)
            local spots = {}
            for _, mapID in ipairs(mapIDs) do
                local quest = maps[mapID]
                if quest.x and quest.y then
                    table.insert(spots, ("%d@%d %.3f,%.3f"):format(mapID, quest.from or mapID, quest.x, quest.y))
                end
            end
            table.insert(markers, ("%d:%s %s"):format(w.questID, table.concat(mapIDs, ","), table.concat(spots, " ")))
        end
    end
    db.probe.markers = markers
    local sorted = {}
    for i, w in ipairs(list) do sorted[i] = w end
    table.sort(sorted, function(a, b)
        local ka, kb = key[a.questID], key[b.questID]
        if ka.here ~= kb.here then return ka.here < kb.here end
        -- By distance, the ones the map can place come first, nearest first;
        -- the rest follow by level.
        if (ka.dist ~= nil) ~= (kb.dist ~= nil) then return ka.dist ~= nil end
        if ka.dist and ka.dist ~= kb.dist then return ka.dist < kb.dist end
        if ka.level ~= kb.level then return ka.level < kb.level end
        if ka.title ~= kb.title then return ka.title < kb.title end
        return a.questID < b.questID
    end)
    local same = true
    for i, w in ipairs(sorted) do
        if list[i].questID ~= w.questID then same = false; break end
    end
    if same then return end
    for _, w in ipairs(sorted) do
        if not (Watch.Modern() or log[w.questID]) then return end
    end
    local wanted = {}
    for _, w in ipairs(sorted) do table.insert(wanted, w.questID) end
    wanted = table.concat(wanted, " ")
    local function Apply(current, all)
        sorting = true
        local ok, err = pcall(Watch.Set, current, sorted, log, db.newestFirst, all)
        sorting = false
        if not ok then db.probe.error = tostring(err) end
        local after = {}
        for _, w in ipairs(Watch.List(ReadLog())) do table.insert(after, w.questID) end
        return table.concat(after, " "), after
    end
    local current = {}
    for _, w in ipairs(list) do table.insert(current, w.questID) end
    local after, afterList = Apply(current)
    -- Which end of the watch list the tracker puts on top is not documented:
    -- if the order came out wrong, try the other guess with every watch, and
    -- keep it only if that worked.
    if after ~= wanted and #afterList == #sorted then
        db.newestFirst = not db.newestFirst
        after = Apply(afterList, true)
        if after ~= wanted then db.newestFirst = not db.newestFirst end
    end
    db.probe.wanted, db.probe.after = wanted, after
end

-- Watches every quest in the log, done ones TurnInQueue takes aside, and
-- turns trackHere off so the next sort does not take them off again. Quests
-- you stopped watching yourself are watched too. Returns how many quests are
-- watched now and how many the client refused, or nil in combat.
local function WatchAll()
    if InCombatLockdown and InCombatLockdown() then return nil end
    db.trackHere = false
    db.untracked = {}
    db.kept = {}
    local log = ReadLog()
    local watched, refused = 0, 0
    sorting = true
    for questID, q in pairs(log) do
        if not (q.complete and TIQTakes(questID)) then
            if not Watch.IsWatched(questID, q) then pcall(Watch.Add, questID, q) end
            if Watch.IsWatched(questID, q) then watched = watched + 1 else refused = refused + 1 end
        end
    end
    sorting = false
    Sort()
    return watched, refused
end

local function ReportWatchAll(watched, refused)
    if not watched then
        print(PREFIX .. "not in combat; try again afterwards.")
        return
    end
    print(PREFIX .. ("watching all %d quests; only sorting from now on (/sqt track to go back)."):format(watched))
    if refused > 0 then print(PREFIX .. ("%d more could not be watched; the tracker may be full."):format(refused)) end
end

-- Quest progress fires many events at once; sort once they settle.
local function Schedule()
    if pending then return end
    if C_Timer and C_Timer.After then
        pending = true
        C_Timer.After(THROTTLE, function()
            pending = false
            Sort()
        end)
    else
        Sort()
    end
end

-- By distance the order changes as you walk, with no event to say so.
local function WalkCheck()
    if not (db and db.enabled and db.sortBy == "distance") or Paused() then return end
    if InCombatLockdown and InCombatLockdown() then return end
    local before = lastSpot
    if before == false then return end
    if not before then
        Schedule()
        return
    end
    local ok, pos = pcall(C_Map.GetPlayerMapPosition, before.mapID, "player")
    local x, y
    if ok and pos and pos.GetXY then x, y = pos:GetXY() end
    if x and y and math.abs(x - before.x) + math.abs(y - before.y) >= WALK_MOVED then Schedule() end
end

-- ------------------------------------------------------------
-- Options > AddOns
-- ------------------------------------------------------------

local settingsCategory

local function BuildSettingsPage(page)
    local heading = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 16, -16)
    heading:SetText("Sort Quest Tracker")

    local function Check(key, name, y, text, onClick)
        local box = CreateFrame("CheckButton", "SortQuestTrackerSettings" .. name .. "Check", page, "UICheckButtonTemplate")
        box:SetPoint("TOPLEFT", 10, y)
        box:SetSize(24, 24)
        local label = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", box, "RIGHT", 2, 0)
        label:SetText(text)
        box:SetScript("OnClick", function(self)
            db[key] = self:GetChecked() and true or false
            if onClick then onClick() end
            page.refresh()
            Sort()
        end)
        page[key] = box
    end
    Check("enabled", "Enabled", -48, "Sort the quest tracker: quests where you are first, then by level")
    Check("trackHere", "TrackHere", -70, "Watch only the quests where you are, and take the others off the tracker")

    -- Level or distance: one or the other, so a pair that acts as radio buttons.
    local function Order(value, name, y, text)
        local box = CreateFrame("CheckButton", "SortQuestTrackerSettings" .. name .. "Check", page, "UICheckButtonTemplate")
        box:SetPoint("TOPLEFT", 30, y)
        box:SetSize(24, 24)
        local label = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", box, "RIGHT", 2, 0)
        label:SetText(text)
        box:SetScript("OnClick", function()
            db.sortBy = value
            page.refresh()
            Sort()
        end)
        return box
    end
    page.byLevel = Order("level", "ByLevel", -96, "Within each group, by quest level")
    page.byDistance = Order("distance", "ByDistance", -118, "Within each group, by distance: the nearest objective first")

    local all = CreateFrame("Button", "SortQuestTrackerSettingsWatchAllButton", page, "UIPanelButtonTemplate")
    all:SetPoint("TOPLEFT", 16, -148)
    all:SetSize(160, 22)
    all:SetText("Watch all quests")
    all:SetScript("OnClick", function()
        ReportWatchAll(WatchAll())
        page.refresh()
    end)
    local allNote = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    allNote:SetPoint("LEFT", all, "RIGHT", 8, 0)
    allNote:SetWidth(380)
    allNote:SetJustifyH("LEFT")
    allNote:SetText("Puts every quest in the log back on the tracker and turns off the option above.")

    Check("withController", "Controller", -186, "Also with the Controller UI")

    local note = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", 40, -210)
    note:SetWidth(520)
    note:SetJustifyH("LEFT")
    note:SetText("Off by default. The Controller UI's tracker redraws itself for every quest that is "
        .. "moved, so with it on the game can freeze for a moment each time the tracker is sorted.")

    local state = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    state:SetPoint("TOPLEFT", 16, -252)
    state:SetWidth(540)
    state:SetJustifyH("LEFT")
    page.state = state

    function page.refresh()
        page.enabled:SetChecked(db.enabled and true or false)
        page.trackHere:SetChecked(db.trackHere and true or false)
        page.withController:SetChecked(db.withController and true or false)
        page.byLevel:SetChecked(db.sortBy ~= "distance")
        page.byDistance:SetChecked(db.sortBy == "distance")
        if not db.enabled then
            state:SetText("")
        elseif Paused() then
            state:SetText("The Controller UI is on: the tracker is left alone.")
        elseif ControllerUI() then
            state:SetText("The Controller UI is on, and the tracker is sorted anyway.")
        else
            state:SetText("")
        end
    end
end

local function RegisterSettingsPage()
    if settingsCategory then return end
    local page = CreateFrame("Frame")
    -- A new frame starts shown, so the panel showing it the first time is no
    -- change and OnShow, which fills in the values, would not run.
    page:Hide()
    page.name = "Sort Quest Tracker"
    -- Built now rather than in OnShow: creating the controls while the panel
    -- was showing the page froze the game with the Controller UI.
    BuildSettingsPage(page)
    page:SetScript("OnShow", function(self) self.refresh() end)
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, page, page.name)
        if ok and category then
            pcall(Settings.RegisterAddOnCategory, category)
            settingsCategory = category
            return
        end
    end
    if InterfaceOptions_AddCategory then
        pcall(InterfaceOptions_AddCategory, page)
        settingsCategory = page
    end
end

local function OpenSettings()
    if settingsCategory and Settings and Settings.OpenToCategory and settingsCategory.GetID then
        pcall(Settings.OpenToCategory, settingsCategory:GetID())
    elseif settingsCategory and InterfaceOptionsFrame_OpenToCategory then
        pcall(InterfaceOptionsFrame_OpenToCategory, settingsCategory)
    else
        print(PREFIX .. "no options window in this client; use the slash commands.")
    end
end

-- ------------------------------------------------------------
-- Events and command
-- ------------------------------------------------------------

local frame = CreateFrame("Frame")
for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED",
    "QUEST_LOG_UPDATE", "QUEST_WATCH_LIST_CHANGED", "QUEST_ACCEPTED", "PLAYER_REGEN_ENABLED" }) do
    pcall(frame.RegisterEvent, frame, event)
end
frame:SetScript("OnEvent", function(_, event, arg1, arg2)
    -- A watch taken off a quest, by someone other than this addon or
    -- TurnInQueue, is your choice: it stays off. One you add yourself
    -- stays on, wherever its objectives are. The client's watch on a quest
    -- just taken is not yours.
    if event == "QUEST_ACCEPTED" then
        local questID = type(arg2) == "number" and arg2 or arg1
        if type(questID) == "number" then
            acceptedAt[questID] = GetTime and GetTime() or 0
            if db and db.kept then db.kept[questID] = nil end
        end
    end
    if event == "QUEST_WATCH_LIST_CHANGED" and db and not sorting and type(arg1) == "number" then
        db.untracked = db.untracked or {}
        db.kept = db.kept or {}
        if arg2 == true then
            db.untracked[arg1] = nil
            local taken = acceptedAt[arg1]
            if not (taken and GetTime and GetTime() - taken < ACCEPT_WATCH) then db.kept[arg1] = true end
        elseif arg2 == false then
            db.kept[arg1] = nil
            if not (IsDone(arg1) and TIQTakes(arg1)) then db.untracked[arg1] = true end
        end
    end
    if event == "ADDON_LOADED" then
        if arg1 ~= "SortQuestTracker" then return end
        SortQuestTrackerDB = SortQuestTrackerDB or {}
        db = SortQuestTrackerDB
        db.trackAll = nil
        for k, v in pairs(DEFAULTS) do
            if db[k] == nil then db[k] = v end
        end
        RegisterSettingsPage()
        if C_Timer and C_Timer.NewTicker then C_Timer.NewTicker(WALK_CHECK, WalkCheck) end
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        if not queued then return end
        queued = false
    end
    if not sorting then Schedule() end
end)

SLASH_SORTQUESTTRACKER1 = "/sqt"
SlashCmdList["SORTQUESTTRACKER"] = function(input)
    local cmd = (input or ""):lower():match("^%s*(%S*)")
    if cmd == "" then
        db.enabled = not db.enabled
        print(PREFIX .. (db.enabled and "sorting the quest tracker." or "no longer sorting the quest tracker."))
        if db.enabled then Sort() end
    elseif cmd == "track" then
        db.trackHere = not db.trackHere
        print(PREFIX .. (db.trackHere and "watching the quests where you are, and taking the others off the tracker."
            or "no longer adding or taking off quests; the tracker is yours."))
        if db.trackHere then Sort() end
    elseif cmd == "all" then
        ReportWatchAll(WatchAll())
    elseif cmd == "distance" or cmd == "level" then
        db.sortBy = cmd
        print(PREFIX .. (cmd == "distance" and "sorting by distance: the nearest objective first within each group."
            or "sorting by quest level within each group."))
        Sort()
    elseif cmd == "controller" then
        db.withController = not db.withController
        print(PREFIX .. (db.withController
            and "sorting with the Controller UI too; the game can freeze for a moment each time."
            or "leaving the tracker alone while the Controller UI is on."))
        if db.withController then Sort() end
    elseif cmd == "options" or cmd == "gui" then
        OpenSettings()
    elseif cmd == "status" then
        Sort()
        local p = db.probe or {}
        print(PREFIX .. ("%s; zone %s%s; map markers %s; watch calls %s."):format(
            db.enabled and "on" or "off", tostring(p.zone or "unknown"),
            p.dungeon and (", dungeon " .. p.dungeon) or "",
            p.mapMarkers and "read" or "not available", tostring(p.watchAPI or "unknown")))
        if Paused() then print(PREFIX .. "the Controller UI is on, so the tracker is left alone (/sqt controller).") end
        if p.error then print(PREFIX .. "last error: " .. p.error) end
    else
        print(PREFIX .. "commands:")
        print("  /sqt         - turn sorting on or off")
        print("  /sqt track   - watch only the quests where you are, or leave the tracker alone")
        print("  /sqt all     - watch every quest in the log, and stop taking any off")
        print("  /sqt level | distance - order each group by quest level or by distance")
        print("  /sqt controller - also sort with the Controller UI (can freeze the game for a moment)")
        print("  /sqt options - open the options page")
        print("  /sqt status  - what the addon can see")
    end
end
