-- HealerMana -- shows the mana of the healers in your group or raid, so the
-- tank or raid leader can tell whether to wait before the next pull.
--
-- Only members who picked the healer role count, each with a bar of their
-- own. Forever hands out mana -- others' and your own -- as secret values,
-- which an addon may show on a bar or in a text but not compare or add up, so
-- there is no average. The bar's colour comes from the client's own colour
-- curve for the same reason.

local ADDON_NAME, ns = ...

local DEFAULTS = {
    enabled = true,
    locked = false,
    bgAlpha = 0.75,
    textSize = 100, -- percent of the style's own size
    growUp = false, -- more healers make the frame taller upwards rather than downwards
    -- width and height stay nil until the frame is resized
    point = "TOP", relativePoint = "TOP", x = 0, y = -120,
}
local MANA = 0 -- Enum.PowerType.Mana
local REFRESH_INTERVAL = 0.25
local LOW, MID = 30, 60 -- percent: below LOW is red, below MID yellow
local PADDING = 8
local MIN_SIZE, MAX_SIZE = 50, 200 -- text size, percent
local MAX_WIDTH, MAX_HEIGHT = 1200, 400
local ROW_GAP = 2
local BAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
local MANA_BLUE = "0070de" -- a secret percentage without the client's colour curves

-- ------------------------------------------------------------
-- Styles
--
-- The same seven looks as DungeonLevelGuide, TurnInQueue and
-- ZoneLevelGuide, with the table copied as is from TurnInQueue so the
-- copies stay easy to compare. This frame only uses the fonts, the
-- background, the edges and a few of the colours.
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
    return STYLES[HealerManaDB and HealerManaDB.style] or STYLES[DEFAULT_STYLE]
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

local function Msg(fmt, ...)
    print("|cff7fbf7fHealerMana|r: " .. string.format(fmt, ...))
end

-- The colours the text needs, as |cff codes: the style's own, or for
-- "blizzard" the plain ones the frame had before styles.
local function Colors()
    local style = Style()
    if not Styled() then
        return { low = "ff4040", mid = "ffd040", high = "40ff40", dim = "909090", alert = "ff8080" }
    end
    local d = style.difficulty
    return { low = d.impossible, mid = d.difficult, high = d.standard, dim = style.dim,
        alert = d.verydifficult, text = style.text }
end

local function GroupUnits()
    local units = {}
    if IsInRaid and IsInRaid() then
        for i = 1, GetNumGroupMembers() do table.insert(units, "raid" .. i) end
    elseif IsInGroup and IsInGroup() then
        table.insert(units, "player")
        for i = 1, GetNumGroupMembers() - 1 do table.insert(units, "party" .. i) end
    end
    return units
end

-- An error is said once in the chat, not four times a second; the frame
-- goes on with what it could read.
local reported = {}
local function Report(err)
    err = tostring(err)
    if reported[err] then return end
    reported[err] = true
    print("|cff33ff99HealerMana|r: could not read the group: " .. err)
end
ns.Report = Report

-- A member with the healer role as { name, unit, percent, secret, dead,
-- offline }, or nil. percent is 0-100, and nil when unknown, e.g. a druid in
-- a shapeshift form on a client that still hands out plain numbers.
local function ReadHealer(unit)
    if not (UnitExists(unit) and UnitGroupRolesAssigned(unit) == "HEALER") then return nil end
    local h = { name = UnitName(unit) or "?", unit = unit }
    if UnitIsConnected and not UnitIsConnected(unit) then
        h.offline = true
    elseif UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit) then
        h.dead = true
    elseif UnitPowerPercent and CurveConstants and CurveConstants.ScaleTo100 then
        h.percent = UnitPowerPercent(unit, MANA, false, CurveConstants.ScaleTo100)
        h.secret = issecretvalue ~= nil and issecretvalue(h.percent) or false
    else
        local max = UnitPowerMax(unit, MANA) or 0
        if max > 0 then h.percent = 100 * (UnitPower(unit, MANA) or 0) / max end
    end
    return h
end

-- Every member with the healer role. One the client will not answer for
-- shows as "?" rather than leaving the frame empty.
local function Healers()
    if ns.testHealers then return ns.testHealers() end
    local healers = {}
    if not UnitGroupRolesAssigned then return healers end
    for _, unit in ipairs(GroupUnits()) do
        local ok, h = pcall(ReadHealer, unit)
        if not ok then
            Report(h)
            h = { name = (pcall(UnitName, unit) and UnitName(unit)) or unit }
        end
        if h then table.insert(healers, h) end
    end
    return healers
end
ns.Healers = Healers

local function Paint(hex, text)
    return "|cff" .. hex .. text .. "|r"
end

-- For a plain number: red below LOW, yellow below MID, else green.
local function LevelHex(percent)
    local c = Colors()
    return percent < LOW and c.low or percent < MID and c.mid or c.high
end

-- The same three colours for a secret percentage, through the client's own
-- colour curve, which may look at it where the addon may not. Nil without
-- curves. Rebuilt when the style changes.
local manaCurve
local function CurveColor(unit)
    if manaCurve == nil then
        local ok, curve = pcall(function()
            local c, curve = Colors(), C_CurveUtil.CreateColorCurve()
            if curve.SetType and Enum and Enum.LuaCurveType and Enum.LuaCurveType.Step then
                curve:SetType(Enum.LuaCurveType.Step)
            end
            curve:AddPoint(0, CreateColor(RGB(c.low)))
            curve:AddPoint(LOW / 100, CreateColor(RGB(c.mid)))
            curve:AddPoint(MID / 100, CreateColor(RGB(c.high)))
            return curve
        end)
        manaCurve = ok and curve or false
    end
    if not manaCurve then return nil end
    local ok, color = pcall(UnitPowerPercent, unit, MANA, false, manaCurve)
    return ok and color or nil
end

local frame = CreateFrame("Frame", "HealerManaFrame", UIParent)
frame:SetSize(200, 24)
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:SetFrameStrata("MEDIUM")
frame:Hide()

local background = frame:CreateTexture(nil, "BACKGROUND")
background:SetAllPoints()
local edges = MakeEdges(frame, 0)
local outline = MakeEdges(frame, 3)
local accentLine = frame:CreateTexture(nil, "ARTWORK")
accentLine:SetPoint("TOPLEFT")
accentLine:SetPoint("TOPRIGHT")
accentLine:SetHeight(2)

-- Shown instead of the bars when no one has the healer role.
local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
label:SetPoint("CENTER")
label:SetJustifyH("CENTER")
local baseFile, baseSize, baseFlags = label:GetFont()
ns.frame, ns.label, ns.background = frame, label, background

-- One bar per healer, made as they are needed: the name on the left, the
-- mana on the right.
local rows = {}
ns.rows = rows
local rowCount = 1

-- The frame keeps one width, so it does not jump as the mana changes. The
-- smallest it can be is measured on these in the style's font, and only grows
-- if a name turns out wider still. A secret percentage cannot be measured,
-- so the widest one stands in for it.
local ruler = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
ruler:Hide()
local WIDEST = {
    "Healer mana: no healer role",
    "Wwwwwwwwwwww  100%",
}
local textWidth, textHeight, valueWidth = 0, 0, 0

local function Measure()
    textWidth, textHeight = 0, 0
    for _, text in ipairs(WIDEST) do
        ruler:SetText(text)
        textWidth = math.max(textWidth, ruler:GetStringWidth() or 0)
        textHeight = math.max(textHeight, ruler:GetStringHeight() or 0)
    end
    ruler:SetText("100%")
    valueWidth = ruler:GetStringWidth() or 0
end

-- The style's font when it loads, else the client's: a font file the client
-- cannot read makes SetFont answer false rather than throw.
local function StyleText(text)
    local style = Style()
    local scale = (HealerManaDB.textSize or 100) / 100
    local size = ((baseSize or 12) + (style.sizeBoost or 0)) * scale
    local ok, set = false, false
    if style.body then ok, set = pcall(text.SetFont, text, FONT_DIR .. style.body, size, baseFlags or "") end
    if not ok or set == false then pcall(text.SetFont, text, baseFile, (baseSize or 12) * scale, baseFlags) end
    if style.text then text:SetTextColor(RGB(style.text)) else text:SetTextColor(1, 1, 1) end
end

local function StyleRow(row)
    local style = Style()
    StyleText(row.name)
    StyleText(row.value)
    local r, g, b = 0.1, 0.1, 0.1
    if style.xpTrack then r, g, b = RGB(style.xpTrack) end
    row.track:SetColorTexture(r, g, b, 0.9)
end

local function Row(i)
    if rows[i] then return rows[i] end
    local row = CreateFrame("StatusBar", nil, frame)
    row:SetStatusBarTexture(BAR_TEXTURE)
    row:SetMinMaxValues(0, 100)
    row.track = row:CreateTexture(nil, "BACKGROUND")
    row.track:SetAllPoints()
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.name:SetPoint("LEFT", 4, 0)
    row.name:SetJustifyH("LEFT")
    row.value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.value:SetPoint("RIGHT", -4, 0)
    row.value:SetJustifyH("RIGHT")
    rows[i] = row
    StyleRow(row)
    return row
end

local function RowHeight()
    return textHeight + 4
end

-- Top down in the group's order, whichever way the frame grows: that is
-- only which edge of it stays put.
local function Layout()
    for i, row in ipairs(rows) do
        local y = -(PADDING / 2 + (i - 1) * (RowHeight() + ROW_GAP))
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, y)
        row:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, y)
        row:SetHeight(RowHeight())
    end
end

local function ApplyStyle()
    local style = Style()
    local r, g, b = 0, 0, 0
    if Styled() then r, g, b = RGB(style.bg) end
    background:SetColorTexture(r, g, b, HealerManaDB.bgAlpha * (style.bgScale or 1))
    PaintEdges(edges, style.edge)
    PaintEdges(outline, style.outline)
    if style.accentLine then
        accentLine:SetColorTexture(RGB(style.accentLine))
        accentLine:Show()
    else
        accentLine:Hide()
    end
    StyleText(label)
    StyleText(ruler)
    for _, row in ipairs(rows) do StyleRow(row) end
    manaCurve = nil
    Measure()
end

local function Place()
    local db = HealerManaDB
    frame:ClearAllPoints()
    frame:SetPoint(db.point, UIParent, db.relativePoint, db.x, db.y)
end

-- Top left against the bottom left of the screen, so a resize grows the frame
-- right and down from where it stands; growing upwards, its bottom left.
local function SavePosition()
    local db = HealerManaDB
    local left = frame:GetLeft()
    local edge = db.growUp and frame:GetBottom() or frame:GetTop()
    if not (left and edge) then return end
    db.point, db.relativePoint, db.x, db.y = db.growUp and "BOTTOMLEFT" or "TOPLEFT", "BOTTOMLEFT", left, edge
end

-- Changing the direction keeps the frame where it stands.
local function SetGrowUp(up)
    HealerManaDB.growUp = up and true or false
    SavePosition()
    Place()
end

-- The text, or the bars, are the smallest the frame can be.
local function MinSize()
    return textWidth + 2 * PADDING, rowCount * RowHeight() + (rowCount - 1) * ROW_GAP + PADDING
end

local function ApplySize()
    local minW, minH = MinSize()
    frame:SetSize(math.max(minW, HealerManaDB.width or 0), math.max(minH, HealerManaDB.height or 0))
end

local resizeGrip = CreateFrame("Button", nil, frame)
resizeGrip:SetSize(12, 12)
resizeGrip:EnableMouse(true)
resizeGrip.tex = resizeGrip:CreateTexture(nil, "OVERLAY")
resizeGrip.tex:SetAllPoints()
resizeGrip.tex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
ns.resizeGrip = resizeGrip

-- In the corner the frame grows towards.
local function PlaceGrip()
    resizeGrip:ClearAllPoints()
    if HealerManaDB.growUp then
        resizeGrip:SetPoint("TOPRIGHT", -1, -1)
    else
        resizeGrip:SetPoint("BOTTOMRIGHT", -1, 1)
    end
end

-- Sized by hand from the cursor, as in TurnInQueue, rather than with
-- StartSizing, whose bounds API differs between clients.
resizeGrip:SetScript("OnMouseDown", function()
    if HealerManaDB.locked then return end
    SavePosition()
    Place()
    local scale = frame:GetEffectiveScale()
    local x0, y0 = GetCursorPosition()
    local w0, h0 = frame:GetWidth(), frame:GetHeight()
    resizeGrip:SetScript("OnUpdate", function()
        local x, y = GetCursorPosition()
        HealerManaDB.width = math.min(MAX_WIDTH, w0 + (x - x0) / scale)
        local dy = (y - y0) / scale
        HealerManaDB.height = math.min(MAX_HEIGHT, h0 + (HealerManaDB.growUp and dy or -dy))
        ApplySize()
    end)
end)
resizeGrip:SetScript("OnMouseUp", function()
    resizeGrip:SetScript("OnUpdate", nil)
    -- What it ended up as: the cursor may have gone past the text's size.
    HealerManaDB.width, HealerManaDB.height = frame:GetWidth(), frame:GetHeight()
end)

-- One healer's bar. A secret percentage goes straight to the bar and the
-- text, which may show it; only a plain one is looked at here.
local function PaintRow(row, h)
    local c = Colors()
    row:Show()
    row.name:SetText(h.name)
    if h.offline or h.dead or h.percent == nil then
        row:SetValue(0)
        row.value:SetText(h.offline and Paint(c.dim, "offline") or h.dead and Paint(c.alert, "dead")
            or Paint(c.dim, "?"))
        return
    end
    row:SetValue(h.percent)
    row.value:SetFormattedText("%.0f%%", h.percent)
    local color = h.secret and h.unit and CurveColor(h.unit)
    if color then
        row:SetStatusBarColor(color:GetRGB())
    elseif h.secret then
        row:SetStatusBarColor(RGB(MANA_BLUE))
    else
        row:SetStatusBarColor(RGB(LevelHex(h.percent)))
    end
end

-- What the bars look like in a group, for placing the frame outside one.
local SAMPLE = { { name = "Healer", percent = 80 }, { name = "Healer", percent = 45 } }

-- Unlocked, the frame also shows outside a group, so it can be put in place,
-- looking as it does in one so it can be sized to that. How to lock it is in
-- the tooltip, not the text, which would make it wider than it needs to be.
local function Refresh()
    if not HealerManaDB then return end
    local inGroup = (IsInGroup and IsInGroup()) or ns.testHealers ~= nil
    local show = HealerManaDB.enabled and (inGroup or not HealerManaDB.locked)
    frame:SetShown(show)
    if not show then return end
    resizeGrip:SetShown(not HealerManaDB.locked)
    PlaceGrip()
    local healers = SAMPLE
    if inGroup then
        local ok, found = pcall(Healers)
        if not ok then Report(found) end
        healers = ok and found or {}
    end
    if #healers == 0 then
        label:SetText(Paint(Colors().dim, "Healer mana: no healer role"))
        label:Show()
        textWidth = math.max(textWidth, label:GetStringWidth() or 0)
    else
        label:Hide()
    end
    for i, h in ipairs(healers) do
        local row = Row(i)
        local ok, err = pcall(PaintRow, row, h)
        if not ok then Report(err) end
        textWidth = math.max(textWidth, (row.name:GetStringWidth() or 0) + valueWidth + 3 * PADDING)
    end
    for i = #healers + 1, #rows do rows[i]:Hide() end
    rowCount = math.max(1, #healers)
    Layout()
    ApplySize()
end
ns.Refresh = Refresh

-- nil for a name that is not a style.
local function SetStyle(name)
    if not STYLES[name] then return nil end
    HealerManaDB.style = name
    ApplyStyle()
    Refresh()
    return name
end

-- `percent` of the style's own size, clamped; nil for no number.
local function SetTextSize(percent)
    percent = tonumber(percent)
    if not percent then return nil end
    percent = math.floor(math.max(MIN_SIZE, math.min(MAX_SIZE, percent)) + 0.5)
    HealerManaDB.textSize = percent
    ApplyStyle()
    Refresh()
    return percent
end

frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function()
    if not HealerManaDB.locked then frame:StartMoving() end
end)
frame:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    SavePosition()
end)

-- The bars name every healer already; unlocked, the tooltip says how to
-- place the frame.
frame:SetScript("OnEnter", function()
    if HealerManaDB.locked then return end
    GameTooltip:SetOwner(frame, "ANCHOR_BOTTOM")
    GameTooltip:AddLine("Drag to move, drag the corner to resize.", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("/hm lock when done; it then only shows in a group.", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)
frame:SetScript("OnLeave", function() GameTooltip:Hide() end)

local sinceRefresh = 0
frame:SetScript("OnUpdate", function(_, elapsed)
    sinceRefresh = sinceRefresh + elapsed
    if sinceRefresh < REFRESH_INTERVAL then return end
    sinceRefresh = 0
    Refresh()
end)

-- ------------------------------------------------------------
-- Options > AddOns
--
-- Built and registered when the addon loads, as in the other addons: the
-- page is hidden before it is registered, or the panel's first showing is
-- no change and OnShow never fills it in.
-- ------------------------------------------------------------

local function BuildSettingsPage(page)
    local heading = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 16, -16)
    heading:SetText("Healer Mana")

    local boxes = {}
    local function Checkbox(key, text, y, onClick)
        local box = CreateFrame("CheckButton", "HealerManaSettings" .. key .. "Check", page,
            "UICheckButtonTemplate")
        box:SetPoint("TOPLEFT", 10, y)
        box:SetSize(24, 24)
        local caption = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        caption:SetPoint("LEFT", box, "RIGHT", 2, 0)
        caption:SetText(text)
        box:SetScript("OnClick", function(self)
            HealerManaDB[key] = self:GetChecked() and true or false
            if onClick then onClick() end
            Refresh()
        end)
        boxes[key] = box
    end

    Checkbox("enabled", "Show healer mana", -48)
    Checkbox("locked", "Lock in place (then it only shows in a group)", -74)
    Checkbox("growUp", "Grow upwards with more healers (else downwards)", -100, function()
        SetGrowUp(HealerManaDB.growUp)
    end)

    local styleLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    styleLabel:SetPoint("TOPLEFT", 14, -138)
    styleLabel:SetText("Style")
    page.styleDropdown = StyleDropdown(page, 58, -133, function(name)
        SetStyle(name)
        page.refresh()
    end)

    -- OptionsSliderTemplate names its labels $parentLow/$parentHigh/$parentText;
    -- newer clients also hand them out as .Low/.High/.Text.
    local sliderName = "HealerManaTextSizeSlider"
    local slider = CreateFrame("Slider", sliderName, page, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 18, -186)
    slider:SetWidth(200)
    slider:SetMinMaxValues(MIN_SIZE, MAX_SIZE)
    slider:SetValueStep(10)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    local low = slider.Low or _G[sliderName .. "Low"]
    local high = slider.High or _G[sliderName .. "High"]
    slider.label = slider.Text or _G[sliderName .. "Text"]
    if low then low:SetText(MIN_SIZE .. "%") end
    if high then high:SetText(MAX_SIZE .. "%") end
    -- Setting the value from refresh fires this too; a value that already
    -- matches the setting is left alone.
    slider:SetScript("OnValueChanged", function(_, value)
        local percent = math.floor(value + 0.5)
        if percent ~= HealerManaDB.textSize then SetTextSize(percent) end
        if slider.label then slider.label:SetText(("Text size: %d%%"):format(HealerManaDB.textSize)) end
    end)
    page.textSizeSlider = slider

    local hint = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 14, -226)
    hint:SetText("Unlocked, drag the corner to resize. Settings are saved per character.")

    function page.refresh()
        for key, box in pairs(boxes) do box:SetChecked(HealerManaDB[key] and true or false) end
        page.styleDropdown.Refresh(HealerManaDB.style)
        slider:SetValue(HealerManaDB.textSize)
        if slider.label then slider.label:SetText(("Text size: %d%%"):format(HealerManaDB.textSize)) end
    end
end

local settingsRegistered = false
local function RegisterSettingsPage()
    if settingsRegistered then return end
    settingsRegistered = true
    local page = CreateFrame("Frame")
    page:Hide()
    page.name = "Healer Mana"
    BuildSettingsPage(page)
    page:SetScript("OnShow", function(self) self.refresh() end)
    ns.settingsPage = page

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, page, page.name)
        if ok and category then
            pcall(Settings.RegisterAddOnCategory, category)
            return
        end
    end
    if InterfaceOptions_AddCategory then pcall(InterfaceOptions_AddCategory, page) end
end

local function Help()
    Msg("commands:")
    print("  /hm on | off       -- show or hide the frame")
    print("  /hm unlock         -- show the frame outside a group so it can be dragged")
    print("  /hm lock           -- fix it in place; it then only shows in a group")
    print("  /hm reset          -- move it back to the top of the screen, at its smallest")
    print("  /hm grow up | down -- which way more healers make the frame grow")
    print("  /hm style <name>   -- " .. table.concat(STYLE_ORDER, ", "))
    print(("  /hm size <%d-%d>   -- text size in percent"):format(MIN_SIZE, MAX_SIZE))
    if ns.ToggleTest then
        print("  /hm test [1-5]     -- fake healers with draining mana, to try it solo")
        print("  /hm test dead | offline -- toggle the last fake healer's state")
    end
end

SLASH_HEALERMANA1 = "/healermana"
SLASH_HEALERMANA2 = "/hm"

SlashCmdList.HEALERMANA = function(input)
    local cmd, arg = string.match(input or "", "^%s*(%S*)%s*(%S*)")
    cmd, arg = string.lower(cmd or ""), string.lower(arg or "")
    local db = HealerManaDB
    if cmd == "on" then
        db.enabled = true
        Msg("on.")
    elseif cmd == "off" then
        db.enabled = false
        Msg("off.")
    elseif cmd == "lock" then
        db.locked = true
        Msg("locked.")
    elseif cmd == "unlock" then
        db.locked = false
        db.enabled = true
        Msg("unlocked -- drag the frame, then /hm lock.")
    elseif cmd == "reset" then
        for _, k in ipairs({ "point", "relativePoint", "x", "y" }) do db[k] = DEFAULTS[k] end
        db.width, db.height = nil, nil
        ApplySize()
        Place()
        -- Growing upwards, it is held by its bottom edge from here on.
        SavePosition()
        Place()
        Msg("position and size reset.")
    elseif cmd == "grow" and (arg == "up" or arg == "down") then
        SetGrowUp(arg == "up")
        Msg("grows %s.", arg == "up" and "upwards" or "downwards")
    elseif cmd == "grow" then
        Msg("grows %s; /hm grow up | down.", db.growUp and "upwards" or "downwards")
    elseif cmd == "size" then
        local percent = SetTextSize(arg)
        if percent then
            Msg("text size: %d%%.", percent)
        else
            Msg("text size is %d%%; /hm size <%d-%d>.", db.textSize, MIN_SIZE, MAX_SIZE)
        end
    elseif cmd == "test" and ns.ToggleTest then
        ns.ToggleTest(arg)
    elseif cmd == "style" then
        if SetStyle(arg) then
            Msg("style: %s.", STYLES[arg].label)
        else
            Msg("styles: %s.", table.concat(STYLE_ORDER, ", "))
        end
    else
        Msg("%s, %s, style %s.", db.enabled and "on" or "off", db.locked and "locked" or "unlocked",
            Style().label)
        Help()
    end
    Refresh()
end

local function EnsureDB()
    HealerManaDB = HealerManaDB or {}
    for k, v in pairs(DEFAULTS) do
        if HealerManaDB[k] == nil then HealerManaDB[k] = v end
    end
    if not STYLES[HealerManaDB.style] then HealerManaDB.style = DEFAULT_STYLE end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:SetScript("OnEvent", function(_, event, loaded)
    if event == "ADDON_LOADED" then
        if loaded ~= ADDON_NAME then return end
        EnsureDB()
        RegisterSettingsPage()
    elseif event == "PLAYER_LOGIN" then
        EnsureDB()
        Place()
        ApplyStyle()
    end
    Refresh()
end)
