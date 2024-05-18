local select, string_lower = select, string.lower
local GetSpellInfo = GetSpellInfo
local LibStub = LibStub

local Core = LibStub("TotemPlates")
local L = Core.L

---------------------
-- TOTEM STUFF
---------------------

local totemData = {
    -- Fire
    -- Water
    [string_lower("Mana Tide Totem")] = {id = 16190,texture = select(3, GetSpellInfo(16190)), color = {r = 0.078, g = 0.9, b = 0.16, a = 1}, pulse = 2 },
    [string_lower("Mana Spring Totem")] = { id = 5675, texture = select(3, GetSpellInfo(5675)), color = { r = 0, g = 0, b = 0, a = 1 } },
    [string_lower("Elemental Resistance Totem")] = { id = 8184, texture = select(3, GetSpellInfo(8184)), color = { r = 0, g = 0, b = 0, a = 1 } },
    [string_lower("Totem of Tranquil Mind")] = { id = 87718, texture = select(3, GetSpellInfo(87718)), color = { r = 0, g = 0, b = 0, a = 1 } },
    -- Earth
    [string_lower("Tremor Totem")] = {id = 8143,texture = select(3, GetSpellInfo(8143)), color = {r = 1, g = 0.9, b = 0.1, a = 1}, pulse = { cd = 6, once = true }},
    -- Air
    [string_lower("Spirit Link Totem")] = { id = 98008, texture = select(3, GetSpellInfo(98008)), color = { r = 0, g = 0, b = 0, a = 1 }, pulse = 1 },
}

local totemSpellIdToPulse = {
    [8143] = totemData[string_lower("Tremor Totem")].pulse,
    [98008] = totemData[string_lower("Spirit Link Totem")].pulse,
    [GetSpellInfo(totemData[string_lower("Mana Tide Totem")].id)] = totemData[string_lower("Mana Tide Totem")].pulse,
    [16190] = totemData[string_lower("Mana Tide Totem")].pulse, -- Rank 1
}

local totemNpcIdsToTotemData = {
    [3573] = totemData[string_lower("Mana Spring Totem")],
    [7414] = totemData[string_lower("Mana Spring Totem")],
    [7415] = totemData[string_lower("Mana Spring Totem")],
    [7416] = totemData[string_lower("Mana Spring Totem")],
    [15304] = totemData[string_lower("Mana Spring Totem")],
    [15489] = totemData[string_lower("Mana Spring Totem")],
    [31186] = totemData[string_lower("Mana Spring Totem")],
    [31189] = totemData[string_lower("Mana Spring Totem")],
    [31190] = totemData[string_lower("Mana Spring Totem")],

    [5927] = totemData[string_lower("Elemental Resistance Totem")],
    [47069] = totemData[string_lower("Totem of Tranquil Mind")],
    [53006] = totemData[string_lower("Spirit Link Totem")],

}

local totemDataShared, totemNpcIdsToTotemDataShared, totemSpellIdToPulseShared = Core:GetSharedTotemData()
Core:AddEntriesToTable(totemData, totemDataShared)
Core:AddEntriesToTable(totemNpcIdsToTotemData, totemNpcIdsToTotemDataShared)
Core:AddEntriesToTable(totemSpellIdToPulse, totemSpellIdToPulseShared)

function Core:GetTotemData()
    return totemData, totemNpcIdsToTotemData, totemSpellIdToPulse
end