local ADDON_NAME, ns = ...

-- ============================================================
-- Zone Level Guide -- the zones that suit your level, read from the level
-- ranges the Group Finder gives them, each with the quests you have picked up
-- there: who gave them, where they stood, and the quest's level.
-- ============================================================

local PREFIX = "|cff00ff00ZoneLevelGuide|r: "

local ROW_HEIGHT = 20
local DEFAULT_RANGE = 0
local MIN_FONT_SIZE, MAX_FONT_SIZE = 6, 24
local DONE_ALPHA = 0.45
-- How far above your level a city's quest may be and still list the city,
-- and with hideHigh on, how far above it a zone's quest may be.
local QUEST_WINDOW = 5

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
-- (Copied between DungeonLevelGuide and PendingQuestXP for the same reason
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
    return STYLES[ZoneLevelGuideDB and ZoneLevelGuideDB.style] or STYLES[DEFAULT_STYLE]
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
-- Font size
--
-- Every FontString the panel owns is registered here, so a size or style
-- change reaches all of them, including rows built on demand later. The
-- starting size is read off the client's own font object.
-- ------------------------------------------------------------

local fontStrings = {}
local baseFontSize

-- `role` is "heading" for the title and "body" (the default) for the rest.
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
    return (ZoneLevelGuideDB and ZoneLevelGuideDB.fontSize) or BaseFontSize()
end

local function TextSize()
    return FontSize() + (Style().sizeBoost or 0)
end

local function TextHeight()
    return math.ceil(TextSize() * 1.25)
end

local function StringHeight(fs)
    local measured = fs.GetStringHeight and fs:GetStringHeight() or 0
    return math.max(measured or 0, TextHeight())
end

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

-- ------------------------------------------------------------
-- Zones
--
-- The Group Finder knows each zone's level range but not whose it is, so the
-- side comes from here: "A" and "H" for a faction's own zones, nothing for
-- contested ground. shared marks a starting zone both factions begin in.
-- mapID is the zone's uiMapID, used to open the world map on it. Keys are
-- spelled the way the Group Finder spells them.
-- ------------------------------------------------------------

local ZONES = {
    ["Durotar"] = { side = "H", mapID = 1411 },
    ["Mulgore"] = { side = "H", mapID = 1412 },
    ["The Barrens"] = { side = "H", mapID = 1413 },
    ["Tirisfal Glades"] = { side = "H", mapID = 1420 },
    ["Silverpine Forest"] = { side = "H", mapID = 1421 },
    ["Darkspear Islands"] = { side = "H" },
    ["Elwynn Forest"] = { side = "A", mapID = 1429 },
    ["Dun Morogh"] = { side = "A", mapID = 1426 },
    ["Teldrassil"] = { side = "A", mapID = 1438 },
    ["Zephras Isle"] = { shared = true, mapID = 2521 },
    ["Westfall"] = { side = "A", mapID = 1436 },
    ["Loch Modan"] = { side = "A", mapID = 1432 },
    ["Darkshore"] = { side = "A", mapID = 1439 },
    ["Redridge Mountains"] = { side = "A", mapID = 1433 },
    ["Alterac Mountains"] = { mapID = 1416 },
    ["Arathi Highlands"] = { mapID = 1417 },
    ["Badlands"] = { mapID = 1418 },
    ["Blasted Lands"] = { mapID = 1419 },
    ["Western Plaguelands"] = { mapID = 1422 },
    ["Eastern Plaguelands"] = { mapID = 1423 },
    ["Hillsbrad Foothills"] = { mapID = 1424 },
    ["Hinterlands"] = { mapID = 1425 },
    ["Searing Gorge"] = { mapID = 1427 },
    ["Burning Steppes"] = { mapID = 1428 },
    ["Duskwood"] = { mapID = 1431 },
    ["Stranglethorn Vale"] = { mapID = 1434 },
    ["Swamp of Sorrows"] = { mapID = 1435 },
    ["Wetlands"] = { mapID = 1437 },
    ["Ashenvale"] = { mapID = 1440 },
    ["Thousand Needles"] = { mapID = 1441 },
    ["Stonetalon Mountains"] = { mapID = 1442 },
    ["Desolace"] = { mapID = 1443 },
    ["Feralas"] = { mapID = 1444 },
    ["Dustwallow Marsh"] = { mapID = 1445 },
    ["Tanaris"] = { mapID = 1446 },
    ["Azshara"] = { mapID = 1447 },
    ["Felwood"] = { mapID = 1448 },
    ["Un'Goro Crater"] = { mapID = 1449 },
    ["Silithus"] = { mapID = 1451 },
    ["Winterspring"] = { mapID = 1452 },
    ["Riverglades"] = {},
    ["Mount Hyjal"] = {},

    -- Cities are not in the Group Finder, but a good share of quests start in
    -- them. They are listed for those quests alone, see CityRows.
    ["Orgrimmar"] = { side = "H", mapID = 1454, city = true },
    ["Thunder Bluff"] = { side = "H", mapID = 1456, city = true },
    ["Undercity"] = { side = "H", mapID = 1458, city = true },
    ["Stormwind City"] = { side = "A", mapID = 1453, city = true },
    ["Ironforge"] = { side = "A", mapID = 1455, city = true },
    ["Darnassus"] = { side = "A", mapID = 1457, city = true },
}
ns.ZONES = ZONES

-- "The Hinterlands" and "Hinterlands" are the same zone: the map says one,
-- the Group Finder the other.
local function NormalName(name)
    return (name:lower():gsub("^the ", ""):gsub("[^%w]", ""))
end

local ZONES_BY_NORMAL = {}
for name, zone in pairs(ZONES) do ZONES_BY_NORMAL[NormalName(name)] = zone end

local function ZoneInfo(name)
    return ZONES_BY_NORMAL[NormalName(name)]
end

-- ------------------------------------------------------------
-- SavedVariables
-- ------------------------------------------------------------

-- Defaults for a character with no saved settings yet; saved values win.
-- Recorded quests reach other characters by being harvested into
-- RecordedQuests.lua.
local DEFAULTS = {
    shown = true,
    range = DEFAULT_RANGE,      -- levels beyond a zone's own range, 0-15
    hideOtherSide = true,       -- hide the other faction's own zones
    hideDone = false,           -- hide recorded quests you have handed in
    hideHigh = false,           -- hide quests more than QUEST_WINDOW levels above you
    hideProfession = false,     -- hide quests for a profession you do not have
    hideChainSteps = false,     -- hide a chain's later steps until the one before is done
    chainHelp = false,          -- show chain suggestions and let the player answer them
    style = DEFAULT_STYLE,      -- one of STYLE_ORDER
    bgAlpha = 0.75,             -- 0 see-through, 1 solid
    fontSize = 12,              -- 6-24; nil follows the client
    size = { width = 260, height = 320 },
}

local function EnsureDB()
    ZoneLevelGuideDB = ZoneLevelGuideDB or {}
    local db = ZoneLevelGuideDB
    for key, value in pairs(DEFAULTS) do
        if db[key] == nil then
            if type(value) == "table" then
                local copy = {}
                for k, v in pairs(value) do copy[k] = v end
                db[key] = copy
            else
                db[key] = value
            end
        end
    end
    -- [zone name] = true for the zones whose quest list is unfolded
    db.expanded = db.expanded or {}
    -- [questID] = { title, level, group, dungeon, zone, mapID, x, y, giver, fromItem, handIn, repeatable,
    --               side, after, afterTitle, afterGuess, afterGuessTitle, needs, needsQuest, needsQuestTitle,
    --               instead, during, leadsTo, class,
    --               profession, itemZone, itemMapID, itemX, itemY, turnIn, turnInZone, turnInMapID, turnInX, turnInY }
    -- item*: where the item the quest needs lies, e.g. a book; ctrl-click marks it.
    -- turnIn*: where it is handed in, when the quest only hints at it; ctrl-click marks it.
    -- after = false: the chain was taken away, and harvest removes it too. needsQuest = false likewise.
    db.quests = db.quests or {}
    -- The latest hand-ins, newest first: { id, title }
    db.turnedIn = db.turnedIn or {}
end

EnsureDB()

-- AllQuests' cache, dropped whenever a quest is recorded or noted.
local allQuests, questsByZone

local function QuestsChanged()
    allQuests, questsByZone = nil, nil
end

-- "DRUID", "WARRIOR" and so on: the client's own token, the same in every
-- language. A quest with `class` set is shown to that class alone.
local function PlayerClass()
    if not UnitClass then return nil end
    local _, token = UnitClass("player")
    return token
end

-- `races` lists the race tokens a quest is for ("Gnome"), as UnitRace gives them.
local function ForYourRace(q)
    if not (q.races and UnitRace) then return true end
    local _, token = UnitRace("player")
    if not token then return true end
    for race in q.races:gmatch("%S+") do
        if race == token then return true end
    end
    return false
end

-- The professions you have, by name ("Tailoring"). The client's own list of
-- professions is asked first; it does not care how the skill window is folded.
local function ProfessionList()
    if not (GetProfessions and GetProfessionInfo) then return nil end
    local ok, a, b, c, d, e = pcall(GetProfessions)
    if not ok then return nil end
    local found = {}
    for _, index in pairs({ a, b, c, d, e }) do
        local gotInfo, name = pcall(GetProfessionInfo, index)
        if gotInfo and type(name) == "string" then found[name] = true end
    end
    return next(found) and found or nil
end

-- The skills you have, by the name the skill list shows. Nil when neither
-- list can be read whole: a collapsed header hides its lines, and a quest is
-- only dimmed or hidden for a profession we know you lack.
local function PlayerSkills()
    local professions = ProfessionList()
    if professions then return professions end
    if not (GetNumSkillLines and GetSkillLineInfo) then return nil end
    local found = {}
    for i = 1, GetNumSkillLines() do
        local name, isHeader, isExpanded = GetSkillLineInfo(i)
        if isHeader and not isExpanded then return nil end
        if name and not isHeader then found[name] = true end
    end
    return next(found) and found or nil
end

local function LacksProfession(q)
    if not q.profession then return false end
    local skills = PlayerSkills()
    return skills ~= nil and not skills[q.profession]
end

local CLASS_NAME = {
    DRUID = "Druid", HUNTER = "Hunter", MAGE = "Mage", PALADIN = "Paladin", PRIEST = "Priest",
    ROGUE = "Rogue", SHAMAN = "Shaman", WARLOCK = "Warlock", WARRIOR = "Warrior",
}

local function PlayerSide()
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    if faction == "Alliance" then return "A" end
    if faction == "Horde" then return "H" end
    return nil
end

-- ------------------------------------------------------------
-- The Group Finder's zones
--
-- The finder lists dungeons and zones in separate categories, and says which
-- is which only by name. A category counts as zones when any of its
-- activities is a zone we know; everything in it is then taken, which is how
-- a zone added later still shows, with no side until it is added above.
-- ------------------------------------------------------------

local function LevelField(value)
    if type(value) == "number" and value > 0 then return value end
    return nil
end

local function ActivityDetails(activityID)
    if not (C_LFGList and C_LFGList.GetActivityInfoTable) then return nil end
    local ok, info = pcall(C_LFGList.GetActivityInfoTable, activityID)
    if not (ok and info) then return nil end
    return info.fullName or info.shortName,
        LevelField(info.minLevelSuggestion) or LevelField(info.minLevel),
        LevelField(info.maxLevelSuggestion) or LevelField(info.maxLevel)
end

-- { { name, minLevel, maxLevel }, ... }, or nil while the client has not answered.
local finderZones

local function ScanZones()
    finderZones = nil
    if not (C_LFGList and C_LFGList.GetAvailableCategories and C_LFGList.GetAvailableActivities) then
        return
    end
    local ok, categories = pcall(C_LFGList.GetAvailableCategories)
    if not (ok and categories) then return end

    local found = {}
    for _, categoryID in ipairs(categories) do
        local gotList, activities = pcall(C_LFGList.GetAvailableActivities, categoryID)
        local inCategory, isZones = {}, false
        for _, activityID in ipairs((gotList and activities) or {}) do
            local name, minLevel, maxLevel = ActivityDetails(activityID)
            if name and minLevel and maxLevel then
                table.insert(inCategory, { name = name, minLevel = minLevel, maxLevel = maxLevel })
                if ZoneInfo(name) then isZones = true end
            end
        end
        if isZones then
            for _, zone in ipairs(inCategory) do table.insert(found, zone) end
        end
    end
    if #found > 0 then finderZones = found end
end

local function EnsureZoneScan()
    if finderZones == nil then ScanZones() end
end

-- ------------------------------------------------------------
-- Recording quests
--
-- Each quest you accept is written down with where you stood and who gave
-- it. The giver is caught when the quest text opens (QUEST_DETAIL), since by
-- QUEST_ACCEPTED the dialog is closing and the NPC may be gone. The position
-- is read on the zone's own map, not on a building or cave inside it, so the
-- mark lands in the right place when the zone map is opened.
-- ------------------------------------------------------------

local ZONE_MAP_TYPE = 3   -- Enum.UIMapType.Zone
local GIVER_WINDOW = 120  -- seconds a caught giver stays valid

local CHAIN_WINDOW = 5    -- seconds after a hand-in that an offered quest counts as its follow-up
local RECENT_TURN_INS = 8 -- hand-ins kept for the chain menu
local CHAIN_MENU_AGE = 3600 -- seconds before a quest was taken that a hand-in may still be its previous step

local pendingGiver, pendingGiverAt, pendingText, pendingFromItem, pendingShared, pendingAfter
-- The quest /zlg after and /zlg needs apply to when no ID is given.
local lastRecorded
-- The last hand-in: { id, title, npc, at, menu }. `menu` is set when the
-- NPC's menu opened after it, so what came next was picked, not offered.
local lastTurnIn
local completeTitle, completeNpc, completeID, completeDirect

local function ZoneOfMap(mapID)
    if not (mapID and C_Map and C_Map.GetMapInfo) then return nil end
    local ok, info = pcall(C_Map.GetMapInfo, mapID)
    if not ok then return nil end
    for _ = 1, 5 do
        if not (info and info.mapType and info.mapType > ZONE_MAP_TYPE
            and info.parentMapID and info.parentMapID > 0) then
            break
        end
        ok, info = pcall(C_Map.GetMapInfo, info.parentMapID)
        if not ok then return nil end
    end
    if not info then return nil end
    -- Some caves (Wailing Caverns' mouth) hang straight under the continent:
    -- ask the continent which zone the player is standing in.
    if info.mapType and info.mapType < ZONE_MAP_TYPE and info.mapID ~= mapID
        and C_Map.GetMapInfoAtPosition and C_Map.GetPlayerMapPosition then
        local okPos, pos = pcall(C_Map.GetPlayerMapPosition, info.mapID, "player")
        local x, y
        if okPos and pos and pos.GetXY then x, y = pos:GetXY() end
        if x and y then
            local okAt, at = pcall(C_Map.GetMapInfoAtPosition, info.mapID, x, y)
            if okAt and at and at.mapType == ZONE_MAP_TYPE then info = at end
        end
    end
    return info.name, info.mapID or mapID
end

local function IsContinent(mapID)
    if not (mapID and C_Map and C_Map.GetMapInfo) then return false end
    local ok, info = pcall(C_Map.GetMapInfo, mapID)
    return ok and info and info.mapType and info.mapType < ZONE_MAP_TYPE or false
end

local function PlayerPosition(mapID)
    if not (C_Map and C_Map.GetPlayerMapPosition) then return nil end
    local ok, pos = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
    if not (ok and pos and pos.GetXY) then return nil end
    local x, y = pos:GetXY()
    if not (x and y) or (x == 0 and y == 0) then return nil end
    return math.floor(x * 1000 + 0.5) / 10, math.floor(y * 1000 + 0.5) / 10
end

-- The quest log's entry for a quest, however this client lets us find it.
local function QuestLogInfo(questID)
    if not (C_QuestLog and C_QuestLog.GetInfo) then return nil end
    if C_QuestLog.GetLogIndexForQuestID then
        local ok, index = pcall(C_QuestLog.GetLogIndexForQuestID, questID)
        if ok and index then
            local gotInfo, info = pcall(C_QuestLog.GetInfo, index)
            if gotInfo and info then return info end
        end
    end
    local ok, count = pcall(C_QuestLog.GetNumQuestLogEntries)
    if not (ok and type(count) == "number") then return nil end
    for index = 1, count do
        local gotInfo, info = pcall(C_QuestLog.GetInfo, index)
        if gotInfo and info and info.questID == questID then return info end
    end
    return nil
end

-- Quest tags that mean "this is done in a dungeon": Dungeon and Heroic.
local DUNGEON_TAGS = { [81] = true, [85] = true }

local function IsDungeonQuest(questID)
    if not (C_QuestLog and C_QuestLog.GetQuestTagInfo) then return nil end
    local ok, info = pcall(C_QuestLog.GetQuestTagInfo, questID)
    if ok and info and DUNGEON_TAGS[info.tagID] then return true end
    return nil
end

-- The giver's name and the quest's text, while the dialog is open. The text
-- is kept for dungeon quests only: DungeonLevelGuide reads it to tell which
-- dungeon the quest belongs to.
--
-- A quest started from an item opens the same dialog with no NPC behind it,
-- and the dialog's unit is then you. Your own name is never a giver; the
-- quest is marked as started from an item instead, taken where you stood.
--
-- A quest shared by another player opens it too, with that player behind it.
-- Neither the player nor where you stood says anything about where the quest
-- is picked up, so a shared quest is not recorded at all.
local function Now()
    return (GetTime and GetTime()) or 0
end

-- Inside an instance the client hands out an NPC's name as a secret value:
-- it can be passed on, but not compared or saved.
local function IsSecret(value)
    if issecretvalue then return issecretvalue(value) == true end
    if type(value) ~= "string" then return false end
    return not pcall(function() return value == "" end)
end

local function Readable(value)
    if IsSecret(value) then return nil end
    return value
end

-- Wall-clock seconds, which unlike GetTime survive a logout: when a quest was
-- taken and when one was handed in, so the chain menu offers only earlier ones.
local function Stamp()
    return time and time() or nil
end

local function IsOtherPlayer(unit)
    if not (UnitIsPlayer and UnitIsPlayer(unit)) then return false end
    return not (UnitIsUnit and UnitIsUnit(unit, "player"))
end

-- A quest offered straight after a hand-in, by the same NPC and without its
-- menu in between, is the next step of a chain: the client only does that
-- for a follow-up. Returns the quest handed in.
local function OfferedAfterHandIn(giver)
    local turnIn = lastTurnIn
    if not turnIn or turnIn.menu or Now() - turnIn.at > CHAIN_WINDOW then return nil end
    if giver and turnIn.npc and giver ~= turnIn.npc then return nil end
    lastTurnIn = nil
    return { id = turnIn.id, title = turnIn.title }
end

local function CatchGiver()
    local raw = UnitName and (UnitName("questnpc") or UnitName("npc"))
    -- A hidden name is still an NPC; only the giver is left out.
    local hidden = IsSecret(raw)
    local name = Readable(raw)
    if name and UnitName and name == UnitName("player") then name = nil end
    -- Forever names the item itself instead, and the item is still in the bags.
    -- The modern client only has the C_Item version.
    local itemCount = (C_Item and C_Item.GetItemCount) or GetItemCount
    if name and itemCount then
        local ok, count = pcall(itemCount, name)
        if ok and type(count) == "number" and count > 0 then name = nil end
    end
    pendingGiverAt = Now()
    pendingShared = name ~= nil and (IsOtherPlayer("questnpc") or IsOtherPlayer("npc"))
    pendingGiver = name
    pendingFromItem = name == nil and not hidden
    pendingAfter = not pendingShared and OfferedAfterHandIn(name) or nil
    local okText, text = pcall(GetQuestText)
    local okGoal, goal = pcall(GetObjectiveText)
    pendingText = ((okText and Readable(text)) or "") .. " " .. ((okGoal and Readable(goal)) or "")
end

-- An escort another player started asks before it joins you, with no dialog.
local function CatchSharedEscort()
    pendingGiver, pendingText, pendingFromItem, pendingAfter = nil, nil, nil, nil
    pendingGiverAt = Now()
    pendingShared = true
end

-- The quest's name and NPC while the hand-in dialog is open; by
-- QUEST_TURNED_IN the log no longer has it. A quest that is not in the log
-- while it is being handed in was never taken: the NPC takes an item and the
-- quest is done on the spot, so it is recorded at the hand-in instead.
local function CatchHandIn()
    local ok, text = pcall(GetTitleText)
    text = ok and Readable(text) or nil
    completeTitle = type(text) == "string" and text ~= "" and text or nil
    completeNpc = UnitName and Readable(UnitName("questnpc") or UnitName("npc"))
    local okID, id = pcall(GetQuestID)
    completeID = okID and type(id) == "number" and id > 0 and id or nil
    completeDirect = false
    if completeID and C_QuestLog and C_QuestLog.IsOnQuest then
        local okLog, active = pcall(C_QuestLog.IsOnQuest, completeID)
        completeDirect = okLog and active == false
    end
end

-- A quest handed straight in, recorded where you stood with the NPC as its
-- giver. Only the first time: a later hand-in says nothing new.
local function RecordStraightHandIn(questID, title, npc)
    local known = ZoneLevelGuideDB.quests[questID]
    if known and known.zone then return end
    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local zone, zoneMapID = ZoneOfMap(mapID)
    local x, y = PlayerPosition(zoneMapID or mapID)
    local level
    if C_QuestLog and C_QuestLog.GetQuestDifficultyLevel then
        local ok, value = pcall(C_QuestLog.GetQuestDifficultyLevel, questID)
        if ok and type(value) == "number" and value > 0 then level = value end
    end
    local q = known or {}
    q.title, q.level, q.zone, q.mapID, q.x, q.y = title, level, zone, zoneMapID or mapID, x, y
    q.giver, q.handIn, q.side, q.taken = npc, true, PlayerSide(), Stamp()
    ZoneLevelGuideDB.quests[questID] = q
    lastRecorded = questID
    QuestsChanged()
end

local function RecordHandIn(questID)
    if type(questID) ~= "number" then return end
    local title = (C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID))
    title = Readable(title)
    if type(title) ~= "string" then title = completeTitle end
    lastTurnIn = { id = questID, title = title, npc = completeNpc, at = Now() }
    if completeDirect and completeID == questID then RecordStraightHandIn(questID, title, completeNpc) end
    completeTitle, completeNpc, completeID, completeDirect = nil, nil, nil, nil

    local recent = ZoneLevelGuideDB.turnedIn
    for i = #recent, 1, -1 do
        if recent[i].id == questID then table.remove(recent, i) end
    end
    table.insert(recent, 1, { id = questID, title = title, at = Stamp() })
    for i = #recent, RECENT_TURN_INS + 1, -1 do recent[i] = nil end

    -- The follow-up's dialog can arrive a moment before the hand-in is told.
    if pendingGiverAt and not pendingShared and not pendingAfter and Now() - pendingGiverAt <= 1 then
        pendingAfter = OfferedAfterHandIn(pendingGiver)
    end
end

-- The NPC's menu opened: whatever is taken next was chosen from it.
local function MenuOpened()
    if lastTurnIn then lastTurnIn.menu = true end
end

-- What the quest log says the quest is about, when the dialog was never seen
-- (a quest shared or picked up off an item).
local function ObjectivesText(questID)
    if not (C_QuestLog and C_QuestLog.GetQuestObjectives) then return nil end
    local ok, objectives = pcall(C_QuestLog.GetQuestObjectives, questID)
    if not (ok and objectives) then return nil end
    local parts = {}
    for _, objective in ipairs(objectives) do
        if objective.text then table.insert(parts, objective.text) end
    end
    return #parts > 0 and table.concat(parts, " ") or nil
end

-- Forever's "Camping 101: Skinning" and its kin name their profession.
-- `profession = false` in the shipped data means it was checked: none needed.
local function TitleProfession(title, questID)
    local shipped = ns.RECORDED_QUESTS and ns.RECORDED_QUESTS[questID]
    if shipped and shipped.profession == false then return nil end
    return type(title) == "string" and title:match("^Camping 101: (.+)$") or nil
end

local function RecordQuest(questID)
    if type(questID) ~= "number" or questID <= 0 then return false end

    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local zone, zoneMapID = ZoneOfMap(mapID)
    local x, y = PlayerPosition(zoneMapID or mapID)

    local info = QuestLogInfo(questID)
    local title = (C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID))
        or (info and info.title)
    title = Readable(title)

    local giver, text, fromItem, shared, offeredAfter
    if pendingGiverAt and Now() - pendingGiverAt <= GIVER_WINDOW then
        giver, text, fromItem = pendingGiver, pendingText, pendingFromItem or nil
        shared, offeredAfter = pendingShared, pendingAfter
    end
    pendingGiver, pendingGiverAt, pendingText, pendingFromItem = nil, nil, nil, nil
    pendingShared, pendingAfter = nil, nil
    if shared then return false end
    local dungeon = IsDungeonQuest(questID)

    lastRecorded = questID
    local annotations = ZoneLevelGuideDB.quests[questID] or {}
    -- A suggestion waits for a yes in the chain menu; a no (false) sticks.
    local afterGuess, afterGuessTitle = annotations.afterGuess, annotations.afterGuessTitle
    if offeredAfter and afterGuess ~= false and not annotations.after then
        afterGuess, afterGuessTitle = offeredAfter.id, offeredAfter.title
    end
    ZoneLevelGuideDB.quests[questID] = {
        after = annotations.after,
        afterTitle = annotations.afterTitle,
        afterGuess = afterGuess,
        afterGuessTitle = afterGuessTitle,
        needs = annotations.needs,
        needsQuest = annotations.needsQuest,
        needsQuestTitle = annotations.needsQuestTitle,
        instead = annotations.instead,
        during = annotations.during,
        leadsTo = annotations.leadsTo,
        class = annotations.class,
        profession = annotations.profession or TitleProfession(title, questID),
        title = title,
        level = info and (info.difficultyLevel or info.level),
        group = info and info.suggestedGroup and info.suggestedGroup > 0 or nil,
        dungeon = dungeon,
        text = dungeon and (text or ObjectivesText(questID)) or nil,
        zone = zone,
        mapID = zoneMapID or mapID,
        x = x,
        y = y,
        giver = giver,
        fromItem = fromItem,
        side = PlayerSide(),
        taken = Stamp(),
    }
    QuestsChanged()
    return true
end

-- Classic's quests first, then the harvested ones, then this session's on
-- top, keyed by quest ID. A harvested quest replaces Classic's whole: it is
-- what Forever showed. This session's go on top field by field: a session
-- entry may hold nothing but a note typed in with /zlg needs, and that must
-- not wipe out where the quest is picked up.
--
-- Built once and kept, with the quests grouped by zone, until QuestsChanged.
local function AllQuests()
    if allQuests then return allQuests end
    local all = {}
    for id, q in pairs(ns.CLASSIC_QUESTS or {}) do all[id] = q end
    for id, q in pairs(ns.RECORDED_QUESTS or {}) do all[id] = q end
    for id, q in pairs(ZoneLevelGuideDB.quests or {}) do
        local merged = {}
        for k, v in pairs(all[id] or {}) do merged[k] = v end
        for k, v in pairs(q) do merged[k] = v end
        -- Recorded on the continent map before ZoneOfMap looked past it:
        -- the file's place is better.
        if all[id] and all[id].zone and IsContinent(q.mapID) then
            merged.zone, merged.mapID, merged.x, merged.y = all[id].zone, all[id].mapID, all[id].x, all[id].y
        end
        -- Taken in play, not just noted: Forever has shown it.
        if q.zone then merged.classic = nil end
        if (all[id] or {}).profession == false then merged.profession = nil end
        all[id] = merged
    end
    local byZone = {}
    for id, q in pairs(all) do
        if q.zone then
            local key = NormalName(q.zone)
            byZone[key] = byZone[key] or {}
            byZone[key][id] = q
        end
    end
    allQuests, questsByZone = all, byZone
    return all
end

local function ZoneQuests(zoneName)
    AllQuests()
    return questsByZone[NormalName(zoneName)] or {}
end

-- ------------------------------------------------------------
-- Colours
--
-- A quest is coloured the way the quest log colours it, bucket for bucket. A
-- zone is coloured by where you stand in its range: near the bottom it is
-- still hard going, in the middle it is right, near the top it is easy.
-- ------------------------------------------------------------

local FALLBACK_COLORS = {
    impossible    = { r = 1,    g = 0.1,  b = 0.1 },
    verydifficult = { r = 1,    g = 0.5,  b = 0.25 },
    difficult     = { r = 1,    g = 1,    b = 0 },
    standard      = { r = 0.25, g = 0.75, b = 0.25 },
    trivial       = { r = 0.5,  g = 0.5,  b = 0.5 },
}

local function GreenRange()
    local ok, range = pcall(GetQuestGreenRange, "player")
    if ok and type(range) == "number" and range > 0 then return range end
    return 5
end

local function QuestBucket(level, playerLevel)
    local diff = level - playerLevel
    if diff >= 5 then return "impossible" end
    if diff >= 3 then return "verydifficult" end
    if diff >= -2 then return "difficult" end
    if -diff <= GreenRange() then return "standard" end
    return "trivial"
end

local function ZoneBucket(zone, playerLevel)
    if playerLevel < zone.minLevel then return "impossible" end
    if playerLevel > zone.maxLevel then return "trivial" end
    local span = math.max(1, zone.maxLevel - zone.minLevel)
    local share = (playerLevel - zone.minLevel) / span
    if share < 0.25 then return "verydifficult" end
    if share < 0.75 then return "difficult" end
    return "standard"
end

local function BucketColor(bucket)
    if Styled() then return RGB(Style().difficulty[bucket]) end
    local color = (QuestDifficultyColors and QuestDifficultyColors[bucket]) or FALLBACK_COLORS[bucket]
    return color.r, color.g, color.b
end

-- ------------------------------------------------------------
-- Quests
-- ------------------------------------------------------------

-- The "Low Level Quests" box in the minimap's tracking menu. Nil when the
-- client does not say, and then nothing is hidden by it. The modern client
-- returns a table, older ones the fields one by one.
local function TracksLowLevelQuests()
    local wanted = MINIMAP_TRACKING_TRIVIAL_QUESTS
    if not (wanted and C_Minimap and C_Minimap.GetNumTrackingTypes and C_Minimap.GetTrackingInfo) then
        return nil
    end
    local ok, count = pcall(C_Minimap.GetNumTrackingTypes)
    if not ok or type(count) ~= "number" then return nil end
    for i = 1, count do
        local got, info, _, active = pcall(C_Minimap.GetTrackingInfo, i)
        if got then
            local name = info
            if type(info) == "table" then name, active = info.name, info.active end
            if name == wanted then return active and true or false end
        end
    end
    return nil
end

local function QuestStatus(questID)
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        local ok, done = pcall(C_QuestLog.IsQuestFlaggedCompleted, questID)
        if ok and done then return "done" end
    end
    if C_QuestLog and C_QuestLog.IsOnQuest then
        local ok, active = pcall(C_QuestLog.IsOnQuest, questID)
        if ok and active then return "active" end
    end
    return "open"
end

-- A breadcrumb is no longer offered once you have the quest it leads to.
local function BreadcrumbSpent(q, id)
    return q.leadsTo ~= nil and QuestStatus(id) == "open" and QuestStatus(q.leadsTo) ~= "open"
end

-- Never to be taken again: the other of an either-or is done, the quest it
-- can only be done during is, or a breadcrumb's target is taken. The "hide
-- handed in" filter counts it as done.
local function ClosedForGood(q, id)
    if q.instead and QuestStatus(id) ~= "done" and QuestStatus(q.instead) == "done" then return true end
    if BreadcrumbSpent(q, id) then return true end
    return q.during ~= nil and QuestStatus(q.during) == "done"
end

-- A book: handed straight in, and not again and again. It is found somewhere
-- else, so its level says nothing about the zone it is handed in to.
local function IsBook(q)
    return q.handIn == true and not q.repeatable
end

-- The recorded quests for a zone, lowest level first, minus the ones the
-- filters hide, and how many were hidden. Grey quests follow the minimap's
-- "Low Level Quests" box, as they do on the map, except one in your log.
local function QuestsIn(zoneName, window, level)
    local mine = PlayerSide()
    local playerLevel = level or (UnitLevel and UnitLevel("player")) or 1
    local hideLow = TracksLowLevelQuests() == false
    local out, hidden = {}, 0
    for id, q in pairs(ZoneQuests(zoneName)) do
        -- A window (a city's row) leaves out quests far from your level, and
        -- another class's quests are never yours to take. Neither is hidden
        -- by a filter; they are just not what the row is about.
        local inWindow = not window
            or (q.level == nil and window[1] <= 0)
            or (q.level and q.level >= window[1] and q.level <= window[2])
        local yourClass = not (q.class and PlayerClass() and q.class ~= PlayerClass())
        if inWindow and yourClass and ForYourRace(q) then
            local otherSide = q.side and mine and q.side ~= mine
            if otherSide and ZoneLevelGuideDB.hideOtherSide then
                hidden = hidden + 1
            elseif ZoneLevelGuideDB.hideDone and (QuestStatus(id) == "done" or ClosedForGood(q, id)) then
                hidden = hidden + 1
            elseif ZoneLevelGuideDB.hideProfession and LacksProfession(q) then
                hidden = hidden + 1
            elseif ZoneLevelGuideDB.hideChainSteps and QuestStatus(id) == "open"
                and ((q.after and QuestStatus(q.after) ~= "done")
                    or (q.needsQuest and QuestStatus(q.needsQuest) ~= "done")) then
                hidden = hidden + 1
            elseif hideLow and q.level and QuestBucket(q.level, playerLevel) == "trivial"
                and QuestStatus(id) ~= "active" then
                hidden = hidden + 1
            else
                local entry = { id = id }
                for k, v in pairs(q) do entry[k] = v end
                table.insert(out, entry)
            end
        end
    end
    table.sort(out, function(a, b)
        -- A book goes last, level or not: it is found somewhere else and only
        -- handed in here. So does a quest with no level.
        local aBook, bBook = IsBook(a), IsBook(b)
        if aBook ~= bBook then return bBook end
        local al, bl = a.level or math.huge, b.level or math.huge
        if al ~= bl then return al < bl end
        return (a.title or "") < (b.title or "")
    end)
    return out, hidden
end


-- ------------------------------------------------------------
-- UI
-- ------------------------------------------------------------

local frame = CreateFrame("Frame", "ZoneLevelGuideFrame", UIParent)
frame:SetSize(260, 320)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:SetResizable(true)
frame:SetFrameStrata("MEDIUM")
frame:SetClampedToScreen(true)
if frame.SetResizeBounds then
    frame:SetResizeBounds(200, 160, 500, 700)
elseif frame.SetMinResize then
    frame:SetMinResize(200, 160)
    frame:SetMaxResize(500, 700)
end

local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()

local function ApplyBackground()
    local r, g, b = 0, 0, 0
    if Styled() then r, g, b = RGB(Style().bg) end
    bg:SetColorTexture(r, g, b, ((ZoneLevelGuideDB and ZoneLevelGuideDB.bgAlpha) or 0.75) * (Style().bgScale or 1))
end

local border = frame:CreateTexture(nil, "BORDER")
border:SetPoint("TOPLEFT", -1, 1)
border:SetPoint("BOTTOMRIGHT", 1, -1)
border:SetColorTexture(1, 1, 1, 0.15)

local titleBar = CreateFrame("Frame", nil, frame)
titleBar:SetPoint("TOPLEFT")
titleBar:SetPoint("TOPRIGHT")
titleBar:SetHeight(24)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")

local title = TrackFont(titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal"), "heading")
title:SetPoint("LEFT", 8, 0)
title:SetText("Zone Level Guide")

-- On the title bar, or the bar (same level, there to be dragged) takes the click.
local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -2, -2)

local rangeLabel = TrackFont(frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
rangeLabel:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 8, -6)

local plusBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
plusBtn:SetSize(20, 20)
plusBtn:SetText("+")
plusBtn:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", -8, -4)

local minusBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
minusBtn:SetSize(20, 20)
minusBtn:SetText("-")
minusBtn:SetPoint("RIGHT", plusBtn, "LEFT", -2, 0)

rangeLabel:SetPoint("TOPRIGHT", minusBtn, "TOPLEFT", -6, 0)
rangeLabel:SetJustifyH("LEFT")

local scrollFrame = CreateFrame("ScrollFrame", "ZoneLevelGuideScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 8, -50)
scrollFrame:SetPoint("BOTTOMRIGHT", -28, 20)
scrollFrame.scrollBarHideable = true

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(1, 1)
scrollFrame:SetScrollChild(content)

local resizeGrip = CreateFrame("Button", nil, frame)
resizeGrip:SetSize(16, 16)
resizeGrip:SetPoint("BOTTOMRIGHT", -2, 2)
resizeGrip:EnableMouse(true)
resizeGrip.tex = resizeGrip:CreateTexture(nil, "OVERLAY")
resizeGrip.tex:SetAllPoints()
resizeGrip.tex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

-- The styled looks' own chrome, built once and shown or hidden by ApplyStyle.
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
local plainPlus = PlainButton(frame, "+", 20, 20)
plainPlus:SetPoint("TOPLEFT", plusBtn, "TOPLEFT")
local plainMinus = PlainButton(frame, "\226\136\146", 20, 20)
plainMinus:SetPoint("TOPLEFT", minusBtn, "TOPLEFT")

local function ShowIf(region, show)
    if show then region:Show() else region:Hide() end
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

    if styled then
        title:SetTextColor(RGB(style.titleColor))
        rangeLabel:SetTextColor(RGB(style.dim))
    else
        title:SetTextColor(1, 0.82, 0)
        rangeLabel:SetTextColor(1, 0.82, 0)
    end

    ShowIf(closeBtn, not styled)
    ShowIf(plusBtn, not styled)
    ShowIf(minusBtn, not styled)
    ShowIf(plainClose, styled)
    ShowIf(plainPlus, styled)
    ShowIf(plainMinus, styled)
    PaintButton(plainClose, true)
    PaintButton(plainPlus)
    PaintButton(plainMinus)
end

-- ------------------------------------------------------------
-- Layout
-- ------------------------------------------------------------

local LIST_PAD = 2
local HEAD_GAP = 8
local BAR_INSET, PLAIN_INSET = 28, 10
local scrollBarShown = true

local function ListInset()
    return scrollBarShown and BAR_INSET or PLAIN_INSET
end

local function ListWidth()
    return math.max(1, (frame:GetWidth() or 220) - 8 - ListInset())
end

local function ShowScrollBar(show)
    if show == scrollBarShown then return false end
    scrollBarShown = show
    local bar = _G["ZoneLevelGuideScrollFrameScrollBar"]
    if bar then
        if show then bar:Show() else bar:Hide() end
    end
    if not show then scrollFrame:SetVerticalScroll(0) end
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -ListInset(), 20)
    return true
end

local function LayoutPanel()
    titleBar:SetHeight(math.max(24, StringHeight(title) + 8))
    local barHeight = titleBar:GetHeight()
    local labelBottom = barHeight + 6 + StringHeight(rangeLabel)
    local buttonBottom = barHeight + 4 + 20
    local listTop = math.max(labelBottom, buttonBottom) + HEAD_GAP
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -listTop)
end

-- Always against the screen: a docked panel's own anchor is relative to the
-- panel it hangs from, and RestoreFrame anchors to UIParent. Docking picks it
-- up again after login, since it then stands edge to edge.
local function SavePosition()
    local left, top = frame:GetLeft(), frame:GetTop()
    if not (left and top) then return end
    ZoneLevelGuideDB.point = { point = "TOPLEFT", relativePoint = "BOTTOMLEFT", x = left, y = top }
end

local function SaveSize()
    ZoneLevelGuideDB.size = { width = frame:GetWidth(), height = frame:GetHeight() }
end

local function RestoreFrame()
    local p = ZoneLevelGuideDB.point
    frame:ClearAllPoints()
    if p then
        frame:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
    else
        frame:SetPoint("CENTER")
    end
    local s = ZoneLevelGuideDB.size
    if s then frame:SetSize(s.width, s.height) end
    ShowIf(frame, ZoneLevelGuideDB.shown)
end

-- ------------------------------------------------------------
-- Map
-- ------------------------------------------------------------

local function OpenMapAt(mapID)
    if not (mapID and WorldMapFrame) then return false end
    if not WorldMapFrame:IsShown() then
        if ShowUIPanel then ShowUIPanel(WorldMapFrame) else WorldMapFrame:Show() end
    end
    if WorldMapFrame.SetMapID then pcall(WorldMapFrame.SetMapID, WorldMapFrame, mapID) end
    return true
end

local function SetWaypoint(mapID, x, y)
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

-- A zone's map: the table's when it has one, else one a recorded quest was
-- picked up on, which is how a new zone gets a map before it is listed.
local function ZoneMapID(zoneName)
    local info = ZoneInfo(zoneName)
    if info and info.mapID then return info.mapID end
    local wanted = NormalName(zoneName)
    for _, q in pairs(AllQuests()) do
        if q.zone and q.mapID and NormalName(q.zone) == wanted then return q.mapID end
    end
    return nil
end

local function OnZoneClicked(zone)
    if not OpenMapAt(ZoneMapID(zone.name)) then
        print((PREFIX .. "no map known for %s yet."):format(zone.name))
    end
end

-- Ctrl-click goes to where the item the quest needs lies, or else to where it
-- is handed in, when that is known.
local function OnQuestClicked(q, toItem)
    if toItem and q.itemMapID and q.itemX and q.itemY then
        SetWaypoint(q.itemMapID, q.itemX, q.itemY)
        OpenMapAt(q.itemMapID)
        print((PREFIX .. "marked the item for %s%s (%.1f, %.1f)."):format(q.title or q.id,
            q.itemZone and (", " .. q.itemZone) or "", q.itemX, q.itemY))
        return
    end
    if toItem and q.turnInMapID and q.turnInX and q.turnInY then
        SetWaypoint(q.turnInMapID, q.turnInX, q.turnInY)
        OpenMapAt(q.turnInMapID)
        print((PREFIX .. "marked where %s is handed in%s (%.1f, %.1f)."):format(q.title or q.id,
            q.turnInZone and (", " .. q.turnInZone) or "", q.turnInX, q.turnInY))
        return
    end
    if not (q.mapID and q.x and q.y) then
        print((PREFIX .. "no position was recorded for %s."):format(q.title or q.id))
        return
    end
    SetWaypoint(q.mapID, q.x, q.y)
    OpenMapAt(q.mapID)
    print((PREFIX .. "marked %s%s (%.1f, %.1f)."):format(q.giver or q.title or q.id,
        q.zone and (", " .. q.zone) or "", q.x, q.y))
end

-- ------------------------------------------------------------
-- Tooltips
-- ------------------------------------------------------------

-- ------------------------------------------------------------
-- Chains and prerequisites
--
-- `after` is the quest that has to be done first, `afterTitle` its name for
-- when that quest is not recorded itself, and `needs` is free text for
-- anything else it takes -- an item that summons the mob that drops it, say.
-- `needsQuest` is a quest whose hand-in unlocks this one without it being the
-- next step of a chain: one quest may open several, each its own errand.
-- `instead` is the quest this one is an alternative to: only one of the two
-- can be done, so doing that one closes this one.
-- They come from the seed, from /zlg after and /zlg needs, or by hand in
-- RecordedQuests.lua, and harvest never overwrites them with nothing.
-- ------------------------------------------------------------

-- The quest a chain starts with: `after` followed back as far as it goes.
-- Returns nil for a quest that is not part of a known chain.
local function ChainStart(q)
    if not q.after then return nil end
    local all = AllQuests()
    local seen = {}
    local id, knownTitle = q.after, q.afterTitle
    while id and not seen[id] do
        seen[id] = true
        local prev = all[id]
        if not (prev and prev.after) then
            local start = { id = id, title = (prev and prev.title) or knownTitle }
            if prev then
                for k, v in pairs(prev) do if start[k] == nil then start[k] = v end end
            end
            return start
        end
        id, knownTitle = prev.after, prev.afterTitle
    end
    return nil
end

-- The quest an annotation is for: this session's, or a stub that carries only
-- the annotation, which harvest adds to the record it already has.
local function AnnotationTarget(questID)
    local id = questID or lastRecorded
    if not id then return nil end
    ZoneLevelGuideDB.quests[id] = ZoneLevelGuideDB.quests[id] or {}
    return id, ZoneLevelGuideDB.quests[id]
end

local function QuestTitle(id)
    local q = AllQuests()[id]
    if q and q.title then return q.title end
    if C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local ok, logTitle = pcall(C_QuestLog.GetTitleForQuestID, id)
        if ok and logTitle then return logTitle end
    end
    return "quest " .. id
end

-- Setting chains from the list -- only with Editor.lua present, which the
-- shared zip leaves out. A quest offered straight after a hand-in carries
-- that hand-in as `afterGuess` until it is confirmed or turned down, which
-- anyone who has turned on chain help can do.
local function IsEditor()
    return ns.EDITOR == true
end

local function HelpsWithChains()
    return IsEditor() or ZoneLevelGuideDB.chainHelp == true
end

local function HasGuess(q)
    return q.afterGuess and not q.after and HelpsWithChains()
end

-- `previous` nil takes the chain away; `title` is its name when known.
local function SetAfter(questID, previous, title)
    local _, q = AnnotationTarget(questID)
    if previous then
        q.after, q.afterTitle = previous, title or QuestTitle(previous)
    else
        q.after, q.afterTitle = false, false
    end
    if q.afterGuess ~= nil then q.afterGuess, q.afterGuessTitle = false, nil end
    QuestsChanged()
end

-- `previous` nil takes it away. A guess is answered by it too: the quest
-- offered after the hand-in was unlocked by it rather than chained to it.
local function SetNeedsQuest(questID, previous, title)
    local _, q = AnnotationTarget(questID)
    if previous then
        q.needsQuest, q.needsQuestTitle = previous, title or QuestTitle(previous)
    else
        q.needsQuest, q.needsQuestTitle = false, false
    end
    if q.afterGuess ~= nil then q.afterGuess, q.afterGuessTitle = false, nil end
    QuestsChanged()
end

local function DismissGuess(questID)
    local _, q = AnnotationTarget(questID)
    q.afterGuess, q.afterGuessTitle = false, nil
    QuestsChanged()
end

local function PlaceText(q)
    local where = q.zone or "?"
    if q.x and q.y then where = ("%s (%.1f, %.1f)"):format(where, q.x, q.y) end
    return where
end

local SIDE_NAME = { A = "Alliance", H = "Horde" }

local function ShowZoneTooltip(row, zone)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(zone.name, 1, 1, 1)
    if zone.city then
        GameTooltip:AddLine(("A city: listed for its quests at levels %d-%d"):format(zone.minLevel,
            zone.maxLevel), 0.8, 0.8, 0.8)
    else
        GameTooltip:AddLine(("Level %d-%d (the Group Finder's range)"):format(zone.minLevel,
            zone.maxLevel), 0.8, 0.8, 0.8)
    end
    local info = ZoneInfo(zone.name)
    local side = info and info.side
    if info then
        if not info.city then
            GameTooltip:AddLine(side and (SIDE_NAME[side] .. " territory")
                or (info.shared and "Both factions start here") or "Contested", 0.8, 0.8, 0.8)
        end
    else
        GameTooltip:AddLine("Side not known yet", 0.6, 0.6, 0.6)
    end
    local quests, hidden = QuestsIn(zone.name, zone.window)
    local open, classic = 0, 0
    for _, q in ipairs(quests) do
        if QuestStatus(q.id) ~= "done" then open = open + 1 end
        if q.classic then classic = classic + 1 end
    end
    GameTooltip:AddLine(("%d quest%s, %d not handed in%s"):format(#quests,
        #quests == 1 and "" or "s", open, hidden > 0 and (", " .. hidden .. " hidden") or ""),
        0.6, 0.8, 1)
    if classic > 0 then
        GameTooltip:AddLine(("%d of them from Classic's data, not yet seen in Forever"):format(classic),
            0.6, 0.6, 0.6)
    end
    if zone.window and not zone.city then
        local later = #(QuestsIn(zone.name)) - #quests
        if later > 0 then
            GameTooltip:AddLine(("%d more for later levels, hidden"):format(later), 0.6, 0.6, 0.6)
        end
    end
    GameTooltip:AddLine("Click to open the zone on the world map.", 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

local STATUS_TEXT = { done = "Handed in", active = "In your quest log", open = "Not picked up" }

local function ShowQuestTooltip(row, q)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(q.title or tostring(q.id), 1, 1, 1)
    if q.level then
        GameTooltip:AddLine(("Quest level %d%s"):format(q.level,
            q.dungeon and ", dungeon" or (q.group and ", group" or "")), 0.8, 0.8, 0.8)
    end
    local where = PlaceText(q)
    if q.fromItem then
        GameTooltip:AddLine(("Starts from an item, taken here: %s"):format(where), 1, 0.82, 0)
    elseif q.handIn then
        GameTooltip:AddLine(("Handed straight in to %s, %s"):format(q.giver or "an unknown NPC", where),
            1, 0.82, 0)
    else
        GameTooltip:AddLine(("From %s, %s"):format(q.giver or "an unknown giver", where), 1, 0.82, 0)
    end
    if q.patrols then
        GameTooltip:AddLine(("%s patrols, so look along the way"):format(q.giver or "The giver"), 1, 0.82, 0, true)
    end
    if q.after then
        local previous = AllQuests()[q.after]
        local previousTitle = (previous and previous.title) or q.afterTitle or ("quest " .. q.after)
        local done = QuestStatus(q.after) == "done"
        GameTooltip:AddLine(("After: %s%s"):format(previousTitle, done and " (done)" or ""),
            done and 0.6 or 1, done and 0.6 or 0.5, done and 0.6 or 0.25, true)
        local start = ChainStart(q)
        if start and start.id ~= q.after then
            GameTooltip:AddLine(("Chain starts with %s: %s, %s"):format(start.title or ("quest " .. start.id),
                start.giver or "unknown giver", PlaceText(start)), 1, 0.82, 0, true)
        elseif previous and not done then
            GameTooltip:AddLine(("Get it from %s, %s"):format(previous.giver or "an unknown giver",
                PlaceText(previous)), 1, 0.82, 0, true)
        end
    end
    if HasGuess(q) then
        GameTooltip:AddLine(("Probably after: %s -- offered straight after you handed it in"):format(
            q.afterGuessTitle or ("quest " .. q.afterGuess)), 1, 0.5, 0.25, true)
    end
    if q.needsQuest then
        local previous = AllQuests()[q.needsQuest]
        local previousTitle = (previous and previous.title) or q.needsQuestTitle or ("quest " .. q.needsQuest)
        local done = QuestStatus(q.needsQuest) == "done"
        GameTooltip:AddLine(("Unlocked by handing in %s%s"):format(previousTitle, done and " (done)" or ""),
            done and 0.6 or 1, done and 0.6 or 0.5, done and 0.6 or 0.25, true)
        if previous and not done then
            GameTooltip:AddLine(("Get it from %s, %s"):format(previous.giver or "an unknown giver",
                PlaceText(previous)), 1, 0.82, 0, true)
        end
    end
    if q.needs then
        GameTooltip:AddLine("Needs: " .. q.needs, 1, 0.5, 0.25, true)
    end
    if q.itemMapID and q.itemX and q.itemY then
        GameTooltip:AddLine(("The item lies in %s (%.1f, %.1f) -- ctrl-click to mark it"):format(
            q.itemZone or "?", q.itemX, q.itemY), 1, 0.82, 0, true)
    end
    if q.turnInMapID and q.turnInX and q.turnInY then
        local action = (q.itemMapID and q.itemX and q.itemY) and "" or " -- ctrl-click to mark it"
        GameTooltip:AddLine(("Handed in %sin %s (%.1f, %.1f)%s"):format(
            q.turnIn and ("at " .. q.turnIn .. " ") or "", q.turnInZone or "?",
            q.turnInX, q.turnInY, action), 1, 0.82, 0, true)
    end
    if q.leadsTo then
        local target = AllQuests()[q.leadsTo] or {}
        local targetTitle = target.title or ("quest " .. q.leadsTo)
        if BreadcrumbSpent(q, q.id) then
            GameTooltip:AddLine(("Not available: you already have %s, which it leads to."):format(targetTitle),
                0.6, 0.6, 0.6, true)
        else
            GameTooltip:AddLine(("Leads to %s: %s, %s -- which can be taken without this one"):format(
                targetTitle, target.giver or "unknown giver", PlaceText(target)), 0.6, 0.8, 1, true)
        end
    end
    if q.profession then
        local lacks = LacksProfession(q)
        GameTooltip:AddLine("Needs " .. q.profession, lacks and 1 or 0.6, lacks and 0.5 or 0.6,
            lacks and 0.25 or 0.6, true)
    end
    if q.repeatable then
        GameTooltip:AddLine("Repeatable: it can be handed in again and again.", 0.6, 0.8, 1, true)
    end
    if q.during then
        local other = AllQuests()[q.during]
        local otherTitle = (other and other.title) or ("quest " .. q.during)
        local open = QuestStatus(q.during) == "active"
        GameTooltip:AddLine(("Only while %s is in your quest log."):format(otherTitle),
            open and 1 or 0.6, open and 0.5 or 0.6, open and 0.25 or 0.6, true)
    end
    if q.instead then
        local other = AllQuests()[q.instead]
        local otherTitle = (other and other.title) or ("quest " .. q.instead)
        if QuestStatus(q.instead) == "done" and QuestStatus(q.id) ~= "done" then
            GameTooltip:AddLine(("Not available: you did %s instead."):format(otherTitle), 0.6, 0.6, 0.6, true)
        else
            GameTooltip:AddLine(("Or instead: %s -- only one of them can be done."):format(otherTitle),
                1, 0.5, 0.25, true)
        end
    end
    if q.classic then
        GameTooltip:AddLine("From Classic's data, not yet seen in Forever.", 0.6, 0.6, 0.6, true)
    end
    GameTooltip:AddLine(STATUS_TEXT[QuestStatus(q.id)], 0.6, 0.8, 1)
    GameTooltip:AddLine("Click to mark where it is picked up.", 0.6, 0.6, 0.6)
    if IsEditor() then
        GameTooltip:AddLine("Right-click to set which quest comes before it or unlocks it.", 0.6, 0.6, 0.6)
    elseif HasGuess(q) then
        GameTooltip:AddLine("Right-click to confirm or turn it down.", 0.6, 0.6, 0.6)
    end
    GameTooltip:Show()
end

-- ------------------------------------------------------------
-- List
-- ------------------------------------------------------------

-- Blizzard's dungeon swirl, the one the map puts on an instance entrance, as
-- an inline atlas. A client without that atlas would draw nothing at all, so
-- it is asked first and a short text mark stands in.
local dungeonMark

local function DungeonMark()
    if dungeonMark then return dungeonMark end
    local ok, info = pcall(function() return C_Texture and C_Texture.GetAtlasInfo("Dungeon") end)
    if ok and info then
        dungeonMark = "|A:Dungeon:0:0|a "
    else
        dungeonMark = "|cff8fc3d6[D]|r "
    end
    return dungeonMark
end

local rowPool = {}
local RefreshList

-- The chain menu, on right-clicking a quest: the quest offered right after a
-- hand-in first, then the latest hand-ins, then taking the chain away.
local MENU_WIDTH, MENU_ITEM = 380, 18
local chainMenu
-- "after" sets a chain, "needs" the quest that unlocks it; switched in the menu.
local menuMode = "after"
local OpenChainMenu

-- The same hand-ins, for the quest whose hand-in unlocked this one. That can
-- be long before it was taken, so the hour's limit does not apply.
local function NeedsMenuEntries(q, add, named)
    local gold, dim, white = { 1, 0.82, 0 }, { 0.6, 0.6, 0.6 }, { 0.9, 0.9, 0.9 }
    add((q.title or ("Quest " .. q.id)) .. " is unlocked by handing in:", gold)
    local skip = { [q.id] = true }
    if q.needsQuest then
        skip[q.needsQuest] = true
        add("  " .. named(q.needsQuest, (AllQuests()[q.needsQuest] or {}).title or q.needsQuestTitle) .. " (now)", dim)
    end
    if q.afterGuess and not q.after and not q.needsQuest then
        skip[q.afterGuess] = true
        local title = q.afterGuessTitle or ("quest " .. q.afterGuess)
        add(named(q.afterGuess, title) .. "  |cffff8040(offered after it)|r", white,
            function() SetNeedsQuest(q.id, q.afterGuess, title) end)
    end
    local shown = 0
    for _, turnIn in ipairs(ZoneLevelGuideDB.turnedIn or {}) do
        local later = q.taken and turnIn.at and turnIn.at > q.taken
        if not skip[turnIn.id] and not later and shown < 8 then
            shown = shown + 1
            add(named(turnIn.id, turnIn.title), white,
                function() SetNeedsQuest(q.id, turnIn.id, turnIn.title) end)
        end
    end
    if shown == 0 and not q.afterGuess then add("  No hand-ins saved from before you took it.", dim) end
    if q.needsQuest then
        add("Not unlocked by a quest", { 1, 0.5, 0.25 }, function() SetNeedsQuest(q.id, nil) end)
    end
    add("Back to the chain", { 0.6, 0.8, 1 }, "after")
    add("Cancel", dim, function() end)
end

local function ChainMenuEntries(q)
    local entries = {}
    local function add(text, color, onClick)
        table.insert(entries, { text = text, color = color, onClick = onClick })
    end
    local gold, dim, white = { 1, 0.82, 0 }, { 0.6, 0.6, 0.6 }, { 0.9, 0.9, 0.9 }
    -- Without Editor.lua the suggestion is the only choice: yes or no.
    if not IsEditor() then
        local title = q.afterGuessTitle or ("quest " .. q.afterGuess)
        add(("Is %s part of a chain?"):format(q.title or ("quest " .. q.id)), gold)
        add(("Yes, it comes after %s"):format(title), white, function() SetAfter(q.id, q.afterGuess, title) end)
        add(("No, but %s unlocked it"):format(title), white, function() SetNeedsQuest(q.id, q.afterGuess, title) end)
        add("Not a chain", { 1, 0.5, 0.25 }, function() DismissGuess(q.id) end)
        add("Cancel", dim, function() end)
        return entries
    end
    -- Chain steps often share one title, so the ID and the giver tell them apart.
    local function named(id, title)
        local giver = (AllQuests()[id] or {}).giver
        return (title or ("quest " .. id)) .. "  |cff999999#" .. id .. (giver and (" - " .. giver) or "") .. "|r"
    end

    if menuMode == "needs" then
        NeedsMenuEntries(q, add, named)
        return entries
    end

    add((q.title or ("Quest " .. q.id)) .. " comes after:", gold)
    local skip = { [q.id] = true }
    if q.after then
        skip[q.after] = true
        add("  " .. named(q.after, (AllQuests()[q.after] or {}).title or q.afterTitle) .. " (now)", dim)
    end
    if q.afterGuess and not q.after then
        skip[q.afterGuess] = true
        local title = q.afterGuessTitle or ("quest " .. q.afterGuess)
        add(named(q.afterGuess, title) .. "  |cffff8040(offered after it)|r", white, function() SetAfter(q.id, q.afterGuess, title) end)
    end
    local shown = 0
    local reference = q.taken or Stamp()
    for _, turnIn in ipairs(ZoneLevelGuideDB.turnedIn or {}) do
        -- One handed in after the quest was taken cannot come before it, and
        -- one handed in long before is some other errand.
        local later = q.taken and turnIn.at and turnIn.at > q.taken
        local old = reference and turnIn.at and reference - turnIn.at > CHAIN_MENU_AGE
        if not skip[turnIn.id] and not later and not old and shown < 6 then
            shown = shown + 1
            add(named(turnIn.id, turnIn.title), white,
                function() SetAfter(q.id, turnIn.id, turnIn.title) end)
        end
    end
    if shown == 0 and not q.afterGuess then add("  No hand-ins saved from the hour before you took it.", dim) end
    if q.after then
        add("Not a chain", { 1, 0.5, 0.25 }, function() SetAfter(q.id, nil) end)
    elseif q.afterGuess then
        add("Not a chain", { 1, 0.5, 0.25 }, function() DismissGuess(q.id) end)
    end
    add("Needs: unlocked by a hand-in, not a chain ...", { 0.6, 0.8, 1 }, "needs")
    add("Cancel", dim, function() end)
    return entries
end

function OpenChainMenu(row, q)
    if not chainMenu then
        chainMenu = CreateFrame("Frame", nil, UIParent)
        chainMenu:SetFrameStrata("FULLSCREEN_DIALOG")
        chainMenu:EnableMouse(true)
        chainMenu:SetWidth(MENU_WIDTH)
        local fill = chainMenu:CreateTexture(nil, "BACKGROUND")
        fill:SetAllPoints()
        fill:SetColorTexture(0.06, 0.06, 0.06, 0.96)
        for _, edge in ipairs(MakeEdges(chainMenu, 0)) do edge:SetColorTexture(1, 1, 1, 0.25) end
        chainMenu.items = {}
        frame:HookScript("OnHide", function() chainMenu:Hide() end)
    end
    local entries = ChainMenuEntries(q)
    for i, entry in ipairs(entries) do
        local item = chainMenu.items[i]
        if not item then
            item = CreateFrame("Button", nil, chainMenu)
            item:SetSize(MENU_WIDTH - 8, MENU_ITEM)
            item:SetPoint("TOPLEFT", 4, -4 - (i - 1) * MENU_ITEM)
            item.glow = item:CreateTexture(nil, "HIGHLIGHT")
            item.glow:SetAllPoints()
            item.glow:SetColorTexture(1, 1, 1, 0.12)
            item.text = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            item.text:SetPoint("LEFT", 6, 0)
            item.text:SetPoint("RIGHT", -6, 0)
            item.text:SetJustifyH("LEFT")
            chainMenu.items[i] = item
        end
        item.text:SetText(entry.text)
        item.text:SetTextColor(entry.color[1], entry.color[2], entry.color[3])
        item:EnableMouse(entry.onClick ~= nil)
        ShowIf(item.glow, entry.onClick ~= nil)
        item:SetScript("OnClick", function()
            chainMenu:Hide()
            if type(entry.onClick) == "string" then
                menuMode = entry.onClick
                OpenChainMenu(row, q)
            elseif entry.onClick then
                entry.onClick()
                RefreshList()
            end
        end)
        item:Show()
    end
    for i = #entries + 1, #chainMenu.items do chainMenu.items[i]:Hide() end
    chainMenu:SetHeight(#entries * MENU_ITEM + 8)
    chainMenu:ClearAllPoints()
    chainMenu:SetPoint("TOPLEFT", row, "BOTTOMLEFT", 20, 0)
    chainMenu:Show()
end

local function GetOrCreateRow(index)
    local row = rowPool[index]
    if row then return row end

    row = CreateFrame("Button", nil, content)
    row:SetHeight(RowHeight())

    row.hl = row:CreateTexture(nil, "HIGHLIGHT")
    row.hl:SetAllPoints()
    row.fill = row:CreateTexture(nil, "BACKGROUND")
    row.fill:SetAllPoints()
    row.fill:Hide()

    row.text = TrackFont(row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    ApplyFontSize(row.text)
    row.text:SetJustifyH("LEFT")

    row.meta = TrackFont(row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    ApplyFontSize(row.meta)
    row.meta:SetPoint("RIGHT", -4, 0)
    row.meta:SetJustifyH("RIGHT")

    row.guide = row:CreateTexture(nil, "ARTWORK")
    row.guide:SetWidth(1)
    row.guide:Hide()

    row.toggle = CreateFrame("Button", nil, row)
    row.toggle:SetSize(14, 14)
    row.toggle:SetPoint("LEFT", 2, 0)
    row.toggle.text = TrackFont(row.toggle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
    ApplyFontSize(row.toggle.text)
    row.toggle.text:SetPoint("CENTER")
    row.toggle:SetScript("OnClick", function(self)
        local zone = self:GetParent().zone
        if not zone then return end
        ZoneLevelGuideDB.expanded[zone.name] = (not ZoneLevelGuideDB.expanded[zone.name]) or nil
        RefreshList()
    end)

    if row.RegisterForClicks then row:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
    row:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            if self.quest and (IsEditor() or HasGuess(self.quest)) then
                GameTooltip:Hide()
                menuMode = "after"
                OpenChainMenu(self, self.quest)
            end
        elseif self.quest then
            OnQuestClicked(self.quest, IsControlKeyDown and IsControlKeyDown())
        elseif self.zone then
            OnZoneClicked(self.zone)
        end
    end)
    row:SetScript("OnEnter", function(self)
        if self.quest then
            ShowQuestTooltip(self, self.quest)
        elseif self.zone then
            ShowZoneTooltip(self, self.zone)
        end
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

    rowPool[index] = row
    return row
end

local function DrawZoneRow(row, zone, level)
    row.zone, row.quest = zone, nil
    local style = Style()
    local styled = Styled()
    local expanded = ZoneLevelGuideDB.expanded[zone.name]
    local quests = QuestsIn(zone.name, zone.window, level)
    row.guide:Hide()

    local indent = 4
    if #quests > 0 then
        if styled then
            row.toggle.text:SetText(expanded and "\226\136\146" or "+")
            row.toggle.text:SetTextColor(RGB(expanded and style.titleColor or style.faint))
        else
            row.toggle.text:SetText(expanded and "-" or "+")
            row.toggle.text:SetTextColor(1, 0.82, 0)
        end
        row.toggle:Show()
        indent = 18
    else
        row.toggle:Hide()
    end

    local count = #quests > 0 and tostring(#quests) or ""
    if styled then
        local span = ("%d\226\128\147%d"):format(zone.minLevel, zone.maxLevel)
        row.meta:SetText(#quests > 0
            and ("|cff%s%s|r  |cff%s%s|r"):format(style.faint, count, style.span, span)
            or ("|cff%s%s|r"):format(style.span, span))
        ShowIf(row.fill, expanded)
        if expanded then row.fill:SetColorTexture(RGB(style.selected)) end
        row.hl:SetColorTexture(1, 1, 1, 0.06)
    else
        row.meta:SetText(#quests > 0 and ("|cff999999%s|r"):format(count) or "")
        row.fill:Hide()
        row.hl:SetColorTexture(1, 1, 1, 0.12)
    end
    row.meta:Show()

    local metaWidth = math.ceil((row.meta.GetStringWidth and row.meta:GetStringWidth()) or 0) + 6
    row.text:ClearAllPoints()
    row.text:SetPoint("LEFT", indent, 0)
    row.text:SetWidth(math.max(1, (row:GetWidth() or 220) - indent - 4 - metaWidth))
    if styled then
        row.text:SetText(zone.name)
    else
        row.text:SetText(("%s (%d-%d)"):format(zone.name, zone.minLevel, zone.maxLevel))
    end
    row.text:SetTextColor(BucketColor(ZoneBucket(zone, level)))
    row:SetAlpha(1)
end

local function DrawQuestRow(row, q, level)
    row.quest, row.zone = q, nil
    row.toggle:Hide()
    row.fill:Hide()
    row.meta:Hide()
    local styled = Styled()

    local left = 26
    if styled then
        row.guide:ClearAllPoints()
        row.guide:SetPoint("TOPLEFT", 15, 0)
        row.guide:SetPoint("BOTTOMLEFT", 15, 0)
        row.guide:SetColorTexture(RGB(Style().divider or Style().edge or Style().faint))
        row.guide:Show()
        left = 27
        row.hl:SetColorTexture(1, 1, 1, 0.06)
    else
        row.guide:Hide()
        row.hl:SetColorTexture(1, 1, 1, 0.12)
    end

    local status = QuestStatus(q.id)
    local closed = (q.instead and status ~= "done" and QuestStatus(q.instead) == "done")
        or (q.during and QuestStatus(q.during) ~= "active")
        or BreadcrumbSpent(q, q.id)
    -- A quest without a level (a book hand-in, whose danger depends on where
    -- the book is found) shows no bracket rather than a question mark.
    local levelText = (q.level and tostring(q.level) or "") .. (q.group and "+" or "")
    if levelText ~= "" then levelText = "[" .. levelText .. "] " end
    local mark = status == "active" and "\194\187 " or ""
    row.text:ClearAllPoints()
    row.text:SetPoint("LEFT", left, 0)
    row.text:SetWidth(math.max(1, (row:GetWidth() or 220) - left - 4))
    local tags = ""
    if q.after then
        tags = tags .. " |cff999999(chain)|r"
    elseif HasGuess(q) then
        tags = tags .. " |cffff8040(chain?)|r"
    end
    if q.needs or q.needsQuest then tags = tags .. " |cff999999(needs)|r" end
    if q.instead then tags = tags .. " |cff999999(either)|r" end
    if q.repeatable then tags = tags .. " |cff999999(repeatable)|r" end
    if q.class then tags = tags .. (" |cff999999(%s)|r"):format(CLASS_NAME[q.class] or q.class) end
    if q.profession then tags = tags .. (" |cff999999(%s)|r"):format(q.profession) end
    if q.classic then tags = tags .. " |cff999999(preliminary)|r" end
    row.text:SetText(("%s%s%s%s%s"):format(mark, q.dungeon and DungeonMark() or "",
        levelText, q.title or ("Quest " .. q.id), tags))
    if q.level and not IsBook(q) then
        row.text:SetTextColor(BucketColor(QuestBucket(q.level, level)))
    else
        row.text:SetTextColor(1, 1, 1)
    end
    row:SetAlpha((status == "done" or closed or LacksProfession(q)) and DONE_ALPHA or 1)
end

-- The zones the panel shows: in range (with the margin), and not the other
-- faction's own unless that filter is off. Nil while the finder is silent.
local function ShownZones(level)
    EnsureZoneScan()
    if not finderZones then return nil end
    local range = ZoneLevelGuideDB.range or DEFAULT_RANGE
    local mine = PlayerSide()
    local shown = {}
    for _, zone in ipairs(finderZones) do
        local info = ZoneInfo(zone.name)
        local side = info and info.side
        local otherSide = side and mine and side ~= mine
        local inRange = level >= zone.minLevel - range and level <= zone.maxLevel + range
        if inRange and not (otherSide and ZoneLevelGuideDB.hideOtherSide) then
            table.insert(shown, { name = zone.name, minLevel = zone.minLevel, maxLevel = zone.maxLevel,
                window = ZoneLevelGuideDB.hideHigh and { 0, level + QUEST_WINDOW + range } or nil })
        end
    end

    -- A shared starting zone the finder leaves out (Zephras Isle for a Horde
    -- character) spans the levels of the quests recorded there.
    local listed = {}
    for _, zone in ipairs(finderZones) do listed[NormalName(zone.name)] = true end
    for name, info in pairs(ZONES) do
        if info.shared and not listed[NormalName(name)] then
            local low, high
            for _, q in pairs(ZoneQuests(name)) do
                if q.level and not q.classic then
                    low = math.min(low or q.level, q.level)
                    high = math.max(high or q.level, q.level)
                end
            end
            if low and level >= low - range and level <= high + range then
                table.insert(shown, { name = name, minLevel = low, maxLevel = high,
                    window = ZoneLevelGuideDB.hideHigh and { 0, level + QUEST_WINDOW + range } or nil })
            end
        end
    end

    table.sort(shown, function(a, b)
        if a.minLevel ~= b.minLevel then return a.minLevel < b.minLevel end
        return a.name < b.name
    end)

    -- Then the cities with a quest not handed in and not too far above you,
    -- each spanning the levels of those quests. Below you there is no limit
    -- of its own: grey quests follow the minimap's "Low Level Quests", as in
    -- the zones.
    local window = { 0, level + QUEST_WINDOW + range }
    local cityNames = {}
    for name, info in pairs(ZONES) do
        if info.city and not (info.side and mine and info.side ~= mine and ZoneLevelGuideDB.hideOtherSide) then
            table.insert(cityNames, name)
        end
    end
    table.sort(cityNames)
    for _, name in ipairs(cityNames) do
        local low, high
        for _, q in ipairs((QuestsIn(name, window, level))) do
            -- Only a quest with a known level can say what the city spans.
            if q.level and QuestStatus(q.id) ~= "done" then
                low = math.min(low or q.level, q.level)
                high = math.max(high or q.level, q.level)
            end
        end
        if low then
            table.insert(shown, { name = name, city = true, window = window, minLevel = low, maxLevel = high })
        end
    end
    return shown
end

local emptyText = TrackFont(content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"))
emptyText:SetPoint("TOPLEFT", 4, -LIST_PAD)
emptyText:SetJustifyH("LEFT")

function RefreshList(levelOverride)
    if not ZoneLevelGuideDB then return end
    local level = levelOverride or (UnitLevel and UnitLevel("player")) or 1
    local range = ZoneLevelGuideDB.range or DEFAULT_RANGE
    rangeLabel:SetText(Styled() and ("Level %d \194\183 margin \194\177%d"):format(level, range)
        or ("Level %d, +/- %d"):format(level, range))
    LayoutPanel()

    local zones = ShownZones(level)
    local entries = {}
    for _, zone in ipairs(zones or {}) do
        table.insert(entries, { zone = zone })
        if ZoneLevelGuideDB.expanded[zone.name] then
            for _, q in ipairs((QuestsIn(zone.name, zone.window, level))) do
                table.insert(entries, { quest = q })
            end
        end
    end

    if zones == nil then
        emptyText:SetText("The Group Finder has not answered yet.")
        emptyText:Show()
    elseif #zones == 0 then
        emptyText:SetText("No zone fits your level.")
        emptyText:Show()
    else
        emptyText:Hide()
    end

    for pass = 1, 2 do
        local width = ListWidth()
        local y = LIST_PAD
        for i, entry in ipairs(entries) do
            local row = GetOrCreateRow(i)
            row:SetWidth(width)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
            if entry.zone then DrawZoneRow(row, entry.zone, level) else DrawQuestRow(row, entry.quest, level) end
            local height = RowHeight(row.text)
            row:SetHeight(height)
            row:Show()
            y = y + height
        end
        for i = #entries + 1, #rowPool do rowPool[i]:Hide() end
        content:SetSize(width, math.max(1, y))
        local visible = scrollFrame:GetHeight() or 0
        if not ShowScrollBar(visible > 0 and y > visible) or pass == 2 then break end
    end
end

ns.RefreshList = RefreshList

local function ApplyLook()
    ApplyStyle()
    ApplyFont()
    RefreshList()
end

local function SetRange(n)
    ZoneLevelGuideDB.range = math.max(0, math.min(15, math.floor(n)))
    RefreshList()
    return ZoneLevelGuideDB.range
end

local function SetStyle(name)
    if not STYLES[name] then return nil end
    ZoneLevelGuideDB.style = name
    ApplyLook()
    return name
end

local function SetFontSize(size)
    ZoneLevelGuideDB.fontSize = math.max(MIN_FONT_SIZE, math.min(MAX_FONT_SIZE, math.floor(size)))
    ApplyLook()
    return ZoneLevelGuideDB.fontSize
end

local function SetBackgroundAlpha(percent)
    percent = math.max(0, math.min(100, math.floor(percent)))
    ZoneLevelGuideDB.bgAlpha = percent / 100
    ApplyLook()
    return percent
end

local function Close()
    frame:Hide()
    ZoneLevelGuideDB.shown = false
end

closeBtn:SetScript("OnClick", Close)
plainClose:SetScript("OnClick", Close)
plusBtn:SetScript("OnClick", function() SetRange((ZoneLevelGuideDB.range or DEFAULT_RANGE) + 1) end)
minusBtn:SetScript("OnClick", function() SetRange((ZoneLevelGuideDB.range or DEFAULT_RANGE) - 1) end)
plainPlus:SetScript("OnClick", function() SetRange((ZoneLevelGuideDB.range or DEFAULT_RANGE) + 1) end)
plainMinus:SetScript("OnClick", function() SetRange((ZoneLevelGuideDB.range or DEFAULT_RANGE) - 1) end)

-- ------------------------------------------------------------
-- Docking
--
-- The panels of DungeonLevelGuide, PendingQuestXP and ZoneLevelGuide snap
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
    FRAMES = { "DungeonLevelGuideFrame", "PendingQuestXPFrame", "ZoneLevelGuideFrame" },
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
    if frame.SetUserPlaced then frame:SetUserPlaced(true) end
    SavePosition()
end)
resizeGrip:SetScript("OnMouseDown", function() Dock.BeginSize(frame, resizeGrip) end)
resizeGrip:SetScript("OnMouseUp", function()
    Dock.EndSize(resizeGrip)
    if frame.SetUserPlaced then frame:SetUserPlaced(true) end
    SaveSize()
    RefreshList()
end)
frame:SetScript("OnSizeChanged", function() RefreshList() end)

-- ------------------------------------------------------------
-- Options > AddOns
-- ------------------------------------------------------------

local settingsCategory

local function BuildSettingsPage(page)
    local heading = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 16, -16)
    heading:SetText("Zone Level Guide")

    local boxes = {}
    local function Checkbox(key, label, y)
        local box = CreateFrame("CheckButton", "ZoneLevelGuideSettings" .. key .. "Check", page,
            "UICheckButtonTemplate")
        box:SetPoint("TOPLEFT", 10, y)
        box:SetSize(24, 24)
        local text = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("LEFT", box, "RIGHT", 2, 0)
        text:SetText(label)
        box:SetScript("OnClick", function(self)
            ZoneLevelGuideDB[key] = self:GetChecked() and true or false
            if key == "shown" then ShowIf(frame, ZoneLevelGuideDB.shown) end
            RefreshList()
        end)
        boxes[key] = box
        page[key] = box
    end

    Checkbox("shown", "Show the zone list", -48)
    Checkbox("hideOtherSide", "Hide the other faction's own zones and quests", -74)
    Checkbox("hideDone", "Hide recorded quests you have handed in", -100)
    Checkbox("hideHigh", "Hide quests more than 5 levels above you", -126)
    Checkbox("hideProfession", "Hide quests for professions you don't have", -152)
    Checkbox("hideChainSteps", "Hide chain steps and unlocked quests until the quest before is done", -178)
    Checkbox("chainHelp", "Help find quest chains: mark quests that may follow one you handed in", -204)

    local styleLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    styleLabel:SetPoint("TOPLEFT", 14, -242)
    styleLabel:SetText("Style")
    page.styleDropdown = StyleDropdown(page, 58, -237, function(name)
        SetStyle(name)
        page.refresh()
    end)

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

    Stepper("rangeLabel", -272, 1, function() return ZoneLevelGuideDB.range or DEFAULT_RANGE end, SetRange)
    Stepper("fontLabel", -296, 1, FontSize, SetFontSize)
    Stepper("alphaLabel", -320, 5, function() return (ZoneLevelGuideDB.bgAlpha or 0.75) * 100 end,
        SetBackgroundAlpha)

    local hint = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 14, -352)
    hint:SetText("Settings are saved per character.")

    function page.refresh()
        for key, box in pairs(boxes) do box:SetChecked(ZoneLevelGuideDB[key] and true or false) end
        page.styleDropdown.Refresh(ZoneLevelGuideDB.style)
        page.rangeLabel:SetText(("Levels beyond a zone's range: %d"):format(
            ZoneLevelGuideDB.range or DEFAULT_RANGE))
        page.fontLabel:SetText(("Text size: %d"):format(FontSize()))
        page.alphaLabel:SetText(("Background: %d%% opaque"):format(
            math.floor((ZoneLevelGuideDB.bgAlpha or 0.75) * 100 + 0.5)))
    end
end

local function RegisterSettingsPage()
    if settingsCategory then return end
    local page = CreateFrame("Frame")
    page.name = "Zone Level Guide"
    page:SetScript("OnShow", function(self)
        if not self.built then
            self.built = true
            BuildSettingsPage(self)
        end
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

-- ------------------------------------------------------------
-- Events
-- ------------------------------------------------------------

local eventFrame = CreateFrame("Frame")

-- One pcall each: RegisterEvent throws on a name the client does not know.
local EVENTS = {
    "ADDON_LOADED", "PLAYER_LOGOUT", "PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP",
    "QUEST_DETAIL", "QUEST_ACCEPTED", "QUEST_TURNED_IN", "QUEST_REMOVED",
    "QUEST_COMPLETE", "QUEST_GREETING", "GOSSIP_SHOW", "QUEST_ACCEPT_CONFIRM",
    "LFG_LIST_AVAILABILITY_UPDATE", "LFG_UPDATE", "LFG_LOCK_INFO_RECEIVED",
    "MINIMAP_UPDATE_TRACKING", "SKILL_LINES_CHANGED",
}
for _, event in ipairs(EVENTS) do
    pcall(eventFrame.RegisterEvent, eventFrame, event)
end

local LFG_EVENTS = { LFG_LIST_AVAILABILITY_UPDATE = true, LFG_UPDATE = true, LFG_LOCK_INFO_RECEIVED = true }

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= ADDON_NAME then return end
        EnsureDB()
        QuestsChanged()
        RestoreFrame()
        ApplyLook()
        RegisterSettingsPage()
    elseif event == "PLAYER_LOGOUT" then
        -- A panel moves when the one it hangs from is dragged or resized.
        if ZoneLevelGuideDB then SavePosition() end
    elseif event == "PLAYER_ENTERING_WORLD" or LFG_EVENTS[event] then
        ScanZones()
        RefreshList()
        if event == "PLAYER_ENTERING_WORLD" then Dock.RedockSoon(frame) end
    elseif event == "PLAYER_LEVEL_UP" then
        RefreshList(tonumber((...)))
    elseif event == "QUEST_DETAIL" then
        CatchGiver()
    elseif event == "QUEST_COMPLETE" then
        CatchHandIn()
    elseif event == "QUEST_GREETING" or event == "GOSSIP_SHOW" then
        MenuOpened()
    elseif event == "QUEST_ACCEPT_CONFIRM" then
        CatchSharedEscort()
    elseif event == "QUEST_TURNED_IN" then
        RecordHandIn((...))
        RefreshList()
    elseif event == "QUEST_ACCEPTED" then
        -- Classic passes (logIndex, questID), the modern client (questID).
        local first, second = ...
        if RecordQuest(type(second) == "number" and second or first) then RefreshList() end
    else
        RefreshList()
    end
end)

-- ------------------------------------------------------------
-- Slash commands
-- ------------------------------------------------------------

-- What a recording says that the harvested data did not: fields that differ
-- and fields it adds. A seeded record came from DungeonLevelGuide's list,
-- which is Classic's data, so this is where Forever turns out different.
local PLACE_TOLERANCE = 1.5

local function News(known, q)
    local news = {}
    if q.giver and known.giver and q.giver ~= known.giver then
        table.insert(news, ("giver was %s"):format(known.giver))
    end
    if q.level and known.level and q.level ~= known.level then
        table.insert(news, ("level was %d"):format(known.level))
    end
    if q.zone and known.zone and NormalName(q.zone) ~= NormalName(known.zone) then
        table.insert(news, ("zone was %s"):format(known.zone))
    elseif q.x and q.y and known.x and known.y
        and (math.abs(q.x - known.x) > PLACE_TOLERANCE or math.abs(q.y - known.y) > PLACE_TOLERANCE) then
        table.insert(news, ("place was %.0f, %.0f"):format(known.x, known.y))
    end
    for _, field in ipairs({ "giver", "level", "x" }) do
        if q[field] ~= nil and known[field] == nil then
            table.insert(news, ("adds %s"):format(field == "x" and "place" or field))
        end
    end
    return news
end

local function QuestReport()
    local session, harvested = 0, 0
    for _ in pairs(ZoneLevelGuideDB.quests) do session = session + 1 end
    for _ in pairs(ns.RECORDED_QUESTS or {}) do harvested = harvested + 1 end
    local classicData = ns.CLASSIC_QUESTS or {}
    print((PREFIX .. "%d quest%s recorded this session, %d harvested from earlier ones."):format(
        session, session == 1 and "" or "s", harvested))
    local ids = {}
    for id in pairs(ZoneLevelGuideDB.quests) do table.insert(ids, id) end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local q = ZoneLevelGuideDB.quests[id]
        local known = (ns.RECORDED_QUESTS and ns.RECORDED_QUESTS[id]) or classicData[id]
        if q.zone == nil then
            -- Only a note typed in this session.
            print(("  %d %s -- notes only%s%s%s"):format(id, (known and known.title) or "?",
                q.after and (", after " .. q.after) or "",
                q.needsQuest and (", unlocked by " .. q.needsQuest) or "",
                q.needs and (", needs: " .. q.needs) or ""))
        else
            local verdict = "|cff33ff33new|r"
            if known then
                local news = News(known, q)
                verdict = #news > 0 and ("|cffffd100news: %s|r"):format(table.concat(news, ", "))
                    or (known.classic and "|cff33ff33matches Classic|r" or "|cff999999known|r")
            end
            print(("  %d [%s] %s -- %s, %s%s -- %s"):format(id, tostring(q.level or "?"), q.title or "?",
                q.giver or "no giver", q.zone or "?",
                (q.x and q.y) and (" (%.1f, %.1f)"):format(q.x, q.y) or "", verdict))
        end
    end
end

SLASH_ZONELEVELGUIDE1 = "/zlg"
SlashCmdList["ZONELEVELGUIDE"] = function(input)
    local raw = (input or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local msg = raw:lower()
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    local rawArg = raw:match("^%S*%s*(.-)$") or ""

    if cmd == "" then
        ZoneLevelGuideDB.shown = not frame:IsShown()
        ShowIf(frame, ZoneLevelGuideDB.shown)
        if ZoneLevelGuideDB.shown then RefreshList() end
    elseif cmd == "range" and tonumber(arg) then
        print((PREFIX .. "zones up to %d levels beyond their range."):format(SetRange(tonumber(arg))))
    elseif cmd == "faction" then
        ZoneLevelGuideDB.hideOtherSide = not ZoneLevelGuideDB.hideOtherSide
        RefreshList()
        print(PREFIX .. (ZoneLevelGuideDB.hideOtherSide and "hiding the other faction's own zones."
            or "showing every zone, both factions'."))
    elseif cmd == "high" then
        ZoneLevelGuideDB.hideHigh = not ZoneLevelGuideDB.hideHigh
        RefreshList()
        print(PREFIX .. (ZoneLevelGuideDB.hideHigh and "hiding quests more than 5 levels above you."
            or "showing every quest in a zone, whatever its level."))
    elseif cmd == "profession" then
        ZoneLevelGuideDB.hideProfession = not ZoneLevelGuideDB.hideProfession
        RefreshList()
        print(PREFIX .. (ZoneLevelGuideDB.hideProfession and "hiding quests for professions you don't have."
            or "showing quests for professions you don't have, dimmed."))
    elseif cmd == "steps" then
        ZoneLevelGuideDB.hideChainSteps = not ZoneLevelGuideDB.hideChainSteps
        RefreshList()
        print(PREFIX .. (ZoneLevelGuideDB.hideChainSteps
            and "showing only the next step of each chain."
            or "showing every step of a chain."))
    elseif cmd == "chains" then
        ZoneLevelGuideDB.chainHelp = not ZoneLevelGuideDB.chainHelp
        RefreshList()
        print(PREFIX .. (ZoneLevelGuideDB.chainHelp
            and "marking quests that may be part of a chain -- right-click one to answer."
            or "no longer marking possible chains."))
    elseif cmd == "done" then
        ZoneLevelGuideDB.hideDone = not ZoneLevelGuideDB.hideDone
        RefreshList()
        print(PREFIX .. (ZoneLevelGuideDB.hideDone and "hiding quests you have handed in."
            or "showing quests you have handed in, dimmed."))
    elseif cmd == "style" then
        if SetStyle(arg) then
            print((PREFIX .. "style: %s."):format(STYLES[arg].label))
        else
            print((PREFIX .. "usage: /zlg style %s (now: %s)"):format(
                table.concat(STYLE_ORDER, "|"), ZoneLevelGuideDB.style or DEFAULT_STYLE))
        end
    elseif cmd == "font" and tonumber(arg) then
        print((PREFIX .. "font size %d."):format(SetFontSize(tonumber(arg))))
    elseif cmd == "alpha" and tonumber(arg) then
        print((PREFIX .. "background %d%% opaque."):format(SetBackgroundAlpha(tonumber(arg))))
    elseif cmd == "quests" then
        QuestReport()
    elseif cmd == "after" then
        -- /zlg after <previous>  or  /zlg after <quest> <previous>
        local first, second = arg:match("^(%d+)%s*(%d*)$")
        local questID, previous = nil, tonumber(first)
        if second and second ~= "" then questID, previous = tonumber(first), tonumber(second) end
        local id, q = AnnotationTarget(questID)
        if not (id and previous) then
            print(PREFIX .. "usage: /zlg after <previous questID> -- for the quest you took last,")
            print(PREFIX .. "   or: /zlg after <questID> <previous questID>")
        else
            q.after, q.afterTitle = previous, QuestTitle(previous)
            QuestsChanged()
            RefreshList()
            print((PREFIX .. "%s comes after %s."):format(QuestTitle(id), q.afterTitle))
        end
    elseif cmd == "needs" then
        -- /zlg needs <text>  or  /zlg needs <questID> <text>
        local questID, text = rawArg:match("^(%d+)%s+(.+)$")
        if not questID then text = rawArg end
        local id, q = AnnotationTarget(tonumber(questID))
        if not id or text == "" then
            print(PREFIX .. "usage: /zlg needs <text> -- for the quest you took last,")
            print(PREFIX .. "   or: /zlg needs <questID> <text>")
        else
            q.needs = text
            QuestsChanged()
            RefreshList()
            print((PREFIX .. "%s needs: %s"):format(QuestTitle(id), text))
        end
    elseif cmd == "reset" then
        ZoneLevelGuideDB.point = nil
        ZoneLevelGuideDB.size = { width = DEFAULTS.size.width, height = DEFAULTS.size.height }
        if frame.SetUserPlaced then frame:SetUserPlaced(false) end
        RestoreFrame()
        print(PREFIX .. "position and size reset.")
    else
        print("|cff00ff00ZoneLevelGuide|r commands:")
        print("  /zlg              - show or hide the panel")
        print("  /zlg range <n>    - also show zones up to n levels beyond their range")
        print("  /zlg faction      - show or hide the other faction's own zones")
        print("  /zlg done         - show or hide recorded quests you have handed in")
        print("  /zlg high         - show or hide quests more than 5 levels above you")
        print("  /zlg profession   - show or hide quests for professions you don't have")
        print("  /zlg steps        - show only the next step of each chain, or every step")
        print("  /zlg chains       - help find quest chains: mark quests that may follow another")
        print("  /zlg quests       - list the quests recorded this session")
        print("  /zlg after <id>   - the quest you took last comes after quest <id>")
        print("  /zlg needs <text> - what the quest you took last needs, e.g. an item")
        print("  /zlg style <name> - blizzard, flat, warm, elvui, details, pfui or minimal")
        print("  /zlg font <n>     - text size, 6-24")
        print("  /zlg alpha <n>    - how opaque the background is, 0-100")
        print("  /zlg reset        - reset position and size")
    end
end
