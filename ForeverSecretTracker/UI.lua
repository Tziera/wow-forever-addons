-- The window: an overview grid of every secret, a guide per secret, a
-- filter menu, a toast when one is found and a minimap button.

local _, ns = ...

local WIDTH, HEIGHT = 720, 560
local CELL_W, CELL_H, CELL_GAP = 222, 50, 6
local COLUMNS, GRID_ROWS = 3, 7
local PER_PAGE = COLUMNS * GRID_ROWS
local LIST_WIDTH, LIST_ROW_H, LIST_ROWS = 250, 42, 10
local STEP_ROWS = 16
local STEP_GAP = 3
local ACTION_W = 60
local MODEL_SIZE = 150
local ICON_PATH = "Interface\\Icons\\"
local PORTRAIT = ICON_PATH .. "INV_Misc_Spyglass_02"

local KIND_ORDER = { "pet", "toy", "quest", "boss", "rare", "twist", "mystery" }
local KIND_PLURAL = {
    pet = "Pets", toy = "Toys", quest = "Quests", boss = "Bosses & places", rare = "Rares",
    twist = "Twists", mystery = "Mysteries",
}
local KIND_ICON = {
    pet = "INV_Box_PetCarrier_01", toy = "INV_Misc_Toy_10", quest = "INV_Misc_Note_01", boss = "INV_Misc_Bone_HumanSkull_01",
    rare = "Ability_Hunter_SniperShot", twist = "INV_Misc_Gear_01", mystery = "INV_Misc_QuestionMark",
}

local GOLD = { 1, 0.82, 0 }
local MISSING = { 0.55, 0.47, 0.36 }
local STARTED = { 0.9, 0.9, 0.9 }
local MYSTERY = { 0.78, 0.62, 1 }

local frame
local view = "overview"
local page = 1
local listOffset, stepOffset = 0, 0
local selected
local searchText = ""

local function DB() return ns.DB() end

local function Filters()
    local db = DB()
    db.filters = db.filters or {}
    local f = db.filters
    if f.found == nil then f.found = true end
    if f.missing == nil then f.missing = true end
    f.kinds = f.kinds or {}
    for _, k in ipairs(KIND_ORDER) do
        if f.kinds[k] == nil then f.kinds[k] = true end
    end
    f.sort = f.sort or "type"
    return f
end

local function Try(fn, ...)
    local ok, a, b = pcall(fn, ...)
    if ok then return a, b end
    return nil
end

-- CreateFrame with a template the client might not have.
local function Make(kind, name, parent, template)
    local f = template and Try(CreateFrame, kind, name, parent, template)
    return f or CreateFrame(kind, name, parent)
end

local function Atlas(tex, atlas, fallback)
    local known = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
    if known and tex.SetAtlas then
        tex:SetAtlas(atlas)
    elseif type(fallback) == "string" then
        tex:SetTexture(fallback)
    elseif type(fallback) == "table" then
        tex:SetColorTexture(fallback[1], fallback[2], fallback[3], fallback[4])
    end
end

local function Field(f, key)
    local v = rawget(f, key)
    if type(v) == "table" then return v end
    return nil
end

local function SecretByID(id)
    for _, secret in ipairs(ns.SECRETS) do
        if secret.id == id then return secret end
    end
end

-- Icon and model ------------------------------------------------------------

local function PetInfo(secret)
    if secret.kind ~= "pet" or not (C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID) then return nil end
    local name = secret.done and secret.done.pet or secret.name
    local species = ns.PetSpecies(name)
    if not species then return nil end
    local ok, info = pcall(function() return { C_PetJournal.GetPetInfoBySpeciesID(species) } end)
    return ok and info or nil
end

-- Forever's client lacks some icons that later clients have. A path the
-- client does not know shows nothing, so it falls back to the type's icon.
local function Known(path)
    if not GetFileIDFromPath then return true end
    local ok, id = pcall(GetFileIDFromPath, path)
    return not ok or id ~= nil
end

local function Icon(secret)
    local pet = PetInfo(secret)
    if pet and pet[2] then return pet[2] end
    if secret.icon and Known(ICON_PATH .. secret.icon) then return ICON_PATH .. secret.icon end
    return ICON_PATH .. (KIND_ICON[secret.kind] or "INV_Misc_QuestionMark")
end

local function DisplayID(secret)
    if secret.display then return secret.display end
    local pet = PetInfo(secret)
    return pet and pet[12] or nil
end

local function NameColor(secret, st)
    if secret.kind == "mystery" then return MYSTERY end
    if st.done then return GOLD end
    if st.count > 0 then return STARTED end
    return MISSING
end

local function ProgressText(secret, st)
    if secret.kind == "mystery" then
        if st.count > 0 then return string.format("%d / %d known steps", st.count, st.total) end
        return "Unsolved"
    end
    if st.done then return "Found" end
    return string.format("%d / %d steps", st.count, st.total)
end

-- What is shown ---------------------------------------------------------------

local function Matches(secret)
    if searchText == "" then return true end
    local function has(s) return type(s) == "string" and s:lower():find(searchText, 1, true) end
    if has(secret.name) or has(secret.zone) or has(secret.reward) or has(secret.note) then return true end
    for _, s in ipairs(secret.steps) do
        if has(s.text) or has(s.zone) then return true end
    end
    return false
end

local KIND_RANK = {}
for i, k in ipairs(KIND_ORDER) do KIND_RANK[k] = i end

local function Visible()
    local f = Filters()
    local db = DB()
    local out = {}
    for i, secret in ipairs(ns.SECRETS) do
        local st = ns.Status(secret)
        local foundOk = (st.done and f.found) or (not st.done and f.missing) or secret.kind == "mystery"
        if f.kinds[secret.kind] and foundOk and (db.showAll or ns.ForPlayer(secret)) and Matches(secret) then
            out[#out + 1] = { secret = secret, st = st, n = i }
        end
    end
    table.sort(out, function(a, b)
        if f.sort == "name" then return a.secret.name < b.secret.name end
        if f.sort == "missing" and a.st.done ~= b.st.done then return b.st.done end
        local ka, kb = KIND_RANK[a.secret.kind] or 99, KIND_RANK[b.secret.kind] or 99
        if ka ~= kb then return ka < kb end
        return a.n < b.n
    end)
    local list = {}
    for i, e in ipairs(out) do list[i] = e.secret end
    return list
end

-- Refresh ---------------------------------------------------------------------

local Refresh

local function SetCellLook(cell, secret, st)
    cell.icon:SetTexture(Icon(secret))
    local done = st.done or secret.kind == "mystery"
    if cell.icon.SetDesaturated then cell.icon:SetDesaturated(not done) end
    cell.icon:SetAlpha(done and 1 or 0.75)
    Atlas(cell.slot, done and "collections-itemborder-collected" or "collections-itemborder-uncollected",
        { 0.2, 0.2, 0.2, 0.6 })
    local c = NameColor(secret, st)
    cell.name:SetText(secret.name)
    cell.name:SetTextColor(c[1], c[2], c[3])
    cell.sub:SetText(ProgressText(secret, st))
end

local function RefreshOverview(list)
    local o = frame.overview
    local pages = math.max(1, math.ceil(#list / PER_PAGE))
    if page > pages then page = pages end
    for i, cell in ipairs(o.cells) do
        local secret = list[(page - 1) * PER_PAGE + i]
        if secret then
            SetCellLook(cell, secret, ns.Status(secret))
            cell.secret = secret
            cell:Show()
        else
            cell.secret = nil
            cell:Hide()
        end
    end
    o.pageText:SetText(string.format("Page %d / %d", page, pages))
    o.prev:SetEnabled(page > 1)
    o.next:SetEnabled(page < pages)
    o.empty:SetText(#list == 0 and "Nothing matches the filter." or "")
end

local function RefreshList(list)
    local g = frame.guides
    local maxOffset = math.max(0, #list - LIST_ROWS)
    if listOffset > maxOffset then listOffset = maxOffset end
    for r, row in ipairs(g.rows) do
        local secret = list[r + listOffset]
        if secret then
            local st = ns.Status(secret)
            row.icon:SetTexture(Icon(secret))
            if row.icon.SetDesaturated then row.icon:SetDesaturated(not (st.done or secret.kind == "mystery")) end
            local c = NameColor(secret, st)
            row.name:SetText(secret.name)
            row.name:SetTextColor(c[1], c[2], c[3])
            row.sub:SetText(ProgressText(secret, st))
            row.sel:SetShown(secret.id == selected)
            row.secret = secret
            row:Show()
        else
            row.secret = nil
            row:Hide()
        end
    end
    g.scrollUp:SetShown(listOffset > 0)
    g.scrollDown:SetShown(listOffset < maxOffset)
end

-- A secure button's attributes and visibility cannot change in combat; it
-- keeps what it had, and the window is refreshed when combat ends.
local function SetAction(act, macro)
    if InCombatLockdown and InCombatLockdown() then
        ns.refreshAfterCombat = true
        return
    end
    act.macro = macro
    if macro then
        act:SetAttribute("type", "macro")
        act:SetAttribute("macrotext", macro)
        act.label:SetText(macro:match("^/%S+") or macro)
        act:Show()
    else
        act:SetAttribute("type", nil)
        act:SetAttribute("macrotext", nil)
        act:Hide()
    end
end

-- The height a wrapped font string takes. The client knows it once the text
-- and width are set; without that, it is estimated from the length.
local function TextHeight(fs, width, text)
    local h = fs.GetStringHeight and fs:GetStringHeight()
    if type(h) == "number" and h > 0 then return h end
    local visible = (text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    return math.max(1, math.ceil(#visible * 6 / width)) * 13
end

local function NewCreditLine(d)
    local line = CreateFrame("Button", nil, d)
    line.text = line:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    line.text:SetAllPoints()
    line.text:SetJustifyH("LEFT")
    line.text:SetTextColor(0.45, 0.7, 1)
    line:SetScript("OnClick", function(self) if self.url then ns.ShowLink(self.url) end end)
    line:Hide()
    return line
end

local function StepIcon(row, state)
    if state == "done" then
        Atlas(row.state, "common-icon-checkmark", "Interface\\RaidFrame\\ReadyCheck-Ready")
    elseif state == "next" then
        row.state:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.9)
    else
        row.state:SetColorTexture(0.4, 0.4, 0.4, 0.6)
    end
    local size = state == "done" and 14 or 7
    row.state:SetSize(size, size)
end

local function RefreshModel(secret)
    local m = frame.guides.model
    local display = DisplayID(secret)
    if display and m.SetDisplayInfo then
        Try(m.SetDisplayInfo, m, display)
        m.facing = m.facing or 0
        m:Show()
        m.back:Show()
    else
        m:Hide()
        m.back:Hide()
    end
end

local function RefreshDetail()
    local d = frame.guides.detail
    local secret = selected and SecretByID(selected)
    if not secret then
        d:Hide()
        frame.guides.pick:Show()
        frame.guides.model:Hide()
        frame.guides.model.back:Hide()
        return
    end
    frame.guides.pick:Hide()
    d:Show()
    local st = ns.Status(secret)
    d.icon:SetTexture(Icon(secret))
    if d.icon.SetDesaturated then d.icon:SetDesaturated(not (st.done or secret.kind == "mystery")) end
    local c = NameColor(secret, st)

    -- The header is laid out from the top, each line below the one before,
    -- so long names, zones and notes wrap instead of running into the next.
    -- Without a model beside it, the text takes the whole width.
    local model = DisplayID(secret) ~= nil
    local extra = model and 0 or MODEL_SIZE + 8
    local textW, wideW = d.textW + extra, d.wideW + extra
    local y = 2
    local function Place(fs, x, width, text)
        fs:SetWidth(width)
        fs:SetText(text)
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", x, -y)
        y = y + TextHeight(fs, width, text) + 3
    end
    Place(d.title, 60, textW, secret.name)
    d.title:SetTextColor(c[1], c[2], c[3])
    Place(d.meta, 60, textW, ns.MetaLine(secret))
    local credits = secret.credit
    if credits and credits.name then credits = { credits } end
    for i, line in ipairs(d.credits) do line.url = nil; line:Hide() end
    for i, cr in ipairs(credits or {}) do
        local line = d.credits[i] or NewCreditLine(d)
        d.credits[i] = line
        local text = (cr.what and cr.what .. " found by " or "Found by ") .. cr.name
            .. " |cff808080(click to copy the link)|r"
        line.text:SetWidth(textW)
        line.text:SetText(text)
        local h = TextHeight(line.text, textW, text)
        line:SetSize(textW, h)
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", 60, -y)
        y = y + h + 3
        line.url = cr.url
        line:Show()
    end
    y = math.max(y + 4, 62)
    Place(d.reward, 0, wideW, "Reward: " .. (secret.reward or "unknown"))
    if secret.note then
        y = y + 2
        Place(d.note, 0, wideW, secret.note)
        d.note:Show()
    else
        d.note:SetText("")
        d.note:Hide()
    end
    y = y + 6
    d.bar:SetWidth(wideW)
    d.bar:ClearAllPoints()
    d.bar:SetPoint("TOPLEFT", 0, -y)
    y = y + 14 + 10

    d.bar:SetMinMaxValues(0, math.max(1, st.total))
    d.bar:SetValue(st.done and st.total or st.count)
    d.barText:SetText(secret.kind == "mystery" and ProgressText(secret, st)
        or (st.done and "Found" or string.format("%d / %d steps", st.count, st.total)))

    -- Steps run the full width, so with a model they start below it.
    if model then y = math.max(y, MODEL_SIZE + 8) end

    -- Steps: as many as fit below the header, each as tall as its text.
    local bottom = (HEIGHT - 120) - 30
    local function StepText(s, i)
        local where = ""
        if s.spots and #s.spots > 1 then where = string.format(" |cff808080(%s, %d known spots)|r", s.zone, #s.spots)
        elseif s.zone and s.x then where = string.format(" |cff808080(%s %.1f, %.1f)|r", s.zone, s.x, s.y)
        elseif s.zone then where = " |cff808080(" .. s.zone .. ")|r" end
        local optional = st.optional[i] and " |cff808080(optional)|r" or ""
        return s.text .. where .. optional
    end
    local measure = d.steps[1].text
    local function TextWidth(s)
        return s.macro and d.stepTextW - ACTION_W or d.stepTextW
    end
    local function RowHeight(n)
        local i = st.shown[n]
        local s = secret.steps[i]
        local text = StepText(s, i)
        measure:SetWidth(TextWidth(s))
        return math.max(20, TextHeight(measure, TextWidth(s), text) + 6)
    end
    -- The furthest the list can scroll: the last steps exactly fill the space.
    local maxOffset, room = #st.shown, bottom - y
    while maxOffset > 0 do
        local h = RowHeight(maxOffset) + STEP_GAP
        if h > room then break end
        room = room - h
        maxOffset = maxOffset - 1
    end
    if stepOffset > maxOffset then stepOffset = maxOffset end

    local lastShown = stepOffset
    for r, row in ipairs(d.steps) do
        local n = r + stepOffset
        local i = st.shown[n]
        local h = i and RowHeight(n)
        if i and (r == 1 or y + h <= bottom) then
            local s = secret.steps[i]
            local state = st.steps[i] and "done" or (st.optional[i] and "optional")
                or (i == st.next and "next" or "todo")
            StepIcon(row, state)
            row.text:SetWidth(TextWidth(s))
            row.text:SetText(StepText(s, i))
            SetAction(row.act, s.macro)
            if state == "done" or state == "optional" then row.text:SetTextColor(0.55, 0.55, 0.55)
            elseif state == "next" then row.text:SetTextColor(1, 1, 1)
            else row.text:SetTextColor(0.78, 0.78, 0.78) end
            row:SetHeight(h)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -y)
            y = y + h + STEP_GAP
            row.pin:SetShown(s.x ~= nil and s.mapID ~= nil)
            row.secret, row.index, row.step = secret, i, s
            row:Show()
            lastShown = n
        else
            -- Beyond the space, the rest of the pool stays hidden.
            y = bottom + 1
            SetAction(row.act, nil)
            row.step = nil
            row:Hide()
        end
    end
    local partial = stepOffset > 0 or lastShown < #st.shown
    d.more:SetText(partial and string.format("Scroll for more steps (%d-%d of %d)",
        stepOffset + 1, lastShown, #st.shown) or "")
    d.mark:SetText(DB().manualDone[secret.id] and "Unmark" or "Mark as done")
    d.mark:SetShown(secret.kind ~= "mystery")
    RefreshModel(secret)
end

Refresh = function()
    if not frame then return end
    local list = Visible()
    local found, total = ns.Counts(DB().showAll)
    frame.counter:SetText(string.format("%d / %d secrets found", found, total))
    frame.progress:SetMinMaxValues(0, math.max(1, total))
    frame.progress:SetValue(found)
    frame.overview:SetShown(view == "overview")
    frame.guides:SetShown(view == "guides")
    for _, tab in ipairs(frame.tabs) do
        local on = tab.view == view
        if on and PanelTemplates_SelectTab then PanelTemplates_SelectTab(tab)
        elseif not on and PanelTemplates_DeselectTab then PanelTemplates_DeselectTab(tab) end
        if tab.LockHighlight then
            if on then tab:LockHighlight() else tab:UnlockHighlight() end
        end
    end
    if view == "overview" then
        RefreshOverview(list)
    else
        RefreshList(list)
        RefreshDetail()
    end
end

local function OpenGuide(id)
    view, selected, stepOffset = "guides", id, 0
    local list = Visible()
    for i, secret in ipairs(list) do
        if secret.id == id then
            if i <= listOffset or i > listOffset + LIST_ROWS then
                listOffset = math.max(0, i - math.floor(LIST_ROWS / 2))
            end
            break
        end
    end
    Refresh()
end

-- Tooltips ---------------------------------------------------------------------

local function SecretTooltip(owner, secret)
    if not (GameTooltip and secret) then return end
    local st = ns.Status(secret)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:AddLine(secret.name)
    GameTooltip:AddLine(ns.MetaLine(secret), 0.7, 0.7, 0.7)
    if secret.reward then GameTooltip:AddLine("Reward: " .. secret.reward, 1, 1, 1) end
    GameTooltip:AddLine(ProgressText(secret, st), 0.6, 0.8, 1)
    GameTooltip:AddLine("Click to open the guide", 0.5, 0.5, 0.5)
    GameTooltip:Show()
end

local function StepTooltip(row)
    if not (GameTooltip and row.step) then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:AddLine(row.secret.name)
    local spots = row.step.spots and #row.step.spots or 0
    if spots > 1 then
        GameTooltip:AddLine(TomTom and "Click: a waypoint on every known spot"
            or string.format("Click: a waypoint on the next of %d spots", spots), 1, 1, 1)
    elseif row.step.x then
        GameTooltip:AddLine("Click: set a waypoint", 1, 1, 1)
    end
    GameTooltip:AddLine(ns.Manual(row.secret.id, row.index) and "Right-click: unmark this step"
        or "Right-click: mark this step done", 1, 1, 1)
    GameTooltip:Show()
end

local function HideTooltip()
    if GameTooltip then GameTooltip:Hide() end
end

-- Filter menu -----------------------------------------------------------------

local function Changed()
    page, listOffset = 1, 0
    Refresh()
end

local function SetupFilterMenu(dropdown)
    if not dropdown.SetupMenu then return false end
    dropdown:SetupMenu(function(_, root)
        local f = Filters()
        root:CreateCheckbox("Found", function() return f.found end, function() f.found = not f.found Changed() end)
        root:CreateCheckbox("Not found", function() return f.missing end, function() f.missing = not f.missing Changed() end)
        root:CreateCheckbox("Other factions and classes", function() return DB().showAll and true or false end,
            function() DB().showAll = not DB().showAll or nil Changed() end)
        local types = root:CreateButton("Type")
        types:CreateButton("Select all", function()
            for _, k in ipairs(KIND_ORDER) do f.kinds[k] = true end
            Changed()
        end)
        types:CreateButton("Deselect all", function()
            for _, k in ipairs(KIND_ORDER) do f.kinds[k] = false end
            Changed()
        end)
        types:CreateDivider()
        for _, k in ipairs(KIND_ORDER) do
            types:CreateCheckbox(KIND_PLURAL[k], function() return f.kinds[k] end,
                function() f.kinds[k] = not f.kinds[k] Changed() end)
        end
        local sort = root:CreateButton("Sort")
        for _, opt in ipairs({ { "type", "By type" }, { "name", "By name" }, { "missing", "Not found first" } }) do
            sort:CreateRadio(opt[2], function() return f.sort == opt[1] end, function() f.sort = opt[1] Changed() end)
        end
    end)
    return true
end

-- Building --------------------------------------------------------------------

local function SavePosition(f)
    local point, _, relPoint, x, y = f:GetPoint()
    if point then DB().point = { point, relPoint, x, y } end
end

local function PlaceFrame(f)
    local p = DB().point
    f:ClearAllPoints()
    if type(p) == "table" and p[1] then
        f:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else
        f:SetPoint("CENTER")
    end
end

local function MakeBar(parent, w, h)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(w, h)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(0.25, 0.75, 0.3)
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.5)
    return bar
end

local function BuildOverview(parent)
    local o = CreateFrame("Frame", nil, parent)
    o:SetAllPoints()
    o.cells = {}
    for i = 1, PER_PAGE do
        local col = (i - 1) % COLUMNS
        local row = math.floor((i - 1) / COLUMNS)
        local cell = CreateFrame("Button", nil, o)
        cell:SetSize(CELL_W, CELL_H)
        cell:SetPoint("TOPLEFT", 12 + col * (CELL_W + 4), -48 - row * (CELL_H + CELL_GAP))
        local slot = cell:CreateTexture(nil, "BORDER")
        slot:SetSize(52, 52)
        slot:SetPoint("LEFT", -1, 0)
        cell.slot = slot
        local icon = cell:CreateTexture(nil, "ARTWORK")
        icon:SetSize(40, 40)
        icon:SetPoint("CENTER", slot, "CENTER")
        cell.icon = icon
        local glow = cell:CreateTexture(nil, "HIGHLIGHT")
        glow:SetAllPoints()
        glow:SetColorTexture(1, 1, 1, 0.05)
        local name = cell:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        name:SetPoint("TOPLEFT", 58, -6)
        name:SetWidth(CELL_W - 62)
        name:SetJustifyH("LEFT")
        if name.SetMaxLines then name:SetMaxLines(2) end
        cell.name = name
        local sub = cell:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        sub:SetPoint("BOTTOMLEFT", 58, 5)
        sub:SetJustifyH("LEFT")
        cell.sub = sub
        cell:SetScript("OnClick", function(self) if self.secret then OpenGuide(self.secret.id) end end)
        cell:SetScript("OnEnter", function(self) SecretTooltip(self, self.secret) end)
        cell:SetScript("OnLeave", HideTooltip)
        o.cells[i] = cell
    end

    local pageText = o:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pageText:SetPoint("BOTTOM", 0, 12)
    o.pageText = pageText
    local function PageButton(dir)
        local b = CreateFrame("Button", nil, o)
        b:SetSize(28, 28)
        local name = dir < 0 and "Prev" or "Next"
        b:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. name .. "Page-Up")
        b:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. name .. "Page-Down")
        b:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. name .. "Page-Disabled")
        b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        b:SetScript("OnClick", function()
            page = page + dir
            Refresh()
        end)
        return b
    end
    o.prev = PageButton(-1)
    o.prev:SetPoint("RIGHT", pageText, "LEFT", -8, 0)
    o.next = PageButton(1)
    o.next:SetPoint("LEFT", pageText, "RIGHT", 8, 0)
    o:EnableMouseWheel(true)
    o:SetScript("OnMouseWheel", function(_, delta)
        page = math.max(1, page - delta)
        Refresh()
    end)
    local empty = o:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("TOP", 0, -120)
    o.empty = empty
    return o
end

local function BuildGuides(parent)
    local g = CreateFrame("Frame", nil, parent)
    g:SetAllPoints()

    local listBg = g:CreateTexture(nil, "BACKGROUND")
    listBg:SetPoint("TOPLEFT", 8, -44)
    listBg:SetSize(LIST_WIDTH, LIST_ROWS * LIST_ROW_H + 8)
    listBg:SetColorTexture(0, 0, 0, 0.25)

    local list = CreateFrame("Frame", nil, g)
    list:SetPoint("TOPLEFT", 8, -48)
    list:SetSize(LIST_WIDTH, LIST_ROWS * LIST_ROW_H)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, delta)
        listOffset = math.max(0, listOffset - delta * 2)
        Refresh()
    end)
    g.rows = {}
    for i = 1, LIST_ROWS do
        local row = CreateFrame("Button", nil, list)
        row:SetSize(LIST_WIDTH - 4, LIST_ROW_H - 2)
        row:SetPoint("TOPLEFT", 2, -(i - 1) * LIST_ROW_H)
        local sel = row:CreateTexture(nil, "BACKGROUND")
        sel:SetAllPoints()
        sel:SetColorTexture(1, 0.82, 0, 0.12)
        sel:Hide()
        row.sel = sel
        local glow = row:CreateTexture(nil, "HIGHLIGHT")
        glow:SetAllPoints()
        glow:SetColorTexture(1, 1, 1, 0.06)
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(32, 32)
        icon:SetPoint("LEFT", 4, 0)
        row.icon = icon
        local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        name:SetPoint("TOPLEFT", 42, -4)
        name:SetWidth(LIST_WIDTH - 52)
        name:SetJustifyH("LEFT")
        name:SetWordWrap(false)
        row.name = name
        local sub = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        sub:SetPoint("BOTTOMLEFT", 42, 5)
        row.sub = sub
        row:SetScript("OnClick", function(self)
            if not self.secret then return end
            selected, stepOffset = self.secret.id, 0
            Refresh()
        end)
        g.rows[i] = row
    end
    local up = g:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    up:SetPoint("TOPRIGHT", list, "TOPRIGHT", -4, 12)
    up:SetText("more above")
    g.scrollUp = up
    local down = g:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    down:SetPoint("TOPRIGHT", list, "BOTTOMRIGHT", -4, -6)
    down:SetText("more below")
    g.scrollDown = down

    local left = LIST_WIDTH + 22
    local dWidth = WIDTH - left - 24

    local pick = g:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    pick:SetPoint("TOPLEFT", left, -60)
    pick:SetText("Pick a secret on the left.")
    g.pick = pick

    local d = CreateFrame("Frame", nil, g)
    d:SetPoint("TOPLEFT", left, -44)
    d:SetSize(dWidth, HEIGHT - 120)
    d:EnableMouseWheel(true)
    d:SetScript("OnMouseWheel", function(_, delta)
        stepOffset = math.max(0, stepOffset - delta)
        RefreshDetail()
    end)
    g.detail = d

    local slot = d:CreateTexture(nil, "BORDER")
    slot:SetSize(58, 58)
    slot:SetPoint("TOPLEFT", -3, 3)
    Atlas(slot, "collections-itemborder-collected", { 0.2, 0.2, 0.2, 0.6 })
    d.icon = d:CreateTexture(nil, "ARTWORK")
    d.icon:SetSize(44, 44)
    d.icon:SetPoint("CENTER", slot, "CENTER")

    local textW = dWidth - 60 - MODEL_SIZE
    d.title = d:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    d.title:SetPoint("TOPLEFT", 60, -2)
    d.title:SetWidth(textW)
    d.title:SetJustifyH("LEFT")
    d.meta = d:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    d.meta:SetPoint("TOPLEFT", 60, -24)
    d.meta:SetWidth(textW)
    d.meta:SetJustifyH("LEFT")
    d.meta:SetTextColor(0.7, 0.7, 0.7)
    d.credits = {}
    d.textW, d.wideW = textW, dWidth - MODEL_SIZE - 8
    d.reward = d:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    d.reward:SetWidth(d.wideW)
    d.reward:SetJustifyH("LEFT")
    d.note = d:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    d.note:SetWidth(d.wideW)
    d.note:SetJustifyH("LEFT")
    d.note:SetJustifyV("TOP")
    d.note:SetTextColor(0.75, 0.75, 0.75)

    d.bar = MakeBar(d, dWidth - MODEL_SIZE - 8, 14)
    d.barText = d.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    d.barText:SetPoint("CENTER")

    -- Rows grow with their text; they are laid out on each refresh.
    d.stepTextW = dWidth - 44
    d.steps = {}
    for i = 1, STEP_ROWS do
        local row = CreateFrame("Button", nil, d)
        row:SetSize(dWidth, 28)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        local glow = row:CreateTexture(nil, "HIGHLIGHT")
        glow:SetAllPoints()
        glow:SetColorTexture(1, 1, 1, 0.05)
        local state = row:CreateTexture(nil, "OVERLAY")
        state:SetPoint("CENTER", row, "TOPLEFT", 8, -8)
        row.state = state
        local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("TOPLEFT", 20, -3)
        text:SetWidth(d.stepTextW)
        text:SetJustifyH("LEFT")
        text:SetJustifyV("TOP")
        text:SetWordWrap(true)
        row.text = text
        local pin = CreateFrame("Button", nil, row)
        pin:SetSize(18, 18)
        pin:SetPoint("TOPRIGHT", -2, -1)
        local pinTex = pin:CreateTexture(nil, "ARTWORK")
        pinTex:SetAllPoints()
        Atlas(pinTex, "Waypoint-MapPin-Tracked", "Interface\\Minimap\\Tracking\\None")
        pin:SetScript("OnClick", function() if row.step then ns.StepWaypoint(row.secret, row.step) end end)
        row.pin = pin
        -- A step with a `macro` gets a button that runs it. Targeting and
        -- emotes are protected, so it is a secure macro button: the
        -- player's own click runs the line as if it were typed.
        local act = Make("Button", nil, row, "SecureActionButtonTemplate")
        act:SetSize(ACTION_W - 4, 18)
        act:SetPoint("TOPRIGHT", -22, -1)
        act:RegisterForClicks("AnyUp", "AnyDown")
        local actBack = act:CreateTexture(nil, "BACKGROUND")
        actBack:SetAllPoints()
        actBack:SetColorTexture(0.25, 0.2, 0.05, 0.8)
        local actGlow = act:CreateTexture(nil, "HIGHLIGHT")
        actGlow:SetAllPoints()
        actGlow:SetColorTexture(1, 0.82, 0, 0.25)
        act.label = act:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        act.label:SetPoint("CENTER")
        act:SetScript("OnEnter", function(self)
            if not (GameTooltip and self.macro) then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Click: " .. self.macro, 1, 1, 1)
            GameTooltip:Show()
        end)
        act:SetScript("OnLeave", HideTooltip)
        act:Hide()
        row.act = act
        row:SetScript("OnClick", function(self, button)
            if not self.step then return end
            if button == "RightButton" then ns.ToggleStep(self.secret.id, self.index)
            else ns.StepWaypoint(self.secret, self.step) end
        end)
        row:SetScript("OnEnter", StepTooltip)
        row:SetScript("OnLeave", HideTooltip)
        d.steps[i] = row
    end
    d.more = d:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    d.more:SetPoint("BOTTOMLEFT", 0, 6)

    local mark = Make("Button", nil, d, "UIPanelButtonTemplate")
    mark:SetSize(120, 22)
    mark:SetPoint("BOTTOMRIGHT", 0, 0)
    mark:SetScript("OnClick", function()
        if selected then ns.ToggleDone(selected) end
    end)
    d.mark = mark

    -- The model sits top right in the guide, for what has one to show.
    local back = g:CreateTexture(nil, "BACKGROUND")
    back:SetSize(MODEL_SIZE, MODEL_SIZE)
    back:SetPoint("TOPRIGHT", -14, -44)
    back:SetColorTexture(0, 0, 0, 0.35)
    local model = CreateFrame("PlayerModel", nil, g)
    model:SetAllPoints(back)
    model.back = back
    model:EnableMouse(true)
    model:SetScript("OnMouseDown", function(self) self.turning = GetCursorPosition() end)
    model:SetScript("OnMouseUp", function(self) self.turning = nil end)
    model:SetScript("OnUpdate", function(self)
        if not self.turning then return end
        local x = GetCursorPosition()
        self.facing = (self.facing or 0) + (x - self.turning) * 0.02
        self.turning = x
        if self.SetFacing then self:SetFacing(self.facing) end
    end)
    model:Hide()
    back:Hide()
    g.model = model
    return g
end

local function BuildFrame()
    local f = Make("Frame", "ForeverSecretTrackerFrame", UIParent, "PortraitFrameTemplate")
    f:SetSize(WIDTH, HEIGHT)
    PlaceFrame(f)
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition(self)
    end)
    f:Hide()
    if ButtonFrameTemplate_HideAttic then Try(ButtonFrameTemplate_HideAttic, f) end

    if not Field(f, "PortraitContainer") and not Field(f, "NineSlice") then
        local bg = f:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.08, 0.07, 0.06, 0.96)
    end
    if f.SetTitle and Field(f, "TitleContainer") then
        f:SetTitle("Forever Secret Tracker")
    else
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -6)
        title:SetText("Forever Secret Tracker")
    end
    local container = Field(f, "PortraitContainer")
    local portrait = container and Field(container, "portrait") or Field(f, "portrait")
    if portrait then portrait:SetTexture(PORTRAIT) end
    if not Field(f, "CloseButton") then
        local close = Make("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -2, -2)
    end

    local inset = CreateFrame("Frame", nil, f)
    inset:SetPoint("TOPLEFT", 4, -60)
    inset:SetPoint("BOTTOMRIGHT", -6, 4)
    local insetBg = inset:CreateTexture(nil, "BACKGROUND")
    insetBg:SetAllPoints()
    insetBg:SetColorTexture(0.11, 0.09, 0.07, 0.98)
    f.inset = inset

    -- Header, shared by both tabs.
    local counter = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    counter:SetPoint("TOPLEFT", 70, -34)
    f.counter = counter
    f.progress = MakeBar(f, 200, 12)
    f.progress:SetPoint("LEFT", counter, "RIGHT", 12, 0)

    local search = Make("EditBox", "ForeverSecretTrackerSearch", inset, "SearchBoxTemplate")
    if not Field(search, "Instructions") then
        search:Hide()
        search = Make("EditBox", "ForeverSecretTrackerSearch", inset, "InputBoxTemplate")
    end
    search:SetSize(200, 20)
    search:SetPoint("TOPLEFT", 14, -12)
    search:SetAutoFocus(false)
    search:HookScript("OnTextChanged", function(self)
        searchText = (self:GetText() or ""):lower()
        Changed()
    end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    f.search = search

    local filter = Try(CreateFrame, "DropdownButton", nil, inset, "WowStyle1FilterDropdownTemplate")
        or Make("Button", nil, inset, "UIPanelButtonTemplate")
    filter:SetSize(90, 22)
    filter:SetPoint("TOPRIGHT", -12, -10)
    if filter.SetText then filter:SetText("Filter") end
    if not SetupFilterMenu(filter) then
        -- No menu API: the button steps through showing everything or not.
        filter:SetScript("OnClick", function()
            DB().showAll = not DB().showAll or nil
            Changed()
        end)
    end
    f.filter = filter

    f.overview = BuildOverview(inset)
    f.guides = BuildGuides(inset)

    f.tabs = {}
    local prev
    for i, t in ipairs({ { "overview", "Overview" }, { "guides", "Guides" } }) do
        local tab = Make("Button", "ForeverSecretTrackerFrameTab" .. i, f, "PanelTabButtonTemplate")
        tab:SetText(t[2])
        if PanelTemplates_TabResize then Try(PanelTemplates_TabResize, tab, 0) else tab:SetSize(100, 32) end
        if prev then tab:SetPoint("LEFT", prev, "RIGHT", 3, 0)
        else tab:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 11, 2) end
        tab.view = t[1]
        tab:SetScript("OnClick", function()
            view = t[1]
            Refresh()
        end)
        f.tabs[i] = tab
        prev = tab
    end

    if UISpecialFrames then table.insert(UISpecialFrames, "ForeverSecretTrackerFrame") end
    return f
end

-- Copy box ------------------------------------------------------------------

-- The game cannot open links, so the link is put in a box, selected,
-- for Ctrl+C.
local copyBox

local function BuildCopyBox()
    local c = CreateFrame("Frame", "ForeverSecretTrackerCopy", UIParent)
    c:SetSize(360, 86)
    c:SetPoint("CENTER", 0, 120)
    c:SetFrameStrata("FULLSCREEN_DIALOG")
    c:EnableMouse(true)
    local bg = c:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.06, 0.05, 0.08, 0.97)
    local top = c:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT")
    top:SetPoint("TOPRIGHT")
    top:SetHeight(2)
    top:SetColorTexture(0.8, 0.65, 0.1)
    local label = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOP", 0, -10)
    label:SetText("Press Ctrl+C to copy the link")
    local box = Make("EditBox", "ForeverSecretTrackerCopyBox", c, "InputBoxTemplate")
    box:SetSize(320, 22)
    box:SetPoint("TOP", 0, -34)
    box:SetAutoFocus(false)
    box:SetScript("OnEscapePressed", function() c:Hide() end)
    box:SetScript("OnEnterPressed", function() c:Hide() end)
    -- Typing in it would lose the link, so it keeps putting it back.
    box:SetScript("OnTextChanged", function(self, user)
        if user and self:GetText() ~= c.url then
            self:SetText(c.url or "")
            self:HighlightText()
        end
    end)
    c.box = box
    local hint = c:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOM", 0, 8)
    hint:SetText("Escape or Enter closes")
    local close = Make("Button", nil, c, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)
    c:Hide()
    return c
end

function ns.ShowLink(url)
    copyBox = copyBox or BuildCopyBox()
    copyBox.url = url
    copyBox.box:SetText(url)
    copyBox:Show()
    copyBox.box:SetFocus()
    copyBox.box:HighlightText()
end

-- Toast -----------------------------------------------------------------------

local toast
local TOAST_IN, TOAST_HOLD, TOAST_OUT = 0.3, 5, 1

local function BuildToast()
    local t = CreateFrame("Button", "ForeverSecretTrackerToast", UIParent)
    t:SetSize(300, 64)
    t:SetPoint("TOP", 0, -150)
    t:SetFrameStrata("HIGH")
    local bg = t:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.04, 0.03, 0.09, 0.95)
    local top = t:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT")
    top:SetPoint("TOPRIGHT")
    top:SetHeight(2)
    top:SetColorTexture(0.8, 0.65, 0.1)
    local icon = t:CreateTexture(nil, "ARTWORK")
    icon:SetSize(44, 44)
    icon:SetPoint("LEFT", 10, 0)
    t.icon = icon
    local label = t:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", 64, -12)
    label:SetText("Secret found!")
    local name = t:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    name:SetPoint("TOPLEFT", 64, -28)
    name:SetWidth(226)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    t.name = name
    t:SetScript("OnClick", function(self)
        self:Hide()
        if not (frame and frame:IsShown()) then ns.Toggle() end
        if self.secret then OpenGuide(self.secret.id) end
    end)
    t:SetScript("OnUpdate", function(self, elapsed)
        self.age = (self.age or 0) + (elapsed or 0)
        local a
        if self.age < TOAST_IN then a = self.age / TOAST_IN
        elseif self.age < TOAST_IN + TOAST_HOLD then a = 1
        else a = 1 - (self.age - TOAST_IN - TOAST_HOLD) / TOAST_OUT end
        if a <= 0 then self:Hide() return end
        self:SetAlpha(a)
    end)
    t:Hide()
    return t
end

function ns.OnFound(secret)
    toast = toast or BuildToast()
    toast.secret = secret
    toast.icon:SetTexture(Icon(secret))
    toast.name:SetText(secret.name)
    toast.age = 0
    toast:SetAlpha(0)
    toast:Show()
    if PlaySound and SOUNDKIT then
        local sound = SOUNDKIT.UI_EPICLOOT_TOAST or SOUNDKIT.UI_LEGENDARY_LOOT_TOAST
        if sound then Try(PlaySound, sound) end
    end
end

-- Minimap button --------------------------------------------------------------

local minimapButton

local function PlaceMinimapButton()
    local angle = math.rad(DB().minimapAngle or 225)
    local radius = (Minimap:GetWidth() or 140) / 2 + 5
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function BuildMinimapButton()
    local b = CreateFrame("Button", "ForeverSecretTrackerMinimapButton", Minimap)
    b:SetSize(32, 32)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")
    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexture(PORTRAIT)
    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
    b:SetScript("OnClick", function() ns.Toggle() end)
    b:SetScript("OnDragStart", function(self) self.dragging = true end)
    b:SetScript("OnDragStop", function(self) self.dragging = nil end)
    b:SetScript("OnUpdate", function(self)
        if not self.dragging then return end
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale() or 1
        DB().minimapAngle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
        PlaceMinimapButton()
    end)
    b:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Forever Secret Tracker")
        local found, total = ns.Counts(DB().showAll)
        GameTooltip:AddLine(string.format("%d / %d secrets found", found, total), 1, 1, 1)
        GameTooltip:AddLine("Click to open, drag to move", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", HideTooltip)
    return b
end

function ns.UpdateMinimapButton()
    if not Minimap then return end
    minimapButton = minimapButton or BuildMinimapButton()
    PlaceMinimapButton()
    minimapButton:SetShown(not DB().hideMinimap)
end

-- Entry points ----------------------------------------------------------------

function ns.Toggle()
    frame = frame or BuildFrame()
    if frame:IsShown() then
        frame:Hide()
    else
        ns.EvaluateAll(true)
        frame:Show()
        Refresh()
    end
end

function ns.OnChanged()
    if frame and frame:IsShown() then Refresh() end
end

function ns.OpenGuide(id)
    if not (frame and frame:IsShown()) then ns.Toggle() end
    OpenGuide(id)
end

-- Options page ----------------------------------------------------------------

local optionsPage, optionsCategory

local OPTIONS = {
    { label = "Write finds and waypoints in chat",
      note = "Only you see these lines. Answers to /fst commands are always written.",
      get = function() return not DB().quiet end,
      set = function(on) DB().quiet = not on or nil end },
    { label = "Post finds in guild chat",
      note = "Says \"Found a secret: <name>!\" in guild chat when the addon sees you find one. Marks you make by hand are not posted.",
      get = function() return DB().guild and true or false end,
      set = function(on) DB().guild = on or nil end },
    { label = "Show the minimap button",
      get = function() return not DB().hideMinimap end,
      set = function(on)
          DB().hideMinimap = not on or nil
          ns.UpdateMinimapButton()
      end },
}

function ns.RefreshOptions()
    if not optionsPage then return end
    for _, box in ipairs(optionsPage.boxes) do box:SetChecked(box.option.get()) end
end

function ns.RegisterOptions()
    if optionsPage then return end
    local panel = CreateFrame("Frame")
    -- A new frame starts shown, so the first OnShow would never come.
    panel:Hide()
    panel.name = "Forever Secret Tracker"
    local heading = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 16, -16)
    heading:SetText("Forever Secret Tracker")
    panel.boxes = {}
    local y = -56
    for _, option in ipairs(OPTIONS) do
        local box = Make("CheckButton", nil, panel, "UICheckButtonTemplate")
        box:SetSize(26, 26)
        box:SetPoint("TOPLEFT", 16, y)
        box.option = option
        box:SetScript("OnClick", function(self) option.set(self:GetChecked() and true or false) end)
        local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("LEFT", box, "RIGHT", 4, 0)
        label:SetText(option.label)
        if option.note then
            local note = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            note:SetPoint("TOPLEFT", 48, y - 26)
            note:SetWidth(520)
            note:SetJustifyH("LEFT")
            note:SetText(option.note)
            y = y - 22
        end
        panel.boxes[#panel.boxes + 1] = box
        y = y - 36
    end
    panel:SetScript("OnShow", ns.RefreshOptions)
    optionsPage = panel
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, panel, panel.name)
        if ok and category then
            pcall(Settings.RegisterAddOnCategory, category)
            optionsCategory = category
            return
        end
    end
    if InterfaceOptions_AddCategory then
        pcall(InterfaceOptions_AddCategory, panel)
        optionsCategory = panel
    end
end

function ns.OpenOptions()
    if optionsCategory and Settings and Settings.OpenToCategory and optionsCategory.GetID then
        pcall(Settings.OpenToCategory, optionsCategory:GetID())
    elseif optionsCategory and InterfaceOptionsFrame_OpenToCategory then
        pcall(InterfaceOptionsFrame_OpenToCategory, optionsCategory)
    else
        ns.Msg("no options window in this client; use /fst chat, /fst guild and /fst minimap.")
    end
end
