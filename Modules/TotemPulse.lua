local select, pairs, tremove, tinsert, format, strsplit, tonumber = select, pairs, tremove, tinsert, format, strsplit, tonumber
local type = type
local C_NamePlate = C_NamePlate
local Core = LibStub("TotemPlates")
local L = Core.L
local GetSpellInfo, CreateFrame = GetSpellInfo, CreateFrame
local GetTime, UnitIsEnemy, UnitGUID = GetTime, UnitIsEnemy, UnitGUID
local UIParent = UIParent

---------------------------------------------------

-- Helper

---------------------------------------------------

local totemDataConfig, npcIdToTotemData, cooldowns = Core:GetTotemData()
local ninetyDegreeInRad = 90 * math.pi / 180

local function TotemOptions()
    local defaultDB = {}
    local options = {}
    local indexedList = {}
    for k,v in pairs(totemDataConfig) do
        if v.pulse then
            tinsert(indexedList, {name = k, id = v.id, color = v.color, texture = v.texture})
        end
    end
    table.sort(indexedList, function (a, b)
        return a.name < b.name
    end)
    for i=1,#indexedList do
        defaultDB["totem" .. indexedList[i].id] = {enabled = true, attachTototemPlateFrame = true, style = "COOLDOWN", reverse = false}
        options["totem" .. indexedList[i].id] = {
            order = i+1,
            name = select(1, GetSpellInfo(indexedList[i].id)),
            --inline = true,
            width  = "3.0",
            type = "group",
            icon = indexedList[i].texture,
            args = {
                headerTotemConfig = {
                    type = "header",
                    name = format("|T%s:20|t %s", indexedList[i].texture, select(1, GetSpellInfo(indexedList[i].id))),
                    order = 1,
                },
                enabled = {
                    order = 2,
                    name = L["Enabled"],
                    desc = "Enable " .. format("|T%s:20|t %s", indexedList[i].texture, select(1, GetSpellInfo(indexedList[i].id))),
                    type = "toggle",
                    width = "full",
                    get = function() return Core.dbi.profile.totemPulseTotems["totem" .. indexedList[i].id].enabled end,
                    set = function(_, value)
                        Core.dbi.profile.totemPulseTotems["totem" .. indexedList[i].id].enabled = value
                        Core:UpdateFrame()
                    end
                },
                attachTototemPlateFrame = {
                    order = 3,
                    disabled = function() return not Core.dbi.profile.totemPulseTotems["totem" .. indexedList[i].id].enabled end,
                    name = L["Attach To TotemPlate"],
                    desc = "Attach " .. format("|T%s:20|t %s", indexedList[i].texture, select(1, GetSpellInfo(indexedList[i].id))) .. "  To TotemPlate",
                    type = "toggle",
                    width = "full",
                    get = function() return Core.dbi.profile.totemPulseTotems["totem" .. indexedList[i].id].attachTototemPlateFrame end,
                    set = function(_, value)
                        Core.dbi.profile.totemPulseTotems["totem" .. indexedList[i].id].attachTototemPlateFrame = value
                        Core:UpdateFrame()
                    end
                },
                style = {
                    type = "select",
                    name = L["Style"],
                    order = 4,
                    values = {
                        COOLDOWN = L["Cooldown"],
                        Vertical = L["Bar vertical"],
                        Horizontal = L["Bar horizontal"]
                    },
                    get = function() return Core.dbi.profile.totemPulseTotems["totem" .. indexedList[i].id].style end,
                    set = function(_, value)
                        Core.dbi.profile.totemPulseTotems["totem" .. indexedList[i].id].style = value
                        Core:UpdateFrame()
                    end
                },
                reverse = {
                    order = 5,
                    disabled = function() return not Core.dbi.profile.totemPulseTotems["totem" .. indexedList[i].id].enabled end,
                    name = L["Reverse"],
                    type = "toggle",
                    width = "full",
                    get = function() return Core.dbi.profile.totemPulseTotems["totem" .. indexedList[i].id].reverse end,
                    set = function(_, value)
                        Core.dbi.profile.totemPulseTotems["totem" .. indexedList[i].id].reverse = value
                        Core:UpdateFrame()
                    end
                },
            }
        }
    end
    return options,defaultDB
end

---------------------------------------------------

-- Core

---------------------------------------------------

local TotemPulse = Core:NewModule("Totem Pulse", 1, {
    totemPulseEnabled = true,
    totemPulseEnabledShowFriendly = true,
    totemPulseEnabledShowEnemy = true,
    totemPulseStyle = "", -- "COOLDOWN", "COOLDOWNREVERSE", "BARVERTICAL", "BARHORIZONTAL"
    --text
    totemPulseTextColor = { r = 1, g = 1, b = 1, a = 1 },
    totemPulseTextSize = 14,
    totemPulseTextFont = "DorisPP",
    --bar
    totemPulseBarWidth = 40,
    totemPulseBarHeight = 20,
    totemPulseBarColor =  { r = 1, g = 0, b = 0, a = .5 },
    totemPulseBarBgColor =  { r = 0, g = 1, b = 0, a = .5 },
    totemPulseBarBorderColor = { r = 0, g = 0, b = 0, a = 1 },
    totemPulseBarBorderSize = 4,
    totemPulseBarBorderStyle = "Gladdy Tooltip squared",
    totemPulseBarTexture = "Flat",
    totemPulseBarReverse = false,
    --cooldown
    totemPulseCooldownWidth = 40,
    totemPulseCooldownHeight = 20,
    totemPulseCooldownAlpha = 1,
    totemPulseCooldownReverse = true,
    --totems
    totemPulseTotems = select(2, TotemOptions())
})

function TotemPulse:Initialize()
    self.timeStamps = {}
    self.cooldownCache = {}
    self.barCache = {}
    self.activeFrames = { bars = {}, cooldowns = {} }
    if Core.db.totemPulseEnabled then
        self:RegisterMessage("COMBAT_LOG_EVENT_UNFILTERED")
        self:RegisterMessage("NAME_PLATE_UNIT_REMOVED")
        self:RegisterMessage("NAME_PLATE_UNIT_ADDED")
        self:RegisterMessage("UNIT_NAME_UPDATE")
        self:RegisterMessage("PLAYER_ENTERING_WORLD")
    end
end

---------------------------------------------------

-- EVENTS

---------------------------------------------------

function TotemPulse:PLAYER_ENTERING_WORLD()
    self.timeStamps = {}
end

function TotemPulse:COMBAT_LOG_EVENT_UNFILTERED(eventType, sourceGUID, destGUID, spellID, spellName)
    local pulse = cooldowns[spellID] or cooldowns[spellName]
    local npcId = tonumber(select(6, strsplit("-", destGUID)), 10)
    if eventType == "UNIT_DESTROYED" and self.timeStamps[destGUID] then
        self.timeStamps[destGUID] = nil
    end
    if (eventType == "SWING_DAMAGE" or eventType == "SPELL_DAMAGE") and self.timeStamps[destGUID] and npcIdToTotemData[npcId] then
        self.timeStamps[destGUID] = nil
    end
    if not pulse then
        return
    end
    if eventType == "SPELL_CAST_SUCCESS" then
        self.timeStamps[sourceGUID] = { timeStamp = GetTime(), pulse = pulse }
    end
    if eventType == "SPELL_SUMMON" then
        local totemData = npcIdToTotemData[npcId]
        if not totemData then
            return
        end
        if not (totemData.npc or Core.dbi.profile.totemPulseTotems["totem" .. totemData.id] and Core.dbi.profile.totemPulseTotems["totem" .. totemData.id].enabled) then
            return
        end
        if self.timeStamps[sourceGUID] then
            self.timeStamps[destGUID] = self.timeStamps[sourceGUID]
            self.timeStamps[destGUID].id = totemData.id
            self.timeStamps[sourceGUID] = nil
        else
            self.timeStamps[destGUID] = { timeStamp = GetTime(), pulse = pulse, id = totemData.id }
        end
        self.timeStamps[destGUID].totemData = totemData
    end
end

function TotemPulse:NAME_PLATE_UNIT_REMOVED(unitId)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitId)
    if nameplate.totemTick then
        nameplate.totemTick:SetScript("OnUpdate", nil)
        nameplate.totemTick:Hide()
        nameplate.totemTick:SetParent(nil)
        tinsert(nameplate.totemTick.bar and self.barCache or self.cooldownCache, nameplate.totemTick)
        self.activeFrames.bars[nameplate.totemTick] = nil
        self.activeFrames.cooldowns[nameplate.totemTick] = nil
        nameplate.totemTick = nil
    end
end

function TotemPulse:NAME_PLATE_UNIT_ADDED(unitId)
    self:OnUnitAdded(unitId)
end

function TotemPulse:UNIT_NAME_UPDATE(unitId)
    self:OnUnitAdded(unitId)
end

function TotemPulse:OnUnitAdded(unitId)
    local isEnemy = UnitIsEnemy("player", unitId)
    local guid = UnitGUID(unitId)
    if strsplit("-", guid) ~= "Creature" then
        return
    end

    local nameplate = C_NamePlate.GetNamePlateForUnit(unitId)

    if nameplate and (isEnemy and Core.db.totemPulseEnabledShowEnemy or not isEnemy and Core.db.totemPulseEnabledShowFriendly) then
        if self.timeStamps[guid] and strsplit("-", guid) then
            self:AddTimerFrame(nameplate, self.timeStamps[guid])
        else
            if nameplate.totemTick then
                nameplate.totemTick:SetScript("OnUpdate", nil)
                nameplate.totemTick:Hide()
                nameplate.totemTick:SetParent(nil)
                tinsert(nameplate.totemTick.bar and self.barCache or self.cooldownCache, nameplate.totemTick)
                self.activeFrames.bars[nameplate.totemTick] = nil
                self.activeFrames.cooldowns[nameplate.totemTick] = nil
                nameplate.totemTick = nil
            end
        end
    end
end

---------------------------------------------------

-- FRAMES

---------------------------------------------------

function TotemPulse:CreateCooldownFrame(style)
    local totemTick

    if style == "COOLDOWN" then
        if #self.cooldownCache > 0 then
            totemTick = tremove(self.cooldownCache, #self.cooldownCache)
        else
            totemTick = CreateFrame("Frame")
            totemTick:SetWidth(Core.db.totemPulseCooldownWidth)
            totemTick:SetHeight(Core.db.totemPulseCooldownHeight)
            totemTick.cd = CreateFrame("Cooldown", nil, totemTick, "CooldownFrameTemplate")
            totemTick.cd:SetAllPoints(totemTick)
            totemTick.cd.noCooldownCount = true
            totemTick:SetFrameStrata("MEDIUM")
            totemTick:SetFrameLevel(4)
            totemTick.cd:SetReverse(Core.db.totemPulseCooldownReverse)
            totemTick.cd:SetHideCountdownNumbers(true)
            totemTick.cd:SetAlpha(Core.db.totemPulseCooldownAlpha)

            totemTick.textFrame = CreateFrame("Frame", nil, totemTick)
            totemTick.textFrame:SetAllPoints(totemTick)
            totemTick.text = totemTick.textFrame:CreateFontString(nil, "OVERLAY")
            totemTick.text:SetPoint("CENTER", totemTick.textFrame, "CENTER")
            totemTick.text:SetFont(Core:SMFetch("font", "totemPulseTextFont"), Core.db.totemPulseTextSize, "OUTLINE")
            totemTick.text:SetJustifyH("CENTER")
            totemTick.text:SetShadowOffset(1, -1)
            totemTick.text:SetTextColor(Core:SetColor(Core.db.totemPulseTextColor))
        end
    else
        if #self.barCache > 0 then
            totemTick = tremove(self.barCache, #self.barCache)
            totemTick.bar:SetOrientation(style)
            totemTick.spark:SetRotation(style == "Vertical" and ninetyDegreeInRad or 0)
            totemTick.spark:SetHeight(style == "Vertical" and Core.db.totemPulseBarWidth or Core.db.totemPulseBarHeight)
        else
            totemTick = CreateFrame("Frame", nil)

            totemTick:SetWidth(Core.db.totemPulseBarWidth)
            totemTick:SetHeight(Core.db.totemPulseBarHeight)

            totemTick.backdrop = CreateFrame("Frame", nil, totemTick, BackdropTemplateMixin and "BackdropTemplate")
            totemTick.backdrop:SetAllPoints(totemTick)
            totemTick.backdrop:SetBackdrop({ edgeFile = Core:SMFetch("border", "totemPulseBarBorderStyle"),
                                             edgeSize = Core.db.totemPulseBarBorderSize })
            totemTick.backdrop:SetBackdropBorderColor(Core:SetColor(Core.db.totemPulseBarBorderColor))
            totemTick.backdrop:SetFrameLevel(1)

            totemTick.bar = CreateFrame("StatusBar", nil, totemTick)
            totemTick.bar:SetStatusBarTexture(Core:SMFetch("statusbar", "totemPulseBarTexture"))
            totemTick.bar:SetStatusBarColor(Core:SetColor(Core.db.totemPulseBarColor))
            totemTick.bar:SetOrientation(style)
            totemTick.bar:SetFrameLevel(0)
            totemTick.bar:SetAllPoints(totemTick)

            totemTick.spark = totemTick.bar:CreateTexture(nil, "OVERLAY")
            totemTick.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
            totemTick.spark:SetBlendMode("ADD")
            totemTick.spark:SetWidth(8)
            totemTick.spark:SetHeight(style == "Vertical" and Core.db.totemPulseBarWidth or Core.db.totemPulseBarHeight)
            totemTick.spark.position = 0
            totemTick.spark:SetRotation(style == "Vertical" and ninetyDegreeInRad or 0)

            totemTick.bg = totemTick:CreateTexture(nil, "ARTWORK")
            totemTick.bg:SetTexture(Core:SMFetch("statusbar", "totemPulseBarTexture"))
            totemTick.bg:SetAllPoints(totemTick.bar)
            totemTick.bg:SetVertexColor(Core:SetColor(Core.db.totemPulseBarBgColor))

            totemTick.text = totemTick.bar:CreateFontString(nil, "OVERLAY")
            totemTick.text:SetPoint("CENTER", totemTick, "CENTER", 0, 0)
            totemTick.text:SetFont(Core:SMFetch("font", "totemPulseTextFont"), Core.db.totemPulseTextSize, "OUTLINE")
            totemTick.text:SetJustifyH("CENTER")
            totemTick.text:SetShadowOffset(1, -1)
            totemTick.text:SetTextColor(Core:SetColor(Core.db.totemPulseTextColor))
        end
    end
    return totemTick
end

function TotemPulse:AddTimerFrame(nameplate, timestamp, test)
    if (nameplate:IsShown() or test) and timestamp then
        if not nameplate.totemTick then
            if timestamp.totemData and timestamp.totemData.npc then
                nameplate.totemTick = TotemPulse:CreateCooldownFrame("COOLDOWN")
            else
                nameplate.totemTick = TotemPulse:CreateCooldownFrame(Core.db.totemPulseTotems["totem" .. timestamp.id].style)
            end
        end
        nameplate.totemTick:SetParent(nameplate)

        local cd = type(timestamp.pulse) == "table" and timestamp.pulse.cd or timestamp.pulse
        local once = type(timestamp.pulse) == "table"
        local cooldown = (timestamp.timeStamp - GetTime()) % cd

        nameplate.totemTick.timestamp = timestamp.timeStamp
        nameplate.totemTick.totemData = timestamp.totemData
        nameplate.totemTick.maxValue = cd
        nameplate.totemTick.value = cooldown
        nameplate.totemTick.once = once
        nameplate.totemTick.id = timestamp.id

        if nameplate.totemTick.bar then
            self:UpdateBarPartial(nameplate.totemTick)
            nameplate.totemTick.bar:SetMinMaxValues(0, cd)
            nameplate.totemTick.bar:SetValue(cooldown)
            self.activeFrames.bars[nameplate.totemTick] = nameplate.totemTick
        else
            self:UpdateCooldown(nameplate.totemTick)
            self.activeFrames.cooldowns[nameplate.totemTick] = nameplate.totemTick
        end

        if once and GetTime() - timestamp.timeStamp > cd then
            nameplate.totemTick:SetScript("OnUpdate", nil)
            nameplate.totemTick:Hide()
        else
            nameplate.totemTick:SetScript("OnUpdate", TotemPulse.TotemPulseOnUpdate)
            nameplate.totemTick:Show()
        end
    else
        if nameplate.totemTick then
            nameplate.totemTick:SetScript("OnUpdate", nil)
            nameplate.totemTick:Hide()
            nameplate.totemTick:SetParent(nil)
            tinsert(nameplate.totemTick.bar and self.barCache or self.cooldownCache, nameplate.totemTick)
            self.activeFrames.bars[nameplate.totemTick] = nil
            self.activeFrames.cooldowns[nameplate.totemTick] = nil
            nameplate.totemTick = nil
        end
    end
end

function TotemPulse:SetSparkPosition(totemTick, referenceSize, vertical)
    if not Core.db.totemPulseTotems["totem" .. totemTick.id].reverse then
        totemTick.bar:SetValue(totemTick.maxValue - totemTick.value)
        totemTick.spark.position = referenceSize / 2 - (totemTick.value / totemTick.maxValue) * referenceSize
        if ( totemTick.spark.position < -referenceSize / 2 ) then
            totemTick.spark.position = -referenceSize / 2
        end
    else
        totemTick.bar:SetValue(totemTick.value)
        totemTick.spark.position = referenceSize / 2 - ((totemTick.maxValue - totemTick.value) / totemTick.maxValue) * referenceSize
        if ( totemTick.spark.position > referenceSize / 2 ) then
            totemTick.spark.position = referenceSize / 2
        end
    end
    totemTick.spark:SetPoint("CENTER", totemTick.bar, "CENTER", vertical and 0 or totemTick.spark.position, vertical and totemTick.spark.position or 0)
end

function TotemPulse.TotemPulseOnUpdate(totemTick)
    totemTick.now = GetTime()
    totemTick.value = (totemTick.timestamp - totemTick.now) % totemTick.maxValue
    if totemTick.once and totemTick.now - totemTick.timestamp >= totemTick.maxValue then
        totemTick:SetScript("OnUpdate", nil)
        totemTick:Hide()
    end
    if not totemTick.bar and not (totemTick.once and totemTick.now - totemTick.timestamp >= totemTick.maxValue) then
        if totemTick.totemData and totemTick.totemData.npc or Core.db.totemPulseTotems["totem" .. totemTick.id].reverse then
            totemTick.cd:SetCooldown(totemTick.now - totemTick.value, totemTick.maxValue)
        else
            totemTick.cd:SetCooldown(totemTick.now - (totemTick.maxValue - totemTick.value), totemTick.maxValue)
        end
    elseif totemTick.bar then
        if Core.db.totemPulseTotems["totem" .. totemTick.id].style == "Vertical" then
            TotemPulse:SetSparkPosition(totemTick, totemTick.bar:GetHeight(), true)
        else
            TotemPulse:SetSparkPosition(totemTick, totemTick.bar:GetWidth(), false)
        end
    end
    totemTick.text:SetFormattedText("%.1f", totemTick.value)
end

---------------------------------------------------

-- Update Styles

---------------------------------------------------

function TotemPulse:UpdateBarPartial(bar)
    local style = bar.id and Core.db.totemPulseTotems["totem" .. bar.id].style

    bar:SetWidth(Core.db.totemPulseBarWidth)
    bar:SetHeight(Core.db.totemPulseBarHeight)

    bar.spark:SetWidth(8)
    bar.spark:SetHeight(style == "Vertical" and Core.db.totemPulseBarWidth or Core.db.totemPulseBarHeight)
    bar.spark:SetRotation(style == "Vertical" and ninetyDegreeInRad or 0)


    if bar:GetParent() and bar:GetParent() ~= UIParent then
        local totemPlateFrame = bar:GetParent().totemPlateFrame and bar:GetParent().totemPlateFrame
        local nameplate = bar:GetParent()
        bar:ClearAllPoints()
        if bar.id and totemPlateFrame and totemPlateFrame:IsShown() and Core.db.totemPulseTotems["totem" .. bar.id].attachTototemPlateFrame then
            bar:SetPoint("TOPLEFT", totemPlateFrame, "TOPLEFT", Core.db.npTotemPlatesSize/16, -Core.db.npTotemPlatesSize/16)
            bar:SetPoint("BOTTOMRIGHT", totemPlateFrame, "BOTTOMRIGHT", -Core.db.npTotemPlatesSize/16, Core.db.npTotemPlatesSize/16)
            if style then
                bar.spark:SetHeight(style == "Vertical" and totemPlateFrame:GetWidth() or totemPlateFrame:GetHeight())
            end
        elseif bar.id and totemPlateFrame and totemPlateFrame:IsShown() and not Core.db.totemPulseTotems["totem" .. bar.id].attachTototemPlateFrame then
            bar:SetPoint("TOP", totemPlateFrame, "BOTTOM", 0, -0.5)
        else
            bar:SetPoint("TOP", nameplate, "BOTTOM", 0, -0.5)
        end
    end
    bar.bar:SetOrientation(style ~= "COOLDOWN" and style or bar.bar:GetOrientation())
end

function TotemPulse:UpdateBar(bar)
    self:UpdateBarPartial(bar)

    bar.backdrop:SetBackdrop({ edgeFile = Core:SMFetch("border", "totemPulseBarBorderStyle"),
                               edgeSize = Core.db.totemPulseBarBorderSize })
    bar.backdrop:SetBackdropBorderColor(Core:SetColor(Core.db.totemPulseBarBorderColor))

    bar.bar:SetStatusBarTexture(Core:SMFetch("statusbar", "totemPulseBarTexture"))
    bar.bar:SetStatusBarColor(Core:SetColor(Core.db.totemPulseBarColor))

    bar.bg:SetTexture(Core:SMFetch("statusbar", "totemPulseBarTexture"))
    bar.bg:SetVertexColor(Core:SetColor(Core.db.totemPulseBarBgColor))

    bar.text:SetFont(Core:SMFetch("font", "totemPulseTextFont"), Core.db.totemPulseTextSize, "OUTLINE")
    bar.text:SetTextColor(Core:SetColor(Core.db.totemPulseTextColor))
end

function TotemPulse:UpdateCooldown(cooldown)
    cooldown:SetWidth(Core.db.totemPulseCooldownWidth)
    cooldown:SetHeight(Core.db.totemPulseCooldownHeight)

    cooldown.cd:SetCooldown(0,0)
    cooldown.cd:SetReverse(Core.db.totemPulseCooldownReverse)
    cooldown.cd:SetAlpha(Core.db.totemPulseCooldownAlpha)

    cooldown.text:SetFont(Core:SMFetch("font", "totemPulseTextFont"), Core.db.totemPulseTextSize, "OUTLINE")
    cooldown.text:SetTextColor(Core:SetColor(Core.db.totemPulseTextColor))

    if cooldown:GetParent() and cooldown:GetParent() ~= UIParent then
        local totemPlateFrame = cooldown:GetParent().totemPlateFrame and cooldown:GetParent().totemPlateFrame
        local nameplate = cooldown:GetParent()
        cooldown:ClearAllPoints()
        if cooldown.id and totemPlateFrame and totemPlateFrame:IsShown() and (cooldown.totemData and cooldown.totemData.npc or Core.db.totemPulseTotems["totem" .. cooldown.id].attachTototemPlateFrame) then
            cooldown:SetPoint("TOPLEFT", totemPlateFrame, "TOPLEFT", Core.db.npTotemPlatesSize/16, -Core.db.npTotemPlatesSize/16)
            cooldown:SetPoint("BOTTOMRIGHT", totemPlateFrame, "BOTTOMRIGHT", -Core.db.npTotemPlatesSize/16, Core.db.npTotemPlatesSize/16)
        elseif cooldown.id and totemPlateFrame and totemPlateFrame:IsShown() and not Core.db.totemPulseTotems["totem" .. cooldown.id].attachTototemPlateFrame then
            cooldown:SetPoint("TOP", totemPlateFrame, "BOTTOM", 0, -0.5)
        else
            cooldown:SetPoint("TOP", nameplate, "BOTTOM", 0, -0.5)
        end
    end
end

function TotemPulse:UpdateFrameOnce()
    if Core.testing then
        TotemPulse:TestOnce()
    end
    if Core.db.totemPulseEnabled then
        self:RegisterMessage("COMBAT_LOG_EVENT_UNFILTERED")
        self:RegisterMessage("NAME_PLATE_UNIT_REMOVED")
        self:RegisterMessage("NAME_PLATE_UNIT_ADDED")
        self:RegisterMessage("UNIT_NAME_UPDATE")
        self:RegisterMessage("PLAYER_ENTERING_WORLD")
    else
        for _,bar in pairs(self.activeFrames.bars) do
            bar:SetScript("OnUpdate", nil)
            bar:Hide()
            bar:SetParent(nil)
            tinsert(self.barCache, bar)
            self.activeFrames.bars[bar] = nil
        end
        for _,cooldown in pairs(self.activeFrames.cooldowns) do
            cooldown:SetScript("OnUpdate", nil)
            cooldown:Hide()
            cooldown:SetParent(nil)
            tinsert(self.cooldownCache, cooldown)
            self.activeFrames.cooldowns[cooldown] = nil
        end
        self:UnregisterAllMessages()
    end
    for _,bar in pairs(self.activeFrames.bars) do
        self:UpdateBar(bar)
    end
    for _,cooldown in pairs(self.activeFrames.cooldowns) do
        self:UpdateCooldown(cooldown)
    end
    for _,bar in pairs(self.barCache) do
        self:UpdateBar(bar)
    end
    for _,cooldown in pairs(self.cooldownCache) do
        self:UpdateCooldown(cooldown)
    end
end

---------------------------------------------------

-- TEST

---------------------------------------------------

function TotemPulse:TestOnce()
    local totemPlatesTestFrame = Core.modules["Totem Plates"].testFrame
    if totemPlatesTestFrame then
        totemPlatesTestFrame.totemData = npcIdToTotemData[5913]
        if totemPlatesTestFrame.totemTick
                and (Core.db.totemPulseTotems["totem" .. npcIdToTotemData[5913].id].style == "COOLDOWN" and totemPlatesTestFrame.totemTick.bar
                or Core.db.totemPulseTotems["totem" .. npcIdToTotemData[5913].id].style ~= "COOLDOWN" and not totemPlatesTestFrame.totemTick.bar) then
            totemPlatesTestFrame.totemTick:SetScript("OnUpdate", nil)
            totemPlatesTestFrame.totemTick:Hide()
            totemPlatesTestFrame.totemTick:SetParent(nil)
            totemPlatesTestFrame.totemTick.id = nil
            tinsert(totemPlatesTestFrame.totemTick.bar and self.barCache or self.cooldownCache, totemPlatesTestFrame.totemTick)
            self.activeFrames.bars[totemPlatesTestFrame.totemTick] = nil
            self.activeFrames.cooldowns[totemPlatesTestFrame.totemTick] = nil
            totemPlatesTestFrame.totemTick = nil
        end

        local timestamp = { timeStamp = GetTime(), pulse = npcIdToTotemData[5913].pulse, id = npcIdToTotemData[5913].id }
        TotemPulse:AddTimerFrame(totemPlatesTestFrame, timestamp, true)
        self.testFrame = totemPlatesTestFrame.totemTick
    end
end

function TotemPulse:Reset()
    if self.testFrame then
        self.testFrame:SetScript("OnUpdate", nil)
        self.testFrame:Hide()
        self.testFrame:SetParent(nil)
        tinsert(self.testFrame.bar and self.barCache or self.cooldownCache, self.testFrame)
        self.activeFrames.bars[self.testFrame] = nil
        self.activeFrames.cooldowns[self.testFrame] = nil
        self.testFrame = nil
        Core.modules["Totem Plates"].testFrame.totemTick = nil
    end
end

---------------------------------------------------

-- OPTIONS

---------------------------------------------------

function TotemPulse:GetOptions()
    return {
        headerClassicon = {
            type = "header",
            name = L["Totem Pulse"],
            order = 2,
        },
        totemPulseEnabled = Core:option({
            type = "toggle",
            name = L["Totem Pulse Enabled"],
            order = 3,
        }),
        group = {
            type = "group",
            childGroups = "tree",
            name = L["Frame"],
            order = 4,
            disabled = function() return not Core.db.totemPulseEnabled end,
            args = {
                barFrame = {
                    type = "group",
                    name = L["Bar"],
                    order = 2,
                    args = {
                        headerSize = {
                            type = "header",
                            name = L["Size"],
                            order = 10,
                        },
                        totemPulseBarHeight = Core:option({
                            type = "range",
                            name = L["Bar height"],
                            desc = L["Height of the bar"],
                            order = 11,
                            min = 0.1,
                            max = 200,
                            step = .1,
                            width = "full",
                        }),
                        totemPulseBarWidth = Core:option({
                            type = "range",
                            name = L["Bar width"],
                            desc = L["Width of the bar"],
                            order = 12,
                            min = 0.1,
                            max = 600,
                            step = .1,
                            width = "full",
                        }),
                        headerTexture = {
                            type = "header",
                            name = L["Texture"],
                            order = 20,
                        },
                        totemPulseBarTexture = Core:option({
                            type = "select",
                            name = L["Bar texture"],
                            desc = L["Texture of the bar"],
                            order = 21,
                            dialogControl = "LSM30_Statusbar",
                            values = AceGUIWidgetLSMlists.statusbar,
                        }),
                        totemPulseBarColor = Core:colorOption({
                            type = "color",
                            name = L["Bar color"],
                            desc = L["Color of the cast bar"],
                            order = 22,
                            hasAlpha = true,
                        }),
                        totemPulseBarBgColor = Core:colorOption({
                            type = "color",
                            name = L["Background color"],
                            desc = L["Color of the cast bar background"],
                            order = 23,
                            hasAlpha = true,
                        }),
                        headerBorder = {
                            type = "header",
                            name = L["Border"],
                            order = 30,
                        },
                        totemPulseBarBorderSize = Core:option({
                            type = "range",
                            name = L["Border size"],
                            order = 31,
                            min = 0.5,
                            max = Core.db.totemPulseBarHeight/2,
                            step = 0.5,
                            width = "full",
                        }),
                        totemPulseBarBorderStyle = Core:option({
                            type = "select",
                            name = L["Status Bar border"],
                            order = 32,
                            dialogControl = "LSM30_Border",
                            values = AceGUIWidgetLSMlists.border,
                        }),
                        totemPulseBarBorderColor = Core:colorOption({
                            type = "color",
                            name = L["Status Bar border color"],
                            order = 33,
                            hasAlpha = true,
                        }),
                    },
                },
                cooldownFrame = {
                    type = "group",
                    name = L["Cooldown"],
                    order = 3,
                    args = {
                        headerSize = {
                            type = "header",
                            name = L["Frame"],
                            order = 10,
                        },
                        totemPulseCooldownHeight = Core:option({
                            type = "range",
                            name = L["Height"],
                            order = 11,
                            min = 0.1,
                            max = 200,
                            step = .1,
                            width = "full",
                        }),
                        totemPulseCooldownWidth = Core:option({
                            type = "range",
                            name = L["Width"],
                            order = 12,
                            min = 0.1,
                            max = 600,
                            step = .1,
                            width = "full",
                        }),
                        totemPulseCooldownAlpha = Core:option({
                            type = "range",
                            name = L["Alpha"],
                            order = 21,
                            min = 0.1,
                            max = 1,
                            step = .1,
                            width = "full",
                        }),

                    },
                },
                text = {
                    type = "group",
                    name = L["Text"],
                    order = 4,
                    args = {
                        headerSize = {
                            type = "header",
                            name = L["Text"],
                            order = 10,
                        },
                        totemPulseTextSize = Core:option({
                            type = "range",
                            name = L["Size"],
                            order = 11,
                            min = 0.5,
                            max = 30,
                            step = 0.5,
                            width = "full",
                        }),
                        totemPulseTextFont = Core:option({
                            type = "select",
                            name = L["Font"],
                            desc = L["Font of the bar"],
                            order = 12,
                            dialogControl = "LSM30_Font",
                            values = AceGUIWidgetLSMlists.font,
                        }),
                        totemPulseTextColor = Core:colorOption({
                            type = "color",
                            name = L["Font color"],
                            desc = L["Color of the text"],
                            order = 13,
                            hasAlpha = true,
                        }),
                    },
                },
            },
        },
        customizeTotems = {
            order = 50,
            name = L["Customize Totems"],
            type = "group",
            childGroups = "tree",
            disabled = function() return not Core.db.totemPulseEnabled end,
            args = select(1, TotemOptions())
        },
    }
end