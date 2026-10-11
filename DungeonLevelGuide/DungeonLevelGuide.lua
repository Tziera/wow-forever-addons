local ADDON_NAME, ns = ...

-- ============================================================
-- Dungeon Level Guide -- a movable, resizable panel listing the dungeons
-- that suit your current level, within an adjustable +/- margin. Clicking a
-- row centres the world map on the zone and opens the Group Finder filtered
-- to the matching activity.
-- ============================================================

local PREFIX = "|cff00ff00DungeonLevelGuide|r: "

local ROW_HEIGHT = 20
local MAX_TOOLTIP_QUESTS = 10
local DEFAULT_RANGE = 5

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
    return STYLES[DungeonLevelGuideDB and DungeonLevelGuideDB.style] or STYLES[DEFAULT_STYLE]
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
-- Every FontString the panel owns is registered here, so changing the size
-- reaches all of them -- including the rows, which are built on demand long
-- after this runs. The starting size is READ off the client's own font
-- object rather than assumed, so leaving it alone follows whatever the
-- client uses.
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
    return (DungeonLevelGuideDB and DungeonLevelGuideDB.fontSize) or BaseFontSize()
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

-- Rows have to grow with the text, or a larger font just overlaps the row
-- below it. The padding above and below the text is what stays constant.
--
-- Pass the row's FontString and it grows with a WRAPPED name too. That is
-- the same bug one level down: "Ruins of Lordaeron (15)" does not fit 260
-- pixels at 18 pt, breaks into two lines, and a one-line row height then
-- draws the next dungeon straight through the second line.
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
-- Dungeons and the level each one is tuned for.
--
-- Read out of the client itself: LFGDungeons joined with ContentTuning from
-- build 1.60.1.69893. The client stores ONE level per dungeon, not a range
-- (MinLevelSquish == MaxLevelSquish everywhere), so that is the bottom of the
-- range the panel shows, and bossLevel the top. The hand-typed ranges this
-- replaced were guesses from Classic and several were wrong -- Deadmines said
-- 18, the client says 16.
--
-- bossLevel is the last boss's level in Classic, the top of the range until
-- the dungeon has been measured in game (see "Measured mob levels" below).
-- It is a guess for Forever, and the panel marks it with a "?". Ruins of
-- Lordaeron's 20 comes from WoW Forever Builds' notes; the other new
-- dungeons have none. Bosses above 60 are capped there, since nobody out-levels
-- them anyway.
--
-- unverified = true marks the dungeons the client does not list at all. They
-- are almost certainly above the beta's level cap of 30, and their numbers are
-- still the guesses from before.
--
-- quests = { { id = questID, name = "..." }, ... } -- related quests, empty
-- for now. The tooltip below renders an empty list cleanly, so the addon
-- works without it.
-- ------------------------------------------------------------
local DUNGEONS = {
    -- From the client, build 1.60.1.69893 (LFGDungeons + ContentTuning)
    { name = "Hall of Thanes",               level = 13, lfgID = 3273 },
    { name = "Ragefire Chasm",               level = 13, bossLevel = 16, lfgID = 3 },
    { name = "Ruins of Lordaeron",           level = 15, bossLevel = 20, lfgID = 3272 },
    { name = "Deadmines",                    level = 16, bossLevel = 21, lfgID = 5 },
    { name = "Wailing Caverns",              level = 17, bossLevel = 22, lfgID = 1 },
    { name = "Shadowfang Keep",              level = 18, bossLevel = 26, lfgID = 7 },
    { name = "Blackfathom Deeps",            level = 22, bossLevel = 28, lfgID = 9 },
    { name = "Stormwind Stockades",          level = 23, bossLevel = 29, lfgID = 11 },
    { name = "Razorfen Kraul",               level = 24, bossLevel = 33, lfgID = 15 },
    { name = "Gnomeregan",                   level = 25, bossLevel = 34, lfgID = 13 },
    { name = "Excavation Site: Wetlands",    level = 26, lfgID = 3274 },
    { name = "City of Dalaran",              level = 28, lfgID = 3271 },
    { name = "Scarlet Monastery",            level = 30, bossLevel = 42, lfgID = 17 },
    { name = "Razorfen Downs",               level = 34, bossLevel = 41, lfgID = 19 },
    { name = "Uldaman",                      level = 35, bossLevel = 47, lfgID = 21 },
    { name = "Maraudon",                     level = 42, bossLevel = 51, lfgID = 25 },
    { name = "Zul'Farak",                    level = 42, bossLevel = 48, lfgID = 23 },
    { name = "Sunken Temple",                level = 45, bossLevel = 55, lfgID = 27 },
    { name = "Blackrock Depths",             level = 48, bossLevel = 59, lfgID = 29 },
    { name = "Lower Blackrock Spire",        level = 53, bossLevel = 60, lfgID = 31 },
    { name = "Upper Blackrock Spire",        level = 53, bossLevel = 60, lfgID = 43 },
    { name = "Dire Maul - East",             level = 54, bossLevel = 60, lfgID = 33 },
    { name = "Dire Maul - North",            level = 54, bossLevel = 60, lfgID = 37 },
    { name = "Dire Maul - West",             level = 54, bossLevel = 60, lfgID = 35 },
    { name = "Stratholme",                   level = 55, bossLevel = 60, lfgID = 39 },
    { name = "Scholomance",                  level = 57, bossLevel = 60, lfgID = 2 },

    -- Named in the announcements but absent from the client's tables, so these
    -- levels are unconfirmed guesses.
    { name = "The Drowned City",             level = 35, unverified = true },
    { name = "Krol'dok Stronghold",          level = 40, unverified = true },
    { name = "Alcaz Prison",                 level = 48, unverified = true },
    { name = "Blackmaw Hold",                level = 55, unverified = true },
    { name = "Shaper's Terrace",             level = 58, unverified = true },
}

-- ------------------------------------------------------------
-- Which quests belong to which dungeon.
--
-- Extracted from ForeverGuide's bundled database, which in turn is generated
-- from Questie's Classic Era data (and through it from the cmangos/vmangos
-- projects). Quest id and name, plus who hands it out and where -- game facts,
-- not anyone's prose -- and nothing here is redistributed: the repo is private. Publishing the addon
-- would mean collecting this in game instead, or asking upstream first.
--
-- The mapping is what that data can answer, and it has known holes. A quest is
-- listed here when Questie sorts it under the dungeon's own areaID. Quests
-- handed out in the open world with item objectives inside the instance -- most
-- of Gnomeregan's, Uldaman's, Zul'Farak's -- are sorted under the outdoor zone
-- and cannot be told apart, because the bundle carries no spawn data at all
-- inside instances. Dire Maul's wings and both halves of Blackrock Spire share
-- one areaID, so their quests cannot be split per wing and are left out rather
-- than repeated three times. PARTIAL_QUESTS marks every dungeon whose list is
-- known to be short, so the tooltip can say so.
--
-- giver/where/x/y is the quest giver and the first of their spawn points, on
-- the zone's own map, 0-100. An NPC standing INSIDE an instance has no spawn
-- of its own in this data and inherits the surrounding zone, so a giver listed
-- as "The Barrens" may well be standing in the cave.
--
-- mapID is the uiMapID of that same spawn point, so clicking a quest can put
-- a marker on the map. It comes from Questie's areaID -> uiMapID table and is
-- picked to match the x/y already on the line, not looked up again. Every
-- line that has coordinates has one.
--
-- inside = true means the quest is picked up in the dungeon itself. That is
-- not the same as having no giver on file: a row with neither says "we do not
-- know", this one says "there is nothing out there to walk to". Only set by
-- hand, for quests someone has actually looked up.
--
-- fromObject = true means you pick it up off a thing -- a scroll, a chest, a
-- plaque -- rather than from someone. Worth its own field because it changes
-- what you are looking for in the room: no NPC will ever light up.
--
-- fromDrop = true is the third way in: no giver, no object, the quest comes
-- off the mobs as loot and starts itself the first time it drops. Then there
-- is nothing at all to look for, only things to kill.
--
-- note = "..." is one line of plain text for what the other fields cannot
-- say -- that the giver is a corpse, that the object moves between runs. It
-- is shown as it stands, in the quest's own tooltip.
--
-- chain/chainGiver/... is the FIRST quest of the chain this one belongs to,
-- which is the one you actually have to go and pick up. 62 of the 144 are part
-- of a chain.
--
-- faction = "A"/"H" is which side can take the quest; absent means both.
-- 93 of the 148 lines carry one. 92 of those come straight from the race mask
-- in the same data, which is exact. A missing mask (races == 0) means no race
-- restriction at all, and there the giver's city decides -- but only for the
-- six faction capitals and the starting zones, where nothing else is possible,
-- which settles exactly one more line. Everything left over, the Argent Dawn,
-- the Barrens goblins, the NPCs standing inside the instances, really is open
-- to both, so an untagged quest is never hidden from anyone.
-- ------------------------------------------------------------
local DUNGEON_QUESTS = {
    ["Blackfathom Deeps"] = {
        { id = 6562, name = "Trouble in the Deeps", faction = "H", giver = "Tsunaman", where = "Stonetalon Mountains", x = 47, y = 64, mapID = 1442 },
        { id = 6563, name = "The Essence of Aku'Mai", faction = "H", giver = "Je'neu Sancrea", where = "Ashenvale", x = 12, y = 34, mapID = 1440 },
        { id = 6564, name = "Allegiance to the Old Gods", faction = "H", chain = "Trouble in the Deeps", chainID = 6562, chainGiver = "Tsunaman", chainWhere = "Stonetalon Mountains", chainX = 47, chainY = 64, chainMapID = 1442 },
        { id = 971, name = "Knowledge in the Deeps", faction = "A", giver = "Gerrig Bonegrip", where = "Ironforge", x = 51, y = 6, mapID = 1455 },
        { id = 1198, name = "In Search of Thaelrid", faction = "A", giver = "Dawnwatcher Shaedlass", where = "Darnassus", x = 55, y = 25, mapID = 1457 },
        { id = 1275, name = "Researching the Corruption", faction = "A", giver = "Gershala Nightwhisper", where = "Darkshore", x = 38, y = 43, mapID = 1439 },
        { id = 1199, name = "Twilight Falls", faction = "A", giver = "Argent Guard Manados", where = "Darnassus", x = 55, y = 24, mapID = 1457 },
        { id = 6565, name = "Allegiance to the Old Gods", faction = "H", giver = "Je'neu Sancrea", where = "Ashenvale", x = 12, y = 34, mapID = 1440, chain = "Trouble in the Deeps", chainID = 6562, chainGiver = "Tsunaman", chainWhere = "Stonetalon Mountains", chainX = 47, chainY = 64, chainMapID = 1442 },
        { id = 1200, name = "Blackfathom Villainy", faction = "A", giver = "Argent Guard Thaelrid" },
        { id = 6561, name = "Blackfathom Villainy", faction = "H", giver = "Argent Guard Thaelrid" },
        { id = 6921, name = "Amongst the Ruins", faction = "H", giver = "Je'neu Sancrea", where = "Ashenvale", x = 12, y = 34, mapID = 1440 },
        { id = 6922, name = "Baron Aquanis", faction = "H" },
    },
    ["Blackrock Depths"] = {
        { id = 4295, name = "Rocknot's Ale", giver = "Private Rocknot" },
        { id = 3801, name = "Dark Iron Legacy", giver = "Franclorn Forgewright", where = "Burning Steppes", x = 29, y = 29, mapID = 1428 },
        { id = 3802, name = "Dark Iron Legacy", giver = "Franclorn Forgewright", where = "Burning Steppes", x = 29, y = 29, mapID = 1428 },
        { id = 3906, name = "Disharmony of Flame", faction = "H", giver = "Thunderheart", where = "Badlands", x = 3, y = 48, mapID = 1418 },
        { id = 3981, name = "Commander Gor'shak", faction = "H", giver = "Galamav the Marksman", where = "Badlands", x = 6, y = 48, mapID = 1418, chain = "Disharmony of Flame", chainID = 3906, chainGiver = "Thunderheart", chainWhere = "Badlands", chainX = 3, chainY = 48, chainMapID = 1418 },
        { id = 4081, name = "KILL ON SIGHT: Dark Iron Dwarves", faction = "H" },
        { id = 4262, name = "Overmaster Pyron", faction = "A", giver = "Jalinda Sprig", where = "Burning Steppes", x = 85, y = 70, mapID = 1428 },
        { id = 4136, name = "Ribbly Screwspigot", giver = "Yuka Screwspigot", where = "Burning Steppes", x = 66, y = 22, mapID = 1428 },
        { id = 4324, name = "Yuka Screwspigot", giver = "Yorba Screwspigot", where = "Tanaris", x = 67, y = 24, mapID = 1446 },
        { id = 3982, name = "What Is Going On?", faction = "H", giver = "Commander Gor'shak", chain = "Disharmony of Flame", chainID = 3906, chainGiver = "Thunderheart", chainWhere = "Badlands", chainX = 3, chainY = 48, chainMapID = 1418 },
        { id = 4001, name = "What Is Going On?", faction = "H", giver = "Commander Gor'shak", chain = "Disharmony of Flame", chainID = 3906, chainGiver = "Thunderheart", chainWhere = "Badlands", chainX = 3, chainY = 48, chainMapID = 1418 },
        { id = 4002, name = "The Eastern Kingdom", faction = "H", giver = "Thrall", where = "Orgrimmar", x = 32, y = 38, mapID = 1454, chain = "Disharmony of Flame", chainID = 3906, chainGiver = "Thunderheart", chainWhere = "Badlands", chainX = 3, chainY = 48, chainMapID = 1418 },
        { id = 4082, name = "KILL ON SIGHT: High Ranking Dark Iron Officials", faction = "H", chain = "KILL ON SIGHT: Dark Iron Dwarves", chainID = 4081 },
        { id = 4201, name = "The Love Potion", giver = "Mistress Nagmara" },
        { id = 4241, name = "Marshal Windsor", faction = "A", giver = "Marshal Maxwell", where = "Burning Steppes", x = 85, y = 69, mapID = 1428, chain = "Dragonkin Menace", chainID = 4182, chainGiver = "Helendis Riverhorn", chainWhere = "Burning Steppes", chainX = 86, chainY = 69, chainMapID = 1428 },
        { id = 4242, name = "Abandoned Hope", faction = "A", giver = "Marshal Windsor", chain = "Dragonkin Menace", chainID = 4182, chainGiver = "Helendis Riverhorn", chainWhere = "Burning Steppes", chainX = 86, chainY = 69, chainMapID = 1428 },
        { id = 7201, name = "The Last Element", faction = "H", giver = "Shadowmage Vivian Lagrave", where = "Badlands", x = 3, y = 48, mapID = 1418, chain = "Disharmony of Flame", chainID = 3906, chainGiver = "Thunderheart", chainWhere = "Badlands", chainX = 3, chainY = 48, chainMapID = 1418 },
        { id = 4083, name = "The Spectral Chalice" },
        { id = 4123, name = "The Heart of the Mountain", giver = "Maxwort Uberglint", where = "Burning Steppes", x = 65, y = 24, mapID = 1428 },
        { id = 4126, name = "Hurley Blackbreath", faction = "A", giver = "Ragnar Thunderbrew", where = "Dun Morogh", x = 47, y = 52, mapID = 1426 },
        { id = 4128, name = "Ragnar Thunderbrew", faction = "A", giver = "Enohar Thunderbrew", where = "Blasted Lands", x = 64, y = 21, mapID = 1419 },
        { id = 4133, name = "Vivian Lagrave", faction = "H", giver = "Apothecary Zinge", where = "Undercity", x = 50, y = 68, mapID = 1458 },
        { id = 4134, name = "Lost Thunderbrew Recipe", faction = "H", giver = "Shadowmage Vivian Lagrave", where = "Badlands", x = 3, y = 48, mapID = 1418 },
        { id = 3907, name = "Disharmony of Fire", faction = "H", giver = "Thunderheart", where = "Badlands", x = 3, y = 48, mapID = 1418, chain = "Disharmony of Flame", chainID = 3906, chainGiver = "Thunderheart", chainWhere = "Badlands", chainX = 3, chainY = 48, chainMapID = 1418 },
        { id = 4263, name = "Incendius!", faction = "A", giver = "Jalinda Sprig", where = "Burning Steppes", x = 85, y = 70, mapID = 1428, chain = "Overmaster Pyron", chainID = 4262, chainGiver = "Jalinda Sprig", chainWhere = "Burning Steppes", chainX = 85, chainY = 70, chainMapID = 1428 },
        { id = 4286, name = "The Good Stuff", faction = "A", giver = "Oralius", where = "Burning Steppes", x = 85, y = 69, mapID = 1428 },
        { id = 4024, name = "A Taste of Flame", giver = "Cyrus Therepentous", where = "Burning Steppes", x = 95, y = 32, mapID = 1428, chain = "Divine Retribution", chainID = 3441, chainGiver = "Kalaran Windblade", chainWhere = "Searing Gorge", chainX = 39, chainY = 39, chainMapID = 1427 },
        { id = 4063, name = "The Rise of the Machines", faction = "H", giver = "Lotwil Veriatus", where = "Badlands", x = 26, y = 45, mapID = 1418 },
        { id = 4121, name = "Precarious Predicament", faction = "H", giver = "Grark Lorkrub", where = "Burning Steppes", x = 40, y = 34, mapID = 1428, chain = "KILL ON SIGHT: Dark Iron Dwarves", chainID = 4081 },
        { id = 4122, name = "Grark Lorkrub", faction = "H", giver = "Lexlort", where = "Badlands", x = 6, y = 48, mapID = 1418, chain = "KILL ON SIGHT: Dark Iron Dwarves", chainID = 4081 },
        { id = 4132, name = "Operation: Death to Angerforge", faction = "H", giver = "Warlord Goretooth", where = "Badlands", x = 6, y = 48, mapID = 1418, chain = "KILL ON SIGHT: Dark Iron Dwarves", chainID = 4081 },
        { id = 4264, name = "A Crumpled Up Note", faction = "A", chain = "Dragonkin Menace", chainID = 4182, chainGiver = "Helendis Riverhorn", chainWhere = "Burning Steppes", chainX = 86, chainY = 69, chainMapID = 1428 },
        { id = 4282, name = "A Shred of Hope", faction = "A", giver = "Marshal Windsor", chain = "Dragonkin Menace", chainID = 4182, chainGiver = "Helendis Riverhorn", chainWhere = "Burning Steppes", chainX = 86, chainY = 69, chainMapID = 1428 },
        { id = 4322, name = "Jail Break!", faction = "A", giver = "Marshal Windsor", chain = "Dragonkin Menace", chainID = 4182, chainGiver = "Helendis Riverhorn", chainWhere = "Burning Steppes", chainX = 86, chainY = 69, chainMapID = 1428 },
        { id = 4003, name = "The Royal Rescue", faction = "H", giver = "Thrall", where = "Orgrimmar", x = 32, y = 38, mapID = 1454, chain = "Disharmony of Flame", chainID = 3906, chainGiver = "Thunderheart", chainWhere = "Badlands", chainX = 3, chainY = 48, chainMapID = 1418 },
        { id = 4341, name = "Kharan Mighthammer", faction = "A", giver = "King Magni Bronzebeard", where = "Ironforge", x = 39, y = 56, mapID = 1455, chain = "The Smoldering Ruins of Thaurissan", chainID = 3702, chainGiver = "Royal Historian Archesonus", chainWhere = "Ironforge", chainX = 38, chainY = 55, chainMapID = 1455 },
        { id = 4342, name = "Kharan's Tale", faction = "A", giver = "Kharan Mighthammer", chain = "The Smoldering Ruins of Thaurissan", chainID = 3702, chainGiver = "Royal Historian Archesonus", chainWhere = "Ironforge", chainX = 38, chainY = 55, chainMapID = 1455 },
        { id = 4361, name = "The Bearer of Bad News", faction = "A", giver = "Kharan Mighthammer", chain = "The Smoldering Ruins of Thaurissan", chainID = 3702, chainGiver = "Royal Historian Archesonus", chainWhere = "Ironforge", chainX = 38, chainY = 55, chainMapID = 1455 },
        { id = 4362, name = "The Fate of the Kingdom", faction = "A", giver = "King Magni Bronzebeard", where = "Ironforge", x = 39, y = 56, mapID = 1455, chain = "The Smoldering Ruins of Thaurissan", chainID = 3702, chainGiver = "Royal Historian Archesonus", chainWhere = "Ironforge", chainX = 38, chainY = 55, chainMapID = 1455 },
        { id = 4363, name = "The Princess's Surprise", faction = "A", giver = "Princess Moira Bronzebeard", chain = "The Smoldering Ruins of Thaurissan", chainID = 3702, chainGiver = "Royal Historian Archesonus", chainWhere = "Ironforge", chainX = 38, chainY = 55, chainMapID = 1455 },
        { id = 4004, name = "The Princess Saved?", faction = "H", giver = "Princess Moira Bronzebeard", chain = "Disharmony of Flame", chainID = 3906, chainGiver = "Thunderheart", chainWhere = "Badlands", chainX = 3, chainY = 48, chainMapID = 1418 },
        { id = 7604, name = "A Binding Contract" },
        { id = 9015, name = "The Challenge", giver = "Falrin Treeshaper", chain = "An Earnest Proposition", chainID = 8905, chainGiver = "Deliana", chainWhere = "Ironforge", chainX = 44, chainY = 53, chainMapID = 1455 },
    },
    ["Deadmines"] = {
        { id = 214, name = "Red Silk Bandanas", faction = "A", giver = "Scout Riell", where = "Westfall", x = 57, y = 47, mapID = 1436, chain = "The Defias Brotherhood", chainID = 65, chainGiver = "Gryan Stoutmantle", chainWhere = "Westfall", chainX = 56, chainY = 48, chainMapID = 1436 },
        { id = 168, name = "Collecting Memories", faction = "A", giver = "Wilder Thistlenettle", where = "Stormwind City", x = 65, y = 21, mapID = 1453 },
        { id = 167, name = "Oh Brother. . .", faction = "A", giver = "Wilder Thistlenettle", where = "Stormwind City", x = 65, y = 21, mapID = 1453 },
        { id = 2040, name = "Underground Assault", faction = "A", giver = "Shoni the Shilent", where = "Stormwind City", x = 56, y = 12, mapID = 1453 },
        { id = 166, name = "The Defias Brotherhood", faction = "A", giver = "Gryan Stoutmantle", where = "Westfall", x = 56, y = 48, mapID = 1436 },
        { id = 92753, name = "Destruction in Deadmines", faction = "A", note = "Plant the Extra-Destructive Explosives at the forge hidden inside, then meet Alba Fairmoon at the exit." },
        { id = 373, name = "The Unsent Letter", faction = "A", inside = true, fromDrop = true, note = "Edwin VanCleef drops the letter. It opens a long Stormwind chain." },
    },
    ["Gnomeregan"] = {
        { id = 2929, name = "The Grand Betrayal", faction = "A", giver = "High Tinker Mekkatorque", where = "Ironforge", x = 69, y = 49, mapID = 1455 },
    },
    ["Hall of Thanes"] = {
        { id = 96393, name = "Old Ironforge Incursion", faction = "A", giver = "Earthseer Farsen", where = "Dun Morogh", x = 65, y = 58, mapID = 1426, note = "Needs Underground Map, from the Dark Iron Map that Dark Iron Spies drop." },
        { id = 96394, name = "The Restless Dead", faction = "A", giver = "Afadra Dunwall", where = "Ironforge", x = 36, y = 48, mapID = 1455 },
        { id = 96395, name = "An Ancient Grudge", giver = "Ghostly Attendant", inside = true },
        { id = 96403, name = "Important Heirlooms", faction = "A", giver = "Thom Filch", where = "Ironforge", x = 32, y = 44, mapID = 1455 },
        { id = 98423, name = "The Treaty of Understanding", faction = "A", inside = true, fromObject = true },
    },
    ["Maraudon"] = {
        { id = 7068, name = "Shadowshard Fragments", faction = "H", giver = "Uthel'nay", where = "Orgrimmar", x = 39, y = 86, mapID = 1454 },
        { id = 7070, name = "Shadowshard Fragments", faction = "A", giver = "Archmage Tervosh", where = "Dustwallow Marsh", x = 66, y = 49, mapID = 1445 },
        { id = 7028, name = "Twisted Evils", giver = "Willow", where = "Desolace", x = 62, y = 40, mapID = 1443 },
        { id = 7029, name = "Vyletongue Corruption", faction = "H", giver = "Vark Battlescar", where = "Desolace", x = 23, y = 70, mapID = 1443 },
        { id = 7041, name = "Vyletongue Corruption", faction = "A", giver = "Talendria", where = "Desolace", x = 68, y = 9, mapID = 1443 },
        { id = 7067, name = "The Pariah's Instructions", giver = "Centaur Pariah", where = "Desolace", x = 50, y = 87, mapID = 1443 },
        { id = 7044, name = "Legends of Maraudon", giver = "Cavindra", where = "Desolace", x = 32, y = 64, mapID = 1443 },
        { id = 7046, name = "The Scepter of Celebras", giver = "Celebras the Redeemed", chain = "Legends of Maraudon", chainID = 7044, chainGiver = "Cavindra", chainWhere = "Desolace", chainX = 32, chainY = 64, chainMapID = 1443 },
        { id = 7064, name = "Corruption of Earth and Seed", faction = "H", giver = "Selendra", where = "Desolace", x = 27, y = 78, mapID = 1443 },
        { id = 7065, name = "Corruption of Earth and Seed", faction = "A", giver = "Keeper Marandis", where = "Desolace", x = 64, y = 11, mapID = 1443 },
        { id = 7066, name = "Seed of Life", giver = "Zaetar's Spirit" },
    },
    ["Ragefire Chasm"] = {
        { id = 5723, name = "Testing an Enemy's Strength", faction = "H", giver = "Rahauro", where = "Thunder Bluff", x = 70, y = 30, mapID = 1456 },
        { id = 5722, name = "Searching for the Lost Satchel", faction = "H", giver = "Rahauro", where = "Thunder Bluff", x = 70, y = 30, mapID = 1456 },
        { id = 5724, name = "Returning the Lost Satchel", faction = "H", giver = "Maur Grimtotem", chain = "Searching for the Lost Satchel", chainID = 5722, chainGiver = "Rahauro", chainWhere = "Thunder Bluff", chainX = 70, chainY = 30, chainMapID = 1456 },
        { id = 5725, name = "The Power to Destroy...", faction = "H", giver = "Varimathras", where = "Undercity", x = 56, y = 92, mapID = 1458 },
        { id = 5728, name = "Hidden Enemies", faction = "H", giver = "Thrall", where = "Orgrimmar", x = 32, y = 38, mapID = 1454 },
        { id = 5761, name = "Slaying the Beast", faction = "H", giver = "Neeru Fireblade", where = "Orgrimmar", x = 50, y = 51, mapID = 1454 },
    },
    ["Razorfen Downs"] = {
        { id = 6626, name = "A Host of Evil", giver = "Myriam Moonsinger", where = "The Barrens", x = 49, y = 95, mapID = 1413 },
        { id = 6521, name = "An Unholy Alliance", faction = "H", giver = "Varimathras", where = "Undercity", x = 56, y = 92, mapID = 1458 },
        { id = 6522, name = "An Unholy Alliance", faction = "H" },
        { id = 3523, name = "Scourge of the Downs", giver = "Belnistrasz" },
        { id = 3525, name = "Extinguishing the Idol", giver = "Belnistrasz", chain = "Scourge of the Downs", chainID = 3523, chainGiver = "Belnistrasz" },
        { id = 3341, name = "Bring the End", faction = "H", giver = "Andrew Brownell", where = "Undercity", x = 74, y = 33, mapID = 1458 },
        { id = 3636, name = "Bring the Light", faction = "A", giver = "Archbishop Benedictus", where = "Stormwind City", x = 40, y = 27, mapID = 1453 },
    },
    ["Razorfen Kraul"] = {
        { id = 1144, name = "Willix the Importer", giver = "Willix the Importer" },
        { id = 1221, name = "Blueleaf Tubers", giver = "Mebok Mizzyrix", where = "The Barrens", x = 62, y = 38, mapID = 1413 },
    },
    ["Ruins of Lordaeron"] = {
        { id = 92401, name = "A Frightened Request", faction = "H", giver = "Tabitha Heartweaver", where = "Silverpine Forest", x = 45, y = 43, mapID = 1421 },
        { id = 92415, name = "Remember That I Love You", faction = "A", giver = "Edward Heartweaver", inside = true, note = "Edward Heartweaver lies dead near the end of the dungeon, and the body carries the quest marker." },
        { id = 92421, name = "Light's Justice", faction = "H", giver = "Morbin Lightbane", where = "Undercity", x = 58, y = 90, mapID = 1458 },
        { id = 92422, name = "The Wrath of Rath'mael", faction = "H", giver = "Deathguard Kristof", where = "Tirisfal Glades", x = 65, y = 60, mapID = 1420 },
        { id = 95189, name = "Crest of Lordaeron", faction = "A", inside = true, fromObject = true, note = "The crest spawns in one of several places, so where it lay last run says nothing about this one -- in and around the towers is where to start looking." },
        { id = 95195, name = "Bloodied Insignia", faction = "A", inside = true, fromDrop = true },
        { id = 95204, name = "Crest of Lordaeron", faction = "H", inside = true, fromObject = true, note = "The crest spawns in one of several places, so where it lay last run says nothing about this one -- in and around the towers is where to start looking." },
        { id = 95216, name = "The New Plague", faction = "H", giver = "Theodore Griffs", where = "Undercity", x = 47, y = 71, mapID = 1458 },
        { id = 95250, name = "Abominable Creatures", faction = "A", giver = "Captain Truman", inside = true, note = "Captain Truman stands right inside the entrance and carries a quest marker, so the minimap finds him." },
        { id = 97288, name = "Unending Torment", faction = "H", inside = true, fromDrop = true, note = "The Abominable Head drops off The Baron -- one named kill, not something the trash hands you." },
    },
    ["Scarlet Monastery"] = {
        { id = 1051, name = "Vorrel's Revenge", faction = "H", giver = "Vorrel Sengutz" },
        { id = 1113, name = "Hearts of Zeal", faction = "H", giver = "Master Apothecary Faranell", where = "Undercity", x = 49, y = 69, mapID = 1458, chain = "Going, Going, Guano!", chainID = 1109, chainGiver = "Master Apothecary Faranell", chainWhere = "Undercity", chainX = 49, chainY = 69, chainMapID = 1458 },
        { id = 1160, name = "Test of Lore", faction = "H", giver = "Parqual Fintallas", where = "Undercity", x = 58, y = 65, mapID = 1458, chain = "Test of Faith", chainID = 1149, chainGiver = "Dorn Plainstalker", chainWhere = "Thousand Needles", chainX = 54, chainY = 42, chainMapID = 1441 },
        { id = 1049, name = "Compendium of the Fallen", faction = "H", giver = "Sage Truthseeker", where = "Thunder Bluff", x = 34, y = 47, mapID = 1456 },
        { id = 1050, name = "Mythology of the Titans", faction = "A", giver = "Librarian Mae Paledust", where = "Ironforge", x = 75, y = 12, mapID = 1455 },
        { id = 1053, name = "In the Name of the Light", faction = "A", giver = "Raleigh the Devout", where = "Hillsbrad Foothills", x = 52, y = 58, mapID = 1424, chain = "Down the Scarlet Path", chainID = 261, chainGiver = "Brother Anton", chainWhere = "Desolace", chainX = 66, chainY = 8, chainMapID = 1443 },
        { id = 1048, name = "Into The Scarlet Monastery", faction = "H", giver = "Varimathras", where = "Undercity", x = 56, y = 92, mapID = 1458 },
    },
    ["Scholomance"] = {
        { id = 5529, name = "Plagued Hatchlings", giver = "Betina Bigglezink", where = "Eastern Plaguelands", x = 82, y = 60, mapID = 1423 },
        { id = 5582, name = "Healthy Dragon Scale", chain = "Plagued Hatchlings", chainID = 5529, chainGiver = "Betina Bigglezink", chainWhere = "Eastern Plaguelands", chainX = 82, chainY = 60, chainMapID = 1423 },
        { id = 4771, name = "Dawn's Gambit", giver = "Betina Bigglezink", where = "Eastern Plaguelands", x = 82, y = 60, mapID = 1423, chain = "Broodling Essence", chainID = 4726, chainGiver = "Tinkee Steamboil", chainWhere = "Burning Steppes", chainX = 65, chainY = 24, chainMapID = 1428 },
        { id = 5341, name = "Barov Family Fortune", faction = "H", giver = "Alexi Barov", where = "Tirisfal Glades", x = 83, y = 72, mapID = 1420 },
        { id = 5343, name = "Barov Family Fortune", faction = "A", giver = "Weldon Barov", where = "Western Plaguelands", x = 44, y = 84, mapID = 1422 },
        { id = 5382, name = "Doctor Theolen Krastinov, the Butcher", giver = "Eva Sarkhoff", where = "Western Plaguelands", x = 70, y = 74, mapID = 1422 },
        { id = 5384, name = "Kirtonos the Herald", giver = "Eva Sarkhoff", where = "Western Plaguelands", x = 70, y = 74, mapID = 1422, chain = "Doctor Theolen Krastinov, the Butcher", chainID = 5382, chainGiver = "Eva Sarkhoff", chainWhere = "Western Plaguelands", chainX = 70, chainY = 74, chainMapID = 1422 },
        { id = 5466, name = "The Lich, Ras Frostwhisper", giver = "Magistrate Marduke", where = "Western Plaguelands", x = 71, y = 74, mapID = 1422, chain = "Doctor Theolen Krastinov, the Butcher", chainID = 5382, chainGiver = "Eva Sarkhoff", chainWhere = "Western Plaguelands", chainX = 70, chainY = 74, chainMapID = 1422 },
        { id = 5515, name = "Krastinov's Bag of Horrors", giver = "Eva Sarkhoff", where = "Western Plaguelands", x = 70, y = 74, mapID = 1422, chain = "Doctor Theolen Krastinov, the Butcher", chainID = 5382, chainGiver = "Eva Sarkhoff", chainWhere = "Western Plaguelands", chainX = 70, chainY = 74, chainMapID = 1422 },
        { id = 5531, name = "Betina Bigglezink", giver = "Leonid Barthalomew the Revered", where = "Eastern Plaguelands", x = 82, y = 58, mapID = 1423, chain = "Broodling Essence", chainID = 4726, chainGiver = "Tinkee Steamboil", chainWhere = "Burning Steppes", chainX = 65, chainY = 24, chainMapID = 1428 },
        { id = 7629, name = "Imp Delivery", giver = "Gorzeeki Wildeyes", where = "Burning Steppes", x = 12, y = 32, mapID = 1428, chain = "Mor'zul Bloodbringer", chainID = 7562, chainGiver = "Spackle Thornberry", chainWhere = "Stormwind City", chainX = 26, chainY = 78, chainMapID = 1453 },
        { id = 7647, name = "Judgment and Redemption", faction = "A", giver = "Lord Grayson Shadowbreaker", where = "Stormwind City", x = 37, y = 33, mapID = 1453, chain = "Lord Grayson Shadowbreaker", chainID = 7638, chainGiver = "Duthorian Rall", chainWhere = "Stormwind City", chainX = 40, chainY = 30, chainMapID = 1453 },
        { id = 8969, name = "The Left Piece of Lord Valthalak's Amulet", giver = "Bodley", where = "Eastern Kingdoms - the continent map", x = 49, y = 64, mapID = 1415, chain = "An Earnest Proposition", chainID = 8905, chainGiver = "Deliana", chainWhere = "Ironforge", chainX = 44, chainY = 53, chainMapID = 1455 },
        { id = 8992, name = "The Right Piece of Lord Valthalak's Amulet", giver = "Bodley", where = "Eastern Kingdoms - the continent map", x = 49, y = 64, mapID = 1415, chain = "An Earnest Proposition", chainID = 8905, chainGiver = "Deliana", chainWhere = "Ironforge", chainX = 44, chainY = 53, chainMapID = 1455 },
    },
    ["Shadowfang Keep"] = {
        { id = 1098, name = "Deathstalkers in Shadowfang", faction = "H", giver = "High Executor Hadrec", where = "Silverpine Forest", x = 43, y = 41, mapID = 1421 },
        { id = 1013, name = "The Book of Ur", faction = "H", giver = "Keeper Bel'dugur", where = "Undercity", x = 54, y = 54, mapID = 1458 },
        { id = 1014, name = "Arugal Must Die", faction = "H", giver = "Dalar Dawnweaver", where = "Silverpine Forest", x = 44, y = 40, mapID = 1421 },
        { id = 1740, name = "The Orb of Soran'ruk", giver = "Doan Karhan", where = "The Barrens", note = "Warlocks only." },
    },
    ["Stormwind Stockades"] = {
        { id = 386, name = "What Comes Around...", faction = "A", giver = "Guard Berton", where = "Redridge Mountains", x = 26, y = 47, mapID = 1433 },
        { id = 377, name = "Crime and Punishment", faction = "A", giver = "Councilman Millstipe", where = "Duskwood", x = 72, y = 48, mapID = 1431 },
        { id = 387, name = "Quell The Uprising", faction = "A", giver = "Warden Thelwater", where = "Stormwind City", x = 41, y = 58, mapID = 1453 },
        { id = 388, name = "The Color of Blood", faction = "A", giver = "Nikova Raskol", where = "Stormwind City", x = 73, y = 51, mapID = 1453 },
        { id = 378, name = "The Fury Runs Deep", faction = "A", giver = "Motley Garmason", where = "Wetlands", x = 50, y = 18, mapID = 1437, chain = "The Dark Iron War", chainID = 303, chainGiver = "Motley Garmason", chainWhere = "Wetlands", chainX = 50, chainY = 18, chainMapID = 1437 },
        { id = 391, name = "The Stockade Riots", faction = "A", giver = "Warden Thelwater", where = "Stormwind City", x = 41, y = 58, mapID = 1453, chain = "The Unsent Letter", chainID = 373 },
    },
    ["Stratholme"] = {
        { id = 5122, name = "The Medallion of Faith", giver = "Aurius" },
        { id = 5125, name = "Aurius' Reckoning", giver = "Aurius", chain = "The Medallion of Faith", chainID = 5122, chainGiver = "Aurius" },
        { id = 5212, name = "The Flesh Does Not Lie", giver = "Betina Bigglezink", where = "Eastern Plaguelands", x = 82, y = 60, mapID = 1423 },
        { id = 5213, name = "The Active Agent", giver = "Betina Bigglezink", where = "Eastern Plaguelands", x = 82, y = 60, mapID = 1423, chain = "The Flesh Does Not Lie", chainID = 5212, chainGiver = "Betina Bigglezink", chainWhere = "Eastern Plaguelands", chainX = 82, chainY = 60, chainMapID = 1423 },
        { id = 5214, name = "The Great Ezra Grimm", giver = "Smokey LaRue", where = "Eastern Plaguelands", x = 81, y = 58, mapID = 1423 },
        { id = 5243, name = "Houses of the Holy", giver = "Leonid Barthalomew the Revered", where = "Eastern Plaguelands", x = 82, y = 58, mapID = 1423 },
        { id = 5251, name = "The Archivist", giver = "Duke Nicholas Zverenhoff", where = "Eastern Plaguelands", x = 81, y = 60, mapID = 1423 },
        { id = 5262, name = "The Truth Comes Crashing Down", chain = "The Archivist", chainID = 5251, chainGiver = "Duke Nicholas Zverenhoff", chainWhere = "Eastern Plaguelands", chainX = 81, chainY = 60, chainMapID = 1423 },
        { id = 5263, name = "Above and Beyond", giver = "Duke Nicholas Zverenhoff", where = "Eastern Plaguelands", x = 81, y = 60, mapID = 1423, chain = "The Archivist", chainID = 5251, chainGiver = "Duke Nicholas Zverenhoff", chainWhere = "Eastern Plaguelands", chainX = 81, chainY = 60, chainMapID = 1423 },
        { id = 5282, name = "The Restless Souls", giver = "Egan", where = "Eastern Plaguelands", x = 14, y = 34, mapID = 1423 },
        { id = 5463, name = "Menethil's Gift", giver = "Leonid Barthalomew the Revered", where = "Eastern Plaguelands", x = 82, y = 58, mapID = 1423, chain = "Doctor Theolen Krastinov, the Butcher", chainID = 5382, chainGiver = "Eva Sarkhoff", chainWhere = "Western Plaguelands", chainX = 70, chainY = 74, chainMapID = 1422 },
        { id = 5848, name = "Of Love and Family", giver = "Artist Renfray", where = "Western Plaguelands", x = 66, y = 75, mapID = 1422, chain = "Demon Dogs", chainID = 5542, chainGiver = "Tirion Fordring", chainWhere = "Eastern Plaguelands", chainX = 8, chainY = 44, chainMapID = 1423 },
        { id = 6163, name = "Ramstein", faction = "H", giver = "Nathanos Blightcaller", where = "Eastern Plaguelands", x = 26, y = 75, mapID = 1423, chain = "To Kill With Purpose", chainID = 6022, chainGiver = "Nathanos Blightcaller", chainWhere = "Eastern Plaguelands", chainX = 26, chainY = 75, chainMapID = 1423 },
        { id = 8945, name = "Dead Man's Plea", giver = "Anthion Harmon", where = "Eastern Plaguelands", x = 31, y = 17, mapID = 1423, chain = "An Earnest Proposition", chainID = 8905, chainGiver = "Deliana", chainWhere = "Ironforge", chainX = 44, chainY = 53, chainMapID = 1455 },
        { id = 8968, name = "The Left Piece of Lord Valthalak's Amulet", giver = "Bodley", where = "Eastern Kingdoms - the continent map", x = 49, y = 64, mapID = 1415, chain = "An Earnest Proposition", chainID = 8905, chainGiver = "Deliana", chainWhere = "Ironforge", chainX = 44, chainY = 53, chainMapID = 1455 },
        { id = 8991, name = "The Right Piece of Lord Valthalak's Amulet", giver = "Bodley", where = "Eastern Kingdoms - the continent map", x = 49, y = 64, mapID = 1415, chain = "An Earnest Proposition", chainID = 8905, chainGiver = "Deliana", chainWhere = "Ironforge", chainX = 44, chainY = 53, chainMapID = 1455 },
    },
    ["Uldaman"] = {
        { id = 2398, name = "The Lost Dwarves", faction = "A", giver = "Prospector Stormpike", where = "Ironforge", x = 75, y = 12, mapID = 1455 },
        { id = 2284, name = "Necklace Recovery, Take 2", faction = "H", giver = "Dran Droffers", where = "Orgrimmar", x = 60, y = 37, mapID = 1454, chain = "Necklace Recovery", chainID = 2283, chainGiver = "Dran Droffers", chainWhere = "Orgrimmar", chainX = 60, chainY = 37, chainMapID = 1454 },
        { id = 2200, name = "Back to Uldaman", faction = "A", giver = "Talvash del Kissel", where = "Ironforge", x = 36, y = 4, mapID = 1455, chain = "The Shattered Necklace", chainID = 2198 },
    },
    ["Wailing Caverns"] = {
        { id = 1489, name = "Hamuul Runetotem", faction = "H", giver = "Tonga Runetotem", where = "The Barrens", x = 52, y = 32, mapID = 1413, chain = "The Forgotten Pools", chainID = 870, chainGiver = "Tonga Runetotem", chainWhere = "The Barrens", chainX = 52, chainY = 32, chainMapID = 1413 },
        { id = 1490, name = "Nara Wildmane", faction = "H", giver = "Arch Druid Hamuul Runetotem", where = "Thunder Bluff", x = 79, y = 29, mapID = 1456, chain = "The Forgotten Pools", chainID = 870, chainGiver = "Tonga Runetotem", chainWhere = "The Barrens", chainX = 52, chainY = 32, chainMapID = 1413 },
        { id = 1486, name = "Deviate Hides", giver = "Nalpak", where = "The Barrens", x = 46, y = 36, mapID = 1413 },
        { id = 959, name = "Trouble at the Docks", giver = "Crane Operator Bigglefuzz", where = "The Barrens", x = 63, y = 38, mapID = 1413 },
        { id = 962, name = "Serpentbloom", faction = "H", giver = "Apothecary Zamah", where = "Thunder Bluff", x = 23, y = 21, mapID = 1456 },
        { id = 1491, name = "Smart Drinks", giver = "Mebok Mizzyrix", where = "The Barrens", x = 62, y = 38, mapID = 1413, chain = "Raptor Horns", chainID = 865, chainGiver = "Mebok Mizzyrix", chainWhere = "The Barrens", chainX = 62, chainY = 38, chainMapID = 1413 },
        { id = 1487, name = "Deviate Eradication", giver = "Ebru", where = "The Barrens", x = 46, y = 36, mapID = 1413 },
        { id = 914, name = "Leaders of the Fang", faction = "H", giver = "Nara Wildmane", where = "Thunder Bluff", x = 76, y = 32, mapID = 1456, chain = "The Forgotten Pools", chainID = 870, chainGiver = "Tonga Runetotem", chainWhere = "The Barrens", chainX = 52, chainY = 32, chainMapID = 1413 },
        { id = 6981, name = "The Glowing Shard" },
        { id = 3366, name = "The Glowing Shard", inside = true, fromDrop = true },
    },
}

local PARTIAL_QUESTS = {
    ["Gnomeregan"] = true,
    ["Razorfen Kraul"] = true,
    ["Uldaman"] = true,
    ["Zul'Farak"] = true,
    ["Sunken Temple"] = true,
    ["Dire Maul - East"] = true,
    ["Dire Maul - North"] = true,
    ["Dire Maul - West"] = true,
    ["Lower Blackrock Spire"] = true,
    ["Upper Blackrock Spire"] = true,
    ["Ruins of Lordaeron"] = true,
    ["Excavation Site: Wetlands"] = true,
    ["City of Dalaran"] = true,
    ["The Drowned City"] = true,
    ["Krol'dok Stronghold"] = true,
    ["Alcaz Prison"] = true,
    ["Blackmaw Hold"] = true,
    ["Shaper's Terrace"] = true,
}

for _, d in ipairs(DUNGEONS) do
    d.quests = DUNGEON_QUESTS[d.name]
    d.questsPartial = PARTIAL_QUESTS[d.name] or false
end

ns.DUNGEONS = DUNGEONS

-- ------------------------------------------------------------
-- SavedVariables
-- ------------------------------------------------------------

-- ------------------------------------------------------------
-- Settings
--
-- Defaults for a character with no saved settings yet. What you set with the
-- slash commands or the options panel is saved and wins over these.
--
-- Once the client starts remembering again, this goes back to being what it
-- says on the tin -- the defaults for a fresh install.
-- ------------------------------------------------------------
local DEFAULTS = {
    range = DEFAULT_RANGE,                  -- +/- level margin, 0-15
    size = { width = 260, height = 340 },
    hideOtherFaction = true,                -- hide the other side's quests
    hideCompleted = false,                  -- hide quests you have done
    lfgOnly = true,                         -- only what the Group Finder offers
    style = DEFAULT_STYLE,                  -- one of STYLE_ORDER
    bgAlpha = 0.75,                         -- 0 see-through, 1 solid
    -- fontSize is deliberately absent: nil means "whatever the client's own
    -- font object uses", which is read off it rather than assumed. Put a
    -- number here (6-24) to override it.
}

-- Field by field rather than one table literal, because a saved database from
-- an earlier version is missing whatever was added since -- the old
-- `DB = DB or { ... }` left those nil. EnsureDB is also called at load, not
-- only at ADDON_LOADED, so the table is never missing.
local MOB_LEVELS_VERSION = 2

local function EnsureDB()
    DungeonLevelGuideDB = DungeonLevelGuideDB or {}
    local db = DungeonLevelGuideDB

    for key, value in pairs(DEFAULTS) do
        if db[key] == nil then
            -- Copy tables, or dragging the panel would resize DEFAULTS.
            if type(value) == "table" then
                local copy = {}
                for k, v in pairs(value) do copy[k] = v end
                db[key] = copy
            else
                db[key] = value
            end
        end
    end

    -- db.point stays nil until the panel is dragged: { point, relativePoint, x, y }
    -- [dungeonName] = { mapID = ..., x = ..., y = ... }
    db.dungeonCoords = db.dungeonCoords or {}
    -- [dungeonName] = true for the dungeons whose quest list is unfolded
    db.expanded = db.expanded or {}
    -- [instance name as the client gives it] = { min = ..., max = ..., at = player level }
    -- Version 2 counts elites only; older measurements included the mobs'
    -- non-elite pets, so they are dropped, and harvest skips them too.
    if (db.mobLevelsVersion or 1) < MOB_LEVELS_VERSION then
        db.mobLevels, db.looseLevels, db.mobMisses = {}, {}, {}
        db.mobLevelsVersion = MOB_LEVELS_VERSION
    end
    db.mobLevels = db.mobLevels or {}
    db.mobMisses = db.mobMisses or {}
    db.looseLevels = db.looseLevels or {}
    db.normalLevels = db.normalLevels or {}
    -- [questID] = { dungeon, confirmed, title, level, giver, zone, mapID, x, y, side }
    db.learned = db.learned or {}
end

EnsureDB()

-- Forward declaration: defined down in the list section, but the quest filter
-- just below needs it to answer "is this one already done".
local GetQuestStatus

-- ------------------------------------------------------------
-- Faction
-- ------------------------------------------------------------

-- "A" or "H". Cached on the first real answer: UnitFactionGroup can still
-- return nil at ADDON_LOADED, and a nil cached as an answer would stick.
local playerFaction
local function PlayerFaction()
    if playerFaction then return playerFaction end
    local group = UnitFactionGroup and UnitFactionGroup("player")
    if group == "Alliance" then
        playerFaction = "A"
    elseif group == "Horde" then
        playerFaction = "H"
    end
    return playerFaction
end

-- A quest with no faction of its own is open to both -- see the data comment.
local function CanTakeQuest(q)
    local mine = PlayerFaction()
    return not q.faction or not mine or q.faction == mine
end

local function ShouldShowQuest(q)
    if not DungeonLevelGuideDB.hideOtherFaction then return true end
    return CanTakeQuest(q)
end

local FACTION_TAG = {
    A = "|cff6699ff[A]|r ",
    H = "|cffff5555[H]|r ",
}

local STATUS_COLOR = {
    completed    = { label = "Completed",     r = 0.5, g = 0.5, b = 0.5 },
    active       = { label = "Active",        r = 0.2, g = 1,   b = 0.2 },
    not_picked_up = { label = "Not picked up", r = 0.9, g = 0.9, b = 0.3 },
}

-- Status is carried by colour alone, with a completed quest dimmed on top of
-- it so it sinks away without disappearing. Two earlier attempts put a symbol
-- in front of the name instead: first characters (U+2605, U+2713), which the
-- game drew as the empty box a font uses for a glyph it does not have, then
-- inline textures, which drew but cluttered a 20px row. Colour was doing the
-- job all along -- what was actually broken was that nothing redrew the rows
-- when the quest log changed, so it was always showing yesterday's answer.
local COMPLETED_ALPHA = 0.45

-- ------------------------------------------------------------
-- Learned quests
--
-- Dungeon quests picked up in play and filed under their dungeon without
-- being typed into the list above. The dungeon is known one of two ways: the
-- quest's own text names it (ZoneLevelGuide keeps the text when the quest is
-- taken), or the quest makes progress, or is picked up, while you are inside
-- the dungeon. The second is certain and overrides the first. Harvested ones
-- come from LearnedQuests.lua, this session's from the database, and the
-- hand-written list always wins over both.
-- ------------------------------------------------------------

local HAND_WRITTEN = {}
for _, quests in pairs(DUNGEON_QUESTS) do
    for _, q in ipairs(quests) do HAND_WRITTEN[q.id] = true end
end

-- Names a quest text uses for a dungeon besides the panel's own.
local TEXT_ALIASES = {
    ["Stormwind Stockades"] = { "the stockade" },
    ["Zul'Farak"] = { "zul'farrak" },
    ["Sunken Temple"] = { "temple of atal'hakkar" },
}

-- The one dungeon a text names, or nil when it names none or several.
local function DungeonForText(text)
    if type(text) ~= "string" or text == "" then return nil end
    local lower = text:lower()
    local found
    for _, d in ipairs(DUNGEONS) do
        local names = { d.name:lower() }
        for _, alias in ipairs(TEXT_ALIASES[d.name] or {}) do table.insert(names, alias) end
        for _, name in ipairs(names) do
            if lower:find(name, 1, true) then
                if found and found ~= d then return nil end
                found = d
            end
        end
    end
    return found
end

local LEARNED_DETAILS = { "title", "level", "giver", "zone", "mapID", "x", "y", "side" }

-- Files a quest under a dungeon, copying what ZoneLevelGuide recorded about
-- where it is picked up. A guess never overrides a certainty.
local function LearnQuest(questID, dungeonName, confirmed)
    if HAND_WRITTEN[questID] then return false end
    local learned = DungeonLevelGuideDB.learned
    local have = learned[questID]
    if have and have.confirmed and not confirmed then return false end
    if have and have.dungeon == dungeonName and (have.confirmed or not confirmed) then return false end

    local entry = have or {}
    entry.dungeon = dungeonName
    entry.confirmed = confirmed and true or nil
    local recorded = ZoneLevelGuideDB and ZoneLevelGuideDB.quests and ZoneLevelGuideDB.quests[questID]
    for _, field in ipairs(LEARNED_DETAILS) do
        if entry[field] == nil and recorded then entry[field] = recorded[field] end
    end
    if not entry.title and C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local ok, title = pcall(C_QuestLog.GetTitleForQuestID, questID)
        if ok then entry.title = title end
    end
    learned[questID] = entry
    return true
end

-- Goes through what ZoneLevelGuide has recorded this session for dungeon
-- quests whose text names a dungeon. Nothing happens without ZoneLevelGuide.
local function LearnFromQuestTexts()
    local recorded = ZoneLevelGuideDB and ZoneLevelGuideDB.quests
    if type(recorded) ~= "table" then return end
    for questID, q in pairs(recorded) do
        if q.dungeon and q.text and not DungeonLevelGuideDB.learned[questID] then
            local d = DungeonForText(q.text)
            if d then LearnQuest(questID, d.name, false) end
        end
    end
end

local function Rounded(value)
    return value and math.floor(value + 0.5) or nil
end

-- The learned quests of one dungeon, in the same shape as the hand-written
-- ones so the rest of the panel treats them alike.
local function LearnedFor(d)
    local merged = {}
    for id, l in pairs(ns.LEARNED_QUESTS or {}) do merged[id] = l end
    for id, l in pairs(DungeonLevelGuideDB.learned or {}) do
        local harvested = merged[id]
        if not (harvested and harvested.confirmed and not l.confirmed) then merged[id] = l end
    end

    local out = {}
    for id, l in pairs(merged) do
        if l.dungeon == d.name and not HAND_WRITTEN[id] then
            table.insert(out, {
                id = id,
                name = l.title or ("Quest " .. id),
                faction = l.side,
                giver = l.giver,
                where = l.zone,
                x = Rounded(l.x),
                y = Rounded(l.y),
                mapID = l.x and l.mapID or nil,
                learned = true,
                note = l.confirmed and "Learned in play: it made progress inside this dungeon."
                    or "Learned in play: the quest's text names this dungeon.",
            })
        end
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

-- The dungeon's quests minus the ones the filters hide, plus a count of each
-- kind hidden -- the tooltip says which is which, and "hidden" with no reason
-- given would just look like missing data.
local function QuestsFor(d)
    local out, byFaction, byDone = {}, 0, 0
    local all = {}
    for _, q in ipairs(d.quests or {}) do table.insert(all, q) end
    for _, q in ipairs(LearnedFor(d)) do table.insert(all, q) end
    for _, q in ipairs(all) do
        if not ShouldShowQuest(q) then
            byFaction = byFaction + 1
        elseif DungeonLevelGuideDB.hideCompleted and GetQuestStatus(q.id) == "completed" then
            byDone = byDone + 1
        else
            table.insert(out, q)
        end
    end
    return out, byFaction, byDone
end

-- ------------------------------------------------------------
-- UI
-- ------------------------------------------------------------

local frame = CreateFrame("Frame", "DungeonLevelGuideFrame", UIParent)
frame:SetSize(260, 340)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:SetResizable(true)
frame:SetFrameStrata("MEDIUM")
frame:SetClampedToScreen(true)

-- Newer clients expose SetResizeBounds, older ones SetMinResize/SetMaxResize.
-- Which one Forever ships is unknown, so handle both.
if frame.SetResizeBounds then
    frame:SetResizeBounds(200, 200, 500, 700)
elseif frame.SetMinResize then
    frame:SetMinResize(200, 200)
    frame:SetMaxResize(500, 700)
end

local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0, 0, 0, 0.75)

local function ApplyBackground()
    local r, g, b = 0, 0, 0
    if Styled() then r, g, b = RGB(Style().bg) end
    bg:SetColorTexture(r, g, b, ((DungeonLevelGuideDB and DungeonLevelGuideDB.bgAlpha) or 0.75) * (Style().bgScale or 1))
end

local border = frame:CreateTexture(nil, "BORDER")
border:SetPoint("TOPLEFT", -1, 1)
border:SetPoint("BOTTOMRIGHT", 1, -1)
border:SetColorTexture(1, 1, 1, 0.15)

-- Title bar (drag handle)
local titleBar = CreateFrame("Frame", nil, frame)
titleBar:SetPoint("TOPLEFT")
titleBar:SetPoint("TOPRIGHT")
titleBar:SetHeight(24)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")

local title = TrackFont(titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal"), "heading")
title:SetPoint("LEFT", 8, 0)
title:SetText("Dungeon Level Guide")

-- On the title bar, or the bar (same level, there to be dragged) takes the click.
local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -2, -2)
closeBtn:SetScript("OnClick", function() frame:Hide() end)

-- Range controls
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

-- A right edge as well, so a long label at a big text size wraps instead of
-- running in under the buttons. TOPRIGHT rather than RIGHT: two points that
-- both fix the top leave the height to the text, which is the point -- a
-- wrapped label is two lines tall and the list has to start below both.
rangeLabel:SetPoint("TOPRIGHT", minusBtn, "TOPLEFT", -6, 0)
rangeLabel:SetJustifyH("LEFT")

-- Scrolling list
local scrollFrame = CreateFrame("ScrollFrame", "DungeonLevelGuideScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 8, -50)
scrollFrame:SetPoint("BOTTOMRIGHT", -28, 20)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(1, 1)
scrollFrame:SetScrollChild(content)

-- ------------------------------------------------------------
-- Layout
--
-- Everything above the list grows with the text size, so the space it needs
-- is measured off the font instead of being a fixed number: 50 pixels was
-- right at 12pt and laid the range label over the first row at 18.
-- ------------------------------------------------------------

-- A couple of pixels between the top edge and the first row, so the row is
-- not sitting on the line the ScrollFrame clips at.
local LIST_PAD = 2

-- The scrollbar is worth its width only when there is something to scroll.
-- Its up arrow sits level with the first row, so on a short list it is both
-- dead weight and a crowd right where the eye starts reading.
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
    return math.max(1, (frame:GetWidth() or 220) - 8 - ListInset())
end

-- Returns true when the answer changed, which means the list has to be laid
-- out again at the new width.
local function ShowScrollBar(show)
    if show == scrollBarShown then return false end
    scrollBarShown = show

    local bar = _G["DungeonLevelGuideScrollFrameScrollBar"]
    if bar then
        if show then bar:Show() else bar:Hide() end
    end
    -- A list that shrank while you were scrolled down would otherwise keep
    -- its offset and show blank space with no bar left to scroll back with.
    if not show then scrollFrame:SetVerticalScroll(0) end
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -ListInset(), 20)
    return true
end

-- Air between the last thing above the list and the list itself.
local HEAD_GAP = 8

-- Kept for /dlg layout, which is the only way to see these numbers from
-- inside the game.
local listTop = 0

local function LayoutPanel()
    titleBar:SetHeight(math.max(24, StringHeight(title) + 8))
    local barHeight = titleBar:GetHeight()
    -- Whichever hangs lower: the range label, or the +/- buttons beside it.
    local labelBottom = barHeight + 6 + StringHeight(rangeLabel)
    local buttonBottom = barHeight + 4 + 20
    listTop = math.max(labelBottom, buttonBottom) + HEAD_GAP
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -listTop)
end

-- Both numbers, because they disagreeing is the whole story: the measured one
-- is what the client says the label needs, the guess is what the code assumes
-- when it has nothing to measure yet.
local function LayoutReport()
    return ("text %d, title bar %d, label %d measured / %d guessed, list starts %d down")
        :format(FontSize(), titleBar:GetHeight(),
            (rangeLabel.GetStringHeight and rangeLabel:GetStringHeight()) or 0,
            TextHeight(), listTop)
end

-- Resize grip
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
plainClose:SetScript("OnClick", function() frame:Hide() end)

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
-- Position and size: save and restore
-- ------------------------------------------------------------

-- Always against the screen: a docked panel's own anchor is relative to the
-- panel it hangs from, and RestoreFrame anchors to UIParent. Docking picks it
-- up again after login, since it then stands edge to edge.
local function SavePosition()
    local left, top = frame:GetLeft(), frame:GetTop()
    if not (left and top) then return end
    DungeonLevelGuideDB.point = { point = "TOPLEFT", relativePoint = "BOTTOMLEFT", x = left, y = top }
end

local function SaveSize()
    DungeonLevelGuideDB.size = { width = frame:GetWidth(), height = frame:GetHeight() }
end

local function RestoreFrame()
    local p = DungeonLevelGuideDB.point
    if p then
        frame:ClearAllPoints()
        frame:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
    else
        frame:ClearAllPoints()
        frame:SetPoint("CENTER")
    end

    local s = DungeonLevelGuideDB.size
    if s then
        frame:SetSize(s.width, s.height)
    end
end

-- ------------------------------------------------------------
-- Copy window
--
-- Chat cannot be selected with the mouse, so anything long the addon prints
-- has to be typed off the screen by hand. A multi-line EditBox can be
-- selected, so reports go in one of those instead: it opens with everything
-- already highlighted, and Ctrl+C takes it.
-- ------------------------------------------------------------

local copyFrame, copyBox, copyTitle
local lastReport

local function BuildCopyFrame()
    copyFrame = CreateFrame("Frame", "DungeonLevelGuideCopyFrame", UIParent)
    copyFrame:SetSize(620, 440)
    copyFrame:SetPoint("CENTER")
    copyFrame:SetMovable(true)
    copyFrame:SetClampedToScreen(true)
    copyFrame:SetFrameStrata("DIALOG")

    local backdrop = copyFrame:CreateTexture(nil, "BACKGROUND")
    backdrop:SetAllPoints()
    backdrop:SetColorTexture(0, 0, 0, 0.9)

    local edge = copyFrame:CreateTexture(nil, "BORDER")
    edge:SetPoint("TOPLEFT", -1, 1)
    edge:SetPoint("BOTTOMRIGHT", 1, -1)
    edge:SetColorTexture(1, 1, 1, 0.2)

    local bar = CreateFrame("Frame", nil, copyFrame)
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("TOPRIGHT")
    bar:SetHeight(24)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function() copyFrame:StartMoving() end)
    bar:SetScript("OnDragStop", function() copyFrame:StopMovingOrSizing() end)

    copyTitle = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    copyTitle:SetPoint("LEFT", 8, 0)

    local close = CreateFrame("Button", nil, copyFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() copyFrame:Hide() end)

    local hint = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", 10, 6)
    hint:SetText("Everything is selected already -- Ctrl+C copies, Esc closes.")

    local scroll = CreateFrame("ScrollFrame", "DungeonLevelGuideCopyScroll", copyFrame,
        "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -28)
    scroll:SetPoint("BOTTOMRIGHT", -30, 24)

    copyBox = CreateFrame("EditBox", nil, scroll)
    copyBox:SetMultiLine(true)
    copyBox:SetAutoFocus(false)
    copyBox:SetFontObject("ChatFontNormal")
    copyBox:SetWidth(560)
    copyBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        copyFrame:Hide()
    end)
    scroll:SetScrollChild(copyBox)
end

-- lines is a list of strings; they are joined with newlines.
local function ShowCopyText(heading, lines)
    lastReport = table.concat(lines, "\n")

    local ok = pcall(function()
        if not copyFrame then BuildCopyFrame() end
        copyTitle:SetText(heading)
        copyBox:SetText(lastReport)
        copyBox:SetCursorPosition(0)
        copyBox:HighlightText()
        copyFrame:Show()
        copyBox:SetFocus()
    end)

    if not ok then
        -- No window: chat is worse than nothing, but it is not nothing.
        for _, line in ipairs(lines) do print(line) end
    end
    return ok
end

ns.ShowCopyText = ShowCopyText

-- ------------------------------------------------------------
-- Map marker
--
-- The marker is drawn by us, on the world map's own canvas, rather than
-- through C_Map.SetUserWaypoint alone: whether Forever draws user waypoints
-- at all is unknown, and a pin we place ourselves shows up either way. The
-- Blizzard waypoint is set as well when the API is there, because that is
-- what gives the arrow and the distance -- the two land on the same spot.
-- ------------------------------------------------------------

-- { mapID, x, y, label }, or nil when nothing is marked.
local marker
local pin

local function MapCanvas()
    if not (WorldMapFrame and WorldMapFrame.GetCanvas) then return nil end
    local ok, canvas = pcall(WorldMapFrame.GetCanvas, WorldMapFrame)
    if ok then return canvas end
    return nil
end

local function EnsurePin()
    if pin then return pin end
    local canvas = MapCanvas()
    if not canvas then return nil end

    pin = CreateFrame("Frame", "DungeonLevelGuidePin", canvas)
    pin:SetSize(18, 18)
    pin:SetFrameStrata("TOOLTIP")

    pin.icon = pin:CreateTexture(nil, "OVERLAY")
    pin.icon:SetAllPoints()
    pin.icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")

    pin.label = pin:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pin.label:SetPoint("LEFT", pin, "RIGHT", 2, 0)
    pin.label:SetTextColor(1, 0.9, 0.3)

    return pin
end

-- Re-anchors the pin to the canvas. Called on a timer while a marker is set,
-- because the canvas moves and resizes as the map is panned and zoomed, and
-- the map can be switched to a zone the marker is not in.
local function UpdatePin()
    if not pin and not marker then return end
    local p = EnsurePin()
    if not p then return end

    local canvas = MapCanvas()
    local shownMap = canvas and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
    if not marker or not canvas or shownMap ~= marker.mapID then
        p:Hide()
        return
    end

    p:ClearAllPoints()
    p:SetPoint("CENTER", canvas, "TOPLEFT",
        (marker.x / 100) * canvas:GetWidth(),
        -(marker.y / 100) * canvas:GetHeight())
    p.label:SetText(marker.label or "")
    p:Show()
end

local function SetBlizzardWaypoint(mapID, x, y)
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

local function OpenMapAt(mapID)
    if not WorldMapFrame then return false end
    if not WorldMapFrame:IsShown() then
        if ShowUIPanel then
            ShowUIPanel(WorldMapFrame)
        else
            WorldMapFrame:Show()
        end
    end
    if WorldMapFrame.SetMapID then
        pcall(WorldMapFrame.SetMapID, WorldMapFrame, mapID)
    end
    return true
end

local function ClearMarker()
    marker = nil
    if C_Map and C_Map.ClearUserWaypoint then pcall(C_Map.ClearUserWaypoint) end
    UpdatePin()
end

-- ------------------------------------------------------------
-- List: filtering and rendering
-- ------------------------------------------------------------

local rowPool = {}

-- Forward declarations: defined further down, but the rows' scripts are
-- created above and need to call them.
local ShowDungeonTooltip, ShowQuestTooltip, RefreshList

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
    ApplyFontSize(row.text)
    row.text:SetJustifyH("LEFT")

    -- The styled looks only: a fill behind an unfolded dungeon, the level
    -- span and LFG mark in a column of their own, and a quest's status
    -- marker -- a dot or a guide line, depending on the style.
    row.fill = row:CreateTexture(nil, "BACKGROUND")
    row.fill:SetAllPoints()
    row.fill:Hide()
    row.meta = TrackFont(row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    ApplyFontSize(row.meta)
    row.meta:SetPoint("RIGHT", -4, 0)
    row.meta:SetJustifyH("RIGHT")
    row.meta:Hide()
    row.dot = row:CreateTexture(nil, "ARTWORK")
    row.dot:SetSize(5, 5)
    row.dot:Hide()
    row.guide = row:CreateTexture(nil, "ARTWORK")
    row.guide:SetWidth(1)
    row.guide:Hide()

    -- The fold-out handle, on dungeon rows that have quests to show.
    row.toggle = CreateFrame("Button", nil, row)
    row.toggle:SetSize(14, 14)
    row.toggle:SetPoint("LEFT", 2, 0)
    row.toggle.hl = row.toggle:CreateTexture(nil, "HIGHLIGHT")
    row.toggle.hl:SetAllPoints()
    row.toggle.hl:SetColorTexture(1, 1, 1, 0.25)
    row.toggle.text = TrackFont(row.toggle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
    ApplyFontSize(row.toggle.text)
    row.toggle.text:SetPoint("CENTER")
    row.toggle:SetScript("OnClick", function(self)
        local d = self:GetParent().dungeon
        if not d then return end
        DungeonLevelGuideDB.expanded[d.name] = (not DungeonLevelGuideDB.expanded[d.name]) or nil
        RefreshList()
    end)

    row:SetScript("OnClick", function(self, button)
        if self.quest then
            if button == "RightButton" then
                ClearMarker()
            else
                ns.OnQuestClicked(self.quest)
            end
        elseif self.dungeon then
            ns.OnDungeonClicked(self.dungeon)
        end
    end)

    row:SetScript("OnEnter", function(self)
        if self.quest then
            ShowQuestTooltip(self, self.quest)
        elseif self.dungeon then
            ShowDungeonTooltip(self, self.dungeon)
        end
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

    rowPool[index] = row
    return row
end

-- ------------------------------------------------------------
-- Measured mob levels
--
-- The client has one level per dungeon, and Classic's boss levels are only a
-- guess for Forever. So inside a dungeon the panel notes the lowest and
-- highest level of every hostile mob it gets to see -- target, mouseover,
-- nameplates -- and once a dungeon has been measured that range replaces
-- both numbers. That also settles the bottom end: a dungeon the client calls
-- 24 whose mobs start at 30 shows as 30.
--
-- Stored under the instance name the client gives, not the panel's own, so a
-- name that matches nothing is still kept and shows up in /dlg levels. `at`
-- is the player's level at the last update: if min and max keep following
-- it, the dungeon scales to you and the numbers mean nothing.
--
-- The beta never reads SavedVariables back, so a session's measurements only
-- survive by being harvested off disk into MeasuredLevels.lua (see
-- tools/harvest-levels.lua). That file and this session are combined.
-- ------------------------------------------------------------

local function NormalName(name)
    return (name:lower():gsub("^the ", ""):gsub("[^%w]", ""))
end

-- The client's instance names where they differ from the panel's, by
-- NormalName.
local INSTANCE_ALIASES = {
    ["zulfarrak"] = "Zul'Farak",
    ["templeofatalhakkar"] = "Sunken Temple",
}

-- The dungeon an instance name belongs to, or nil. A name that fits several
-- -- "Dire Maul" fits all three wings -- belongs to none of them, rather than
-- to whichever came first.
local function DungeonForInstance(instanceName)
    if type(instanceName) ~= "string" or instanceName == "" then return nil end
    local wanted = NormalName(instanceName)
    local alias = INSTANCE_ALIASES[wanted]
    local found
    for _, d in ipairs(DUNGEONS) do
        local own = NormalName(d.name)
        if d.name == alias or own == wanted then return d end
        if own:find(wanted, 1, true) or wanted:find(own, 1, true) then
            if found then return nil end
            found = d
        end
    end
    return found
end

local function Widen(span, seen)
    if not span then return { min = seen.min, max = seen.max } end
    span.min, span.max = math.min(span.min, seen.min), math.max(span.max, seen.max)
    return span
end

local function MeasuredLevels(d)
    local span
    for _, source in ipairs({ ns.MEASURED_LEVELS or {}, DungeonLevelGuideDB.mobLevels or {} }) do
        for instanceName, seen in pairs(source) do
            if DungeonForInstance(instanceName) == d then span = Widen(span, seen) end
        end
    end
    return span
end

-- bottom, top, and whether they were measured here.
-- Defined with the Group Finder code further down.
local ActivityFor

-- bottom, top, and where they came from: "finder" when the Group Finder gives
-- the activity a range, "measured" in the dungeon, nil for the client's level
-- up to Classic's last boss. The finder's range is Forever's own word on who
-- the dungeon is for; the mobs seen inside go in the tooltip beside it.
local function LevelSpan(d)
    local activity = ActivityFor(d)
    if activity and activity.minLevel and activity.maxLevel then
        return activity.minLevel, activity.maxLevel, "finder"
    end
    local seen = MeasuredLevels(d)
    if seen then return seen.min, seen.max, "measured" end
    return d.level, math.max(d.level, d.bossLevel or d.level), nil
end

-- Whether the top of the span is still a guess, and gets a "?".
local function SpanGuessed(d, source)
    return source == nil and (d.bossLevel or d.unverified) and true or false
end

-- "16-21" known, "16-21?" still Classic's top, "13" when there is no top.
local function SpanText(d)
    local low, high, source = LevelSpan(d)
    local text = (low == high) and tostring(low) or ("%d-%d"):format(low, high)
    if SpanGuessed(d, source) then text = text .. "?" end
    return text
end

-- In range when any part of the dungeon's span is within the margin of you.
local function IsInRange(d, level, range)
    local low, high = LevelSpan(d)
    return level >= low - range and level <= high + range
end

local function CurrentInstanceName()
    if type(IsInInstance) ~= "function" or type(GetInstanceInfo) ~= "function" then return nil end
    local inside, kind = IsInInstance()
    if not inside or kind ~= "party" then return nil end
    return (GetInstanceInfo())
end

local IGNORED_CREATURE_TYPES = { ["Critter"] = true, ["Non-combat Pet"] = true }
-- Dungeon trash is elite; the non-elites inside are mostly the mobs' pets.
local ELITE_CLASSIFICATIONS = { elite = true, rareelite = true, worldboss = true }

-- Inside an instance the client may hand out a unit's details as secret
-- values, which cannot be compared or saved.
local function IsSecret(value)
    if issecretvalue then return issecretvalue(value) == true end
    return false
end

-- Reads one value about a unit. Returns the value, or nil and why not:
-- "secret" when the client hands it out as a secret value, or the error.
local function ReadUnit(f, ...)
    if not f then return nil, "missing" end
    local ok, value = pcall(f, ...)
    if not ok then return nil, value end
    if IsSecret(value) then return nil, "secret" end
    return value
end

-- The unit's level, whether it is only "loose", and what could not be read.
-- A check the client keeps secret (is it hostile, a player, a pet?) is
-- skipped rather than trusted, and the level then only counts as loose: it
-- may be a friendly NPC's. In Hall of Thanes (2026-09-28) only the creature
-- type was secret; without it a critter is told apart by its level 1.
local CHECKS = {
    { "UnitExists", function(unit) return UnitExists and UnitExists(unit) end, false },
    { "UnitIsPlayer", function(unit) return UnitIsPlayer and UnitIsPlayer(unit) end, true },
    { "UnitPlayerControlled", function(unit) return UnitPlayerControlled and UnitPlayerControlled(unit) end, true },
    { "UnitCanAttack", function(unit) return UnitCanAttack and UnitCanAttack("player", unit) end, false },
}

local function HostileMobLevel(unit)
    local unread = {}
    local loose = false
    for _, check in ipairs(CHECKS) do
        local name, read, skipWhen = check[1], check[2], check[3]
        local value, why = ReadUnit(read, unit)
        if why then
            unread[name] = why
            loose = true
        elseif (value and true or false) == skipWhen then
            return nil, false, unread
        end
    end
    local creatureType, typeWhy = ReadUnit(UnitCreatureType, unit)
    if typeWhy then
        unread.UnitCreatureType = typeWhy
    elseif IGNORED_CREATURE_TYPES[creatureType or ""] then
        return nil, false, unread
    end
    local level, levelWhy = ReadUnit(UnitLevel, unit)
    if levelWhy then unread.UnitLevel = levelWhy end
    if typeWhy and level == 1 then return nil, false, unread end
    local classification, classWhy = ReadUnit(function(u) return UnitClassification and UnitClassification(u) end, unit)
    if classWhy then unread.UnitClassification = classWhy end
    local normal = classification ~= nil and not ELITE_CLASSIFICATIONS[classification]
    return level, loose, unread, normal
end

-- What could not be read, per instance and function: kept in SavedVariables
-- so a run that measured nothing still says why.
local function NoteMisses(instanceName, unread)
    if not next(unread) then return end
    local misses = DungeonLevelGuideDB.mobMisses
    local entry = misses[instanceName] or {}
    misses[instanceName] = entry
    entry.mobs = (entry.mobs or 0) + 1
    entry.unread = entry.unread or {}
    for name, why in pairs(unread) do
        local key = name .. ": " .. tostring(why)
        entry.unread[key] = (entry.unread[key] or 0) + 1
    end
end

local function Widened(store, instanceName, level)
    local seen = store[instanceName]
    local playerLevel = UnitLevel("player")
    if not seen then
        store[instanceName] = { min = level, max = level, at = playerLevel }
        return true
    end
    if level >= seen.min and level <= seen.max then return false end
    seen.min = math.min(seen.min, level)
    seen.max = math.max(seen.max, level)
    seen.at = playerLevel
    return true
end

-- true when the unit widened the instance's range. A skull boss reports -1.
-- A loose level goes in looseLevels, apart from the real ones, until it is
-- known how far it can be trusted.
local function RecordMobLevel(unit)
    local instanceName = CurrentInstanceName()
    if not instanceName or type(unit) ~= "string" then return false end
    local level, loose, unread, normal = HostileMobLevel(unit)
    NoteMisses(instanceName, unread)
    if type(level) ~= "number" or level <= 0 then return false end
    if normal then
        Widened(DungeonLevelGuideDB.normalLevels, instanceName, level)
        return false
    end
    if loose then
        Widened(DungeonLevelGuideDB.looseLevels, instanceName, level)
        return false
    end
    return Widened(DungeonLevelGuideDB.mobLevels, instanceName, level)
end

-- ------------------------------------------------------------
-- Quest progress inside a dungeon
--
-- The quest log is read into a number per quest that only grows while the
-- quest moves forward. A dungeon-tagged quest whose number grows, or that
-- appears, while you are inside a dungeon belongs to it. The first reading
-- after entering is only a baseline, so progress made outside never counts.
-- ------------------------------------------------------------

local DUNGEON_TAGS = { [81] = true, [85] = true }

local function IsDungeonTagged(questID)
    if not (C_QuestLog and C_QuestLog.GetQuestTagInfo) then return false end
    local ok, info = pcall(C_QuestLog.GetQuestTagInfo, questID)
    return ok and info and DUNGEON_TAGS[info.tagID] or false
end

local function QuestProgress()
    local progress = {}
    if not (C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo) then return progress end
    local ok, count = pcall(C_QuestLog.GetNumQuestLogEntries)
    for index = 1, (ok and type(count) == "number") and count or 0 do
        local gotInfo, info = pcall(C_QuestLog.GetInfo, index)
        if gotInfo and info and info.questID and not info.isHeader then
            local done = info.isComplete and 1000 or 0
            local gotObjectives, objectives = pcall(C_QuestLog.GetQuestObjectives, info.questID)
            for _, objective in ipairs((gotObjectives and objectives) or {}) do
                done = done + (objective.numFulfilled or 0) + (objective.finished and 1 or 0)
            end
            progress[info.questID] = done
        end
    end
    return progress
end

local lastProgress, progressInstance = {}, nil

local function CheckDungeonProgress()
    local instanceName = CurrentInstanceName()
    local d = instanceName and DungeonForInstance(instanceName)
    local now = QuestProgress()
    if d and progressInstance == instanceName then
        for questID, done in pairs(now) do
            local before = lastProgress[questID]
            if (before == nil or done > before) and IsDungeonTagged(questID) then
                LearnQuest(questID, d.name, true)
            end
        end
    end
    lastProgress, progressInstance = now, instanceName
end

local function LearnedReport()
    local lines = { "dungeon quests learned in play this session:" }
    local ids = {}
    for id in pairs(DungeonLevelGuideDB.learned) do table.insert(ids, id) end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local l = DungeonLevelGuideDB.learned[id]
        table.insert(lines, ("  %d %s -> %s (%s)"):format(id, tostring(l.title), l.dungeon,
            l.confirmed and "made progress inside" or "from the quest text"))
    end
    if #ids == 0 then table.insert(lines, "  none yet.") end
    local harvested = 0
    for _ in pairs(ns.LEARNED_QUESTS or {}) do harvested = harvested + 1 end
    table.insert(lines, ("harvested from earlier sessions: %d"):format(harvested))
    return lines
end

local function MobLevelReport()
    local lines = { "mob levels seen this session (lowest-highest, and your level then):" }
    local names = {}
    for name in pairs(DungeonLevelGuideDB.mobLevels) do table.insert(names, name) end
    table.sort(names)
    for _, name in ipairs(names) do
        local seen = DungeonLevelGuideDB.mobLevels[name]
        table.insert(lines, ("  %s: %d-%d, at %s%s"):format(name, seen.min, seen.max,
            tostring(seen.at), DungeonForInstance(name) and "" or " -- matches no dungeon in the list"))
    end
    if #names == 0 then
        table.insert(lines, "  nothing yet -- target or mouse over mobs inside a dungeon.")
    end
    for name, miss in pairs(DungeonLevelGuideDB.mobMisses or {}) do
        table.insert(lines, ("  %s: %d mobs with something unreadable:"):format(name, miss.mobs or 0))
        local keys = {}
        for key in pairs(miss.unread or {}) do table.insert(keys, key) end
        table.sort(keys)
        for _, key in ipairs(keys) do
            table.insert(lines, ("    %s (%d)"):format(key, miss.unread[key]))
        end
    end
    for name, seen in pairs(DungeonLevelGuideDB.looseLevels or {}) do
        table.insert(lines, ("  %s: %d-%d unchecked -- could include friendly NPCs"):format(name, seen.min, seen.max))
    end
    for name, seen in pairs(DungeonLevelGuideDB.normalLevels or {}) do
        table.insert(lines, ("  %s: %d-%d non-elite, not counted -- mostly the mobs' pets"):format(name, seen.min, seen.max))
    end

    local harvested = {}
    for name in pairs(ns.MEASURED_LEVELS or {}) do table.insert(harvested, name) end
    table.sort(harvested)
    table.insert(lines, ("harvested from earlier sessions: %d"):format(#harvested))
    for _, name in ipairs(harvested) do
        local seen = ns.MEASURED_LEVELS[name]
        table.insert(lines, ("  %s: %d-%d, at %s-%s"):format(name, seen.min, seen.max,
            tostring(seen.atLow), tostring(seen.atHigh)))
    end
    return lines
end

-- ------------------------------------------------------------
-- What Blizzard's own Group Finder offers
--
-- The panel's list is "dungeons tuned near your level"; the Group Finder's is
-- "what is on offer right now", and it is shorter. The answer comes from
-- C_LFGList's available activities, which is the list the client's own window
-- is built from -- already filtered by level and faction, so there is nothing
-- for us to re-derive.
--
-- GetLFGDungeonInfo's levels are NOT that answer, which the beta settled on
-- 2026-09-21: it reports minLevel == maxLevel == the dungeon's tuned level
-- for every single one (13-13, 15-15, 16-16), the same single number the
-- panel already shows. Testing "is my level inside that span" therefore only
-- ever matched the dungeon tuned to exactly your level, and marked Deadmines
-- at 16 while Blizzard's window was offering three entirely different ones.
-- ------------------------------------------------------------

-- Name of an activity, whichever of the two shapes this client's API has.
-- A level of 0 means "none set", the same as no field at all.
local function LevelField(value)
    if type(value) == "number" and value > 0 then return value end
    return nil
end

-- Name of an activity, and the level range the Group Finder shows beside it
-- ("Deadmines (17-26)") when this client's info table carries one. The
-- Classic-style finder keeps it as a suggestion; minLevel/maxLevel are the
-- other shape seen in older clients. Either may be missing.
local function ActivityDetails(activityID)
    if not C_LFGList then return nil end
    if C_LFGList.GetActivityInfoTable then
        local ok, info = pcall(C_LFGList.GetActivityInfoTable, activityID)
        if ok and info then
            return info.fullName or info.shortName,
                LevelField(info.minLevelSuggestion) or LevelField(info.minLevel),
                LevelField(info.maxLevelSuggestion) or LevelField(info.maxLevel)
        end
    end
    if C_LFGList.GetActivityInfo then
        local ok, fullName, shortName = pcall(C_LFGList.GetActivityInfo, activityID)
        if ok then return fullName or shortName end
    end
    return nil
end

-- [lowercased activity name] = { id, category, minLevel, maxLevel },
-- or nil while the client has not answered. Rebuilt on the LFG events rather
-- than per row, since redrawing happens on every resize.
local availableActivities

local function ScanActivities()
    availableActivities = nil
    if not (C_LFGList and C_LFGList.GetAvailableCategories
        and C_LFGList.GetAvailableActivities) then
        return
    end

    local ok, categories = pcall(C_LFGList.GetAvailableCategories)
    if not ok or not categories then return end

    local found, count = {}, 0
    for _, categoryID in ipairs(categories) do
        local gotList, activities = pcall(C_LFGList.GetAvailableActivities, categoryID)
        for _, activityID in ipairs((gotList and activities) or {}) do
            local name, minLevel, maxLevel = ActivityDetails(activityID)
            if name then
                found[name:lower()] = {
                    id = activityID, category = categoryID,
                    minLevel = minLevel, maxLevel = maxLevel,
                }
                count = count + 1
            end
        end
    end

    -- Nothing at all is "cannot tell", not "offers nothing". An empty answer
    -- must not be allowed to empty the panel.
    if count > 0 then availableActivities = found end
end

local function EnsureActivityScan()
    if availableActivities == nil then ScanActivities() end
end

-- The activity matching a dungeon: the exact name, or an activity name that
-- CONTAINS the dungeon's ("The Hall of Thanes" for "Hall of Thanes"). Never
-- the other way round. The finder lists zones too, and "Excavation Site:
-- Wetlands" contains the zone "Wetlands" -- that match gave the dungeon the
-- zone's 18-34 and had it offered at 19 while the finder's window showed no
-- such thing (beta, build 69977).
function ActivityFor(d)
    if not availableActivities then return nil end
    local wanted = d.name:lower()
    local exact = availableActivities[wanted]
    if exact then return exact end
    for name, activity in pairs(availableActivities) do
        if name:find(wanted, 1, true) then return activity end
    end
    return nil
end

-- Whether you are inside the range the Group Finder gives the activity. An
-- activity with no range is taken as offered: the list itself was the answer
-- on the build this was first written against, already filtered by level.
local function WithinActivityRange(activity)
    local level = UnitLevel("player") or 1
    if activity.minLevel and level < activity.minLevel then return false end
    if activity.maxLevel and level > activity.maxLevel then return false end
    return true
end

-- true, false, or nil when there is no answer to be had. nil is never treated
-- as "no": a client that does not answer must not empty the panel.
--
-- Listed is not enough when the activity carries a level range: a client
-- whose list holds every dungeon offers only the ones whose range you are in,
-- which is what its own window shows.
local function ClientOffers(d)
    if not availableActivities then return nil end
    local activity = ActivityFor(d)
    if not activity then return false end
    return WithinActivityRange(activity)
end

-- Whether the panel shows a dungeon. By default that is exactly what the
-- Group Finder offers. Widening (lfgOnly off) adds everything whose span is
-- within the margin of you, on top of that. A client that answers nothing
-- about the Group Finder falls back to the margin either way, so the panel
-- is never emptied by silence.
local function ShowsDungeon(d, level, range)
    local offered = ClientOffers(d)
    if offered == true then return true end
    if DungeonLevelGuideDB.lfgOnly and offered == false then return false end
    return IsInRange(d, level, range)
end

-- true when the list is the Group Finder's alone, and the margin plays no part.
local function FinderOnly()
    return DungeonLevelGuideDB.lfgOnly and availableActivities ~= nil
end

-- Only for the report: the client's own name and level for a dungeon id.
local function ClientLFGInfo(d)
    if not d.lfgID or type(GetLFGDungeonInfo) ~= "function" then return nil end
    local ok, name, _, _, minLevel, maxLevel = pcall(GetLFGDungeonInfo, d.lfgID)
    if not ok or not name then return nil end
    return name, minLevel, maxLevel
end

-- Reads quest status from the player's live quest log rather than a database
-- of our own, so this addon depends on nothing but the client.
function GetQuestStatus(questID)
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        local ok, done = pcall(C_QuestLog.IsQuestFlaggedCompleted, questID)
        if ok and done then return "completed" end
    end

    if C_QuestLog and C_QuestLog.IsOnQuest then
        local ok, active = pcall(C_QuestLog.IsOnQuest, questID)
        if ok and active then return "active" end
    elseif GetQuestLogIndexByID then
        local idx = GetQuestLogIndexByID(questID)
        if idx and idx > 0 then return "active" end
    end

    return "not_picked_up"
end

-- Where to go to get a quest you have not picked up. For a quest in a chain
-- that is the chain's first quest, not this one -- walking to this one's giver
-- would be a wasted trip.
local function QuestPickupHint(q)
    local name, where, x, y = q.giver, q.where, q.x, q.y
    local prefix = ""
    if q.chain then
        name, where, x, y = q.chainGiver, q.chainWhere, q.chainX, q.chainY
        prefix = ("chain from %s: "):format(q.chain)
        if not name then return prefix:sub(1, -3) end
    end
    if not name then return nil end

    -- A giver with no zone is either one we have not looked up or one standing
    -- in the instance. Only the second is something we can say out loud.
    local place = where or (q.inside and "inside the dungeon") or "?"
    if x and y then place = ("%s (%d, %d)"):format(place, x, y) end
    return prefix .. name .. ", " .. place
end

-- Three ways to start a quest inside the dungeon, and three different
-- searches: an NPC standing there, a thing to click, or loot off the mobs.
local function InsideText(q)
    if q.fromObject then
        return "Picked up inside the dungeon, off an object rather than an NPC -- look for something to click."
    elseif q.fromDrop then
        return "Starts from an item the mobs inside drop -- the first one to drop puts it in your log."
    end
    return "Picked up inside the dungeon -- nothing to walk to first."
end

-- Where you go to pick the quest up, which for a chain quest is the chain's
-- first giver -- the same place QuestPickupHint names.
local function PickupLocation(q)
    if q.chain then
        return q.chainMapID, q.chainX, q.chainY, q.chainGiver or q.chain
    end
    return q.mapID, q.x, q.y, q.giver or q.name
end

-- Lists the dungeon's related quests, colour-coded by status: green active,
-- grey completed, yellow not picked up yet.
function ShowDungeonTooltip(row, d)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(d.name, 1, 1, 1)
    local low, high, from = LevelSpan(d)
    local source = ""
    if from == "measured" then
        source = " (measured in here)"
    elseif from == "finder" then
        source = " (the Group Finder's range)"
    elseif d.unverified then
        source = " (unconfirmed)"
    elseif d.bossLevel then
        source = " (top is Classic's last boss, not seen here yet)"
    end
    GameTooltip:AddLine(("Level %s%s"):format(
        low == high and tostring(low) or ("%d-%d"):format(low, high), source), 0.8, 0.8, 0.8)
    local seen = MeasuredLevels(d)
    if seen and from ~= "measured" then
        GameTooltip:AddLine(("Mobs seen inside: %s"):format(
            seen.min == seen.max and tostring(seen.min) or ("%d-%d"):format(seen.min, seen.max)), 0.8, 0.8, 0.8)
    end

    local offered = ClientOffers(d)
    if offered ~= nil then
        if offered then
            GameTooltip:AddLine("In the Group Finder's list right now", 0.4, 0.8, 1)
        else
            GameTooltip:AddLine("Not in the Group Finder's list right now", 0.6, 0.6, 0.6)
        end
    end

    local quests, hiddenFaction, hiddenDone = QuestsFor(d)

    if #quests == 0 then
        GameTooltip:AddLine(" ")
        if hiddenFaction > 0 and hiddenDone > 0 then
            GameTooltip:AddLine(("All %d linked quests are hidden: %d for the other faction, %d already done."):format(
                hiddenFaction + hiddenDone, hiddenFaction, hiddenDone), 0.6, 0.6, 0.6, true)
        elseif hiddenFaction > 0 then
            GameTooltip:AddLine(("All %d linked quests are for the other faction."):format(hiddenFaction),
                0.6, 0.6, 0.6, true)
        elseif hiddenDone > 0 then
            GameTooltip:AddLine(("All %d linked quests are already done."):format(hiddenDone),
                0.6, 0.6, 0.6, true)
        else
            GameTooltip:AddLine("Linked quests not known yet.", 0.6, 0.6, 0.6, true)
        end
    else
        GameTooltip:AddLine(" ")
        local shown = 0
        for _, q in ipairs(quests) do
            if shown >= MAX_TOOLTIP_QUESTS then
                GameTooltip:AddLine(("... and %d more"):format(#quests - shown), 0.6, 0.6, 0.6)
                break
            end
            local c = STATUS_COLOR[GetQuestStatus(q.id)]
            GameTooltip:AddDoubleLine((FACTION_TAG[q.faction] or "") .. q.name, c.label,
                1, 1, 1, c.r, c.g, c.b)
            if c == STATUS_COLOR.not_picked_up then
                local where = QuestPickupHint(q)
                if where then GameTooltip:AddLine("   " .. where, 0.55, 0.55, 0.55) end
            end
            shown = shown + 1
        end
        if hiddenFaction > 0 then
            GameTooltip:AddLine(("%d more for the other faction, hidden."):format(hiddenFaction),
                0.6, 0.6, 0.6)
        end
        if hiddenDone > 0 then
            GameTooltip:AddLine(("%d already done, hidden."):format(hiddenDone), 0.6, 0.6, 0.6)
        end
    end

    if d.questsPartial then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Quest list is incomplete -- see README.", 0.6, 0.6, 0.6, true)
    end

    if #quests > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click + to unfold the quests, then a quest to mark it on the map.",
            0.5, 0.5, 0.5, true)
    end

    GameTooltip:Show()
end

-- One quest's own row: status, where to pick it up, and whether clicking it
-- can mark anything.
function ShowQuestTooltip(row, q)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText((FACTION_TAG[q.faction] or "") .. q.name, 1, 1, 1)

    local c = STATUS_COLOR[GetQuestStatus(q.id)]
    GameTooltip:AddLine(c.label, c.r, c.g, c.b)

    if q.faction then
        GameTooltip:AddLine(q.faction == "A" and "Alliance only" or "Horde only", 0.7, 0.7, 0.7)
    end

    local where = QuestPickupHint(q)
    if where then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(where, 0.8, 0.8, 0.8, true)
    end

    if q.note then
        if not where then GameTooltip:AddLine(" ") end
        GameTooltip:AddLine(q.note, 0.7, 0.7, 0.7, true)
    end

    -- Where the chain's first quest is known by id, its status answers the
    -- question the hint raises: is that trip still ahead of me?
    if q.chainID then
        local rootStatus = GetQuestStatus(q.chainID)
        if rootStatus == "completed" then
            GameTooltip:AddLine("The chain's first quest is already done.", 0.2, 1, 0.2)
        elseif rootStatus == "active" then
            GameTooltip:AddLine("The chain's first quest is in your log.", 0.2, 1, 0.2)
        end
    end

    GameTooltip:AddLine(" ")
    local mapID, x, y = PickupLocation(q)
    if mapID and x and y then
        GameTooltip:AddLine("Click to mark the pickup point on the map.", 0.5, 0.5, 0.5, true)
        GameTooltip:AddLine("Right-click to remove the marker.", 0.5, 0.5, 0.5, true)
    elseif q.inside then
        GameTooltip:AddLine(InsideText(q), 0.5, 0.5, 0.5, true)
    else
        GameTooltip:AddLine("No coordinate for where this one is picked up -- the giver stands inside the instance, or the data has a hole.",
            0.5, 0.5, 0.5, true)
    end

    GameTooltip:Show()
end

-- True if any of the dungeon's quests is active right now, so the list can
-- show an indicator without the user hovering every row.
local function HasActiveLinkedQuest(d)
    for _, q in ipairs(QuestsFor(d)) do
        if GetQuestStatus(q.id) == "active" then
            return true
        end
    end
    return false
end

-- A dungeon row, with the fold-out handle when there is anything to unfold.
-- The right-hand column of a styled row: the LFG mark, then the level span,
-- with the "?" of an unmeasured top in the faint colour.
local function MetaText(d, style)
    local low, high, source = LevelSpan(d)
    local span = (low == high) and tostring(low) or ("%d\226\128\147%d"):format(low, high)
    local guess = SpanGuessed(d, source)
    local text = ("|cff%s%s|r"):format(style.span, span)
    if guess then text = text .. ("|cff%s?|r"):format(style.faint) end
    if ClientOffers(d) == true then
        text = ("|cff%s%s|r  "):format(style.lfgColor, style.lfg) .. text
    end
    return text
end

local STATUS_KEY = { active = "active", not_picked_up = "open", completed = "done" }

local function DrawDungeonRow(row, d)
    row.dungeon, row.quest = d, nil
    local style = Style()
    local styled = Styled()
    local expanded = DungeonLevelGuideDB.expanded[d.name]
    row.dot:Hide()
    row.guide:Hide()

    local indent = 4
    if #QuestsFor(d) > 0 then
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

    local metaWidth = 0
    if styled then
        row.meta:SetText(MetaText(d, style))
        row.meta:Show()
        metaWidth = math.ceil((row.meta.GetStringWidth and row.meta:GetStringWidth()) or 0) + 6
        ShowIf(row.fill, expanded)
        if expanded then row.fill:SetColorTexture(RGB(style.selected)) end
        row.hl:SetColorTexture(1, 1, 1, 0.06)
    else
        row.meta:Hide()
        row.fill:Hide()
        row.hl:SetColorTexture(1, 1, 1, 0.12)
    end

    row.text:ClearAllPoints()
    row.text:SetPoint("LEFT", indent, 0)
    -- A width of its own rather than a right anchor: an anchored FontString
    -- only knows how tall it wrapped to once the client has laid the frame
    -- out, and the row height is needed before that.
    row.text:SetWidth(math.max(1, (row:GetWidth() or 220) - indent - 4 - metaWidth))

    if styled then
        row.text:SetText(d.name)
    else
        -- Only marks the ones the client positively offers. No answer, no tag.
        local lfgTag = ClientOffers(d) == true and "|cff66ccff[LFG]|r " or ""
        row.text:SetText(("%s%s (%s)"):format(lfgTag, d.name, SpanText(d)))
    end

    -- Green means the same thing here as on a quest row: you are on something
    -- in there. It replaces the star that used to sit in front of the name.
    -- The styled looks also grey out what the Group Finder says no to.
    if HasActiveLinkedQuest(d) then
        if styled then
            row.text:SetTextColor(RGB(style.active))
        else
            local active = STATUS_COLOR.active
            row.text:SetTextColor(active.r, active.g, active.b)
        end
    elseif styled and ClientOffers(d) == false then
        row.text:SetTextColor(RGB(style.dim))
    elseif styled then
        row.text:SetTextColor(RGB(style.text))
    else
        row.text:SetTextColor(1, 1, 1)
    end
    row:SetAlpha(1)
end

local function DrawQuestRow(row, q)
    row.quest, row.dungeon = q, nil
    row.toggle:Hide()
    row.meta:Hide()
    row.fill:Hide()

    -- The glyph is this quest's own status and nothing else. Whether the
    -- chain's first quest is done is a different question, and it stays in
    -- the tooltip -- a star that sometimes meant the chain root would stop
    -- meaning "you are on this one".
    local status = GetQuestStatus(q.id)
    local style = Style()
    local r, g, b
    local left = 26
    if Styled() then
        r, g, b = RGB(style[STATUS_KEY[status]])
        if style.marker == "dot" then
            row.dot:ClearAllPoints()
            row.dot:SetPoint("LEFT", 22, 0)
            row.dot:SetColorTexture(r, g, b)
            row.dot:Show()
            row.guide:Hide()
            left = 33
        else
            row.guide:ClearAllPoints()
            row.guide:SetPoint("TOPLEFT", 15, 0)
            row.guide:SetPoint("BOTTOMLEFT", 15, 0)
            row.guide:SetColorTexture(RGB(style.divider or style.faint))
            row.guide:Show()
            row.dot:Hide()
            left = 27
        end
        row.hl:SetColorTexture(1, 1, 1, 0.06)
    else
        local c = STATUS_COLOR[status]
        r, g, b = c.r, c.g, c.b
        row.dot:Hide()
        row.guide:Hide()
        row.hl:SetColorTexture(1, 1, 1, 0.12)
    end

    row.text:ClearAllPoints()
    row.text:SetPoint("LEFT", left, 0)
    row.text:SetWidth(math.max(1, (row:GetWidth() or 220) - left - 4))
    row.text:SetText((FACTION_TAG[q.faction] or "") .. q.name)
    row.text:SetTextColor(r, g, b)
    -- Rows come from a pool, so the alpha has to be set both ways every time.
    row:SetAlpha(status == "completed" and COMPLETED_ALPHA or 1)
end

-- Stacks the rows by their own height rather than a fixed one, and returns
-- how tall the list came out. A row is measured only after its text is set,
-- so the pass draws first and sizes second.
local function DrawRows(entries, width)
    local y = LIST_PAD
    for i, entry in ipairs(entries) do
        local row = GetOrCreateRow(i)
        row:SetWidth(width)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
        if entry.quest then
            DrawQuestRow(row, entry.quest)
        else
            DrawDungeonRow(row, entry.dungeon)
        end
        local height = RowHeight(row.text)
        row:SetHeight(height)
        row:Show()
        y = y + height
    end
    return y
end

-- `levelOverride` exists for PLAYER_LEVEL_UP, where UnitLevel("player") still
-- reports the level you just left -- the new one arrives as the event's first
-- argument. Without it the list redraws one level behind and only catches up
-- the next time something else calls in here.
function RefreshList(levelOverride)
    if not DungeonLevelGuideDB then return end

    EnsureActivityScan()

    local level = levelOverride or UnitLevel("player") or 1
    local range = DungeonLevelGuideDB.range or DEFAULT_RANGE
    local finderOnly = FinderOnly()
    if finderOnly then
        rangeLabel:SetText(Styled() and ("Level %d \194\183 as the Group Finder"):format(level)
            or ("Level %d, as the Group Finder"):format(level))
    else
        rangeLabel:SetText(Styled() and ("Level %d \194\183 margin \194\177%d"):format(level, range)
            or ("Level %d, +/- %d"):format(level, range))
    end
    -- The margin does nothing while the list is the Group Finder's, so its
    -- buttons go with it rather than seeming broken.
    ShowIf(plusBtn, not finderOnly and not Styled())
    ShowIf(minusBtn, not finderOnly and not Styled())
    ShowIf(plainPlus, not finderOnly and Styled())
    ShowIf(plainMinus, not finderOnly and Styled())
    -- After SetText, never before: the label is measured, and an old text
    -- measures the old height.
    LayoutPanel()

    local shown = {}
    for _, d in ipairs(DUNGEONS) do
        if ShowsDungeon(d, level, range) then table.insert(shown, d) end
    end
    table.sort(shown, function(a, b)
        local lowA, lowB = LevelSpan(a), LevelSpan(b)
        if lowA ~= lowB then return lowA < lowB end
        return a.name < b.name
    end)

    -- Flat list of what the panel draws: a dungeon, then its quests when it
    -- is unfolded.
    local entries = {}
    for _, d in ipairs(shown) do
        table.insert(entries, { dungeon = d })
        if DungeonLevelGuideDB.expanded[d.name] then
            for _, q in ipairs(QuestsFor(d)) do
                table.insert(entries, { quest = q, dungeon = d })
            end
        end
    end

    -- Two passes at most, and usually one: the bar costs width, the width
    -- decides which names wrap, and what wraps decides whether the list is
    -- long enough to need the bar in the first place.
    local width = ListWidth()
    local listHeight = DrawRows(entries, width)
    if ShowScrollBar(listHeight > (scrollFrame:GetHeight() or 0)) then
        width = ListWidth()
        listHeight = DrawRows(entries, width)
    end

    for i = #entries + 1, #rowPool do
        rowPool[i].dungeon, rowPool[i].quest = nil, nil
        rowPool[i]:Hide()
    end

    content:SetSize(width, math.max(listHeight, 1))
end

-- Applies both, then redraws: row heights depend on the font size.
-- RefreshList lays the panel out once the label carries its new text.
local function ApplyLook()
    ApplyStyle()
    ApplyFont()
    RefreshList()
end

-- nil for a name that is not a style.
local function SetStyle(name)
    if not STYLES[name] then return nil end
    DungeonLevelGuideDB.style = name
    ApplyLook()
    return name
end

local function SetFontSize(size)
    size = math.max(MIN_FONT_SIZE, math.min(MAX_FONT_SIZE, math.floor(size)))
    DungeonLevelGuideDB.fontSize = size
    ApplyLook()
    return size
end

-- Takes a percentage, because "how see-through" is easier to think about in
-- whole numbers than in 0.85.
local function SetBackgroundAlpha(percent)
    percent = math.max(0, math.min(100, math.floor(percent)))
    DungeonLevelGuideDB.bgAlpha = percent / 100
    ApplyLook()
    return percent
end

local function SetRange(newRange)
    if newRange < 0 then newRange = 0 end
    if newRange > 15 then newRange = 15 end
    DungeonLevelGuideDB.range = newRange
    RefreshList()
end

plusBtn:SetScript("OnClick", function() SetRange((DungeonLevelGuideDB.range or DEFAULT_RANGE) + 1) end)
minusBtn:SetScript("OnClick", function() SetRange((DungeonLevelGuideDB.range or DEFAULT_RANGE) - 1) end)
plainPlus:SetScript("OnClick", function() SetRange((DungeonLevelGuideDB.range or DEFAULT_RANGE) + 1) end)
plainMinus:SetScript("OnClick", function() SetRange((DungeonLevelGuideDB.range or DEFAULT_RANGE) - 1) end)

-- ------------------------------------------------------------
-- Options panel
--
-- Every filter here also has a slash command, but a filter you cannot see is
-- a filter that makes things vanish for no reason: a dungeon dropping out of
-- the list because lfgOnly is on looks exactly like a bug. So the panel shows
-- all of them at once, and says how many rows each one is currently hiding.
-- ------------------------------------------------------------

local gui

-- Every frame holding the option controls: the /dlg gui dialog and the page
-- under Options > AddOns. Both are refreshed the same way.
local optionPanels = {}

local function RefreshPanel(panel)
    local current = DungeonLevelGuideDB.style
    panel.styleDropdown.Refresh(current)

    panel.faction:SetChecked(DungeonLevelGuideDB.hideOtherFaction)
    panel.done:SetChecked(DungeonLevelGuideDB.hideCompleted)
    panel.lfgOnly:SetChecked(DungeonLevelGuideDB.lfgOnly)
    panel.rangeLabel:SetText(("Margin when widened: +/- %d"):format(
        DungeonLevelGuideDB.range or DEFAULT_RANGE))
    panel.fontLabel:SetText(("Text size: %d"):format(FontSize()))
    -- math.floor, not just %d: WoW's Lua 5.1 truncates a float silently but
    -- 5.4, which the test suite runs, throws on it.
    panel.alphaLabel:SetText(("Background: %d%% opaque"):format(
        math.floor((DungeonLevelGuideDB.bgAlpha or 0.75) * 100 + 0.5)))

    local mine = PlayerFaction()
    panel.factionLabel:SetText(("Hide the other faction's quests%s"):format(
        mine and (" (you are " .. (mine == "A" and "Alliance" or "Horde") .. ")") or ""))

    -- What the filters are actually doing right now, counted rather than
    -- described -- "3 hidden" is the answer to "where did it go".
    local level = UnitLevel("player") or 1
    local range = DungeonLevelGuideDB.range or DEFAULT_RANGE
    local shownCount, byLFG, byOtherFaction, byDone = 0, 0, 0, 0
    for _, d in ipairs(DUNGEONS) do
        if ShowsDungeon(d, level, range) then
            shownCount = shownCount + 1
            local _, hiddenFaction, hiddenDone = QuestsFor(d)
            byOtherFaction = byOtherFaction + hiddenFaction
            byDone = byDone + hiddenDone
        elseif IsInRange(d, level, range) then
            byLFG = byLFG + 1
        end
    end

    -- One short line each. A single sentence wrapped down past the bottom
    -- edge of the panel, and a wrapped line is exactly what you cannot budget
    -- height for.
    panel.statusDungeons:SetText(("Dungeons: %d shown"):format(shownCount))
    panel.statusLFG:SetText(byLFG > 0
        and ("%d hidden by the Group Finder filter"):format(byLFG) or "")

    local questParts = {}
    if byOtherFaction > 0 then
        table.insert(questParts, ("%d other faction"):format(byOtherFaction))
    end
    if byDone > 0 then
        table.insert(questParts, ("%d already done"):format(byDone))
    end
    panel.statusQuests:SetText(#questParts > 0
        and ("Quests hidden: %s"):format(table.concat(questParts, ", ")) or "")
end

local function RefreshGUI()
    for _, panel in ipairs(optionPanels) do
        if panel:IsShown() then RefreshPanel(panel) end
    end
end

ns.RefreshGUI = RefreshGUI

local function Checkbox(panel, globalName, label, y, onClick)
    local box = CreateFrame("CheckButton", globalName, panel, "UICheckButtonTemplate")
    box:SetPoint("TOPLEFT", 10, y)
    box:SetSize(24, 24)
    local text = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", box, "RIGHT", 2, 0)
    text:SetPoint("RIGHT", panel, "RIGHT", -10, 0)
    text:SetJustifyH("LEFT")
    text:SetText(label)
    box:SetScript("OnClick", function(self)
        onClick(self:GetChecked() and true or false)
        RefreshList()
        RefreshGUI()
    end)
    return box, text
end

-- The checkboxes, steppers and status lines, into `panel`, starting `top`
-- pixels down. `prefix` keeps the checkboxes' global names apart between
-- the two panels that carry them.
local function BuildControls(panel, prefix, top)
    panel.faction, panel.factionLabel = Checkbox(panel, prefix .. "FactionCheck",
        "Hide the other faction's quests", top,
        function(on) DungeonLevelGuideDB.hideOtherFaction = on end)

    panel.done = Checkbox(panel, prefix .. "DoneCheck", "Hide quests you have already done", top - 26,
        function(on) DungeonLevelGuideDB.hideCompleted = on end)

    panel.lfgOnly = Checkbox(panel, prefix .. "LFGOnlyCheck", "Only what the Group Finder shows (untick to widen)",
        top - 52, function(on) DungeonLevelGuideDB.lfgOnly = on end)

    -- Three identical rows: a label on the left, - and + on the right. The
    -- labels are deliberately NOT tracked for font size -- the options panel
    -- has a fixed height, so it must not grow with the setting it controls.
    local function Stepper(key, y, step, get, set)
        local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("TOPLEFT", 14, y)
        panel[key] = label

        local minus = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        minus:SetSize(24, 20)
        minus:SetText("-")
        minus:SetPoint("TOPLEFT", 200, y + 5)
        minus:SetScript("OnClick", function()
            set(get() - step)
            RefreshGUI()
        end)

        local plus = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        plus:SetSize(24, 20)
        plus:SetText("+")
        plus:SetPoint("LEFT", minus, "RIGHT", 4, 0)
        plus:SetScript("OnClick", function()
            set(get() + step)
            RefreshGUI()
        end)
    end

    Stepper("rangeLabel", top - 86, 1,
        function() return DungeonLevelGuideDB.range or DEFAULT_RANGE end,
        SetRange)
    Stepper("fontLabel", top - 110, 1, FontSize, SetFontSize)
    Stepper("alphaLabel", top - 134, 5,
        function() return (DungeonLevelGuideDB.bgAlpha or 0.75) * 100 end,
        SetBackgroundAlpha)

    local styleLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    styleLabel:SetPoint("TOPLEFT", 14, top - 160)
    styleLabel:SetText("Style")
    panel.styleDropdown = StyleDropdown(panel, 58, top - 155, function(name)
        SetStyle(name)
        RefreshGUI()
    end)

    -- Separate lines rather than one wrapping paragraph: the panel has a
    -- fixed height, so the text has to have a predictable one too.
    local statusY = top - 190
    for _, key in ipairs({ "statusDungeons", "statusLFG", "statusQuests" }) do
        local line = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        line:SetPoint("TOPLEFT", 14, statusY)
        line:SetPoint("RIGHT", panel, "RIGHT", -14, 0)
        line:SetJustifyH("LEFT")
        line:SetWordWrap(false)
        panel[key] = line
        statusY = statusY - 15
    end

    table.insert(optionPanels, panel)
    return statusY
end

local function BuildGUI()
    gui = CreateFrame("Frame", "DungeonLevelGuideConfigFrame", UIParent)
    gui:SetSize(340, 311)
    gui:SetPoint("CENTER")
    gui:SetMovable(true)
    gui:SetClampedToScreen(true)
    gui:SetFrameStrata("DIALOG")

    local guiBg = gui:CreateTexture(nil, "BACKGROUND")
    guiBg:SetAllPoints()
    guiBg:SetColorTexture(0, 0, 0, 0.82)

    local guiEdge = gui:CreateTexture(nil, "BORDER")
    guiEdge:SetPoint("TOPLEFT", -1, 1)
    guiEdge:SetPoint("BOTTOMRIGHT", 1, -1)
    guiEdge:SetColorTexture(1, 1, 1, 0.15)

    local guiBar = CreateFrame("Frame", nil, gui)
    guiBar:SetPoint("TOPLEFT")
    guiBar:SetPoint("TOPRIGHT")
    guiBar:SetHeight(24)
    guiBar:EnableMouse(true)
    guiBar:RegisterForDrag("LeftButton")
    guiBar:SetScript("OnDragStart", function() gui:StartMoving() end)
    guiBar:SetScript("OnDragStop", function() gui:StopMovingOrSizing() end)

    local guiTitle = guiBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    guiTitle:SetPoint("LEFT", 8, 0)
    guiTitle:SetText("Dungeon Level Guide options")

    local guiClose = CreateFrame("Button", nil, gui, "UIPanelCloseButton")
    guiClose:SetPoint("TOPRIGHT", -2, -2)
    guiClose:SetScript("OnClick", function() gui:Hide() end)

    BuildControls(gui, "DungeonLevelGuide", -30)

    local hint = gui:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", 14, 8)
    hint:SetText("Settings are saved per character.")

    -- A frame is shown the moment it is created, so without this the first
    -- /dlg gui builds the panel, sees it as open and closes it again. You
    -- would have to type the command twice to see anything.
    gui:Hide()
end

-- ------------------------------------------------------------
-- Options > AddOns
--
-- The same controls on a page of Blizzard's own settings window. The page is
-- registered at load but filled in the first time it is shown, when the
-- database is sure to exist. Settings is the modern API; InterfaceOptions is
-- the older one some clients still carry. Neither answering leaves /dlg gui.
-- ------------------------------------------------------------

local settingsCategory

local function BuildSettingsPage(page)
    local heading = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 16, -16)
    heading:SetText("Dungeon Level Guide")

    local statusBottom = BuildControls(page, "DungeonLevelGuideSettings", -48)

    local toggle = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    toggle:SetSize(160, 22)
    toggle:SetPoint("TOPLEFT", 14, statusBottom - 10)
    toggle:SetText("Show / hide the panel")
    toggle:SetScript("OnClick", function()
        if frame:IsShown() then frame:Hide() else frame:Show() end
    end)

    local hint = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", toggle, "BOTTOMLEFT", 0, -10)
    hint:SetText("Settings are saved per character.")
end

local function RegisterSettingsPage()
    if settingsCategory then return end
    local page = CreateFrame("Frame")
    page.name = "Dungeon Level Guide"
    page:SetScript("OnShow", function(self)
        if not self.built then
            self.built = true
            BuildSettingsPage(self)
        end
        RefreshPanel(self)
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

local function ToggleGUI()
    if not gui then BuildGUI() end
    if gui:IsShown() then
        gui:Hide()
    else
        gui:Show()
        RefreshGUI()
    end
end

-- ------------------------------------------------------------
-- Clicking a dungeon: centre the map, open the Group Finder
-- ------------------------------------------------------------

-- The Group Finder UI is load-on-demand, and until it has been loaded once
-- PVEFrame and LFGListFrame do not exist at all -- which is why the panel
-- printed "could not auto-select" and nothing opened. Load it first, and try
-- whichever of these the client happens to have.
local GROUP_FINDER_UI = {
    "Blizzard_GroupFinder",
    "Blizzard_PVEFrame",
    "Blizzard_LFGList",
    "Blizzard_GroupFinder_VanillaStyle",
    "Blizzard_LookingForGroupUI",
}

-- Forever turned out to run the vanilla-style Group Finder
-- (Blizzard_GroupFinder_VanillaStyle): LFGParentFrame exists, and none of the
-- retail frames do. The retail names stay in the list anyway -- they cost one
-- table lookup each and keep the addon working if a later build swaps back.
--
-- Top-level windows only. These are what we ask to open and what we check to
-- see whether anything opened.
local GROUP_FINDER_FRAMES = {
    "LFGParentFrame", "PVEFrame", "GroupFinderFrame", "LFGListFrame", "LFDParentFrame",
}

-- Panels that live INSIDE those windows. Listing them above broke opening the
-- Group Finder entirely: a child reports IsShown() == true whenever it has not
-- been hidden itself, parent or no parent, so LFGBrowseFrame answered "already
-- open" while LFGParentFrame was shut, and the opener returned without doing
-- anything. They are only worth reporting on, and visibility is asked for with
-- IsVisible, which is the one that accounts for the parents.
local GROUP_FINDER_PANELS = {
    "LFGBrowseFrame", "LFGListingFrame",
}

local function AddOnIsLoaded(name)
    local fn = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    if not fn then return nil end
    local ok, loaded = pcall(fn, name)
    if not ok then return nil end
    return loaded and true or false
end

local function LoadGroupFinderUI()
    local load = (C_AddOns and C_AddOns.LoadAddOn) or LoadAddOn
    if not load then return end
    for _, name in ipairs(GROUP_FINDER_UI) do
        if AddOnIsLoaded(name) == false then
            pcall(load, name)
        end
    end
end

-- The name of whichever Group Finder window is on screen, or nil. IsVisible,
-- not IsShown: the question is whether the player can see it.
local function GroupFinderIsShown()
    for _, name in ipairs(GROUP_FINDER_FRAMES) do
        local f = _G[name]
        if f and type(f.IsVisible) == "function" and f:IsVisible() then return name end
    end
    return nil
end

-- Returns a description of what worked, or nil if nothing put it on screen.
local function ShowGroupFinder()
    local already = GroupFinderIsShown()
    if already then return already .. " (already open)" end

    LoadGroupFinderUI()

    local tries = {
        { "PVEFrame_ShowFrame", "GroupFinderFrame", "LFGListFrame" },
        { "PVEFrame_ToggleFrame", "GroupFinderFrame", "LFGListFrame" },
        { "ToggleLFGListFrame" },
        { "ToggleLFGParentFrame" },
    }
    for _, try in ipairs(tries) do
        local fn = _G[try[1]]
        if type(fn) == "function" then
            pcall(fn, try[2], try[3])
            if GroupFinderIsShown() then return try[1] end
        end
    end

    -- Nothing toggled it: show the frame itself, if it exists by now.
    for _, name in ipairs(GROUP_FINDER_FRAMES) do
        local f = _G[name]
        if f and type(f.Show) == "function" then
            if ShowUIPanel then pcall(ShowUIPanel, f) else pcall(f.Show, f) end
            if GroupFinderIsShown() then return "ShowUIPanel(" .. name .. ")" end
        end
    end

    return nil
end

-- Points the open window at the dungeon's activity. The activity itself comes
-- from the same scan the [LFG] tag uses, so this no longer depends on
-- LFGListFrame existing -- it does not, in Forever, while C_LFGList does.
local function SelectActivity(d)
    EnsureActivityScan()
    local activity = ActivityFor(d)
    if not activity then return false end

    -- Retail's premade panel, when a client has it.
    if LFGListFrame then
        local applied = false
        if LFGListFrame.CategorySelection and LFGListFrame.CategorySelection.SelectCategory then
            applied = pcall(LFGListFrame.CategorySelection.SelectCategory,
                LFGListFrame.CategorySelection, activity.category) or applied
        end
        if LFGListFrame.SearchPanel and LFGListFrame.SearchPanel.SetSelectedActivity then
            applied = pcall(LFGListFrame.SearchPanel.SetSelectedActivity,
                LFGListFrame.SearchPanel, activity.id) or applied
        end
        if applied then return true end
    end

    -- Vanilla-style: ask the client to search that category and let its own
    -- window draw the result. Which frame field holds the selection is not
    -- known yet, so nothing is written into Blizzard's frames by hand.
    if _G.LFGBrowseFrame and C_LFGList and C_LFGList.Search then
        if pcall(C_LFGList.Search, activity.category) then return true end
    end

    return false
end

-- The Dungeon Finder is a different system from the premade group list, and
-- it is the one that shows a list of dungeon names. It keys on the dungeon's
-- own LFG id, which the panel already carries from the client's LFGDungeons
-- table -- no name matching needed.
local function SelectLFDDungeon(d)
    if not d.lfgID then return false end

    -- SetLFGDungeon exists in Forever but LFDParentFrame does not, so calling
    -- it points at a window that is not there: it would return "worked" and
    -- nothing would move. Only try this where there is a Dungeon Finder.
    if not (_G.LFDParentFrame or _G.LFDQueueFrame) then return false end

    local setType = _G.LFDQueueFrame_SetType
    if type(setType) == "function" and pcall(setType, d.lfgID) then
        return true
    end

    -- The older pair: tick the dungeon, point the queue at it, redraw.
    local enable = _G.LFGDungeonList_SetDungeonEnabled
    local setDungeon = _G.SetLFGDungeon
    local update = _G.LFDQueueFrame_Update
    local worked = false
    if type(enable) == "function" then
        worked = pcall(enable, d.lfgID, true) or worked
    end
    if type(setDungeon) == "function" then
        worked = pcall(setDungeon, _G.LE_LFG_CATEGORY_LFD or 1, d.lfgID) or worked
    end
    if worked and type(update) == "function" then pcall(update) end
    return worked
end

-- Opens Blizzard's Group Finder and points it at the dungeon. Opening it is
-- the part that has to work; the filtering is a bonus, so the two report
-- separately. The Dungeon Finder is tried first, because that is the tab the
-- beta actually shows, and the premade list second.
local function OpenGroupFinderFor(d)
    local how = ShowGroupFinder()
    if not how then
        print(PREFIX .. "could not open the Group Finder -- none of the usual frames answered. Run /dlg lfg and send what it prints.")
        return
    end

    ScanActivities()
    RefreshList()

    if SelectLFDDungeon(d) then return end
    if SelectActivity(d) then return end

    if ClientOffers(d) == false then
        print((PREFIX .. "Group Finder is open, but it is not offering %s right now -- the rows tagged [LFG] are the ones it lists."):format(d.name))
    else
        print((PREFIX .. "Group Finder is open, but %s could not be selected automatically -- pick it from the list. /dlg lfg prints what this client has."):format(d.name))
    end
end

-- What this client actually has, so a failure to open the Group Finder can be
-- reported instead of guessed at. Returns lines rather than printing them --
-- this goes in the copy window, because nobody should type it off the screen.
local function GroupFinderDiagnostics()
    local out = { "Group Finder, what this client has:" }
    local function add(...) table.insert(out, (("  %s"):format(...))) end

    for _, name in ipairs(GROUP_FINDER_UI) do
        local loaded = AddOnIsLoaded(name)
        add(("addon %-34s %s"):format(name,
            loaded == nil and "cannot tell" or (loaded and "loaded" or "not loaded")))
    end

    local function frameState(f)
        if not f then return "missing" end
        local shown = f.IsShown and f:IsShown()
        local visible = f.IsVisible and f:IsVisible()
        return ("exists, IsShown %s, IsVisible %s"):format(
            shown and "yes" or "no", visible and "yes" or "no")
    end

    for _, name in ipairs(GROUP_FINDER_FRAMES) do
        add(("frame %-34s %s"):format(name, frameState(_G[name])))
    end
    for _, name in ipairs(GROUP_FINDER_PANELS) do
        add(("panel %-34s %s"):format(name, frameState(_G[name])))
    end

    for _, name in ipairs({ "PVEFrame_ShowFrame", "PVEFrame_ToggleFrame",
        "ToggleLFGListFrame", "ToggleLFGParentFrame", "LFGListSearchPanel_SetCategory",
        "LFDQueueFrame_SetType", "LFDQueueFrame_Update", "SetLFGDungeon",
        "LFGDungeonList_SetDungeonEnabled", "GetLFGDungeonInfo",
        -- The vanilla-style UI, which is the one Forever has.
        "LFGBrowseFrame_DoSearch", "LFGBrowseFrame_Update", "LFGParentFrame_SetTab",
        "LFGListingFrame_SetActivity", "LFGBrowseFrameCategoryDropDown_OnClick" }) do
        add(("func  %-34s %s"):format(name, type(_G[name]) == "function" and "yes" or "no"))
    end
    add(("table %-34s %s"):format("LFGLockList",
        type(_G.LFGLockList) == "table" and "exists" or "missing"))

    if not C_LFGList then
        add("C_LFGList                                missing")
        return out
    end

    for _, name in ipairs({ "GetAvailableCategories", "GetAvailableActivities",
        "GetActivityInfoTable", "GetActivityInfo", "GetCategoryInfo", "Search" }) do
        add(("C_LFGList.%-29s %s"):format(name,
            type(C_LFGList[name]) == "function" and "yes" or "no"))
    end

    -- The activities themselves: this is the list Blizzard's own window is
    -- built from, so it is the one to compare the panel against.
    local ok, categories = pcall(C_LFGList.GetAvailableCategories)
    if not ok then
        add("categories                               error")
        return out
    end

    add(("categories returned                      %d"):format(#(categories or {})))
    for _, categoryID in ipairs(categories or {}) do
        local label = tostring(categoryID)
        if C_LFGList.GetCategoryInfo then
            local gotInfo, name = pcall(C_LFGList.GetCategoryInfo, categoryID)
            if gotInfo and name then label = ("%s (%s)"):format(categoryID, tostring(name)) end
        end

        local gotList, activities = pcall(C_LFGList.GetAvailableActivities, categoryID)
        activities = (gotList and activities) or {}
        add(("category %-14s %d activities"):format(label, #activities))
        for _, activityID in ipairs(activities) do
            local name, low, high = ActivityDetails(activityID)
            add(("    %-8s %s (%s-%s)"):format(activityID, tostring(name),
                tostring(low or "?"), tostring(high or "?")))
        end
    end

    return out
end

-- What the client says about each dungeon the panel is currently showing --
-- the direct answer to why its list and the Group Finder's differ.
local function ClientDungeonList(level, range)
    local out = {
        ("what the client's own Group Finder says, level %d +/- %d:"):format(level, range),
    }

    if type(GetLFGDungeonInfo) ~= "function" then
        table.insert(out, "  GetLFGDungeonInfo does not exist in this client -- it cannot be asked.")
        return out
    end

    EnsureActivityScan()

    local answered = 0
    for _, d in ipairs(DUNGEONS) do
        if IsInRange(d, level, range) then
            local name, minLevel, maxLevel = ClientLFGInfo(d)
            local offers = ClientOffers(d)
            local activity = ActivityFor(d)
            local verdict = offers == nil and "no activity list"
                or (offers and "IN THE LIST" or (activity and "listed, outside its range" or "not listed"))
            if activity then
                verdict = ("%s, finder range %s-%s"):format(verdict,
                    tostring(activity.minLevel or "?"), tostring(activity.maxLevel or "?"))
            end
            if not name then
                table.insert(out, ("  %-26s lfgID %-6s no answer      %s"):format(
                    d.name, tostring(d.lfgID), verdict))
            else
                answered = answered + 1
                table.insert(out, ("  %-26s lfgID %-6s %-24s client level %s-%s  %s"):format(
                    d.name, tostring(d.lfgID), name,
                    tostring(minLevel), tostring(maxLevel), verdict))
            end
        end
    end

    if answered == 0 then
        table.insert(out, "  Nothing answered, so the [LFG] tag and /dlg lfgonly stay quiet.")
    end

    return out
end

-- The whole report, ready to be copied out in one piece.
local function ShowGroupFinderReport()
    local level = UnitLevel("player") or 1
    local range = DungeonLevelGuideDB.range or DEFAULT_RANGE

    local lines = {
        ("DungeonLevelGuide -- Group Finder report, %s level %s, client build %s"):format(
            UnitClass and select(1, UnitClass("player")) or "?",
            tostring(level),
            (GetBuildInfo and select(2, GetBuildInfo())) or "?"),
        "",
    }
    for _, line in ipairs(GroupFinderDiagnostics()) do table.insert(lines, line) end
    table.insert(lines, "")
    for _, line in ipairs(ClientDungeonList(level, range)) do table.insert(lines, line) end

    if ShowCopyText("Group Finder report", lines) then
        print(PREFIX .. "report is in the copy window -- Ctrl+C takes it.")
    end
end

function ns.OnDungeonClicked(d)
    local coords = DungeonLevelGuideDB.dungeonCoords[d.name]
    if coords and coords.mapID and WorldMapFrame then
        OpenMapAt(coords.mapID)
    end

    OpenGroupFinderFor(d)
end

-- Clicking a quest marks the place you pick it up -- for a chain quest the
-- chain's first giver, not this quest's own.
function ns.OnQuestClicked(q)
    local mapID, x, y, label = PickupLocation(q)
    if not (mapID and x and y) then
        if q.inside then
            local how = (q.fromObject and ", off an object")
                or (q.fromDrop and ", off a mob drop") or ""
            print((PREFIX .. "%s is picked up inside the dungeon%s -- nothing to mark."):format(
                q.name, how))
        else
            print((PREFIX .. "no coordinate for where %s is picked up."):format(q.name))
        end
        return
    end

    marker = { mapID = mapID, x = x, y = y, label = label }
    SetBlizzardWaypoint(mapID, x, y)
    OpenMapAt(mapID)
    UpdatePin()

    local where = q.chain and q.chainWhere or q.where
    print((PREFIX .. "marked %s%s (%d, %d) -- right-click the row to remove it."):format(
        label or q.name, where and (", " .. where) or "", x, y))
end

ns.ClearMarker = ClearMarker

-- ------------------------------------------------------------
-- Drag / resize
-- ------------------------------------------------------------

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
    SavePosition()
end)

resizeGrip:SetScript("OnMouseDown", function()
    Dock.BeginSize(frame, resizeGrip)
end)
resizeGrip:SetScript("OnMouseUp", function()
    Dock.EndSize(resizeGrip)
    if frame.SetUserPlaced then frame:SetUserPlaced(true) end
    SaveSize()
    RefreshList()
end)

frame:SetScript("OnSizeChanged", function()
    RefreshList()
end)

-- ------------------------------------------------------------
-- Events
-- ------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
local questsDirty = false
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

-- Where the mob levels come from, and the unit each one is about. A nameplate
-- names its unit in the event itself.
local MOB_EVENTS = {
    PLAYER_TARGET_CHANGED = "target",
    UPDATE_MOUSEOVER_UNIT = "mouseover",
    NAME_PLATE_UNIT_ADDED = false,
}

-- The Group Finder's answers arrive after login, so the [LFG] tag has to be
-- redrawn when they do. Whether these events exist here is unknown, and
-- RegisterEvent throws on an unknown one -- so one pcall each, not a loop
-- around the lot, or one missing name would take the others with it.
local LFG_EVENTS = {
    LFG_LOCK_INFO_RECEIVED = true,
    LFG_UPDATE = true,
    LFG_LIST_AVAILABILITY_UPDATE = true,
    LFG_LIST_ACTIVE_ENTRY_UPDATE = true,
}

-- Quest status is read live for the tooltip but drawn once into the rows, so
-- without these the row colours went stale the moment you picked a quest up:
-- hovering told the truth while the list underneath it did not.
local QUEST_EVENTS = {
    QUEST_LOG_UPDATE = true,
    QUEST_ACCEPTED = true,
    QUEST_REMOVED = true,
    QUEST_TURNED_IN = true,
}

for event in pairs(LFG_EVENTS) do
    pcall(eventFrame.RegisterEvent, eventFrame, event)
end
for event in pairs(QUEST_EVENTS) do
    pcall(eventFrame.RegisterEvent, eventFrame, event)
end
for event in pairs(MOB_EVENTS) do
    pcall(eventFrame.RegisterEvent, eventFrame, event)
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == ADDON_NAME then
            EnsureDB()
            RestoreFrame()
            ApplyLook()
            RegisterSettingsPage()
        end
    elseif event == "PLAYER_LOGOUT" then
        -- A panel moves when the one it hangs from is dragged or resized.
        if DungeonLevelGuideDB then SavePosition() end
    elseif event == "PLAYER_LEVEL_UP" then
        local newLevel = ...
        RefreshList(tonumber(newLevel))
    elseif event == "PLAYER_ENTERING_WORLD" then
        ScanActivities()
        CheckDungeonProgress()
        RefreshList()
        Dock.RedockSoon(frame)
    elseif LFG_EVENTS[event] then
        ScanActivities()
        RefreshList()
    elseif MOB_EVENTS[event] ~= nil then
        -- Redrawn the same throttled way as quests: a pull of nameplates
        -- arrives all at once.
        if RecordMobLevel(MOB_EVENTS[event] or ...) then questsDirty = true end
    elseif QUEST_EVENTS[event] then
        -- QUEST_LOG_UPDATE fires in bursts, several times for one accepted
        -- quest, so this only notes that a redraw is due. The OnUpdate below
        -- does it, once.
        questsDirty = true
    end
end)

-- The marker has to follow the map: the canvas moves and resizes as you pan
-- and zoom, and switching zones has to hide it. There is no event for that,
-- so it is a slow poll, and only while something is actually marked.
local sincePinUpdate, sinceQuestCheck = 0, 0
eventFrame:SetScript("OnUpdate", function(_, elapsed)
    if questsDirty then
        sinceQuestCheck = sinceQuestCheck + elapsed
        if sinceQuestCheck >= 0.2 then
            sinceQuestCheck = 0
            questsDirty = false
            LearnFromQuestTexts()
            CheckDungeonProgress()
            RefreshList()
        end
    end

    if not marker then return end
    sincePinUpdate = sincePinUpdate + elapsed
    if sincePinUpdate < 0.1 then return end
    sincePinUpdate = 0
    UpdatePin()
end)

-- ------------------------------------------------------------
-- Slash commands
-- ------------------------------------------------------------

SLASH_DUNGEONLEVELGUIDE1 = "/dlg"
SlashCmdList["DUNGEONLEVELGUIDE"] = function(msg)
    msg = (msg or ""):lower():trim()

    if msg == "" or msg == "toggle" then
        if frame:IsShown() then frame:Hide() else frame:Show() end

    elseif msg:match("^range") then
        local n = tonumber(msg:match("range%s+(%d+)"))
        if n then
            SetRange(n)
            RefreshGUI()
            print((PREFIX .. "range set to +/- %d."):format(n))
        else
            print(PREFIX .. "usage: /dlg range <number>")
        end

    elseif msg:match("^font") then
        local n = tonumber(msg:match("font%s+(%d+)"))
        if n then
            print((PREFIX .. "font size %d."):format(SetFontSize(n)))
            RefreshGUI()
        else
            print((PREFIX .. "usage: /dlg font <%d-%d>, currently %d."):format(
                MIN_FONT_SIZE, MAX_FONT_SIZE, FontSize()))
        end

    elseif msg:match("^alpha") then
        local n = tonumber(msg:match("alpha%s+(%d+)"))
        if n then
            print((PREFIX .. "background %d%% opaque."):format(SetBackgroundAlpha(n)))
            RefreshGUI()
        else
            print((PREFIX .. "usage: /dlg alpha <0-100>, currently %d."):format(
                math.floor((DungeonLevelGuideDB.bgAlpha or 0.75) * 100 + 0.5)))
        end

    elseif msg:match("^style") then
        local name = msg:match("^style%s+(%a+)")
        if name and SetStyle(name) then
            RefreshGUI()
            print((PREFIX .. "style: %s."):format(STYLES[name].label))
        else
            print((PREFIX .. "usage: /dlg style %s (now: %s)"):format(
                table.concat(STYLE_ORDER, "|"), DungeonLevelGuideDB.style or DEFAULT_STYLE))
        end

    elseif msg == "layout" then
        print(PREFIX .. LayoutReport() .. ".")

    elseif msg == "gui" then
        ToggleGUI()

    elseif msg == "reset" then
        DungeonLevelGuideDB.point = nil
        DungeonLevelGuideDB.size = { width = DEFAULTS.size.width, height = DEFAULTS.size.height }
        RestoreFrame()
        print(PREFIX .. "position and size reset.")

    elseif msg == "faction" then
        DungeonLevelGuideDB.hideOtherFaction = not DungeonLevelGuideDB.hideOtherFaction
        RefreshList()
        RefreshGUI()
        local mine = PlayerFaction()
        if DungeonLevelGuideDB.hideOtherFaction then
            print((PREFIX .. "hiding quests the other faction owns%s."):format(
                mine and (" -- you are " .. (mine == "A" and "Alliance" or "Horde")) or ""))
        else
            print(PREFIX .. "showing every quest, both factions.")
        end

    elseif msg == "done" then
        DungeonLevelGuideDB.hideCompleted = not DungeonLevelGuideDB.hideCompleted
        RefreshList()
        RefreshGUI()
        print(PREFIX .. (DungeonLevelGuideDB.hideCompleted
            and "hiding quests you have already done."
            or "showing quests you have already done."))

    elseif msg == "clear" then
        ClearMarker()
        print(PREFIX .. "map marker removed.")

    elseif msg == "lfg" then
        ShowGroupFinderReport()

    elseif msg == "levels" then
        local lines = MobLevelReport()
        lastReport = table.concat(lines, "\n")
        for _, line in ipairs(lines) do print(PREFIX .. line) end

    elseif msg == "learned" then
        local lines = LearnedReport()
        lastReport = table.concat(lines, "\n")
        for _, line in ipairs(lines) do print(PREFIX .. line) end

    elseif msg == "levels reset" then
        DungeonLevelGuideDB.mobLevels = {}
        RefreshList()
        print(PREFIX .. "this session's mob levels cleared. Harvested ones stay -- remove them from MeasuredLevels.lua.")

    elseif msg == "copy" then
        if lastReport then
            ShowCopyText("Last report", { lastReport })
        else
            print(PREFIX .. "nothing to copy yet -- run /dlg lfg first.")
        end

    elseif msg == "lfgonly" or msg == "widen" then
        DungeonLevelGuideDB.lfgOnly = not DungeonLevelGuideDB.lfgOnly
        RefreshList()
        RefreshGUI()
        if not DungeonLevelGuideDB.lfgOnly then
            print((PREFIX .. "widened: the Group Finder's dungeons plus everything within +/- %d."):format(
                DungeonLevelGuideDB.range or DEFAULT_RANGE))
        else
            local answered = false
            for _, d in ipairs(DUNGEONS) do
                if ClientOffers(d) ~= nil then answered = true end
            end
            if answered then
                print(PREFIX .. "showing only what the Group Finder offers you.")
            else
                print(PREFIX .. "this client answers nothing about the Group Finder, so the list is unchanged -- see /dlg lfg.")
            end
        end

    else
        print("|cff00ff00DungeonLevelGuide|r commands:")
        print("  /dlg              - show or hide the panel")
        print("  /dlg gui          - open the options panel, which shows every filter at once")
        print("  /dlg range <n>    - set the +/- level margin (default 5)")
        print("  /dlg faction      - show or hide the other faction's quests")
        print("  /dlg widen        - add the +/- margin to what the Group Finder shows, or go back")
        print("  /dlg done         - show or hide quests you have already done")
        print("  /dlg clear        - remove the map marker")
        print("  /dlg lfg          - report what this client has of the Group Finder API")
        print("  /dlg levels       - mob levels measured inside dungeons (/dlg levels reset clears them)")
        print("  /dlg learned      - dungeon quests learned in play")
        print("  /dlg copy         - reopen the last report in a window you can copy from")
        print("  /dlg font <n>     - text size, 6-24")
        print("  /dlg alpha <n>    - how opaque the background is, 0-100")
        print("  /dlg style <name> - blizzard, flat, warm, elvui, details, pfui or minimal")
        print("  /dlg layout       - what the panel measured the text to, if the top row looks wrong")
        print("  /dlg reset        - reset position and size")
    end
end
