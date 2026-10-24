-- QuestPlateProgress -- shows quest progress on the nameplates of mobs you
-- still need, e.g. "Kill 5/8" or "Cirrusfly Wing 3/10".
--
-- The client already knows which objectives a unit counts towards: it lists
-- them in the unit's tooltip. So each nameplate's unit is read the way its
-- tooltip would be, and the unfinished objectives go on the plate.

local ADDON_NAME, ns = ...

local DEFAULTS = {
    enabled = true,
    showParty = false,
    fontSize = 15,
    -- where the first line's middle sits, in pixels right of and above the
    -- middle of the health bar; further lines go on away from the bar
    x = 0,
    y = -16,
}
local MIN_FONT_SIZE, MAX_FONT_SIZE = 6, 24
local REFRESH_DELAY = 0.2 -- seconds; progress changes arrive in bursts
local SCAN_TOOLTIP = "QuestPlateProgressScanTooltip"
local QUEST_OBJECTIVE_LINE = 8 -- Enum.TooltipDataLineType.QuestObjective
local QUEST_TITLE_LINE = 17     -- Enum.TooltipDataLineType.QuestTitle
local QUEST_PLAYER_LINE = 18    -- Enum.TooltipDataLineType.QuestPlayer

local MAX_PLATES = 40
local plates = {} -- unit token -> the plate's text frame
local units = {}  -- unit tokens with a nameplate right now
local dirty = false
local sinceRefresh = 0

local function Msg(fmt, ...)
    print("|cff7fbf7fQuestPlateProgress|r: " .. string.format(fmt, ...))
end

-- Inside instances the client can hand out tooltip text as a secret value:
-- it may be passed on but not read.
local function IsSecret(value)
    if issecretvalue then return issecretvalue(value) == true end
    if type(value) ~= "string" then return false end
    return not pcall(function() return value == "" end)
end

-- "Pesky Cirrusfly slain: 5/8", " - Cirrusfly Wing: 3/10" or the modern
-- "5/8 Pesky Cirrusfly slain". Returns the name, done and needed.
local function ParseObjective(text)
    if type(text) ~= "string" or IsSecret(text) then return nil end
    text = text:gsub("^%s*%-%s*", ""):gsub("^%s+", ""):gsub("%s+$", "")
    local name, done, needed = text:match("^(.-):%s*(%d+)%s*/%s*(%d+)$")
    if not name then
        done, needed, name = text:match("^(%d+)%s*/%s*(%d+)%s+(.+)$")
    end
    if not name or name == "" then return nil end
    name = name:gsub("%s+slain$", "")
    return name, tonumber(done), tonumber(needed)
end

-- Some clients leave a line's text in its args until they are surfaced.
local function LineText(line)
    if line.leftText ~= nil then return line.leftText end
    for _, arg in ipairs(line.args or {}) do
        if arg.field == "leftText" then return arg.stringVal end
    end
    return nil
end

local function LineType(line)
    if line.type ~= nil then return line.type end
    for _, arg in ipairs(line.args or {}) do
        if arg.field == "type" then return arg.intVal end
    end
    return nil
end

-- The unit's tooltip lines, from the tooltip data API when the client has it
-- and from a hidden tooltip otherwise. Each is { text, objective }, where
-- objective is true or false when the client says and nil when it does not.
local scanTooltip
local function TooltipLines(unit)
    if C_TooltipInfo and C_TooltipInfo.GetUnit then
        local ok, data = pcall(C_TooltipInfo.GetUnit, unit)
        if ok and data and data.lines then
            local lines = {}
            for i, line in ipairs(data.lines) do
                if i > 1 then
                    local lineType = LineType(line)
                    local objective
                    if lineType ~= nil then objective = lineType == QUEST_OBJECTIVE_LINE end
                    table.insert(lines, { text = LineText(line), type = lineType, objective = objective })
                end
            end
            return lines
        end
    end
    if not scanTooltip then
        scanTooltip = CreateFrame("GameTooltip", SCAN_TOOLTIP, nil, "GameTooltipTemplate")
    end
    scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    local ok = pcall(scanTooltip.SetUnit, scanTooltip, unit)
    local lines = {}
    if ok then
        for i = 2, scanTooltip:NumLines() or 0 do
            local left = _G[SCAN_TOOLTIP .. "TextLeft" .. i]
            table.insert(lines, { text = left and left:GetText() })
        end
    end
    scanTooltip:Hide()
    return lines
end

-- An NPC you cannot attack, such as one a quest sends you to speak with.
-- Unknown counts as attackable.
local function IsFriendly(unit)
    if not UnitCanAttack then return false end
    local ok, canAttack = pcall(UnitCanAttack, "player", unit)
    return ok and canAttack == false
end

-- The objectives on this unit that are not finished yet, one per line.
-- An objective for the unit itself is shown as "Kill 5/8", or "Talk 0/1" on
-- one you cannot attack, since the plate already carries the name.
--
-- In a group the tooltip names each member doing the quest, with that
-- member's objectives under the name. Yours come first; the others' only
-- with showParty, greyed and named.
local PARTY_COLOR = "|cffb0b0b0"

local function ProgressText(unit)
    local mine, party = {}, {}
    local unitName = UnitName and UnitName(unit)
    if IsSecret(unitName) then unitName = nil end
    local me = UnitName and UnitName("player")
    local own = IsFriendly(unit) and "Talk %d/%d" or "Kill %d/%d"
    local who
    for _, line in ipairs(TooltipLines(unit)) do
        if line.type == QUEST_TITLE_LINE then
            who = nil
        elseif line.type == QUEST_PLAYER_LINE then
            who = type(line.text) == "string" and not IsSecret(line.text) and line.text:gsub("%-.*$", "") or "?"
            if who == me then who = nil end
        elseif line.objective ~= false then
            local name, done, needed = ParseObjective(line.text)
            if name and done and needed and done < needed then
                local text = name == unitName and own:format(done, needed)
                    or ("%s %d/%d"):format(name, done, needed)
                if not who then
                    table.insert(mine, text)
                elseif QuestPlateProgressDB.showParty then
                    table.insert(party, ("%s%s: %s|r"):format(PARTY_COLOR, who, text))
                end
            end
        end
    end
    for _, text in ipairs(party) do table.insert(mine, text) end
    if #mine == 0 then return nil end
    return table.concat(mine, "\n")
end

local function PlateFor(unit)
    if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then return nil end
    -- A forbidden plate (friendly ones inside instances) comes back as nil.
    local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
    if ok then return plate end
    return nil
end

-- The plate's frame reaches well above what is drawn, so the text is placed
-- from the middle of the health bar. The first line stays where it was put
-- however many lines follow: below the bar they grow downwards, above it
-- upwards. Without a bar to find, the plate itself stands in.
local function Part(frame, key)
    local part = type(frame) == "table" and frame[key]
    if type(part) == "table" then return part end
    return nil
end

local function Anchor(plate)
    local unitFrame = Part(plate, "UnitFrame")
    return Part(unitFrame, "healthBar") or Part(unitFrame, "HealthBarsContainer") or plate
end

local function ApplyLook(holder)
    holder.text:SetFont(holder.fontFile, QuestPlateProgressDB.fontSize, "OUTLINE")
    holder.text:ClearAllPoints()
    local halfLine = QuestPlateProgressDB.fontSize / 2
    local y = QuestPlateProgressDB.y
    if y > 0 then
        holder.text:SetPoint("BOTTOM", Anchor(holder:GetParent()), "CENTER", QuestPlateProgressDB.x, y - halfLine)
    else
        holder.text:SetPoint("TOP", Anchor(holder:GetParent()), "CENTER", QuestPlateProgressDB.x, y + halfLine)
    end
end

local function Holder(plate)
    if plate.questPlateProgress then return plate.questPlateProgress end
    local holder = CreateFrame("Frame", nil, plate)
    holder:SetAllPoints()
    holder.text = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    holder.text:SetJustifyH("CENTER")
    holder.text:SetTextColor(1, 0.82, 0)
    holder.fontFile = holder.text:GetFont() or "Fonts\\FRIZQT__.TTF"
    ApplyLook(holder)
    plate.questPlateProgress = holder
    return holder
end

local function Clear(unit)
    local holder = plates[unit]
    if holder then holder:Hide() end
    plates[unit] = nil
end

local function Update(unit)
    if not QuestPlateProgressDB.enabled then return Clear(unit) end
    local plate = PlateFor(unit)
    if not plate then return Clear(unit) end
    local text = ProgressText(unit)
    if not text then return Clear(unit) end
    local holder = Holder(plate)
    ApplyLook(holder)
    holder.text:SetText(text)
    holder:Show()
    plates[unit] = holder
end

-- The units come from the nameplate events; after a login or reload the
-- plates already up never announced themselves, so those are looked for too.
local function UpdateAll()
    if UnitExists then
        for i = 1, MAX_PLATES do
            local unit = "nameplate" .. i
            if UnitExists(unit) then units[unit] = true end
        end
    end
    for unit in pairs(units) do Update(unit) end
end

local function RestyleAll()
    for _, holder in pairs(plates) do ApplyLook(holder) end
end

ns.ParseObjective = ParseObjective

-- ------------------------------------------------------------
-- Settings
-- ------------------------------------------------------------

local function SetEnabled(on)
    QuestPlateProgressDB.enabled = on and true or false
    UpdateAll()
end

local function SetShowParty(on)
    QuestPlateProgressDB.showParty = on and true or false
    UpdateAll()
end

local function SetFontSize(size)
    size = math.floor(tonumber(size) or DEFAULTS.fontSize)
    QuestPlateProgressDB.fontSize = math.max(MIN_FONT_SIZE, math.min(MAX_FONT_SIZE, size))
    RestyleAll()
end

local function SetX(pixels)
    QuestPlateProgressDB.x = math.floor(tonumber(pixels) or DEFAULTS.x)
    RestyleAll()
end

local function SetY(pixels)
    QuestPlateProgressDB.y = math.floor(tonumber(pixels) or DEFAULTS.y)
    RestyleAll()
end

-- Options > AddOns: the same switches as the slash commands, built the first
-- time the page is shown.
local settingsCategory

local function BuildSettingsPage(page)
    local heading = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 16, -16)
    heading:SetText("Quest Plate Progress")

    local box = CreateFrame("CheckButton", "QuestPlateProgressSettingsEnabledCheck", page, "UICheckButtonTemplate")
    box:SetPoint("TOPLEFT", 10, -48)
    box:SetSize(24, 24)
    local label = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", box, "RIGHT", 2, 0)
    label:SetText("Show quest progress on nameplates")
    box:SetScript("OnClick", function(self) SetEnabled(self:GetChecked()) end)
    page.enabled = box

    local partyBox = CreateFrame("CheckButton", "QuestPlateProgressSettingsPartyCheck", page, "UICheckButtonTemplate")
    partyBox:SetPoint("TOPLEFT", 10, -70)
    partyBox:SetSize(24, 24)
    local partyLabel = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    partyLabel:SetPoint("LEFT", partyBox, "RIGHT", 2, 0)
    partyLabel:SetText("Also show party members' progress, greyed")
    partyBox:SetScript("OnClick", function(self) SetShowParty(self:GetChecked()) end)
    page.showParty = partyBox

    local function Stepper(key, y, step, get, set)
        local text = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("TOPLEFT", 14, y)
        page[key] = text
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
    Stepper("sizeLabel", -108, 1, function() return QuestPlateProgressDB.fontSize end, SetFontSize)
    Stepper("xLabel", -132, 2, function() return QuestPlateProgressDB.x end, SetX)
    Stepper("yLabel", -156, 2, function() return QuestPlateProgressDB.y end, SetY)

    local reset = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    reset:SetSize(120, 22)
    reset:SetPoint("TOPLEFT", 14, -184)
    reset:SetText("Default placement")
    reset:SetScript("OnClick", function() SetX(DEFAULTS.x); SetY(DEFAULTS.y); page.refresh() end)

    function page.refresh()
        page.enabled:SetChecked(QuestPlateProgressDB.enabled and true or false)
        page.showParty:SetChecked(QuestPlateProgressDB.showParty and true or false)
        page.sizeLabel:SetText(("Text size: %d"):format(QuestPlateProgressDB.fontSize))
        page.xLabel:SetText(("Right of the middle: %d"):format(QuestPlateProgressDB.x))
        page.yLabel:SetText(("Above the middle: %d"):format(QuestPlateProgressDB.y))
    end
end

local function RegisterSettingsPage()
    if settingsCategory then return end
    local page = CreateFrame("Frame")
    -- A new frame starts shown, so the panel showing it the first time is no
    -- change and OnShow, which fills in the values, would not run.
    page:Hide()
    page.name = "Quest Plate Progress"
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

local function OpenSettings()
    if settingsCategory and Settings and Settings.OpenToCategory and settingsCategory.GetID then
        pcall(Settings.OpenToCategory, settingsCategory:GetID())
    elseif settingsCategory and InterfaceOptionsFrame_OpenToCategory then
        pcall(InterfaceOptionsFrame_OpenToCategory, settingsCategory)
    else
        Msg("no options window in this client; use the slash commands.")
    end
end

-- ------------------------------------------------------------
-- Events
-- ------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
for _, event in ipairs({
    "PLAYER_ENTERING_WORLD", "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED",
    "QUEST_LOG_UPDATE", "UNIT_QUEST_LOG_CHANGED",
}) do
    pcall(events.RegisterEvent, events, event)
end

events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        QuestPlateProgressDB = QuestPlateProgressDB or {}
        for key, value in pairs(DEFAULTS) do
            if QuestPlateProgressDB[key] == nil then QuestPlateProgressDB[key] = value end
        end
        QuestPlateProgressDB.offsetY, QuestPlateProgressDB.offset, QuestPlateProgressDB.position = nil, nil, nil
        RegisterSettingsPage()
    elseif not QuestPlateProgressDB then
        return
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        units[arg1] = true
        Update(arg1)
        -- Right after a plate appears the tooltip may not have its quest
        -- lines yet; look again shortly.
        dirty = true
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        units[arg1] = nil
        Clear(arg1)
    else
        dirty = true
    end
end)

events:SetScript("OnUpdate", function(_, elapsed)
    if not dirty then return end
    sinceRefresh = sinceRefresh + (elapsed or 0)
    if sinceRefresh < REFRESH_DELAY then return end
    sinceRefresh, dirty = 0, false
    if QuestPlateProgressDB then UpdateAll() end
end)

-- Copy window. Chat cannot be selected, so reports go in a multi-line EditBox
-- that opens with everything highlighted. The same window as in EventLogger.
local copyFrame, copyBox, copyTitle

local function BuildCopyFrame()
    copyFrame = CreateFrame("Frame", "QuestPlateProgressCopyFrame", UIParent)
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

    local scroll = CreateFrame("ScrollFrame", "QuestPlateProgressCopyScroll", copyFrame,
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

local function ShowCopyText(heading, lines)
    local ok = pcall(function()
        if not copyFrame then BuildCopyFrame() end
        copyTitle:SetText(heading)
        copyBox:SetText(table.concat(lines, "\n"))
        copyBox:SetCursorPosition(0)
        copyBox:HighlightText()
        copyFrame:Show()
        copyBox:SetFocus()
    end)
    if not ok then
        for _, line in ipairs(lines) do print(line) end
    end
    return ok
end

-- What the addon sees for one unit, in the copy window and kept in the saved
-- variables so it can be read outside the game after a /reload.
local function Describe(value)
    if IsSecret(value) then return "<secret>" end
    return tostring(value)
end

local function Debug(unit)
    local report = {}
    local function Add(fmt, ...) table.insert(report, string.format(fmt, ...)) end
    if GetBuildInfo then
        local version, build = GetBuildInfo()
        Add("QuestPlateProgress debug, build %s (%s)", tostring(build), tostring(version))
    end
    Add("unit %s, exists %s, name %s", unit, Describe(UnitExists and UnitExists(unit)),
        Describe(UnitName and UnitName(unit)))
    Add("C_TooltipInfo.GetUnit %s, C_NamePlate.GetNamePlateForUnit %s",
        tostring(C_TooltipInfo and C_TooltipInfo.GetUnit ~= nil),
        tostring(C_NamePlate and C_NamePlate.GetNamePlateForUnit ~= nil))
    local plate = PlateFor(unit)
    Add("plate %s, token %s", tostring(plate ~= nil), Describe(plate and plate.namePlateUnitToken))
    local plateUnits = {}
    for token in pairs(units) do table.insert(plateUnits, token) end
    table.sort(plateUnits)
    Add("nameplate units seen: %s", #plateUnits > 0 and table.concat(plateUnits, " ") or "none")
    for i, line in ipairs(TooltipLines(unit)) do
        local name, done, needed = ParseObjective(line.text)
        Add("line %d: type %s, text %s -> %s", i + 1, Describe(line.type), Describe(line.text),
            name and ("%s %s/%s"):format(name, tostring(done), tostring(needed)) or "no objective")
    end
    Add("shown: %s", Describe(ProgressText(unit)))
    QuestPlateProgressDB.debug = report
    return report
end

-- ------------------------------------------------------------
-- Slash commands
-- ------------------------------------------------------------

local function Help()
    Msg("commands:")
    print("  /qpp              -- show current state")
    print("  /qpp on | off     -- show or hide the progress text")
    print("  /qpp party on | off -- also show party members' progress")
    print("  /qpp size <n>     -- text size, " .. MIN_FONT_SIZE .. "-" .. MAX_FONT_SIZE)
    print("  /qpp move <x> <y> -- pixels from the middle of the health bar; minus is left/down")
    print("  /qpp x <n> | y <n> -- one of the two")
    print("  /qpp center       -- back to the middle")
    print("  /qpp reset        -- default size and placement")
    print("  /qpp options      -- open the options page")
    print("  /qpp debug        -- what it sees on your target (or mouseover)")
end

SLASH_QUESTPLATEPROGRESS1 = "/qpp"
SlashCmdList["QUESTPLATEPROGRESS"] = function(input)
    local cmd, rest = (input or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
    if cmd == "" then
        Msg("%s | text size %d | moved %d, %d", QuestPlateProgressDB.enabled and "on" or "off",
            QuestPlateProgressDB.fontSize, QuestPlateProgressDB.x, QuestPlateProgressDB.y)
    elseif cmd == "on" or cmd == "off" then
        SetEnabled(cmd == "on")
        Msg(cmd)
    elseif cmd == "party" and (rest == "on" or rest == "off") then
        SetShowParty(rest == "on")
        Msg("party members' progress %s", rest == "on" and "shown" or "hidden")
    elseif cmd == "size" and tonumber(rest) then
        SetFontSize(rest)
        Msg("text size %d", QuestPlateProgressDB.fontSize)
    elseif cmd == "move" and rest:match("^%-?%d+%s+%-?%d+$") then
        local x, y = rest:match("^(%-?%d+)%s+(%-?%d+)$")
        SetX(x)
        SetY(y)
        Msg("moved %d, %d", QuestPlateProgressDB.x, QuestPlateProgressDB.y)
    elseif (cmd == "x" or cmd == "y") and tonumber(rest) then
        if cmd == "x" then SetX(rest) else SetY(rest) end
        Msg("moved %d, %d", QuestPlateProgressDB.x, QuestPlateProgressDB.y)
    elseif cmd == "center" or cmd == "centre" then
        SetX(0)
        SetY(0)
        Msg("back in the middle")
    elseif cmd == "reset" then
        SetFontSize(DEFAULTS.fontSize)
        SetX(DEFAULTS.x)
        SetY(DEFAULTS.y)
        Msg("text size %d, moved %d, %d", QuestPlateProgressDB.fontSize, QuestPlateProgressDB.x,
            QuestPlateProgressDB.y)
    elseif cmd == "options" or cmd == "gui" then
        OpenSettings()
    elseif cmd == "debug" then
        local unit = (UnitExists and UnitExists("target")) and "target" or "mouseover"
        if ShowCopyText("QuestPlateProgress debug: " .. unit, Debug(unit)) then
            Msg("debug for %s is in the copy window.", unit)
        end
    else
        Help()
    end
end
