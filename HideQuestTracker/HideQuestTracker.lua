-- HideQuestTracker -- fades the quest tracker out while you are in combat.
--
-- Alpha rather than Hide(): the tracker holds secure quest item buttons, and
-- hiding their parent in combat is blocked. SetAlpha never is. A faded tracker
-- would still take clicks, so its lines stop taking the mouse until it is back.
-- Quest item buttons are the exception: they keep the mouse, and stay in
-- sight by ignoring the tracker's alpha.

local DEFAULTS = { enabled = true, combatAlpha = 0, fade = 0.3, keepItems = true }
local MAX_FADE = 2
-- Lines the tracker creates mid-fight take the mouse again; look this often.
local SWEEP = 0.5

-- ObjectiveTrackerFrame is the one Forever uses (seen 2026-10-15); the older
-- names are a fallback in case a client branch still has them.
local CANDIDATES = { "ObjectiveTrackerFrame", "QuestWatchFrame", "WatchFrame" }

local db
local tracker, trackerName
local restoreAlpha = 1
local hidden = false
local fading
local muted, kept = {}, {}
local sinceSweep = 0
local settingsCategory

local function Msg(fmt, ...)
    print("|cff7fbf7fHideQuestTracker|r: " .. string.format(fmt, ...))
end

-- The Controller UI has no API of its own to ask; its frames give it away.
local function ControllerUI()
    local bar = GamepadMainActionBarFrame
    return (GamepadCinematicSkipButton or (bar and bar.IsShown and bar:IsShown())) and true or false
end

-- The tracker that is showing wins, so a client that keeps a second one
-- around hidden does not get the fade.
local function FindTracker()
    local first, firstName
    for _, name in ipairs(CANDIDATES) do
        local f = _G[name]
        if f and f.SetAlpha then
            if f:IsShown() then return f, name end
            first, firstName = first or f, firstName or name
        end
    end
    return first, firstName
end

-- Secure, or carrying an item the way Blizzard's buttons do.
local function IsItemButton(f)
    if f.IsProtected and f:IsProtected() then return true end
    local name = f.GetName and f:GetName()
    if name and name:find("ItemButton") then return true end
    if f.GetAttribute then
        local ok, kind = pcall(f.GetAttribute, f, "type")
        if ok and kind == "item" then return true end
    end
    return f.itemLink ~= nil
end

local function Mute(frame)
    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        if IsItemButton(child) then
            if db.keepItems and not kept[child] and child.SetIgnoreParentAlpha
                and pcall(child.SetIgnoreParentAlpha, child, true) then
                kept[child] = true
            end
        else
            if not muted[child] and child.IsMouseEnabled and child:IsMouseEnabled() then
                if pcall(child.EnableMouse, child, false) then muted[child] = true end
            end
            Mute(child)
        end
    end
end

local function Unmute()
    for child in pairs(muted) do pcall(child.EnableMouse, child, true) end
    for child in pairs(kept) do pcall(child.SetIgnoreParentAlpha, child, false) end
    muted, kept = {}, {}
end

-- Switched mid-fight: the buttons follow at once.
local function SetKeepItems(on)
    if on then
        if hidden and tracker then Mute(tracker) end
    else
        for child in pairs(kept) do pcall(child.SetIgnoreParentAlpha, child, false) end
        kept = {}
    end
end

local animator = CreateFrame("Frame")
animator:Hide()

local function FadeTo(alpha)
    if (db.fade or 0) <= 0 then
        tracker:SetAlpha(alpha)
        fading = nil
    else
        fading = { from = tracker:GetAlpha(), to = alpha, t = 0 }
    end
    animator:Show()
end

animator:SetScript("OnUpdate", function(self, elapsed)
    if not tracker then self:Hide() return end
    if fading then
        fading.t = fading.t + elapsed
        local p = math.min(1, fading.t / db.fade)
        tracker:SetAlpha(fading.from + (fading.to - fading.from) * p)
        if p < 1 then return end
        fading = nil
    end
    if hidden then
        -- Held down for the whole fight, in case the tracker resets itself.
        if tracker:GetAlpha() ~= db.combatAlpha then tracker:SetAlpha(db.combatAlpha) end
        sinceSweep = sinceSweep + elapsed
        if sinceSweep >= SWEEP then
            sinceSweep = 0
            Mute(tracker)
        end
    else
        Unmute()
        self:Hide()
    end
end)

local function Conceal()
    if not db.enabled or hidden then return end
    if not fading then
        tracker, trackerName = FindTracker()
        if not tracker then return end
        -- Captured on the way down, so a tracker another addon has dimmed comes
        -- back to where that addon left it.
        restoreAlpha = tracker:GetAlpha()
    end
    hidden = true
    sinceSweep = 0
    Mute(tracker)
    FadeTo(db.combatAlpha)
end

local function Reveal()
    if not tracker or not hidden then return end
    hidden = false
    FadeTo(restoreAlpha)
end

local function Toggle()
    if hidden then Reveal() else Conceal() end
end

-- What the client has, kept in the saved file: with the Controller UI the
-- tracker may be a frame of its own, and its name is what is needed then.
local function Probe()
    local found, others = {}, {}
    for _, name in ipairs(CANDIDATES) do
        local f = _G[name]
        if f then table.insert(found, name .. (f.IsShown and f:IsShown() and "" or " (hidden)")) end
    end
    for name, f in pairs(_G) do
        if type(name) == "string" and type(f) == "table" and f.GetObjectType and f.IsShown
            and (name:find("Gamepad") or name:find("Controller"))
            and (name:find("Quest") or name:find("Objective") or name:find("Tracker")) then
            local ok, shown = pcall(f.IsShown, f)
            if ok and shown then table.insert(others, name) end
        end
    end
    table.sort(others)
    local muteCount, items = 0, {}
    for _ in pairs(muted) do muteCount = muteCount + 1 end
    for child in pairs(kept) do table.insert(items, (child.GetName and child:GetName()) or "?") end
    table.sort(items)
    db.probe = {
        tracker = trackerName or (select(2, FindTracker())),
        candidates = table.concat(found, ", "),
        controllerUI = ControllerUI(),
        controllerFrames = #others > 0 and table.concat(others, ", ") or nil,
        muted = muteCount,
        itemButtons = #items > 0 and table.concat(items, ", ") or nil,
    }
    return db.probe
end

local function Status()
    local p = Probe()
    if not p.tracker then
        Msg("no quest tracker found yet -- still looking each fight.")
    else
        Msg("%s | tracker %s | %d%% in combat | fade %.1fs | %s",
            db.enabled and "on" or "off", p.tracker, math.floor(db.combatAlpha * 100 + 0.5),
            db.fade, hidden and "faded" or "showing")
    end
    if p.controllerUI then
        Msg("Controller UI on%s.", p.controllerFrames and ("; its frames: " .. p.controllerFrames) or "")
    end
end

-- ------------------------------------------------------------
-- Options > AddOns
-- ------------------------------------------------------------

-- OptionsSliderTemplate names its labels $parentLow/$parentHigh/$parentText.
-- Newer clients also expose them as .Low/.High/.Text -- take whichever exists.
local function SliderLabels(slider, name)
    return slider.Low or _G[name .. "Low"],
           slider.High or _G[name .. "High"],
           slider.Text or _G[name .. "Text"]
end

local function BuildSettingsPage(page)
    local heading = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 16, -16)
    heading:SetText("Hide Quest Tracker")

    local function Check(key, name, y, text, onClick)
        local box = CreateFrame("CheckButton", "HideQuestTrackerSettings" .. name .. "Check", page, "UICheckButtonTemplate")
        box:SetPoint("TOPLEFT", 10, y)
        box:SetSize(24, 24)
        local label = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", box, "RIGHT", 2, 0)
        label:SetText(text)
        box:SetScript("OnClick", function(self)
            db[key] = self:GetChecked() and true or false
            onClick()
            page.refresh()
        end)
        page[key] = box
    end
    Check("enabled", "Enabled", -48, "Fade the quest tracker out while you are in combat", function()
        if not db.enabled then Reveal() end
    end)
    Check("keepItems", "KeepItems", -70, "Keep quest item buttons in sight while the rest fades", function()
        SetKeepItems(db.keepItems)
    end)

    local function Slider(name, y, lo, hi, step, lowText, highText, onChange)
        local s = CreateFrame("Slider", name, page, "OptionsSliderTemplate")
        s:SetPoint("TOPLEFT", 20, y)
        s:SetWidth(300)
        s:SetMinMaxValues(lo, hi)
        s:SetValueStep(step)
        if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
        local low, high, text = SliderLabels(s, name)
        if low then low:SetText(lowText) end
        if high then high:SetText(highText) end
        s.label = text
        s:SetScript("OnValueChanged", function(self, value)
            -- Divided rather than multiplied, so 3 steps of 0.1 is exactly 0.3.
            value = math.floor(value / step + 0.5) / math.floor(1 / step + 0.5)
            onChange(value)
            page.refresh()
        end)
        return s
    end

    page.alpha = Slider("HideQuestTrackerAlphaSlider", -122, 0, 1, 0.05, "Gone", "Unchanged", function(v)
        if v == db.combatAlpha then return end
        db.combatAlpha = v
        if hidden and not fading and tracker then tracker:SetAlpha(v) end
    end)
    page.fade = Slider("HideQuestTrackerFadeSlider", -182, 0, MAX_FADE, 0.1, "Instant", MAX_FADE .. " s", function(v)
        db.fade = v
    end)

    local test = CreateFrame("Button", "HideQuestTrackerSettingsTestButton", page, "UIPanelButtonTemplate")
    test:SetPoint("TOPLEFT", 16, -232)
    test:SetSize(140, 24)
    test:SetText("Try it now")
    test:SetScript("OnClick", function()
        Toggle()
        page.refresh()
    end)
    page.test = test

    local note = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", 20, -266)
    note:SetWidth(520)
    note:SetJustifyH("LEFT")
    note:SetText("While faded the tracker does not take clicks, so you cannot open a quest by accident "
        .. "in the middle of a fight. Quest item buttons stay clickable either way.")

    local state = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    state:SetPoint("TOPLEFT", 16, -312)
    state:SetWidth(540)
    state:SetJustifyH("LEFT")
    page.state = state

    function page.refresh()
        page.enabled:SetChecked(db.enabled and true or false)
        page.keepItems:SetChecked(db.keepItems and true or false)
        -- SetValue fires OnValueChanged, so only when it is really off.
        if math.abs((page.alpha:GetValue() or 0) - db.combatAlpha) > 0.001 then page.alpha:SetValue(db.combatAlpha) end
        if math.abs((page.fade:GetValue() or 0) - db.fade) > 0.001 then page.fade:SetValue(db.fade) end
        if page.alpha.label then
            page.alpha.label:SetText(("Tracker opacity in combat: %d%%"):format(math.floor(db.combatAlpha * 100 + 0.5)))
        end
        if page.fade.label then
            page.fade.label:SetText(db.fade <= 0 and "Fade time: instant" or ("Fade time: %.1f s"):format(db.fade))
        end
        page.test:SetText(hidden and "Show it again" or "Try it now")
        local _, name = FindTracker()
        state:SetText(name and ("Quest tracker: " .. name) or "No quest tracker found yet.")
    end
end

local function RegisterSettingsPage()
    if settingsCategory then return end
    local page = CreateFrame("Frame")
    -- A new frame starts shown, so the panel showing it the first time is no
    -- change and OnShow, which fills in the values, would not run.
    page:Hide()
    page.name = "Hide Quest Tracker"
    -- Built now rather than in OnShow: creating controls while the panel was
    -- showing the page froze the game with the Controller UI (SortQuestTracker).
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
        Msg("no options window in this client; use the slash commands.")
    end
end

-- ------------------------------------------------------------
-- Events and command
-- ------------------------------------------------------------

local function Help()
    Msg("commands:")
    print("  /hqt              -- show current state")
    print("  /hqt on | off     -- enable or disable")
    print("  /hqt alpha <0-1>  -- 0 hides fully, 0.15 dims, 1 disables the effect")
    print("  /hqt fade <0-" .. MAX_FADE .. ">  -- seconds to fade over, 0 for instant")
    print("  /hqt items        -- keep quest item buttons in sight, or let them fade too")
    print("  /hqt test         -- toggle it now, so you can check it without a fight")
    print("  /hqt options      -- open the options page")
end

SLASH_HIDEQUESTTRACKER1 = "/hidequesttracker"
SLASH_HIDEQUESTTRACKER2 = "/hqt"

SlashCmdList.HIDEQUESTTRACKER = function(input)
    local cmd, arg = string.match(input or "", "^%s*(%S*)%s*(%S*)")
    cmd = string.lower(cmd or "")
    local n = tonumber(arg)

    if cmd == "" or cmd == "status" then
        Status()
        Help()

    elseif cmd == "on" then
        db.enabled = true
        Status()

    elseif cmd == "off" then
        db.enabled = false
        Reveal()
        Status()

    elseif cmd == "alpha" and n then
        if n < 0 or n > 1 then
            Msg("alpha must be between 0 and 1.")
        else
            db.combatAlpha = n
            if hidden and not fading then tracker:SetAlpha(n) end
            Status()
        end

    elseif cmd == "fade" and n then
        if n < 0 or n > MAX_FADE then
            Msg("fade must be between 0 and %d seconds.", MAX_FADE)
        else
            db.fade = n
            Status()
        end

    elseif cmd == "items" then
        db.keepItems = not db.keepItems
        SetKeepItems(db.keepItems)
        Msg(db.keepItems and "quest item buttons stay in sight while the tracker fades."
            or "quest item buttons fade with the tracker.")

    elseif cmd == "test" then
        Toggle()
        if not tracker then
            Msg("still cannot find a quest tracker. Hover it with /fstack and tell which frame it is.")
        end
        Status()

    elseif cmd == "options" or cmd == "gui" then
        OpenSettings()

    else
        Help()
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")

f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= "HideQuestTracker" then return end
        HideQuestTrackerDB = HideQuestTrackerDB or {}
        db = HideQuestTrackerDB
        for k, v in pairs(DEFAULTS) do
            if db[k] == nil then db[k] = v end
        end
        RegisterSettingsPage()

    elseif not db then
        return

    elseif event == "PLAYER_LOGIN" then
        -- A /reload mid-fight should not leave the tracker showing.
        if InCombatLockdown() then Conceal() end

    elseif event == "PLAYER_REGEN_DISABLED" then
        Conceal()

    elseif event == "PLAYER_REGEN_ENABLED" then
        Reveal()
    end
end)
