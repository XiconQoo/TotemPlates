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
    [string_lower("Fire Elemental Totem")] = {id = 32982,texture = select(3, GetSpellInfo(32982)), color = {r = 0, g = 0, b = 0, a = 1}},
    -- Water
    [string_lower("Mana Tide Totem")] = {id = 16190,texture = select(3, GetSpellInfo(16190)), color = {r = 0.078, g = 0.9, b = 0.16, a = 1}, pulse = 2 },
    [string_lower("Mana Spring Totem")] = { id = 5675, texture = select(3, GetSpellInfo(5675)), color = { r = 0, g = 0, b = 0, a = 1 } },
    [string_lower("Elemental Resistance Totem")] = { id = 8184, texture = select(3, GetSpellInfo(8184)), color = { r = 0, g = 0, b = 0, a = 1 } },
    [string_lower("Totem of Tranquil Mind")] = { id = 87718, texture = select(3, GetSpellInfo(87718)), color = { r = 0, g = 0, b = 0, a = 1 } },
    -- Earth
    [string_lower("Tremor Totem")] = {id = 8143,texture = select(3, GetSpellInfo(8143)), color = {r = 1, g = 0.9, b = 0.1, a = 1}, pulse = { cd = 6, once = true }},
    [string_lower("Earth Elemental Totem")] = {id = 33663,texture = select(3, GetSpellInfo(33663)), color = {r = 0, g = 0, b = 0, a = 1}},
    -- Air
    [string_lower("Spirit Link Totem")] = { id = 98008, texture = select(3, GetSpellInfo(98008)), color = { r = 0, g = 0, b = 0, a = 1 }, pulse = 1 },
    [string_lower("Wrath of Air Totem")] = {id = 3738,texture = select(3, GetSpellInfo(3738)), color = {r = 0, g = 0, b = 0, a = 1}},
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

    [15439] = totemData[string_lower("Fire Elemental Totem")],
    [40830] = totemData[string_lower("Fire Elemental Totem")],
    [41337] = totemData[string_lower("Fire Elemental Totem")],
    [41346] = totemData[string_lower("Fire Elemental Totem")],
    [72301] = totemData[string_lower("Fire Elemental Totem")],

    [15430] = totemData[string_lower("Earth Elemental Totem")],
    [24649] = totemData[string_lower("Earth Elemental Totem")],
    [39387] = totemData[string_lower("Earth Elemental Totem")],
    [40247] = totemData[string_lower("Earth Elemental Totem")],
    [72307] = totemData[string_lower("Earth Elemental Totem")],

    [15447] = totemData[string_lower("Wrath of Air Totem")],
    [36556] = totemData[string_lower("Wrath of Air Totem")],
}

local totemDataShared, totemNpcIdsToTotemDataShared, totemSpellIdToPulseShared = Core:GetSharedTotemData()
Core:AddEntriesToTable(totemData, totemDataShared)
Core:AddEntriesToTable(totemNpcIdsToTotemData, totemNpcIdsToTotemDataShared)
Core:AddEntriesToTable(totemSpellIdToPulse, totemSpellIdToPulseShared)

function Core:GetTotemData()
    return totemData, totemNpcIdsToTotemData, totemSpellIdToPulse
end