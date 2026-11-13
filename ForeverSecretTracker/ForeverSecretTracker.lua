-- ForeverSecretTracker -- a checklist of WoW Forever's hidden pets, quests,
-- bosses and puzzles, with steps that tick themselves off.
--
-- Forever does not flag every quest it hands in, so the addon keeps its own
-- record of what this character took, turned in, looted and killed, and
-- checks steps against that as well as against the client.

local ADDON, ns = ...

local MAX_LOG = 500

local KIND_LABEL = {
    pet = "Pet", toy = "Toy", quest = "Quest", boss = "Boss / place", rare = "Rare",
    twist = "Twist", mystery = "Mystery",
}
local CLASS_LABEL = {
    DRUID = "Druid", HUNTER = "Hunter", MAGE = "Mage", PALADIN = "Paladin",
    PRIEST = "Priest", ROGUE = "Rogue", SHAMAN = "Shaman", WARLOCK = "Warlock",
    WARRIOR = "Warrior",
}

local GREEN = "ff7fdf7f"

local db       -- this character: what it did and what it marked by hand
local account  -- every character's event log, for filling in the data
local status = {}
local questTitles = {}  -- questID -> title, from the quest log
local inLog = {}        -- normalised title -> true, quests in the log now
local killNames = {}    -- normalised names the data waits to see dead
local itemNames = {}    -- normalised item names the data looks for
local pending = false

local function Msg(fmt, ...)
    print("|cffb48cffForeverSecretTracker|r: " .. string.format(fmt, ...))
end

-- Lines the addon writes on its own, as opposed to answers to a command,
-- which the chat option can silence.
local function Notify(fmt, ...)
    if db and db.quiet then return end
    Msg(fmt, ...)
end

local function Secret(v)
    return issecretvalue and issecretvalue(v) or false
end

local function Norm(s)
    if type(s) ~= "string" or Secret(s) then return nil end
    return (s:lower():gsub("^%s+", ""):gsub("%s+$", ""))
end

local function Color(hex, text)
    return "|c" .. hex .. text .. "|r"
end

local function List(v)
    if v == nil then return {} end
    if type(v) == "table" then return v end
    return { v }
end

local function PlayerFaction()
    return UnitFactionGroup and UnitFactionGroup("player") or nil
end

local function PlayerClass()
    return UnitClass and select(2, UnitClass("player")) or nil
end

local function Where()
    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local x, y
    if mapID and C_Map.GetPlayerMapPosition then
        local ok, pos = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
        if ok and pos and pos.GetXY then
            local px, py = pos:GetXY()
            if px and not Secret(px) and not Secret(py) then
                x = math.floor(px * 1000 + 0.5) / 10
                y = math.floor(py * 1000 + 0.5) / 10
            end
        end
    end
    local zone = GetRealZoneText and GetRealZoneText() or nil
    return zone, mapID, x, y
end

-- Every event the checks might care about goes into the account log, with
-- where it happened, so the IDs and spots missing from the data can be
-- filled in from the saved file.
local function Log(ev, id, name)
    if not account then return end
    local zone, mapID, x, y = Where()
    local log = account.log
    log[#log + 1] = {
        t = time and time() or 0,
        char = UnitName and UnitName("player") or nil,
        ev = ev, id = id, name = name,
        zone = zone, mapID = mapID, x = x, y = y,
    }
    while #log > MAX_LOG do table.remove(log, 1) end
end

-- Checks -----------------------------------------------------------------

-- ZoneLevelGuide keeps its own record of quests handed in, from before this
-- addon was installed, so that is asked too when it is loaded.
local function QuestDone(id)
    if db.turnedIn[id] then return true end
    local zlg = ZoneLevelGuideDB
    if type(zlg) == "table" and type(zlg.handedIn) == "table" and zlg.handedIn[id] then return true end
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        return C_QuestLog.IsQuestFlaggedCompleted(id) and true or false
    end
    return IsQuestFlaggedCompleted and IsQuestFlaggedCompleted(id) and true or false
end

local function OnQuest(id)
    if C_QuestLog and C_QuestLog.IsOnQuest and C_QuestLog.IsOnQuest(id) then return true end
    return db.accepted[id] ~= nil or QuestDone(id)
end

local function HasItem(v)
    if GetItemCount then
        local ok, n = pcall(GetItemCount, v, true)
        if ok and n and not Secret(n) and n > 0 then return true end
    end
    return false
end

local function HasPet(name)
    if db.pets[Norm(name)] then return true end
    if not (C_PetJournal and C_PetJournal.FindPetIDByName) then return false end
    local ok, species, guid = pcall(C_PetJournal.FindPetIDByName, name)
    if not ok or not species then return false end
    if guid then return true end
    if C_PetJournal.GetNumCollectedInfo then
        local n = C_PetJournal.GetNumCollectedInfo(species)
        return n ~= nil and n > 0
    end
    return false
end

local TESTS = {
    quest = QuestDone,
    onQuest = OnQuest,
    questName = function(title) return db.turnedInNames[Norm(title)] ~= nil end,
    questAccepted = function(title)
        local key = Norm(title)
        return inLog[key] or db.acceptedNames[key] ~= nil or db.turnedInNames[key] ~= nil
    end,
    item = function(id) return db.lootedIDs[id] ~= nil or HasItem(id) end,
    itemName = function(name) return db.looted[Norm(name)] ~= nil or HasItem(name) end,
    pet = HasPet,
    kill = function(name) return db.kills[Norm(name)] ~= nil end,
}

-- A check passes when any of its tests does, or with `all` when every one
-- of them does.
local function Check(check)
    if not check then return false end
    local any, every, tried = false, true, false
    for key, test in pairs(TESTS) do
        for _, v in ipairs(List(check[key])) do
            tried = true
            if test(v) then any = true else every = false end
        end
    end
    if not tried then return false end
    if check.all then return every end
    return any
end

local function StepShown(s)
    return not s.faction or s.faction == PlayerFaction()
end

local function ForPlayer(secret)
    if secret.faction and secret.faction ~= PlayerFaction() then return false end
    if secret.class and not secret.class[PlayerClass() or ""] then return false end
    return true
end

-- Steps that share a `pick` are alternatives: `secret.picks[name]` of them
-- are needed, and once that many are done the rest are optional.
local function Evaluate(secret)
    local manual = db.manual[secret.id] or {}
    local picks = secret.picks or {}
    local st = { steps = {}, shown = {}, optional = {} }
    for i, s in ipairs(secret.steps) do
        if StepShown(s) then
            st.shown[#st.shown + 1] = i
            st.steps[i] = manual[i] or Check(s.check)
        end
    end
    st.done = db.manualDone[secret.id] or Check(secret.done)
    local last = st.shown[#st.shown]
    if last and st.steps[last] then st.done = true end
    -- A step that is done means the ones before it were done too, even when
    -- nothing recorded them. Alternatives are left as they are: the group as
    -- a whole counts as done.
    local seen = st.done
    local groupDone, groupCount = {}, {}
    for n = #st.shown, 1, -1 do
        local i = st.shown[n]
        local pick = secret.steps[i].pick
        if pick then
            if st.steps[i] then groupCount[pick] = (groupCount[pick] or 0) + 1 end
            if seen then groupDone[pick] = true end
        else
            if st.steps[i] then seen = true end
            if seen then st.steps[i] = true end
        end
    end
    for pick, need in pairs(picks) do
        if (groupCount[pick] or 0) >= need then groupDone[pick] = true end
    end
    st.count, st.total = 0, 0
    local counted = {}
    for _, i in ipairs(st.shown) do
        local pick = secret.steps[i].pick
        if pick then
            if not counted[pick] then
                counted[pick] = true
                local need = picks[pick] or 1
                st.total = st.total + need
                st.count = st.count + (groupDone[pick] and need or math.min(groupCount[pick] or 0, need))
            end
            if not st.steps[i] and groupDone[pick] then st.optional[i] = true end
        else
            st.total = st.total + 1
            if st.steps[i] then st.count = st.count + 1 end
        end
        if not st.steps[i] and not st.optional[i] and not st.next then st.next = i end
    end
    return st
end

local guildFailed = false

local function PostToGuild(secret)
    if not (db.guild and SendChatMessage and IsInGuild and IsInGuild()) then return end
    local ok = pcall(SendChatMessage, "Found a secret: " .. secret.name .. "!", "GUILD")
    if not ok and not guildFailed then
        guildFailed = true
        Msg("the game did not let the addon post in guild chat.")
    end
end

-- `byHand` is a mark the player made: that gets the toast, but is not
-- announced to the guild as a find.
local function EvaluateAll(silent, byHand)
    for _, secret in ipairs(ns.SECRETS) do
        local st = Evaluate(secret)
        status[secret.id] = st
        if st.done and secret.kind ~= "mystery" and not db.found[secret.id] then
            db.found[secret.id] = time and time() or 0
            if not silent then
                Notify("secret found: %s!", Color(GREEN, secret.name))
                if ns.OnFound then ns.OnFound(secret) end
                if not byHand then PostToGuild(secret) end
            end
        elseif not st.done and secret.kind ~= "mystery" then
            db.found[secret.id] = nil
        end
    end
    if ns.OnChanged then ns.OnChanged() end
end

local function Schedule()
    if pending then return end
    pending = true
    local run = function()
        pending = false
        EvaluateAll(false)
    end
    if C_Timer and C_Timer.After then C_Timer.After(0.5, run) else run() end
end

-- Recording ---------------------------------------------------------------

local function ReadQuestLog()
    wipe(inLog)
    if not (C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo) then return end
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID and info.title then
            questTitles[info.questID] = info.title
            local key = Norm(info.title)
            if key then inLog[key] = true end
        end
    end
end

local function QuestTitle(id)
    if questTitles[id] then return questTitles[id] end
    if C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local title = C_QuestLog.GetTitleForQuestID(id)
        if title and not Secret(title) then return title end
    end
    return nil
end

local function OnQuestAccepted(a, b)
    local id = b or a
    if type(id) ~= "number" or Secret(id) then return end
    ReadQuestLog()
    local title = QuestTitle(id)
    db.accepted[id] = title or true
    local key = Norm(title)
    if key then db.acceptedNames[key] = id end
    Log("accept", id, title)
    Schedule()
end

local function OnQuestTurnedIn(id)
    if type(id) ~= "number" or Secret(id) then return end
    local title = QuestTitle(id)
    db.turnedIn[id] = title or true
    local key = Norm(title)
    if key then db.turnedInNames[key] = id end
    Log("turnin", id, title)
    Schedule()
end

local selfLoot
local function SelfLootPrefixes()
    if selfLoot then return selfLoot end
    selfLoot = {}
    for _, fmt in ipairs({
        LOOT_ITEM_SELF, LOOT_ITEM_SELF_MULTIPLE, LOOT_ITEM_PUSHED_SELF,
        LOOT_ITEM_PUSHED_SELF_MULTIPLE, LOOT_ITEM_CREATED_SELF,
    }) do
        if type(fmt) == "string" then
            local prefix = fmt:match("^(.-)%%s")
            if prefix and prefix ~= "" then selfLoot[#selfLoot + 1] = prefix end
        end
    end
    if #selfLoot == 0 then selfLoot = { "You receive", "You create" } end
    return selfLoot
end

local function IsQuestItem(id)
    if not GetItemInfoInstant then return false end
    local ok, _, _, _, _, _, classID = pcall(GetItemInfoInstant, id)
    return ok and classID == 12
end

local function OnLootMessage(text)
    if type(text) ~= "string" or Secret(text) then return end
    local mine = false
    for _, prefix in ipairs(SelfLootPrefixes()) do
        if text:sub(1, #prefix) == prefix then mine = true break end
    end
    if not mine then return end
    local id, name = text:match("|Hitem:(%d+)[^|]*|h%[(.-)%]|h")
    id = tonumber(id)
    if not (id and name) then return end
    local key = Norm(name)
    local wanted = itemNames[key]
    for _, secret in ipairs(ns.SECRETS) do
        for _, s in ipairs(secret.steps) do
            for _, want in ipairs(List(s.check and s.check.item)) do
                if want == id then wanted = true end
            end
        end
    end
    if not (wanted or IsQuestItem(id)) then return end
    db.looted[key] = id
    db.lootedIDs[id] = name
    Log("loot", id, name)
    Schedule()
end

local function OnNewPet(guid)
    if not (guid and C_PetJournal and C_PetJournal.GetPetInfoByPetID) then return end
    local ok, species, _, _, _, _, _, _, name = pcall(C_PetJournal.GetPetInfoByPetID, guid)
    if not ok or not name or Secret(name) then return end
    db.pets[Norm(name)] = species or true
    Log("pet", species, name)
    Schedule()
end

local function RecordKill(name, id)
    local key = Norm(name)
    if not key or db.kills[key] then return end
    db.kills[key] = id or true
    Log("kill", id, name)
    Schedule()
end

-- Secret bosses and rares are often no encounter at all, so a watched name
-- also counts when it is targeted dead.
local function CheckTarget()
    if not (UnitExists and UnitExists("target")) then return end
    if not (UnitIsDead and UnitIsDead("target")) then return end
    local name = UnitName("target")
    local key = Norm(name)
    if key and killNames[key] then RecordKill(name) end
end

local function IndexData()
    for _, secret in ipairs(ns.SECRETS) do
        local checks = { secret.done }
        for _, s in ipairs(secret.steps) do checks[#checks + 1] = s.check end
        for _, c in ipairs(checks) do
            for _, n in ipairs(List(c.kill)) do killNames[Norm(n)] = true end
            for _, n in ipairs(List(c.itemName)) do itemNames[Norm(n)] = true end
        end
    end
end

-- Waypoints ---------------------------------------------------------------

local function SetWaypoint(title, mapID, x, y)
    if TomTom and TomTom.AddWaypoint then
        local ok = pcall(TomTom.AddWaypoint, TomTom, mapID, x / 100, y / 100,
            { title = title, from = ADDON, persistent = false })
        if ok then return true end
    end
    if not (C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates) then
        return false
    end
    return pcall(function()
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x / 100, y / 100))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
    end)
end

-- A step with several known spots: TomTom gets them all, Blizzard's single
-- pin moves to the next spot on each click.
local function SpotsWaypoint(secret, s)
    local spots = s.spots
    if TomTom and TomTom.AddWaypoint then
        local set = 0
        for _, p in ipairs(spots) do
            if SetWaypoint(secret.name, s.mapID, p[1], p[2]) then set = set + 1 end
        end
        Notify("%d waypoints set: %s, %s.", set, secret.name, s.zone)
        return
    end
    s.spot = (s.spot or 0) % #spots + 1
    local p = spots[s.spot]
    if SetWaypoint(secret.name, s.mapID, p[1], p[2]) then
        Notify("waypoint %d of %d set: %s, %s %.1f, %.1f.", s.spot, #spots, secret.name, s.zone, p[1], p[2])
    else
        Msg("could not set a waypoint here: %s %.1f, %.1f.", s.zone, p[1], p[2])
    end
end

local function StepWaypoint(secret, s)
    if not (s.mapID and s.x and s.y) then return end
    if s.spots and #s.spots > 1 then return SpotsWaypoint(secret, s) end
    if SetWaypoint(secret.name, s.mapID, s.x, s.y) then
        Notify("waypoint set: %s, %s %.1f, %.1f.", secret.name, s.zone, s.x, s.y)
    else
        Msg("could not set a waypoint here: %s %.1f, %.1f.", s.zone, s.x, s.y)
    end
end

-- What the window needs --------------------------------------------------

local function Counts(showAll)
    local found, total = 0, 0
    for _, secret in ipairs(ns.SECRETS) do
        if secret.kind ~= "mystery" and (showAll or ForPlayer(secret)) then
            total = total + 1
            if status[secret.id] and status[secret.id].done then found = found + 1 end
        end
    end
    return found, total
end

local function MetaLine(secret)
    local parts = { KIND_LABEL[secret.kind] or secret.kind }
    if secret.zone then parts[#parts + 1] = secret.zone end
    if secret.level then parts[#parts + 1] = "level " .. secret.level .. "+" end
    if secret.faction then parts[#parts + 1] = secret.faction .. " only" end
    if secret.class then
        local names = {}
        for class in pairs(secret.class) do names[#names + 1] = CLASS_LABEL[class] or class end
        table.sort(names)
        parts[#parts + 1] = table.concat(names, " / ") .. " only"
    end
    return table.concat(parts, "  -  ")
end

local function ToggleStep(id, i)
    db.manual[id] = db.manual[id] or {}
    db.manual[id][i] = not db.manual[id][i] or nil
    if next(db.manual[id]) == nil then db.manual[id] = nil end
    EvaluateAll(false, true)
end

local function ToggleDone(id)
    db.manualDone[id] = not db.manualDone[id] or nil
    EvaluateAll(false, true)
end

ns.KIND_LABEL = KIND_LABEL
ns.Msg = Msg
ns.Color = Color
ns.Counts = Counts
ns.MetaLine = MetaLine
ns.ForPlayer = ForPlayer
ns.ToggleStep = ToggleStep
ns.ToggleDone = ToggleDone
ns.StepWaypoint = StepWaypoint
ns.EvaluateAll = EvaluateAll
ns.DB = function() return db end
ns.Status = function(secret)
    local st = status[secret.id]
    if not st then
        st = Evaluate(secret)
        status[secret.id] = st
    end
    return st
end
ns.Manual = function(id, i) return db.manual[id] and db.manual[id][i] or false end
ns.PetSpecies = function(name)
    if not (C_PetJournal and C_PetJournal.FindPetIDByName) then return nil end
    local ok, species = pcall(C_PetJournal.FindPetIDByName, name)
    return ok and species or nil
end

-- The addon compartment (the button by the minimap) calls this by name.
function ForeverSecretTracker_OnCompartment()
    if ns.Toggle then ns.Toggle() end
end

-- Slash commands ----------------------------------------------------------

local function PrintLog(n)
    local log = account and account.log or {}
    n = math.min(n or 15, #log)
    if n == 0 then
        Msg("nothing recorded yet.")
        return
    end
    Msg("the last %d recorded events:", n)
    for i = #log - n + 1, #log do
        local e = log[i]
        local where = e.zone or "?"
        if e.x then where = string.format("%s %.1f, %.1f", where, e.x, e.y) end
        print(string.format("  %s %s %s -- %s", e.ev, tostring(e.id or "-"), e.name or "?", where))
    end
end

local function Help()
    Msg("commands:")
    print("  /fst -- open or close the window")
    print("  /fst minimap -- show or hide the minimap button")
    print("  /fst chat -- turn the addon's own chat lines on or off")
    print("  /fst guild -- post finds in guild chat, on or off")
    print("  /fst options -- open the options page")
    print("  /fst log [n] -- the last n quests, items, pets and kills it recorded")
    print("  /fst reset confirm -- forget every step marked by hand")
end

SLASH_FOREVERSECRETTRACKER1 = "/fst"
SLASH_FOREVERSECRETTRACKER2 = "/secrettracker"

SlashCmdList.FOREVERSECRETTRACKER = function(input)
    local cmd, arg = string.match(input or "", "^%s*(%S*)%s*(%S*)")
    cmd = string.lower(cmd or "")
    if not db then return end
    if cmd == "" or cmd == "show" then
        ns.Toggle()
    elseif cmd == "minimap" then
        db.hideMinimap = not db.hideMinimap or nil
        if ns.UpdateMinimapButton then ns.UpdateMinimapButton() end
        if ns.RefreshOptions then ns.RefreshOptions() end
        Msg(db.hideMinimap and "minimap button hidden." or "minimap button shown.")
    elseif cmd == "chat" then
        db.quiet = not db.quiet or nil
        Msg(db.quiet and "quiet: finds and waypoints are no longer written in chat." or "finds and waypoints are written in chat again.")
        if ns.RefreshOptions then ns.RefreshOptions() end
    elseif cmd == "guild" then
        db.guild = not db.guild or nil
        Msg(db.guild and "finds are posted in guild chat." or "finds are no longer posted in guild chat.")
        if ns.RefreshOptions then ns.RefreshOptions() end
    elseif cmd == "options" then
        if ns.OpenOptions then ns.OpenOptions() end
    elseif cmd == "log" then
        PrintLog(tonumber(arg))
    elseif cmd == "reset" then
        if string.lower(arg or "") == "confirm" then
            db.manual, db.manualDone = {}, {}
            EvaluateAll(true)
            Msg("every hand-made mark is gone.")
        else
            Msg("this forgets every step you marked by hand. Type /fst reset confirm to do it.")
        end
    else
        Help()
    end
end

-- Events -----------------------------------------------------------------

local function InitDB()
    ForeverSecretTrackerDB = ForeverSecretTrackerDB or {}
    db = ForeverSecretTrackerDB
    for _, key in ipairs({
        "accepted", "acceptedNames", "turnedIn", "turnedInNames", "looted",
        "lootedIDs", "pets", "kills", "manual", "manualDone", "found",
    }) do
        db[key] = db[key] or {}
    end
    ForeverSecretTrackerAccountDB = ForeverSecretTrackerAccountDB or {}
    account = ForeverSecretTrackerAccountDB
    account.log = account.log or {}
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("QUEST_ACCEPTED")
events:RegisterEvent("QUEST_TURNED_IN")
events:RegisterEvent("QUEST_LOG_UPDATE")
events:RegisterEvent("CHAT_MSG_LOOT")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("NEW_PET_ADDED")
events:RegisterEvent("ENCOUNTER_END")
events:RegisterEvent("BOSS_KILL")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("UNIT_FLAGS")
events:RegisterEvent("LOOT_OPENED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")

events:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= ADDON then return end
        InitDB()
        IndexData()
        if ns.RegisterOptions then ns.RegisterOptions() end
    elseif not db then
        return
    elseif event == "PLAYER_LOGIN" then
        ReadQuestLog()
        if ns.UpdateMinimapButton then ns.UpdateMinimapButton() end
        local first = function() EvaluateAll(true) end
        if C_Timer and C_Timer.After then C_Timer.After(3, first) else first() end
    elseif event == "QUEST_ACCEPTED" then
        OnQuestAccepted(...)
    elseif event == "QUEST_TURNED_IN" then
        OnQuestTurnedIn(...)
    elseif event == "QUEST_LOG_UPDATE" then
        ReadQuestLog()
    elseif event == "CHAT_MSG_LOOT" then
        OnLootMessage(...)
    elseif event == "BAG_UPDATE_DELAYED" then
        Schedule()
    elseif event == "NEW_PET_ADDED" then
        OnNewPet(...)
    elseif event == "ENCOUNTER_END" then
        local id, name, _, _, success = ...
        if success == 1 then RecordKill(name, id) end
    elseif event == "BOSS_KILL" then
        local id, name = ...
        RecordKill(name, id)
    elseif event == "PLAYER_TARGET_CHANGED" or event == "LOOT_OPENED" then
        CheckTarget()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if ns.refreshAfterCombat then
            ns.refreshAfterCombat = nil
            if ns.OnChanged then ns.OnChanged() end
        end
    elseif event == "UNIT_FLAGS" then
        if ... == "target" then CheckTarget() end
    end
end)
