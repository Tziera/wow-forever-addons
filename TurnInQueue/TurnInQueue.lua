local ADDON_NAME, ns = ...

-- ============================================================
-- Turn-In Queue -- the turn-in queue. Blizzard's tracker is for work in
-- progress: a quest that goes complete is dropped from it and shows up here
-- instead, under a header that answers the one question left -- if I hand all
-- of these in, do I ding?
--
-- Quest XP is not affected by rested, so the sum in the header is exact.
--
-- The quest helpers below are salvaged from QuestProgressTracker, which this
-- addon replaces.
-- ============================================================

local ROW_HEIGHT = 18

local MIN_FONT_SIZE, MAX_FONT_SIZE = 6, 24

-- ------------------------------------------------------------
-- Styles
--
-- Seven looks for the same panel. "blizzard" is the client's own fonts and
-- colours -- the panel as it looked before styles existed -- and every field
-- it leaves out means exactly that. The others bring their own fonts,
-- shipped in Fonts/ under the SIL Open Font License, and a palette kept as
-- hex strings so one value can go both into SetColorTexture and into a |cff
-- colour code. "elvui", "details" and "pfui" are there to sit next to those addons.
-- Chrome fields left out (edge, outline, bar, accentLine, divider) are not
-- drawn; bgScale scales the background opacity setting.
--
-- (Copied between DungeonLevelGuide and TurnInQueue for the same reason
-- as the font helpers below.)
-- ------------------------------------------------------------

local FONT_DIR = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Fonts\\"
local STYLE_ORDER = { "blizzard", "flat", "warm", "elvui", "details", "pfui", "minimal" }
local DEFAULT_STYLE = "warm"

local STYLES = {
    blizzard = { label = "Blizzard" },
    flat = {
        label = "Flat dark",
        body = "BarlowSemiCondensed-Regular.ttf",
        heading = "BarlowSemiCondensed-SemiBold.ttf",
        sizeBoost = 2,
        bg = "15171b", edge = "2b2f36", bar = "1c1f24", accentLine = "4fb3c9",
        titleColor = "e6e8eb", text = "e6e8eb", dim = "8a919c", faint = "6b727d",
        span = "c9ced6", selected = "1e2227",
        buttonBg = "1c1f24", buttonEdge = "2b2f36", buttonText = "e6e8eb",
        lfg = "LFG", lfgColor = "4fb3c9", marker = "dot",
        active = "5fd38a", open = "e8c547", done = "5c636d",
        xpNow = "7a86e6", xpPending = "e8c547", xpTrack = "23272d", ding = "5fd38a",
        difficulty = {
            impossible = "e0564a", verydifficult = "f08a4b", difficult = "e8d547",
            standard = "5fb85f", trivial = "7d848e",
        },
    },
    warm = {
        label = "Warm classic",
        body = "AlegreyaSans-Regular.ttf",
        heading = "Cinzel-SemiBold.ttf",
        sizeBoost = 2,
        bg = "1a1410", edge = "c9a45c", outline = "3a2e1f", divider = "4a3b25",
        titleColor = "c9a45c", text = "eadfc8", dim = "9c8b6c", faint = "7a6a4f",
        span = "c9b893", selected = "251c14",
        buttonBg = "221a13", buttonEdge = "4a3b25", buttonText = "c9a45c",
        lfg = "\226\151\134", lfgColor = "8fc3d6", marker = "line",
        active = "8fd18a", open = "e8c86a", done = "6b5e48",
        xpNow = "8a6fc9", xpPending = "c9a45c", xpTrack = "2c2218", ding = "8fd18a",
        difficulty = {
            impossible = "e05a4a", verydifficult = "e8894b", difficult = "e8d86a",
            standard = "6fbf5f", trivial = "8a7d66",
        },
    },
    -- Matches ElvUI's defaults: its font, 1px black borders, its blue.
    elvui = {
        label = "ElvUI",
        body = "PT_Sans-Narrow-Web-Regular.ttf",
        heading = "PT_Sans-Narrow-Web-Bold.ttf",
        sizeBoost = 2,
        bg = "1a1a1a", edge = "000000", divider = "000000",
        titleColor = "1784d1", text = "ffffff", dim = "b3b3b3", faint = "7f7f7f",
        span = "d9d9d9", selected = "262626",
        buttonBg = "1a1a1a", buttonEdge = "000000", buttonText = "ffffff",
        lfg = "LFG", lfgColor = "1784d1", marker = "dot",
        active = "40bf40", open = "ffd200", done = "7f7f7f",
        xpNow = "0066ff", xpPending = "40bf40", xpTrack = "0f0f0f", ding = "40bf40",
        difficulty = {
            impossible = "ff1a1a", verydifficult = "ff8040", difficult = "ffff00",
            standard = "40bf40", trivial = "808080",
        },
    },
    -- Matches a Details! window: near-black, a darker title bar, no border.
    details = {
        label = "Details!",
        body = "BarlowSemiCondensed-Regular.ttf",
        heading = "BarlowSemiCondensed-SemiBold.ttf",
        sizeBoost = 2,
        bg = "131313", bar = "0a0a0a", divider = "2a2a2a",
        titleColor = "e6e6e6", text = "f2f2f2", dim = "a6a6a6", faint = "737373",
        span = "d9d9d9", selected = "242424",
        buttonBg = "1f1f1f", buttonEdge = "1f1f1f", buttonText = "e6e6e6",
        lfg = "LFG", lfgColor = "4fa3e0", marker = "line",
        active = "33cc66", open = "ffcc33", done = "595959",
        xpNow = "3d8fd9", xpPending = "ffcc33", xpTrack = "1f1f1f", ding = "33cc66",
        difficulty = {
            impossible = "ff1a1a", verydifficult = "ff8040", difficult = "ffff00",
            standard = "40bf40", trivial = "808080",
        },
    },
    -- Matches pfUI: black with a grey 1px edge, white text, its teal.
    -- pfUI's own Myriad Pro cannot be shipped; Source Sans is its free cousin.
    pfui = {
        label = "pfUI",
        body = "SourceSans3-Regular.ttf",
        heading = "SourceSans3-Semibold.ttf",
        sizeBoost = 2,
        bg = "000000", edge = "333333", divider = "333333",
        titleColor = "ffffff", text = "ffffff", dim = "aaaaaa", faint = "777777",
        span = "dddddd", selected = "1a1a1a",
        buttonBg = "0d0d0d", buttonEdge = "333333", buttonText = "ffffff",
        lfg = "LFG", lfgColor = "33ffcc", marker = "dot",
        active = "40bf40", open = "ffd200", done = "777777",
        xpNow = "4040ff", xpPending = "33ffcc", xpTrack = "1a1a1a", ding = "33ffcc",
        difficulty = {
            impossible = "ff1a1a", verydifficult = "ff8040", difficult = "ffff00",
            standard = "40bf40", trivial = "808080",
        },
    },
    -- Text over a faint shade: no border, no title bar.
    minimal = {
        label = "Minimal",
        body = "BarlowSemiCondensed-Regular.ttf",
        heading = "BarlowSemiCondensed-SemiBold.ttf",
        sizeBoost = 2,
        bg = "000000", bgScale = 0.25,
        titleColor = "8c8c8c", text = "e6e6e6", dim = "8c8c8c", faint = "666666",
        span = "bfbfbf", selected = "262626",
        buttonBg = "1a1a1a", buttonEdge = "333333", buttonText = "e6e6e6",
        lfg = "\226\128\162", lfgColor = "7fb8d4", marker = "dot",
        active = "7fd18f", open = "e6c35c", done = "595959",
        xpNow = "bfbfbf", xpPending = "e6c35c", xpTrack = "262626", ding = "7fd18f",
        difficulty = {
            impossible = "e05a4a", verydifficult = "e8894b", difficult = "e8d86a",
            standard = "6fbf5f", trivial = "7f7f7f",
        },
    },
}

local function Style()
    return STYLES[TurnInQueueDB and TurnInQueueDB.style] or STYLES[DEFAULT_STYLE]
end

-- true for the looks that bring their own fonts and palette.
local function Styled()
    return Style().body ~= nil
end

local function RGB(hex)
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255,
        tonumber(hex:sub(5, 6), 16) / 255
end

-- Four one-pixel textures around `parent`, `offset` pixels outside it. A
-- single texture behind the frame would show through a see-through
-- background as a tint over the whole panel.
local function MakeEdges(parent, offset, layer)
    local edges = {}
    for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local t = parent:CreateTexture(nil, layer or "BORDER")
        if side == "TOP" then
            t:SetPoint("TOPLEFT", -offset, offset)
            t:SetPoint("TOPRIGHT", offset, offset)
            t:SetHeight(1)
        elseif side == "BOTTOM" then
            t:SetPoint("BOTTOMLEFT", -offset, -offset)
            t:SetPoint("BOTTOMRIGHT", offset, -offset)
            t:SetHeight(1)
        elseif side == "LEFT" then
            t:SetPoint("TOPLEFT", -offset, offset)
            t:SetPoint("BOTTOMLEFT", -offset, -offset)
            t:SetWidth(1)
        else
            t:SetPoint("TOPRIGHT", offset, offset)
            t:SetPoint("BOTTOMRIGHT", offset, -offset)
            t:SetWidth(1)
        end
        table.insert(edges, t)
    end
    return edges
end

-- nil hides them.
local function PaintEdges(edges, hex)
    for _, t in ipairs(edges) do
        if hex then
            t:SetColorTexture(RGB(hex))
            t:Show()
        else
            t:Hide()
        end
    end
end

-- A plain button for the styled looks: a fill, a one-pixel edge and a label.
-- Blizzard's red UIPanelButtonTemplate cannot be recoloured, so the panel
-- keeps one of each and shows whichever the style asks for.
local function PlainButton(parent, label, width, height)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, height)
    b.fill = b:CreateTexture(nil, "BACKGROUND")
    b.fill:SetAllPoints()
    b.edges = MakeEdges(b, 0)
    b.glow = b:CreateTexture(nil, "HIGHLIGHT")
    b.glow:SetAllPoints()
    b.glow:SetColorTexture(1, 1, 1, 0.08)
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.label:SetPoint("CENTER")
    b.label:SetText(label)
    return b
end

-- The style picker: a button naming the current style that opens a list of
-- them all. Built from plain buttons because the client's own menu API has
-- changed between versions, and which one Forever has is unknown.
local function StyleDropdown(parent, x, y, onPick)
    local width = 150
    local dropdown = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    dropdown:SetSize(width, 20)
    dropdown:SetPoint("TOPLEFT", x, y)
    dropdown.arrow = dropdown:CreateTexture(nil, "OVERLAY")
    dropdown.arrow:SetSize(12, 12)
    dropdown.arrow:SetPoint("RIGHT", -6, -1)
    dropdown.arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")

    local list = CreateFrame("Frame", nil, dropdown)
    list:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    list:SetSize(width, #STYLE_ORDER * 18 + 8)
    list:SetFrameStrata("FULLSCREEN_DIALOG")
    list:EnableMouse(true)
    local fill = list:CreateTexture(nil, "BACKGROUND")
    fill:SetAllPoints()
    fill:SetColorTexture(0.06, 0.06, 0.06, 0.96)
    for _, edge in ipairs(MakeEdges(list, 0)) do edge:SetColorTexture(1, 1, 1, 0.25) end
    list:Hide()
    dropdown.list = list

    -- Alphabetical by what the reader sees, not in STYLE_ORDER.
    local names = {}
    for i, name in ipairs(STYLE_ORDER) do names[i] = name end
    table.sort(names, function(a, b) return STYLES[a].label:lower() < STYLES[b].label:lower() end)

    list.items = {}
    for i, name in ipairs(names) do
        local item = CreateFrame("Button", nil, list)
        item:SetSize(width - 8, 18)
        item:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 18)
        local glow = item:CreateTexture(nil, "HIGHLIGHT")
        glow:SetAllPoints()
        glow:SetColorTexture(1, 1, 1, 0.12)
        item.text = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        item.text:SetPoint("LEFT", 6, 0)
        item.text:SetText(STYLES[name].label)
        item:SetScript("OnClick", function()
            list:Hide()
            onPick(name)
        end)
        list.items[name] = item
    end

    dropdown:SetScript("OnClick", function()
        if list:IsShown() then list:Hide() else list:Show() end
    end)
    dropdown:SetScript("OnHide", function() list:Hide() end)

    -- The current style in gold, as the client marks a selected entry.
    function dropdown.Refresh(current)
        if not STYLES[current] then current = DEFAULT_STYLE end
        dropdown:SetText(STYLES[current].label)
        for name, item in pairs(list.items) do
            if name == current then
                item.text:SetTextColor(1, 0.82, 0)
            else
                item.text:SetTextColor(0.9, 0.9, 0.9)
            end
        end
    end

    return dropdown
end

-- `bare` leaves out the fill and the edge: the close cross is only a glyph.
local function PaintButton(b, bare)
    local style = Style()
    if not style.body then return end
    if bare then
        b.fill:Hide()
        PaintEdges(b.edges, nil)
        b.label:SetTextColor(RGB(style.dim))
    else
        b.fill:SetColorTexture(RGB(style.buttonBg))
        b.fill:Show()
        PaintEdges(b.edges, style.buttonEdge)
        b.label:SetTextColor(RGB(style.buttonText))
    end
    pcall(b.label.SetFont, b.label, FONT_DIR .. style.body, bare and 16 or 14, "")
end

-- ------------------------------------------------------------
-- Font size and background
--
-- Same shape as DungeonLevelGuide's, deliberately: every FontString the panel
-- owns registers here so a size change reaches all of them, including rows
-- built on demand later. The starting size is READ off the client's own font
-- object rather than assumed, so leaving it alone follows the client.
--
-- (Copied rather than shared. Two addons in separate folders cannot share a
-- file without embedding a library in both, and this is forty lines.)
-- ------------------------------------------------------------

local fontStrings = {}
local baseFontSize

-- `role` is "heading" for the title and "body" (the default) for the rest:
-- which of the style's two fonts the string gets.
local function TrackFont(fs, role)
    local file, size, flags = fs:GetFont()
    if not baseFontSize then baseFontSize = size end
    fs.baseFile, fs.baseFlags, fs.fontRole = file, flags, role or "body"
    table.insert(fontStrings, fs)
    return fs
end

local function BaseFontSize()
    return baseFontSize or 10
end

local function FontSize()
    return (TurnInQueueDB and TurnInQueueDB.fontSize) or BaseFontSize()
end

-- What is actually drawn: the styled fonts run small beside the client's, so
-- they get a couple of points on top of the setting.
local function TextSize()
    return FontSize() + (Style().sizeBoost or 0)
end

-- The height one line of the current text takes. Only a floor: a string that
-- wrapped is taller than this, and only the client knows by how much.
local function TextHeight()
    return math.ceil(TextSize() * 1.25)
end

-- What a string actually ended up needing, wrapping included. Falls back to
-- the one-line guess, because a string that has not been drawn yet measures
-- zero and a zero here is what makes two things land on top of each other.
local function StringHeight(fs)
    local measured = fs.GetStringHeight and fs:GetStringHeight() or 0
    return math.max(measured or 0, TextHeight())
end

-- Rows have to grow with the text, or a larger font overlaps the row below.
-- Pass the row's FontString and it grows with a WRAPPED title too: a long
-- quest name at a big text size does not fit beside the XP column.
local function RowHeight(fs)
    local oneLine = math.max(12, ROW_HEIGHT + (TextSize() - BaseFontSize()))
    if not fs then return oneLine end
    local extra = StringHeight(fs) - TextHeight()
    if extra <= 0 then return oneLine end
    return oneLine + math.ceil(extra)
end

-- The style's font when it has one, else the one the string was born with.
-- A font file the client cannot load makes SetFont answer false, and then
-- the client's own is the fallback rather than an invisible string.
local function ApplyFontSize(fs)
    local file = Style()[fs.fontRole or "body"]
    if file then
        local ok, set = pcall(fs.SetFont, fs, FONT_DIR .. file, TextSize(), fs.baseFlags or "")
        if ok and set ~= false then return end
    end
    local base, _, flags = fs.baseFile, nil, fs.baseFlags
    if not base then base, _, flags = fs:GetFont() end
    if base then pcall(fs.SetFont, fs, base, TextSize(), flags) end
end

local function ApplyFont()
    for _, fs in ipairs(fontStrings) do ApplyFontSize(fs) end
end

-- Quest tags that mean "bring friends". Rows carrying one get a +, so a queue
-- full of group quests does not read as a solo evening's work.
local GROUP_TAGS = {
    [1] = true,   -- Group
    [62] = true,  -- Raid
    [81] = true,  -- Dungeon
    [85] = true,  -- Heroic
}

local function Msg(text)
    print("|cff00ff00TurnInQueue|r: " .. text)
end

-- Every client call goes through here. Returning pcall's own ok flag keeps
-- "this client has no such API" apart from "the API said no", which is what
-- the fallbacks below turn on -- Forever is a beta and half of them are
-- guesses.
local function Call(fn, ...)
    if type(fn) ~= "function" then return false end
    return pcall(fn, ...)
end

-- ------------------------------------------------------------
-- SavedVariables
-- ------------------------------------------------------------

-- Defaults for a character with no saved settings yet; saved values win.
local DEFAULTS = {
    shown = true,
    autoUntrack = true,
    untrackDeliveries = false,  -- also untrack quests that were complete on accept
    style = DEFAULT_STYLE,      -- one of STYLE_ORDER
    showLater = true,   -- parked quests sink to the bottom; false hides them
    openMap = false,    -- a click opens the quest log; off, it only tracks the quest
    bgAlpha = 0.75,     -- 0 see-through, 1 solid
    fontSize = 12,      -- 6-24, the size DungeonLevelGuide shows; nil follows the client
    compact = false,    -- the XP line moves onto Blizzard's XP bar
}

local function EnsureDB()
    TurnInQueueDB = TurnInQueueDB or {}
    local db = TurnInQueueDB
    for key, value in pairs(DEFAULTS) do
        if db[key] == nil then db[key] = value end
    end
    -- No default size on purpose: a size here is a size we would impose at
    -- every login, and the client's own layout remembers what you dragged.
    -- Quests whose objectives we watched go from unfinished to finished. In
    -- one session that is obvious; across a /reload it is not, and a quest
    -- that is already complete the first time we see it cannot otherwise be
    -- told apart from a pure delivery quest.
    db.earned = db.earned or {}
    -- [questID] = true for the quests you have parked as "later". Set by hand
    -- only; see the Later section.
    db.later = db.later or {}
    -- Left behind by the XP bar probe and the divider check, October 2026.
    db.barProbe = nil
    db.compactLevels = nil
end

-- Counts logins, and nothing else. The beta client was caught writing
-- SavedVariables it then never reads back (see README), so "did anything
-- survive?" needs an answer that cannot be confused with a default: a counter
-- stuck at 1 means the file is not being read. /tiq debug prints it.
local function CountSession()
    if not TurnInQueueDB then return end
    TurnInQueueDB.sessions = (TurnInQueueDB.sessions or 0) + 1
end

-- ------------------------------------------------------------
-- Reading the quest log
-- ------------------------------------------------------------

-- The level to judge a quest by, which is NOT the same field as the quest log
-- entry's `level` on a scaling quest: that one comes back scaled to the player
-- and would paint a grey-green quest yellow. `difficultyLevel` is the number
-- Blizzard's own quest log colours by, so use it and match.
local function QuestLevel(questID, entry)
    if entry and entry.difficultyLevel and entry.difficultyLevel > 0 then
        return entry.difficultyLevel
    end

    local ok, level = Call(C_QuestLog and C_QuestLog.GetQuestDifficultyLevel, questID)
    if ok and level and level > 0 then return level end

    if entry and entry.level and entry.level > 0 then return entry.level end

    local okIdx, idx = Call(GetQuestLogIndexByID, questID)
    if okIdx and idx and idx > 0 then
        local okTitle, _, classicLevel = Call(GetQuestLogTitle, idx)
        if okTitle and classicLevel and classicLevel > 0 then return classicLevel end
    end
    return nil
end

-- Which of the reward-XP calls this client actually answers. /tiq debug
-- prints it; nil means nothing has returned a number yet.
local xpSource = nil
local xpCache = {}

-- GetQuestLogRewardXP has historically answered for the SELECTED quest rather
-- than for one passed in, and a call given an argument it does not take
-- answers 0 instead of erroring -- which is exactly what an empty XP column
-- looks like. So ask the selection too, and put the selection back: the quest
-- log UI reads it.
local function SelectedQuestXP(questID)
    local okPrevious, previous = Call(C_QuestLog and C_QuestLog.GetSelectedQuest)

    local selected = Call(C_QuestLog and C_QuestLog.SetSelectedQuest, questID)
    if not selected then
        local okIdx, idx = Call(GetQuestLogIndexByID, questID)
        if not (okIdx and idx and idx > 0) then return 0 end
        selected = Call(SelectQuestLogEntry, idx)
        if not selected then return 0 end
    end

    local ok, xp = Call(GetQuestLogRewardXP)

    if okPrevious and previous and previous > 0 and previous ~= questID then
        Call(C_QuestLog and C_QuestLog.SetSelectedQuest, previous)
    end

    if ok and xp and xp > 0 then return xp end
    return 0
end

-- The PREVIEWED reward for a quest still in the log -- the number the quest
-- log itself shows, which shrinks as you out-level the quest.
--
-- Forever has no C_QuestLog.GetQuestLogRewardXP (confirmed 2026-09-20), so in
-- practice the selection route below is the one that answers. The other one
-- stays because it takes a questID and cannot answer for the wrong quest.
-- Passing a questID to the GLOBAL was tried and dropped: a function that
-- ignores the argument answers with the SELECTED quest's reward, which is a
-- plausible-looking number on the wrong row.
local function PreviewXP(questID)
    local ok, xp = Call(C_QuestLog and C_QuestLog.GetQuestLogRewardXP, questID)
    if ok and xp and xp > 0 then
        xpSource = "C_QuestLog.GetQuestLogRewardXP(questID)"
        return xp
    end

    -- Moving the selection mid-fight taints what the map reads when it opens
    -- (SetPassThroughButtons gets blocked), so it is only moved out of combat
    -- and the answer kept until the level changes.
    local level = UnitLevel and UnitLevel("player")
    local cached = xpCache[questID]
    if cached and (cached.level == level or (InCombatLockdown and InCombatLockdown())) then
        return cached.xp
    end
    if InCombatLockdown and InCombatLockdown() then return 0 end

    xp = SelectedQuestXP(questID)
    if xp > 0 then
        xpSource = "selected quest + GetQuestLogRewardXP()"
        xpCache[questID] = { level = level, xp = xp }
        return xp
    end

    return 0
end

-- How many objectives the quest has, and how many are done. A quest with no
-- objectives at all is a delivery: complete from the moment you accept it,
-- and left tracked unless untrackDeliveries says otherwise.
local function Objectives(questID)
    local ok, objectives = Call(C_QuestLog and C_QuestLog.GetQuestObjectives, questID)
    if ok and objectives then
        local total, done = 0, 0
        for _, obj in ipairs(objectives) do
            total = total + 1
            if obj.finished then done = done + 1 end
        end
        return total, done
    end

    local okIdx, idx = Call(GetQuestLogIndexByID, questID)
    if okIdx and idx and idx > 0 then
        local okNum, num = Call(GetNumQuestLeaderBoards, idx)
        if okNum and num then
            local total, done = 0, 0
            for i = 1, num do
                local okBoard, _, _, finished = Call(GetQuestLogLeaderBoard, i, idx)
                if okBoard then
                    total = total + 1
                    if finished then done = done + 1 end
                end
            end
            return total, done
        end
    end
    return 0, 0
end

-- Every non-header line in the quest log, modern API first.
local function QuestLogEntries()
    local entries = {}

    local okNum, num = Call(C_QuestLog and C_QuestLog.GetNumQuestLogEntries)
    if not okNum or not num then
        okNum, num = Call(GetNumQuestLogEntries)
    end
    if not okNum or not num then return entries end

    for i = 1, num do
        local okInfo, info = Call(C_QuestLog and C_QuestLog.GetInfo, i)
        if okInfo and info then
            if not info.isHeader and info.questID and info.questID > 0 then
                table.insert(entries, {
                    questID = info.questID,
                    title = info.title,
                    level = info.level,
                    difficultyLevel = info.difficultyLevel,
                    isScaling = info.isScaling,
                    suggestedGroup = info.suggestedGroup,
                    isComplete = info.isComplete,
                })
            end
        else
            local okTitle, title, level, suggestedGroup, isHeader, _, isComplete, _, questID =
                Call(GetQuestLogTitle, i)
            if okTitle and not isHeader and questID and questID > 0 then
                table.insert(entries, {
                    questID = questID,
                    title = title,
                    level = level,
                    suggestedGroup = suggestedGroup,
                    isComplete = isComplete,
                })
            end
        end
    end

    return entries
end

local function IsReadyForTurnIn(entry)
    local ok, ready = Call(C_QuestLog and C_QuestLog.ReadyForTurnIn, entry.questID)
    if ok then return ready and true or false end

    local okComplete, complete = Call(C_QuestLog and C_QuestLog.IsComplete, entry.questID)
    if okComplete then return complete and true or false end

    -- Classic reports 1 for complete and -1 for failed, so a plain truth test
    -- would queue up quests you cannot hand in.
    return entry.isComplete == true or entry.isComplete == 1
end

local function IsGroupQuest(entry)
    if (entry.suggestedGroup or 0) > 0 then return true end
    local ok, tag = Call(C_QuestLog and C_QuestLog.GetQuestTagInfo, entry.questID)
    if ok and tag and tag.tagID and GROUP_TAGS[tag.tagID] then return true end
    return false
end

-- ------------------------------------------------------------
-- Later
--
-- A quest can be complete and still be an hour away: the giver is in a zone
-- you are done with, or the chain ends somewhere you are not going today.
-- Those quests inflate the header's +XP and turn the one question the panel
-- answers -- if I hand all of these in, do I ding? -- into a lie.
--
-- So they can be parked, by right-clicking the row. Parked quests sink to the
-- bottom, dim, and their XP leaves the sum and is shown on its own instead.
--
-- By hand, because the client cannot answer "how far is the turn-in?" here:
-- GetNextWaypointText gives a sentence, not a distance, and it is empty for
-- plenty of quests. Guessing from the quest's own zone would be wrong exactly
-- where it matters, on the chain that walks you somewhere else. You know; the
-- addon only remembers.
-- ------------------------------------------------------------

local function IsLater(questID)
    local db = TurnInQueueDB
    return (db and db.later and db.later[questID]) and true or false
end

-- nil rather than false: the table is saved, and false entries would pile up
-- one per quest you ever parked.
local function SetLater(questID, later)
    TurnInQueueDB.later[questID] = later or nil
end

local function ShowingLater()
    local db = TurnInQueueDB
    return not db or db.showLater ~= false
end

-- ------------------------------------------------------------
-- Untracking
-- ------------------------------------------------------------

local pendingUntrack = {}

local function IsWatched(questID)
    local ok, watchType = Call(C_QuestLog and C_QuestLog.GetQuestWatchType, questID)
    if ok then return watchType ~= nil end

    local okIdx, idx = Call(GetQuestLogIndexByID, questID)
    if okIdx and idx and idx > 0 then
        local okWatched, watched = Call(IsQuestWatched, idx)
        if okWatched then return watched and true or false end
    end
    return false
end

-- Whether touching the tracker mid-fight is actually a problem in Forever is
-- unverified, so this errs the cheap way and holds the change until the fight
-- ends. PLAYER_REGEN_ENABLED drains the queue.
local function Untrack(questID)
    if InCombatLockdown and InCombatLockdown() then
        pendingUntrack[questID] = true
        return false
    end

    if Call(C_QuestLog and C_QuestLog.RemoveQuestWatch, questID) then return true end

    local okIdx, idx = Call(GetQuestLogIndexByID, questID)
    if okIdx and idx and idx > 0 then
        return (Call(RemoveQuestWatch, idx))
    end
    return false
end

-- ------------------------------------------------------------
-- UI
-- ------------------------------------------------------------

local frame = CreateFrame("Frame", "TurnInQueueFrame", UIParent)
frame:SetSize(250, 200)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:SetResizable(true)
frame:SetFrameStrata("MEDIUM")
frame:SetClampedToScreen(true)

-- Newer clients expose SetResizeBounds, older ones SetMinResize/SetMaxResize.
if frame.SetResizeBounds then
    frame:SetResizeBounds(180, 120, 500, 600)
elseif frame.SetMinResize then
    frame:SetMinResize(180, 120)
    frame:SetMaxResize(500, 600)
end

local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0, 0, 0, 0.75)

local function ApplyBackground()
    local r, g, b = 0, 0, 0
    if Styled() then r, g, b = RGB(Style().bg) end
    bg:SetColorTexture(r, g, b, ((TurnInQueueDB and TurnInQueueDB.bgAlpha) or 0.75) * (Style().bgScale or 1))
end

local border = frame:CreateTexture(nil, "BORDER")
border:SetPoint("TOPLEFT", -1, 1)
border:SetPoint("BOTTOMRIGHT", 1, -1)
border:SetColorTexture(1, 1, 1, 0.15)

local titleBar = CreateFrame("Frame", nil, frame)
titleBar:SetPoint("TOPLEFT")
titleBar:SetPoint("TOPRIGHT")
titleBar:SetHeight(22)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")

local title = TrackFont(titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"), "heading")
title:SetPoint("LEFT", 8, 0)
title:SetText("Turn-in queue")

-- On the title bar, or the bar (same level, there to be dragged) takes the click.
local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -2, -2)

-- The header carries the whole point of the panel, so it gets the big font.
local header = TrackFont(frame:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
header:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 8, -2)
header:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", -8, -2)
header:SetJustifyH("LEFT")
frame.header = header

local scrollFrame = CreateFrame("ScrollFrame", "TurnInQueueScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 8, -44)
scrollFrame:SetPoint("BOTTOMRIGHT", -28, 20)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(1, 1)
scrollFrame:SetScrollChild(content)

-- ------------------------------------------------------------
-- Layout
--
-- The title bar and the header grow with the text size, so the space above
-- the list is measured off the font instead of being a fixed number: 44
-- pixels was right at 10pt and laid the header over the first row at 18.
-- Same shape as DungeonLevelGuide's, deliberately.
-- ------------------------------------------------------------

-- A couple of pixels between the top edge and the first row, so the row is
-- not sitting on the line the ScrollFrame clips at.
local LIST_PAD = 2

-- The scrollbar is worth its width only when there is something to scroll.
-- Its up arrow sits level with the first row, so on a short queue -- which is
-- most of them -- it is both dead weight and a crowd.
local BAR_INSET, PLAIN_INSET = 28, 10
local scrollBarShown = true

-- Clients that honour this hide the bar themselves once the range is empty.
-- Nothing below depends on it; setting it just keeps the two from disagreeing.
scrollFrame.scrollBarHideable = true

local function ListInset()
    return scrollBarShown and BAR_INSET or PLAIN_INSET
end

-- Measured off our own anchors rather than read back off the ScrollFrame:
-- the inset may have changed this very frame.
local function ListWidth()
    return math.max(1, (frame:GetWidth() or 210) - 8 - ListInset())
end

-- Returns true when the answer changed, which means the queue has to be laid
-- out again at the new width.
local function ShowScrollBar(show)
    if show == scrollBarShown then return false end
    scrollBarShown = show

    local bar = _G["TurnInQueueScrollFrameScrollBar"]
    if bar then
        if show then bar:Show() else bar:Hide() end
    end
    -- A list that shrank while you were scrolled down would otherwise keep
    -- its offset and show blank space with no bar left to scroll back with.
    if not show then scrollFrame:SetVerticalScroll(0) end
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -ListInset(), 20)
    return true
end

-- Air between the header and the list.
local HEAD_GAP = 8

-- The styled looks' XP bar under the header.
local XP_BAR_HEIGHT = 5

-- Kept for /tiq layout, which is the only way to see these numbers from
-- inside the game.
local listTop = 0

-- See the Compact section; active only while there is a Blizzard bar to draw on.
local Compact = { active = false }

local function LayoutPanel()
    titleBar:SetHeight(math.max(22, StringHeight(title) + 8))
    if Compact.active then
        listTop = titleBar:GetHeight() + HEAD_GAP / 2
    else
        local bar = Styled() and (4 + XP_BAR_HEIGHT) or 0
        listTop = titleBar:GetHeight() + 2 + StringHeight(header) + bar + HEAD_GAP
    end
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -listTop)
end

-- Both numbers, because them disagreeing is the whole story: the measured one
-- is what the client says the header needs -- two lines' worth once it wraps
-- -- and the guess is what the code assumes with nothing to measure yet.
local function LayoutReport()
    return ("text %d, title bar %d, header %d measured / %d guessed, list starts %d down")
        :format(FontSize(), titleBar:GetHeight(),
            (header.GetStringHeight and header:GetStringHeight()) or 0,
            TextHeight(), listTop)
end

local resizeGrip = CreateFrame("Button", nil, frame)
resizeGrip:SetSize(16, 16)
resizeGrip:SetPoint("BOTTOMRIGHT", -2, 2)
resizeGrip:EnableMouse(true)
resizeGrip.tex = resizeGrip:CreateTexture(nil, "OVERLAY")
resizeGrip.tex:SetAllPoints()
resizeGrip.tex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

-- ------------------------------------------------------------
-- The styled looks' own chrome. Built once, shown or hidden by ApplyStyle,
-- so switching style never rebuilds the panel.
-- ------------------------------------------------------------

local edges = MakeEdges(frame, 0)
local outline = MakeEdges(frame, 3)

local barFill = titleBar:CreateTexture(nil, "BACKGROUND")
barFill:SetAllPoints()

local accentLine = titleBar:CreateTexture(nil, "ARTWORK")
accentLine:SetPoint("TOPLEFT")
accentLine:SetPoint("TOPRIGHT")
accentLine:SetHeight(2)

local divider = frame:CreateTexture(nil, "ARTWORK")
divider:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 10, 0)
divider:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", -10, 0)
divider:SetHeight(1)

local plainClose = PlainButton(titleBar, "\195\151", 18, 18)
plainClose:SetPoint("TOPRIGHT", -4, -3)

-- The -/+ that folds the panel up to its title bar; see the Collapse section.
-- On the frame rather than a local: the main chunks are at Lua's 200-local limit.
frame.Collapse = { hidden = {} }
frame.Collapse.button = PlainButton(titleBar, "-", 18, 18)
frame.collapseButton = frame.Collapse.button

function frame.Collapse.Paint()
    local b = frame.Collapse.button
    b:ClearAllPoints()
    if Styled() then
        b:SetPoint("RIGHT", plainClose, "LEFT", -2, 0)
        PaintButton(b, true)
    else
        b:SetPoint("RIGHT", closeBtn, "LEFT", 2, 0)
        b.fill:Hide()
        b.label:SetTextColor(1, 0.82, 0)
    end
    local folded = TurnInQueueDB and TurnInQueueDB.collapsed
    b.label:SetText(folded and "+" or (Styled() and "\226\136\146" or "-"))
end

-- Under the header: what you have, and in the pending colour what the queue
-- would add. It says the same as the numbers, only faster.
local xpBar = CreateFrame("Frame", nil, frame)
xpBar:SetHeight(XP_BAR_HEIGHT)
xpBar:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
xpBar:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -4)
xpBar.track = xpBar:CreateTexture(nil, "BACKGROUND")
xpBar.track:SetAllPoints()
xpBar.now = xpBar:CreateTexture(nil, "ARTWORK")
xpBar.now:SetPoint("TOPLEFT")
xpBar.now:SetPoint("BOTTOMLEFT")
xpBar.pending = xpBar:CreateTexture(nil, "ARTWORK")
xpBar.pending:SetPoint("TOPLEFT", xpBar.now, "TOPRIGHT")
xpBar.pending:SetPoint("BOTTOMLEFT", xpBar.now, "BOTTOMRIGHT")

local function ShowIf(region, show)
    if show then region:Show() else region:Hide() end
end

-- Widths from the frame, not the bar: the bar has no size of its own until
-- the client has laid it out, and this runs before that on the first draw.
local function UpdateXPBar(xp, pending, xpMax)
    local width = math.max(1, (frame:GetWidth() or 250) - 16)
    local nowShare = (xpMax > 0) and math.min(1, xp / xpMax) or 0
    local pendingShare = (xpMax > 0) and math.min(1 - nowShare, pending / xpMax) or 0
    -- A zero-width texture is drawn at its natural size, so hide it instead.
    ShowIf(xpBar.now, nowShare > 0)
    ShowIf(xpBar.pending, pendingShare > 0)
    xpBar.now:SetWidth(math.max(1, width * nowShare))
    xpBar.pending:SetWidth(math.max(1, width * pendingShare))
end

local function ApplyStyle()
    local style = Style()
    local styled = Styled()
    ApplyBackground()

    ShowIf(border, not styled)
    PaintEdges(edges, style.edge)
    PaintEdges(outline, style.outline)

    ShowIf(barFill, style.bar ~= nil)
    if style.bar then barFill:SetColorTexture(RGB(style.bar)) end
    ShowIf(accentLine, style.accentLine ~= nil)
    if style.accentLine then accentLine:SetColorTexture(RGB(style.accentLine)) end
    ShowIf(divider, style.divider ~= nil)
    if style.divider then divider:SetColorTexture(RGB(style.divider)) end

    ShowIf(xpBar, styled)
    if styled then
        xpBar.track:SetColorTexture(RGB(style.xpTrack))
        xpBar.now:SetColorTexture(RGB(style.xpNow))
        xpBar.pending:SetColorTexture(RGB(style.xpPending))
        title:SetTextColor(RGB(style.titleColor))
        header:SetTextColor(RGB(style.dim))
    else
        title:SetTextColor(1, 0.82, 0)
        header:SetTextColor(1, 0.82, 0)
    end

    ShowIf(closeBtn, not styled)
    ShowIf(plainClose, styled)
    PaintButton(plainClose, true)
end

-- Always against the screen: a docked panel's own anchor is relative to the
-- panel it hangs from, and RestoreFrame anchors to UIParent. Docking picks it
-- up again after login, since it then stands edge to edge.
local function SavePosition()
    local left, top = frame:GetLeft(), frame:GetTop()
    if not (left and top) then return end
    TurnInQueueDB.point = { point = "TOPLEFT", relativePoint = "BOTTOMLEFT", x = left, y = top }
    frame.Collapse.Paint()
    frame.Collapse.HideBody()
end

local function SaveSize()
    TurnInQueueDB.size = { width = frame:GetWidth(), height = frame:GetHeight() }
end

-- The client keeps its own memory of where you dragged a movable frame, in
-- WTF/.../layout-local.txt, and restores it during login. That memory works in
-- this beta while SavedVariables do not -- so the rule here is: only move the
-- panel when we have something better to say than the client does. Anything
-- else re-centres the panel at every login, right after the client put it
-- where you left it. That is what made this one forget and DungeonLevelGuide
-- remember, and the difference was never the .toc.
local function ClientPlacedIt()
    return frame.IsUserPlaced and frame:IsUserPlaced() and true or false
end

local function RestoreFrame()
    local p = TurnInQueueDB.point
    if p then
        frame:ClearAllPoints()
        frame:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
    elseif not ClientPlacedIt() then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER")
    end

    local size = TurnInQueueDB.size
    if size then
        frame:SetSize(size.width, size.height)
    end

    if TurnInQueueDB.shown then frame:Show() else frame:Hide() end
    frame.Collapse.Apply()
end

-- ------------------------------------------------------------
-- Rows
-- ------------------------------------------------------------

local rowPool = {}

-- Forward declaration: the rows' OnEnter scripts are wired up before the
-- tooltip itself is defined.
local ShowQuestTooltip

-- Opening a Blizzard panel from addon code is only safe out of combat: in
-- combat the client holds it back and opens it afterwards, still carrying the
-- addon's taint, and Blizzard's own code then fails on the values it keeps
-- secret. The Controller UI guards the map at all times; its gamepad action
-- bar and cinematic skip button give it away. Even changing what an open
-- quest log shows fails there once the map closes.
local function InCombat()
    return InCombatLockdown and InCombatLockdown() and true or false
end

local function ControllerUI()
    local bar = GamepadMainActionBarFrame
    return (GamepadCinematicSkipButton or (bar and bar.IsShown and bar:IsShown())) and true or false
end

local function MayOpenPanels()
    return not (InCombat() or ControllerUI())
end

-- A quest clicked in combat waits here. Nothing of Blizzard's is touched
-- until the fight is over: even supertracking or selecting a quest mid-fight
-- left the map's pins tainted (SetPassThroughButtons got blocked). Then it is
-- tracked, and shown when the player opens the map themselves. A watcher of
-- our own polls for that, so no addon code runs inside the map's OnShow.
-- With openMap off the quest is only tracked: a map opened or changed by
-- addon code keeps the taint in its pins, and the same error comes when the
-- player opens the map in combat later.
local pendingQuest
local tracked = false
local watcher = CreateFrame("Frame")
watcher:Hide()

local function ApplyPending()
    if not pendingQuest or not MayOpenPanels() then return end
    if not tracked then
        Call(C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID, pendingQuest)
        tracked = true
    end
    if not TurnInQueueDB.openMap then
        pendingQuest = nil
        watcher:Hide()
        return
    end
    if not (WorldMapFrame and WorldMapFrame:IsShown()) then return end
    local questID = pendingQuest
    pendingQuest = nil
    watcher:Hide()
    Call(C_QuestLog and C_QuestLog.SetSelectedQuest, questID)
    Call(QuestMapFrame_ShowQuestDetails, questID)
end
watcher:SetScript("OnUpdate", ApplyPending)

local function SetPending(questID)
    pendingQuest = questID
    tracked = false
    if questID then watcher:Show() else watcher:Hide() end
end

-- Opens the quest the row stands for. Shift-click links it in chat instead,
-- the same gesture as everywhere else in the game, and right-click parks it
-- as later.
local function OnRowClick(self, button)
    local q = self.quest
    if not q then return end

    if button == "RightButton" then
        local later = not IsLater(q.questID)
        SetLater(q.questID, later)
        Msg(later
            and ("%s parked as later -- its XP is out of the sum."):format(q.title or q.questID)
            or ("%s is back in the queue."):format(q.title or q.questID))
        if ns.Refresh then ns.Refresh() end
        return
    end

    if IsShiftKeyDown and IsShiftKeyDown() then
        local ok, link = Call(GetQuestLink, q.questID)
        if ok and link and ChatEdit_InsertLink then
            ChatEdit_InsertLink(link)
            return
        end
    end

    if InCombat() then
        SetPending(q.questID)
        Msg(TurnInQueueDB.openMap
            and "the quest log stays closed in combat -- open the map afterwards and the quest is waiting there."
            or "the quest is tracked once the fight is over.")
        return
    end
    SetPending(nil)
    Call(C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID, q.questID)
    if not TurnInQueueDB.openMap then
        Msg(("tracking %s -- open the map yourself to see it."):format(q.title or tostring(q.questID)))
        return
    end
    if ControllerUI() then
        Msg("the quest log stays closed with the Controller UI -- open it yourself.")
        return
    end
    Call(C_QuestLog and C_QuestLog.SetSelectedQuest, q.questID)
    if not Call(QuestMapFrame_OpenToQuestDetails, q.questID) then
        Msg("could not open " .. (q.title or tostring(q.questID)) ..
            " -- open the quest log instead.")
    end
end

local function GetOrCreateRow(index)
    local row = rowPool[index]
    if row then return row end

    row = CreateFrame("Button", nil, content)
    row:SetHeight(RowHeight())
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    row.hl = row:CreateTexture(nil, "HIGHLIGHT")
    row.hl:SetAllPoints()
    row.hl:SetColorTexture(1, 1, 1, 0.12)

    row.text = TrackFont(row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    row.text:SetPoint("LEFT", 4, 0)
    row.text:SetJustifyH("LEFT")
    ApplyFontSize(row.text)

    -- The styled looks put the level in a column of its own.
    row.level = TrackFont(row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    row.level:SetPoint("LEFT", 4, 0)
    row.level:SetJustifyH("LEFT")
    ApplyFontSize(row.level)
    row.level:Hide()

    row.xp = TrackFont(row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    row.xp:SetPoint("RIGHT", -4, 0)
    row.xp:SetJustifyH("RIGHT")
    ApplyFontSize(row.xp)

    row:SetScript("OnClick", OnRowClick)
    row:SetScript("OnEnter", function(self)
        if self.quest then ShowQuestTooltip(self, self.quest) end
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

    rowPool[index] = row
    return row
end

-- Untracking costs you Blizzard's turn-in arrow, so whatever the client will
-- say about where the quest ends belongs in the tooltip instead.
local function TurnInHint(questID)
    local ok, text = Call(C_QuestLog and C_QuestLog.GetNextWaypointText, questID)
    if ok and text and text ~= "" then return text end
    return nil
end

function ShowQuestTooltip(row, q)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(q.title or tostring(q.questID), 1, 1, 1)
    if q.level then
        GameTooltip:AddLine(("Quest level %d%s"):format(
            q.level, q.isGroup and ", group" or ""), 0.8, 0.8, 0.8)
    end
    GameTooltip:AddLine(("%d XP on turn-in"):format(q.xp or 0), 1, 0.82, 0)

    local where = TurnInHint(q.questID)
    if where then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(where, 0.6, 0.8, 1, true)
    end

    GameTooltip:AddLine(" ")
    if q.later then
        GameTooltip:AddLine("Parked as later -- its XP is counted apart from the sum.",
            0.6, 0.6, 0.6, true)
        GameTooltip:AddLine("Right-click to put it back in the queue.", 0.6, 0.6, 0.6)
    else
        GameTooltip:AddLine("Right-click to park it as later.", 0.6, 0.6, 0.6)
    end
    GameTooltip:AddLine("Click to open the quest, shift-click to link it.", 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

-- ------------------------------------------------------------
-- The queue itself
-- ------------------------------------------------------------

-- Quests seen with unfinished objectives this session. Together with the
-- saved `earned` table this is what tells a quest you completed apart from a
-- delivery that was complete on accept.
local sawUnfinished = {}

local function CollectPending()
    local db = TurnInQueueDB
    local pending = {}

    for _, entry in ipairs(QuestLogEntries()) do
        local questID = entry.questID
        local total, done = Objectives(questID)
        local complete = IsReadyForTurnIn(entry)

        if not complete and total > 0 and done < total then
            sawUnfinished[questID] = true
        end

        if complete then
            local xp = PreviewXP(questID)

            -- By default only a quest you worked for leaves Blizzard's
            -- tracker. A delivery quest is complete the moment you accept it,
            -- and untracking it would hide the errand you just took on.
            if sawUnfinished[questID] then db.earned[questID] = true end
            local mayUntrack = db.earned[questID] or db.untrackDeliveries
            if db.autoUntrack and mayUntrack and IsWatched(questID) then
                Untrack(questID)
            end

            table.insert(pending, {
                questID = questID,
                title = entry.title or ("Quest " .. questID),
                level = QuestLevel(questID, entry),
                isScaling = entry.isScaling,
                xp = xp,
                isGroup = IsGroupQuest(entry),
                later = IsLater(questID),
            })
        end
    end

    -- Lowest quest level first: that is the order they stop being worth XP in.
    -- Parked quests sink below the lot of them, whatever their level.
    table.sort(pending, function(a, b)
        if a.later ~= b.later then return not a.later end
        local al, bl = a.level or 0, b.level or 0
        if al ~= bl then return al < bl end
        return (a.title or "") < (b.title or "")
    end)

    return pending
end

-- The client's own GetQuestDifficultyColor does not reproduce the quest log's
-- colours in this beta. Measured across a full quest log at player level 16:
-- plain, it turns green only at 4 levels below the player (a level 13 quest
-- came out yellow where the quest log showed green); with isScaling passed, it
-- turns green already at 2 below (a level 14 quest came out green where the
-- log showed yellow). The quest log's own boundary sits between the two, at 3
-- below -- which is the classic rule, and it matched all twelve quests.
--
-- So the rule is ours and only the palette is the client's: QuestDifficultyColors
-- is the table Blizzard's own UI paints from, and the fallback below is only
-- for a client that does not expose it.
local FALLBACK_COLORS = {
    impossible    = { r = 1,    g = 0.1,  b = 0.1 },
    verydifficult = { r = 1,    g = 0.5,  b = 0.25 },
    difficult     = { r = 1,    g = 1,    b = 0 },
    standard      = { r = 0.25, g = 0.75, b = 0.25 },
    trivial       = { r = 0.5,  g = 0.5,  b = 0.5 },
}

-- How far below you a quest may be and still count as green. The client knows;
-- 5 is the classic answer for when it does not.
local function GreenRange()
    local ok, range = Call(GetQuestGreenRange, "player")
    if not (ok and type(range) == "number") then
        ok, range = Call(GetQuestGreenRange)
    end
    if ok and type(range) == "number" and range > 0 then return range end
    return 5
end

local function DifficultyBucket(level, playerLevel)
    local diff = level - playerLevel
    if diff >= 5 then return "impossible" end
    if diff >= 3 then return "verydifficult" end
    if diff >= -2 then return "difficult" end
    if -diff <= GreenRange() then return "standard" end
    return "trivial"
end

local function DifficultyColor(level)
    if not level then return 1, 1, 1 end

    local playerLevel = UnitLevel and UnitLevel("player") or level
    local bucket = DifficultyBucket(level, playerLevel)
    if Styled() then return RGB(Style().difficulty[bucket]) end
    local color = (QuestDifficultyColors and QuestDifficultyColors[bucket])
        or FALLBACK_COLORS[bucket]

    if not (color and color.r) then return 1, 1, 1 end
    return color.r, color.g, color.b
end

-- 7820 as "7 820", for the styled looks.
local function Grouped(n)
    local text = tostring(math.floor(n))
    local grouped = text:reverse():gsub("(%d%d%d)", "%1 "):reverse()
    return (grouped:gsub("^ ", ""))
end

local function StyledHeader(xp, sum, xpMax, waiting, laterSum)
    local style = Style()
    local text = ("|cff%s%s|r"):format(style.text, Grouped(xp))
    if waiting > 0 then
        text = text .. (" |cff%s+%s|r"):format(style.xpPending, Grouped(sum))
    end
    text = text .. " / " .. Grouped(xpMax)
    if waiting > 0 and xp + sum >= xpMax then
        text = text .. ("   |cff%sDING|r"):format(style.ding)
    end
    if laterSum > 0 then
        text = text .. ("   |cff%s+%s later|r"):format(style.faint, Grouped(laterSum))
    end
    return text
end

-- ------------------------------------------------------------
-- Compact: the XP line moves onto Blizzard's XP bar
--
-- Forever has the modern status tracking bars: unnamed bars stacked in
-- MainStatusTrackingBarContainer, one shown at a time. The XP bar is the one
-- with the rested fill. Ours is a frame laid over it that only reads its
-- size, so nothing of Blizzard's is changed. With no XP bar on screen -- max
-- level, a reputation in its place, another addon's bar instead -- the
-- panel keeps its own header.
-- ------------------------------------------------------------

local RESTED_COLOR = "4d9fff"

function Compact.BlizzardBar()
    local container = _G.MainStatusTrackingBarContainer
    if not (container and container.GetChildren) then return nil end
    for _, child in ipairs({ container:GetChildren() }) do
        if type(child.ExhaustionLevelFillBar) == "table" and type(child.StatusBar) == "table"
            and child:IsVisible() then
            return child
        end
    end
    return nil
end

local overlay = CreateFrame("Frame", nil, UIParent)
overlay:Hide()
overlay.pending = overlay:CreateTexture(nil, "ARTWORK")
-- The text sits in a frame of its own, above the 5% dividers; the segment
-- stays under them like Blizzard's own fill.
overlay.textFrame = CreateFrame("Frame", nil, overlay)
overlay.textFrame:SetAllPoints()
overlay.text = overlay.textFrame:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
overlay.text:SetPoint("CENTER")
frame.compactText = overlay.text

-- The XP bar is drawn in LOW strata and the 5% dividers beside it in its
-- container's MEDIUM, so a child of the bar is under them whatever its level.
-- The text takes the container's strata and goes one level above what is
-- shown there. Checked again twice a second, since a strata set on the bar
-- would carry down to it.
function Compact.RaiseText()
    local bar = overlay.bar
    if not bar then return end
    local container = bar:GetParent()
    local strata = container:GetFrameStrata()
    local top = 0
    for _, child in ipairs({ container:GetChildren() }) do
        -- Shown ones only: Edit Mode's selection frame sits at 1000.
        if child:IsShown() and child:GetFrameStrata() == strata then
            top = math.max(top, child:GetFrameLevel() or 0)
        end
    end
    local text = overlay.textFrame
    if strata and text:GetFrameStrata() ~= strata then text:SetFrameStrata(strata) end
    if text:GetFrameLevel() ~= top + 1 then text:SetFrameLevel(top + 1) end
end

-- Blizzard's own text shows while the mouse is over the bar; ours steps aside.
overlay:SetScript("OnUpdate", function(self, elapsed)
    local bar = self.bar
    ShowIf(self.text, not (bar and bar.IsMouseOver and bar:IsMouseOver()))
    self.sinceRaise = (self.sinceRaise or 0) + (elapsed or 0)
    if self.sinceRaise > 0.5 then
        self.sinceRaise = 0
        Compact.RaiseText()
    end
end)
-- The segment is placed in pixels, so a bar resized in Edit Mode needs a redraw.
overlay:SetScript("OnSizeChanged", function() if ns.Refresh then ns.Refresh() end end)

local function CompactText(xp, rested, sum, xpMax, waiting, laterSum)
    local style = Style()
    local n = Styled() and Grouped or function(v) return tostring(math.floor(v)) end
    local text = n(xp)
    if rested and rested > 0 then
        text = text .. (" |cff%s(%s)|r"):format(RESTED_COLOR, n(rested))
    end
    if waiting > 0 then
        text = text .. (" |cff%s+%s|r"):format(style.xpPending or "ffd100", n(sum))
    end
    text = text .. " / " .. n(xpMax)
    if waiting > 0 and xp + sum >= xpMax then
        text = text .. ("  |cff%sDING|r"):format(style.ding or "33ff33")
    end
    if laterSum > 0 then
        text = text .. ("  |cff%s+%s later|r"):format(style.faint or "808080", n(laterSum))
    end
    return text
end

-- false when there is no XP bar to draw on.
function Compact.Draw(xp, rested, sum, xpMax, waiting, laterSum)
    local bar = Compact.BlizzardBar()
    if not bar then
        overlay:Hide()
        return false
    end
    local status = bar.StatusBar
    if overlay.bar ~= bar then
        overlay.bar = bar
        overlay:SetParent(bar)
        overlay:ClearAllPoints()
        overlay:SetAllPoints(status)
    end
    overlay:SetFrameLevel(status:GetFrameLevel() + 1)
    Compact.RaiseText()

    -- Full height over the rested fill: the text carries the rested amount.
    local width = status:GetWidth() or 0
    local nowShare = math.min(1, xp / xpMax)
    local pendingShare = math.min(1 - nowShare, sum / xpMax)
    local ding = waiting > 0 and xp + sum >= xpMax
    local style = Style()
    ShowIf(overlay.pending, pendingShare > 0 and width > 0)
    overlay.pending:ClearAllPoints()
    overlay.pending:SetPoint("TOPLEFT", overlay, "TOPLEFT", width * nowShare, 0)
    overlay.pending:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", width * nowShare, 0)
    overlay.pending:SetWidth(math.max(1, width * pendingShare))
    overlay.pending:SetColorTexture(RGB(ding and (style.ding or "33ff33") or (style.xpPending or "ffd100")))

    overlay.text:SetText(CompactText(xp, rested, sum, xpMax, waiting, laterSum))
    overlay:Show()
    return true
end

function Compact.Off()
    overlay:Hide()
    Compact.active = false
end

local function UpdateHeader(pending)
    local xp = UnitXP and UnitXP("player") or 0
    local xpMax = UnitXPMax and UnitXPMax("player") or 0

    if not xpMax or xpMax <= 0 then
        Compact.Off()
        header:Show()
        ShowIf(xpBar, Styled())
        header:SetText("Max level -- quest XP no longer counts.")
        UpdateXPBar(0, 0, 0)
        return
    end

    local sum, laterSum, waiting = 0, 0, 0
    for _, q in ipairs(pending) do
        if q.later then
            laterSum = laterSum + (q.xp or 0)
        else
            sum = sum + (q.xp or 0)
            waiting = waiting + 1
        end
    end

    if TurnInQueueDB.compact then
        local ok, rested = Call(GetXPExhaustion)
        Compact.active = Compact.Draw(xp, ok and rested or nil, sum, xpMax, waiting, laterSum)
    else
        Compact.Off()
    end
    ShowIf(header, not Compact.active)
    ShowIf(xpBar, Styled() and not Compact.active)
    if Compact.active then
        header:SetText("")
        return
    end

    if Styled() then
        header:SetText(StyledHeader(xp, sum, xpMax, waiting, laterSum))
        UpdateXPBar(xp, sum, xpMax)
        return
    end

    if #pending == 0 then
        header:SetText(("%d/%d"):format(xp, xpMax))
        return
    end

    -- With everything parked there is no plus term to show: a "+0" would read
    -- as "these are worth nothing" rather than "none of these are near".
    local text
    if waiting > 0 then
        text = ("%d|cffffd100+%d|r/%d"):format(xp, sum, xpMax)
        -- The DING counts only what is actually within reach, which is the
        -- whole reason parking exists.
        if xp + sum >= xpMax then
            text = text .. "  |cff33ff33DING|r"
        end
    else
        text = ("%d/%d"):format(xp, xpMax)
    end

    if laterSum > 0 then
        text = text .. ("  |cff808080+%d later|r"):format(laterSum)
    end
    header:SetText(text)
end

-- Stacks the rows by their own height rather than a fixed one, and returns
-- how tall the queue came out. The XP column is written first and measured,
-- because what is left of the row is what the title has to wrap inside.
local function DrawRows(pending, width)
    local y, drawn = LIST_PAD, 0
    for _, q in ipairs(pending) do
      if q.later and not ShowingLater() then
        -- Nothing to draw; the header still carries its XP.
      else
        drawn = drawn + 1
        local row = GetOrCreateRow(drawn)
        row:SetWidth(width)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)

        local levelText = (q.level and tostring(q.level) or "?") .. (q.isGroup and "+" or "")
        local left = 4
        if Styled() then
            local style = Style()
            row.xp:SetText(("+%s"):format(Grouped(q.xp or 0)))
            row.xp:SetTextColor(RGB(style.xpPending))
            row.level:SetText(levelText)
            row.level:SetTextColor(DifficultyColor(q.level))
            row.level:Show()
            row.hl:SetColorTexture(1, 1, 1, 0.06)
            left = 34
        else
            row.xp:SetText(("+%d"):format(q.xp or 0))
            row.xp:SetTextColor(1, 1, 1)
            row.level:Hide()
            row.hl:SetColorTexture(1, 1, 1, 0.12)
        end
        local xpWidth = (row.xp.GetStringWidth and row.xp:GetStringWidth()) or 0
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", left, 0)
        row.text:SetWidth(math.max(1, width - left - 4 - math.ceil(xpWidth) - 8))
        if Styled() then
            row.text:SetText(q.title)
        else
            row.text:SetText(("[%s] %s"):format(levelText, q.title))
        end
        row.text:SetTextColor(DifficultyColor(q.level))
        -- Parked rows keep their difficulty colour and lose their weight:
        -- same answer DungeonLevelGuide gives a quest that is already done.
        row:SetAlpha(q.later and 0.45 or 1)
        row.quest = q

        local height = RowHeight(row.text)
        row:SetHeight(height)
        row:Show()
        y = y + height
      end
    end
    return y, drawn
end

local function DoRefresh()
    local pending = CollectPending()
    UpdateHeader(pending)
    -- After the header has its text, never before: it is measured, and an old
    -- text measures the old height -- one line where there are now two.
    LayoutPanel()

    -- Two passes at most, and usually one: the bar costs width, the width
    -- decides which titles wrap, and what wraps decides whether the queue is
    -- long enough to need the bar in the first place.
    local width = ListWidth()
    local listHeight, drawn = DrawRows(pending, width)
    if ShowScrollBar(listHeight > (scrollFrame:GetHeight() or 0)) then
        width = ListWidth()
        listHeight, drawn = DrawRows(pending, width)
    end

    for i = drawn + 1, #rowPool do
        rowPool[i].quest = nil
        rowPool[i]:Hide()
    end

    content:SetSize(width, math.max(listHeight, 1))
end

-- Asking for a quest's reward can select it, and selecting it can fire
-- QUEST_LOG_UPDATE -- which lands right back here. One pass at a time, and
-- the flag is cleared even if the pass throws, so the panel cannot freeze.
local refreshing = false

local function Refresh()
    if not TurnInQueueDB or refreshing then return end

    refreshing = true
    local ok, err = pcall(DoRefresh)
    refreshing = false
    frame.Collapse.HideBody()

    if not ok then Msg("could not redraw the queue: " .. tostring(err)) end
end

-- Applies both, then redraws: row heights depend on the font size.
-- Refresh lays the panel out once the header carries its new text.
local function ApplyLook()
    ApplyStyle()
    ApplyFont()
    Refresh()
end

-- nil for a name that is not a style.
local function SetStyle(name)
    if not STYLES[name] then return nil end
    TurnInQueueDB.style = name
    ApplyLook()
    return name
end

local function SetFontSize(size)
    size = math.max(MIN_FONT_SIZE, math.min(MAX_FONT_SIZE, math.floor(size)))
    TurnInQueueDB.fontSize = size
    ApplyLook()
    return size
end

-- Takes a percentage: "how see-through" is easier in whole numbers than 0.85.
local function SetBackgroundAlpha(percent)
    percent = math.max(0, math.min(100, math.floor(percent)))
    TurnInQueueDB.bgAlpha = percent / 100
    ApplyLook()
    return percent
end

ns.Refresh = Refresh

-- ------------------------------------------------------------
-- Options > AddOns
--
-- A page in Blizzard's own settings window with the same switches as the
-- slash commands. Registered at load, filled in the first time it is shown.
-- Settings is the modern API, InterfaceOptions the older one; with neither,
-- the slash commands are all there is.
-- ------------------------------------------------------------

local settingsCategory

local function BuildSettingsPage(page)
    local heading = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 16, -16)
    heading:SetText("Turn-In Queue")

    local boxes = {}
    local function Checkbox(key, label, y)
        local box = CreateFrame("CheckButton", "TurnInQueueSettings" .. key .. "Check", page,
            "UICheckButtonTemplate")
        box:SetPoint("TOPLEFT", 10, y)
        box:SetSize(24, 24)
        local text = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("LEFT", box, "RIGHT", 2, 0)
        text:SetText(label)
        box:SetScript("OnClick", function(self)
            TurnInQueueDB[key] = self:GetChecked() and true or false
            if key == "shown" then
                if TurnInQueueDB.shown then frame:Show() else frame:Hide() end
            end
            Refresh()
        end)
        boxes[key] = box
        page[key] = box
        page[key .. "Label"] = text
    end

    Checkbox("shown", "Show the turn-in queue", -48)
    Checkbox("autoUntrack", "Untrack completed quests from Blizzard's tracker", -74)
    Checkbox("untrackDeliveries", "Untrack delivery quests too (complete on accept)", -100)
    Checkbox("showLater", "Show parked quests, dimmed, at the bottom", -126)
    Checkbox("openMap", "Open the quest log on a click (can cause blocked-action errors)", -152)
    Checkbox("compact", "Compact: XP and pending XP on Blizzard's XP bar", -178)

    local function Stepper(key, y, step, get, set)
        local label = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("TOPLEFT", 14, y)
        page[key] = label

        local minus = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
        minus:SetSize(24, 20)
        minus:SetText("-")
        minus:SetPoint("TOPLEFT", 200, y + 5)
        minus:SetScript("OnClick", function() set(get() - step); page.refresh() end)

        local plus = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
        plus:SetSize(24, 20)
        plus:SetText("+")
        plus:SetPoint("LEFT", minus, "RIGHT", 4, 0)
        plus:SetScript("OnClick", function() set(get() + step); page.refresh() end)
    end

    local styleLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    styleLabel:SetPoint("TOPLEFT", 14, -216)
    styleLabel:SetText("Style")
    page.styleDropdown = StyleDropdown(page, 58, -211, function(name)
        SetStyle(name)
        page.refresh()
    end)

    Stepper("fontLabel", -246, 1, FontSize, SetFontSize)
    Stepper("alphaLabel", -270, 5,
        function() return (TurnInQueueDB.bgAlpha or 0.75) * 100 end,
        SetBackgroundAlpha)

    local clear = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    clear:SetSize(180, 22)
    clear:SetPoint("TOPLEFT", 14, -302)
    clear:SetText("Put parked quests back")
    clear:SetScript("OnClick", function()
        for questID in pairs(TurnInQueueDB.later) do TurnInQueueDB.later[questID] = nil end
        Refresh()
    end)

    local hint = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", clear, "BOTTOMLEFT", 0, -10)
    hint:SetText("Settings are saved per character.")

    function page.refresh()
        for key, box in pairs(boxes) do box:SetChecked(TurnInQueueDB[key] and true or false) end
        -- The Controller UI keeps the quest log closed whatever the box says.
        local controller = ControllerUI()
        -- Hidden rather than disabled: the Controller UI's cursor still lands on a
        -- disabled button, and clicking it froze the game.
        page.openMap:SetShown(not controller)
        page.openMapLabel:SetText(controller and "Open the quest log on a click -- not with the Controller UI"
            or "Open the quest log on a click (can cause blocked-action errors)")
        page.openMapLabel:SetTextColor(controller and 0.5 or 1, controller and 0.5 or 1, controller and 0.5 or 1)
        page.styleDropdown.Refresh(TurnInQueueDB.style)
        page.fontLabel:SetText(("Text size: %d"):format(FontSize()))
        page.alphaLabel:SetText(("Background: %d%% opaque"):format(
            math.floor((TurnInQueueDB.bgAlpha or 0.75) * 100 + 0.5)))
    end
end

local function RegisterSettingsPage()
    if settingsCategory then return end
    local page = CreateFrame("Frame")
    -- A new frame starts shown, so the panel showing it the first time is no
    -- change and OnShow, which fills in the values, would not run.
    page:Hide()
    page.name = "Turn-In Queue"
    -- Built now rather than in OnShow: creating the controls while the panel
    -- was showing the page froze the game with the Controller UI.
    BuildSettingsPage(page)
    page:SetScript("OnShow", function(self)
        self.refresh()
    end)

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

ns.RegisterSettingsPage = RegisterSettingsPage

-- ------------------------------------------------------------
-- Drag / resize
-- ------------------------------------------------------------

-- ------------------------------------------------------------
-- Docking
--
-- The panels of DungeonLevelGuide, TurnInQueue and ZoneLevelGuide snap
-- together when one is dropped within SNAP pixels of another's edge, and
-- then move as one: the upper (or left) panel carries the one below (or to
-- its right) by anchoring it. Dragging a docked panel pulls it loose, taking
-- anything docked under it along.
--
-- Nothing about the docking is saved -- SavedVariables do not come back in
-- the beta -- but the client's own layout memory puts each panel back where
-- it was, so shortly after login a panel that stands edge to edge with
-- another is docked again. (Copied between the three addons, which cannot
-- share a file.)
-- ------------------------------------------------------------

-- One table rather than a dozen locals: the main chunk of a WoW addon may
-- hold no more than 200, and DungeonLevelGuide is close to that.
local Dock = {
    FRAMES = { "DungeonLevelGuideFrame", "TurnInQueueFrame", "ZoneLevelGuideFrame" },
    SNAP = 12,
    GAP = 4,
    REDOCK_TOLERANCE = 2,
}

function Dock.Edges(f)
    if not (f and f.GetLeft) then return nil end
    local left, right, top, bottom = f:GetLeft(), f:GetRight(), f:GetTop(), f:GetBottom()
    if left and right and top and bottom then return left, right, top, bottom end
    return nil
end

-- The panel `f` is anchored to, when it is one of the docking panels.
function Dock.Parent(f)
    local _, relativeTo = f:GetPoint(1)
    if not relativeTo then return nil end
    for _, name in ipairs(Dock.FRAMES) do
        if relativeTo == _G[name] then return relativeTo end
    end
    return nil
end

-- Whether `f` hangs, directly or further down a chain, from `other`.
function Dock.CarriedBy(f, other)
    local current = f
    for _ = 1, #Dock.FRAMES do
        current = Dock.Parent(current)
        if not current then return false end
        if current == other then return true end
    end
    return false
end

function Dock.Attach(child, parent, side)
    child:ClearAllPoints()
    if side == "below" then
        child:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, -Dock.GAP)
    else
        child:SetPoint("TOPLEFT", parent, "TOPRIGHT", Dock.GAP, 0)
    end
end

-- Pins `f` where it stands, to the screen instead of to a panel.
function Dock.Detach(f)
    local left, _, top = Dock.Edges(f)
    if not left then return end
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
end

-- Joins `f` to a panel whose edge it lies along. `f` below or right of the
-- other hangs from it; above or left, the other hangs from `f` -- unless the
-- other already hangs from something, which it then stays with.
function Dock.Try(f, tolerance)
    local fl, fr, ft, fb = Dock.Edges(f)
    if not fl then return false end
    local reach = tolerance + Dock.GAP
    for _, name in ipairs(Dock.FRAMES) do
        local other = _G[name]
        if other and other ~= f and other:IsShown() then
            local ol, oright, ot, ob = Dock.Edges(other)
            if ol then
                local sideBySideX = fl < oright and ol < fr
                local sideBySideY = fb < ot and ob < ft
                if sideBySideX and math.abs(ft - ob) <= reach and not Dock.CarriedBy(other, f) then
                    Dock.Attach(f, other, "below")
                    return true
                elseif sideBySideY and math.abs(fl - oright) <= reach and not Dock.CarriedBy(other, f) then
                    Dock.Attach(f, other, "right")
                    return true
                elseif sideBySideX and math.abs(fb - ot) <= reach
                    and not Dock.Parent(other) and not Dock.CarriedBy(f, other) then
                    Dock.Attach(other, f, "below")
                    return true
                elseif sideBySideY and math.abs(fr - ol) <= reach
                    and not Dock.Parent(other) and not Dock.CarriedBy(f, other) then
                    Dock.Attach(other, f, "right")
                    return true
                end
            end
        end
    end
    return false
end

function Dock.BeginDrag(f)
    if Dock.Parent(f) then Dock.Detach(f) end
    f:StartMoving()
end

function Dock.EndDrag(f)
    f:StopMovingOrSizing()
    Dock.Try(f, Dock.SNAP)
end

-- Sizing by hand rather than with StartSizing, so the corner can stop at
-- another panel's right or bottom edge on its way past it.
function Dock.SnapSize(f, width, height)
    local left, _, top = Dock.Edges(f)
    if not left then return width, height end
    local right, bottom = left + width, top - height
    local bestX, bestY = Dock.SNAP, Dock.SNAP
    for _, name in ipairs(Dock.FRAMES) do
        local other = _G[name]
        if other and other ~= f and other:IsShown() and not Dock.CarriedBy(other, f) then
            local _, oright, _, obottom = Dock.Edges(other)
            if oright then
                if math.abs(right - oright) <= bestX then
                    bestX = math.abs(right - oright)
                    width = oright - left
                end
                if math.abs(bottom - obottom) <= bestY then
                    bestY = math.abs(bottom - obottom)
                    height = top - obottom
                end
            end
        end
    end
    return width, height
end

function Dock.Bounds(f)
    local minW, minH, maxW, maxH
    if f.GetResizeBounds then
        minW, minH, maxW, maxH = f:GetResizeBounds()
    elseif f.GetMinResize then
        minW, minH = f:GetMinResize()
        maxW, maxH = f:GetMaxResize()
    end
    local function limit(v) return (v and v > 0) and v or math.huge end
    return minW or 0, minH or 0, limit(maxW), limit(maxH)
end

function Dock.BeginSize(f, grip)
    if not Dock.Parent(f) then Dock.Detach(f) end
    local scale = f:GetEffectiveScale()
    local x0, y0 = GetCursorPosition()
    local w0, h0 = f:GetWidth(), f:GetHeight()
    local minW, minH, maxW, maxH = Dock.Bounds(f)
    grip:SetScript("OnUpdate", function()
        local x, y = GetCursorPosition()
        local w, h = Dock.SnapSize(f, w0 + (x - x0) / scale, h0 - (y - y0) / scale)
        f:SetSize(math.max(minW, math.min(maxW, w)), math.max(minH, math.min(maxH, h)))
    end)
end

function Dock.EndSize(grip)
    grip:SetScript("OnUpdate", nil)
end

-- After login, once the client has put the panels back.
function Dock.RedockSoon(f)
    if C_Timer and C_Timer.After then
        C_Timer.After(1, function() Dock.Try(f, Dock.REDOCK_TOLERANCE) end)
    end
end

titleBar:SetScript("OnDragStart", function() Dock.BeginDrag(frame) end)
titleBar:SetScript("OnDragStop", function()
    Dock.EndDrag(frame)
    -- Enrols the frame in the client's own layout memory, which is what
    -- actually survives a restart here.
    if frame.SetUserPlaced then frame:SetUserPlaced(true) end
    SavePosition()
end)

local function Close()
    frame:Hide()
    if TurnInQueueDB then TurnInQueueDB.shown = false end
end
closeBtn:SetScript("OnClick", Close)
plainClose:SetScript("OnClick", Close)

-- ------------------------------------------------------------
-- Collapse
--
-- Folds the panel up to its title bar, like Blizzard's quest tracker. What
-- is below the title is hidden rather than clipped, so nothing folded away
-- can be clicked; a redraw that shows something again is undone by
-- HideBody. (Copied between the three addons.)
-- ------------------------------------------------------------

function frame.Collapse.HideBody()
    if not (TurnInQueueDB and TurnInQueueDB.collapsed) then return end
    for _, child in ipairs({ frame:GetChildren() }) do
        if child ~= titleBar and child:IsShown() then
            child:Hide()
            frame.Collapse.hidden[child] = true
        end
    end
    for _, region in ipairs({ frame:GetRegions() }) do
        if region:GetObjectType() == "FontString" and region:IsShown() then
            region:Hide()
            frame.Collapse.hidden[region] = true
        end
    end
end

-- The resize bounds would otherwise stop the panel at its minimum height.
function frame.Collapse.SetMinHeight(height)
    if frame.GetResizeBounds then
        local minW, _, maxW, maxH = frame:GetResizeBounds()
        frame:SetResizeBounds(minW, height, maxW, maxH)
    elseif frame.SetMinResize then
        frame:SetMinResize((frame:GetMinResize()), height)
    end
end

function frame.Collapse.Apply()
    local db = TurnInQueueDB
    if not db then return end
    frame.Collapse.Paint()
    if not frame.Collapse.minHeight then
        local _, minHeight = Dock.Bounds(frame)
        frame.Collapse.minHeight = minHeight
    end
    local barHeight = titleBar:GetHeight()
    if db.collapsed then
        -- Anchored by its top-left corner, so it folds upward.
        if not Dock.Parent(frame) then Dock.Detach(frame) end
        local height = frame:GetHeight() or 0
        if height > barHeight + 20 then db.expandedHeight = height end
        frame.Collapse.SetMinHeight(barHeight)
        frame.Collapse.HideBody()
        frame:SetHeight(barHeight)
    elseif frame.Collapse.folded then
        if not Dock.Parent(frame) then Dock.Detach(frame) end
        for region in pairs(frame.Collapse.hidden) do region:Show() end
        frame.Collapse.hidden = {}
        frame.Collapse.SetMinHeight(frame.Collapse.minHeight)
        frame:SetHeight(db.expandedHeight or (db.size and db.size.height) or 200)
    end
    frame.Collapse.folded = db.collapsed and true or false
end

frame.Collapse.button:SetScript("OnClick", function()
    TurnInQueueDB.collapsed = not TurnInQueueDB.collapsed or nil
    frame.Collapse.Apply()
    Refresh()
end)

resizeGrip:SetScript("OnMouseDown", function() Dock.BeginSize(frame, resizeGrip) end)
resizeGrip:SetScript("OnMouseUp", function()
    Dock.EndSize(resizeGrip)
    if frame.SetUserPlaced then frame:SetUserPlaced(true) end
    SaveSize()
    Refresh()
end)

frame:SetScript("OnSizeChanged", function() Refresh() end)

-- ------------------------------------------------------------
-- Events
-- ------------------------------------------------------------

-- RegisterEvent throws on an event the client does not know rather than
-- ignoring it, and at file scope that takes every line below with it. One at
-- a time, so a dead name costs nothing but itself.
local function SafeRegister(target, event)
    return (pcall(target.RegisterEvent, target, event))
end

local eventFrame = CreateFrame("Frame")
for _, event in ipairs({
    "ADDON_LOADED",
    "PLAYER_LOGIN",
    "PLAYER_LOGOUT",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_REGEN_ENABLED",
    "QUEST_LOG_UPDATE",
    "QUEST_ACCEPTED",
    "QUEST_REMOVED",
    "QUEST_TURNED_IN",
    "UNIT_QUEST_LOG_CHANGED",
    "PLAYER_XP_UPDATE",
    "UPDATE_EXHAUSTION",
    "PLAYER_LEVEL_UP",
}) do
    SafeRegister(eventFrame, event)
end

-- autoQuestProgress re-tracks a quest the moment it completes, which undoes
-- every untrack this addon does. Say so once rather than fight it silently.
local function WarnAboutAutoTrack()
    local ok, value = Call(GetCVar, "autoQuestProgress")
    if ok and (value == "1" or value == 1) then
        Msg("the autoQuestProgress setting re-tracks completed quests. " ..
            "/tiq auto off turns it off.")
    end
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loaded = ...
        if loaded ~= ADDON_NAME then return end
        EnsureDB()
        RestoreFrame()
        ApplyLook()
        RegisterSettingsPage()
    elseif event == "PLAYER_LOGIN" then
        EnsureDB()
        CountSession()
        RestoreFrame()
        WarnAboutAutoTrack()
        ApplyLook()
    elseif event == "PLAYER_LOGOUT" then
        -- A panel moves when the one it hangs from is dragged or resized.
        if TurnInQueueDB then SavePosition() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        for questID in pairs(pendingUntrack) do
            pendingUntrack[questID] = nil
            Untrack(questID)
        end
        Refresh()
    elseif event == "PLAYER_LEVEL_UP" then
        -- UnitLevel still reports the level you just left, and
        -- GetQuestDifficultyColor reads UnitLevel itself -- so redrawing right
        -- now colours every row against the old level, and a quest that just
        -- went green stays yellow until something else happens to redraw.
        -- Redraw once more when the client has caught up. Same trap
        -- DungeonLevelGuide fell into, one layer further down: there the level
        -- was ours to pass, here it is read behind our back.
        Refresh()
        if C_Timer then
            C_Timer.After(0, Refresh)
            C_Timer.After(1, Refresh)
        end
    elseif event == "QUEST_TURNED_IN" or event == "QUEST_REMOVED" then
        local questID = ...
        if questID then
            sawUnfinished[questID] = nil
            if TurnInQueueDB then TurnInQueueDB.earned[questID] = nil end
        end
        Refresh()
    else
        if event == "PLAYER_ENTERING_WORLD" then
            Dock.RedockSoon(frame)
            -- Blizzard's bars fade in after login; draw on them once they are up.
            if C_Timer then C_Timer.After(2, Refresh) end
        end
        Refresh()
    end
end)

-- The eye compares "green" with Blizzard's quest log far better than it
-- compares 0.25/0.75/0.25, and the comparison is the whole point of /tiq debug.
local function ColorName(r, g, b)
    if not r then return "?" end
    if math.abs(r - g) < 0.1 and math.abs(g - b) < 0.1 then return "grey" end
    if g > r then return "green" end
    if b > 0.4 then return "white" end
    if g < 0.35 then return "red" end
    if g < 0.7 then return "orange" end
    return "yellow"
end

-- Prints what the client actually answered. An empty XP column and an empty
-- queue look the same in the panel and have nothing to do with each other, so
-- this is the first thing to run when a number looks wrong.
local function PrintDebug()
    local entries = QuestLogEntries()
    Msg(("%d quest log entries, XP %s/%s, reward XP came from: %s"):format(
        #entries,
        tostring(UnitXP and UnitXP("player")),
        tostring(UnitXPMax and UnitXPMax("player")),
        xpSource or "nothing answered yet"))

    local db = TurnInQueueDB or {}
    local earned = 0
    for _ in pairs(db.earned or {}) do earned = earned + 1 end
    print(("  client layout memory holds this panel: %s"):format(
        (frame.IsUserPlaced and frame:IsUserPlaced()) and "yes" or "no"))
    print(("  saved: session %s, position %s, size %s, %d earned"):format(
        tostring(db.sessions or 0),
        db.point and ("%s %d,%d"):format(db.point.point or "?", db.point.x or 0, db.point.y or 0) or "none",
        db.size and ("%dx%d"):format(db.size.width or 0, db.size.height or 0) or "none",
        earned))

    local missing = {}
    for _, name in ipairs({
        "GetNumQuestLogEntries", "GetInfo", "ReadyForTurnIn", "IsComplete",
        "GetQuestLogRewardXP", "GetSelectedQuest", "SetSelectedQuest",
        "GetQuestObjectives", "GetQuestWatchType", "RemoveQuestWatch",
        "GetQuestDifficultyLevel", "GetQuestTagInfo", "GetNextWaypointText",
    }) do
        if type(C_QuestLog and C_QuestLog[name]) ~= "function" then
            table.insert(missing, "C_QuestLog." .. name)
        end
    end
    if type(GetQuestLogRewardXP) ~= "function" then
        table.insert(missing, "GetQuestLogRewardXP")
    end
    print(#missing == 0 and "  every API this addon uses exists"
        or ("  missing: " .. table.concat(missing, ", ")))

    -- select(2, ...) yields no values at all when Call hit a missing function,
    -- and tostring() with no argument is an error -- so unpack it first.
    local okRange, greenRange = Call(GetQuestGreenRange, "player")
    if not okRange then okRange, greenRange = Call(GetQuestGreenRange) end
    print(("  player level %s, green range %s"):format(
        tostring(UnitLevel and UnitLevel("player")),
        okRange and tostring(greenRange) or "no GetQuestGreenRange"))

    for _, entry in ipairs(entries) do
        local total, done = Objectives(entry.questID)
        local level = QuestLevel(entry.questID, entry)
        local okDiff, byQuestID = Call(C_QuestLog and C_QuestLog.GetQuestDifficultyLevel, entry.questID)

        print(("  [%s] %s (id %s)%s objectives %d/%d -- %d XP"):format(
            tostring(level), tostring(entry.title), tostring(entry.questID),
            IsReadyForTurnIn(entry) and " COMPLETE" or "",
            done, total, PreviewXP(entry.questID)))

        -- Every candidate side by side, plus what the isScaling flag does to
        -- the answer -- that flag is what the colours disagreed over.
        local okScaled, scaled = Call(GetQuestDifficultyColor, entry.level, true)
        print(("      our rule paints it %s"):format(ColorName(DifficultyColor(level))))
        print(("      level %s -> %s, difficultyLevel %s -> %s, GetQuestDifficultyLevel %s -> %s"):format(
            tostring(entry.level), ColorName(DifficultyColor(entry.level)),
            tostring(entry.difficultyLevel), ColorName(DifficultyColor(entry.difficultyLevel)),
            okDiff and tostring(byQuestID) or "n/a",
            okDiff and ColorName(DifficultyColor(byQuestID)) or "n/a"))
        print(("      isScaling %s, and with that flag passed: %s"):format(
            tostring(entry.isScaling),
            okScaled and scaled and ColorName(scaled.r, scaled.g, scaled.b) or "n/a"))
    end
end

-- One line per quest in the log, with both answers side by side. Two samples
-- measured under two different versions of this print contradicted each other,
-- so the rule gets picked from a handful of quests compared against Blizzard's
-- own quest log in one sitting -- not from whichever quest happens to be open.
local function PrintColors()
    Msg(("colour check at player level %s -- compare each line with the quest log"):format(
        tostring(UnitLevel and UnitLevel("player"))))

    for _, name in ipairs({ "QuestUtil", "QuestUtils_GetQuestDifficultyColor" }) do
        if _G[name] then print(("  note: %s exists on this client"):format(name)) end
    end

    print(("  green range %d, palette from the client: %s"):format(
        GreenRange(), QuestDifficultyColors and "yes" or "no (using our own)"))

    for _, entry in ipairs(QuestLogEntries()) do
        local level = QuestLevel(entry.questID, entry)
        local okPlain, plain = Call(GetQuestDifficultyColor, level)
        local okScaled, scaled = Call(GetQuestDifficultyColor, level, true)
        print(("  [%s] %s -- ours %s (client says %s / %s with isScaling)"):format(
            tostring(level), tostring(entry.title),
            ColorName(DifficultyColor(level)),
            okPlain and plain and ColorName(plain.r, plain.g, plain.b) or "n/a",
            okScaled and scaled and ColorName(scaled.r, scaled.g, scaled.b) or "n/a"))
    end
end

-- ------------------------------------------------------------
-- Slash commands
-- ------------------------------------------------------------

SLASH_TURNINQUEUE1 = "/tiq"
SLASH_TURNINQUEUE2 = "/pqx"  -- the name until October 2026
SlashCmdList["TURNINQUEUE"] = function(input)
    EnsureDB()
    local cmd, arg = string.match(input or "", "^%s*(%S*)%s*(%S*)")
    cmd = string.lower(cmd or "")
    arg = string.lower(arg or "")

    if cmd == "" or cmd == "toggle" then
        if frame:IsShown() then frame:Hide() else frame:Show() end
        TurnInQueueDB.shown = frame:IsShown() and true or false
        Refresh()

    elseif cmd == "auto" then
        if arg == "off" then
            if Call(SetCVar, "autoQuestProgress", "0") then
                Msg("autoQuestProgress off -- completed quests stay untracked.")
            else
                Msg("could not change autoQuestProgress on this client.")
            end
        elseif arg == "on" then
            Call(SetCVar, "autoQuestProgress", "1")
            Msg("autoQuestProgress on -- the game re-tracks completed quests.")
        else
            Msg("usage: /tiq auto on|off")
        end

    elseif cmd == "map" then
        TurnInQueueDB.openMap = not TurnInQueueDB.openMap
        Msg(TurnInQueueDB.openMap and "a click opens the quest log."
            or "a click only tracks the quest; open the map yourself.")

    elseif cmd == "untrack" then
        if arg == "off" then
            TurnInQueueDB.autoUntrack = false
            Msg("leaving completed quests in the tracker.")
        elseif arg == "on" then
            TurnInQueueDB.autoUntrack = true
            Msg("completed quests will be untracked again.")
        else
            Msg("usage: /tiq untrack on|off (now: " ..
                (TurnInQueueDB.autoUntrack and "on" or "off") .. ")")
        end
        Refresh()

    elseif cmd == "style" then
        if SetStyle(arg) then
            Msg(("style: %s."):format(STYLES[arg].label))
        else
            Msg(("usage: /tiq style %s (now: %s)"):format(
                table.concat(STYLE_ORDER, "|"), TurnInQueueDB.style or DEFAULT_STYLE))
        end

    elseif cmd == "compact" then
        if arg == "on" or arg == "off" then
            TurnInQueueDB.compact = (arg == "on")
        else
            TurnInQueueDB.compact = not TurnInQueueDB.compact
        end
        Refresh()
        if not TurnInQueueDB.compact then
            Msg("compact off -- the XP line is back in the panel.")
        elseif Compact.active then
            Msg("compact on -- XP and pending XP are on Blizzard's XP bar.")
        else
            Msg("compact on, but no Blizzard XP bar is showing -- the panel keeps its XP line.")
        end

    elseif cmd == "deliveries" then
        if arg == "on" then
            TurnInQueueDB.untrackDeliveries = true
            Msg("delivery quests leave the tracker too once they are in the queue.")
        elseif arg == "off" then
            TurnInQueueDB.untrackDeliveries = false
            Msg("delivery quests stay in the tracker.")
        else
            Msg("usage: /tiq deliveries on|off (now: " ..
                (TurnInQueueDB.untrackDeliveries and "on" or "off") .. ")")
        end
        Refresh()

    elseif cmd == "later" then
        local db = TurnInQueueDB
        if arg == "show" or arg == "hide" then
            db.showLater = (arg == "show")
            Msg(db.showLater and "parked quests are shown, dimmed, at the bottom."
                or "parked quests are hidden -- their XP still shows in the header.")
            Refresh()
        elseif arg == "clear" then
            local n = 0
            for questID in pairs(db.later) do
                db.later[questID] = nil
                n = n + 1
            end
            Msg(("%d quest%s back in the queue."):format(n, n == 1 and "" or "s"))
            Refresh()
        else
            local names = {}
            for _, q in ipairs(CollectPending()) do
                if q.later then table.insert(names, q.title or tostring(q.questID)) end
            end
            if #names == 0 then
                Msg("nothing parked. Right-click a row to park it as later.")
            else
                Msg(("parked as later: %s."):format(table.concat(names, ", ")))
            end
            Msg("usage: /tiq later show|hide|clear (now: " ..
                (ShowingLater() and "show" or "hide") .. ")")
        end

    elseif cmd == "debug" then
        PrintDebug()

    elseif cmd == "colors" or cmd == "colours" then
        PrintColors()

    elseif cmd == "layout" then
        Msg(LayoutReport() .. ".")

    elseif cmd == "font" then
        local n = tonumber(arg)
        if n then
            Msg(("font size %d."):format(SetFontSize(n)))
        else
            Msg(("usage: /tiq font <%d-%d>, currently %d."):format(
                MIN_FONT_SIZE, MAX_FONT_SIZE, FontSize()))
        end

    elseif cmd == "alpha" then
        local n = tonumber(arg)
        if n then
            Msg(("background %d%% opaque."):format(SetBackgroundAlpha(n)))
        else
            Msg(("usage: /tiq alpha <0-100>, currently %d."):format(
                math.floor((TurnInQueueDB.bgAlpha or 0.75) * 100 + 0.5)))
        end

    elseif cmd == "reset" then
        TurnInQueueDB.point = nil
        TurnInQueueDB.size = nil
        -- Let go of the client's layout memory too, or the panel snaps back to
        -- where it was at the next login and reset looks like it did nothing.
        if frame.SetUserPlaced then frame:SetUserPlaced(false) end
        frame:ClearAllPoints()
        frame:SetPoint("CENTER")
        frame:SetSize(250, 200)
        Refresh()
        Msg("panel back at its default position and size.")

    else
        Msg("/tiq toggles the panel. Also: later show|hide|clear, " ..
            "map, compact on|off, untrack on|off, deliveries on|off, auto on|off, style <name>, font <n>, alpha <n>, debug, " ..
            "colors, layout, reset.")
    end
end
