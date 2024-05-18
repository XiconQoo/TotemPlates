local select, string_lower = select, string.lower
local GetSpellInfo = GetSpellInfo
local LibStub = LibStub

local Core = LibStub("TotemPlates")
local L = Core.L

---------------------
-- TOTEM STUFF
---------------------

local totemDataShared, totemNpcIdsToTotemDataShared, totemSpellIdToPulseShared = Core:GetSharedTotemData()

local totemData = {
    -- Fire
    -- Water
    [string_lower("Frost Resistance Totem")] = {id = 8181,texture = select(3, GetSpellInfo(8181)), color = {r = 0, g = 0, b = 0, a = 1}},
    [string_lower("Fire Resistance Totem")] = {id = 8184,texture = select(3, GetSpellInfo(8184)), color = {r = 0, g = 0, b = 0, a = 1}},
    [string_lower("Disease Cleansing Totem")] = {id = 8170,texture = select(3, GetSpellInfo(8170)), color = {r = 0, g = 0, b = 0, a = 1}, pulse = 5},
    [string_lower("Poison Cleansing Totem")] = {id = 8166,texture = select(3, GetSpellInfo(8166)), color = {r = 0, g = 0, b = 0, a = 1}, pulse = 5},
    [string_lower("Mana Spring Totem")] = {id = 5675,texture = select(3, GetSpellInfo(5675)), color = {r = 0, g = 0, b = 0, a = 1}, pulse = 2},
    -- Earth
    -- Air
    [string_lower("Grace of Air Totem")] = {id = 8835,texture = select(3, GetSpellInfo(8835)), color = {r = 0, g = 0, b = 0, a = 1}},
    [string_lower("Windwall Totem")] = {id = 15107,texture = select(3, GetSpellInfo(15107)), color = {r = 0, g = 0, b = 0, a = 1}},
    [string_lower("Tranquil Air Totem")] = {id = 25908,texture = select(3, GetSpellInfo(25908)), color = {r = 0, g = 0, b = 0, a = 1}},
    [string_lower("Nature Resistance Totem")] = {id = 10595,texture = select(3, GetSpellInfo(10595)), color = {r = 0, g = 0, b = 0, a = 1}},
    [string_lower("Sentry Totem")] = {id = 6495, texture = select(3, GetSpellInfo(6495)), color = {r = 0, g = 0, b = 0, a = 1}},
    --rune
    [string_lower("Decoy Totem")] = {id = 425874,texture = select(3, GetSpellInfo(425874)), color = {r = 0, g = 0, b = 0, a = 1}},

}

local totemSpellIdToPulse = {
    [GetSpellInfo(totemData[string_lower("Poison Cleansing Totem")].id)] = totemData[string_lower("Poison Cleansing Totem")].pulse,
    [8166] = totemData[string_lower("Poison Cleansing Totem")].pulse,
    [GetSpellInfo(totemData[string_lower("Mana Spring Totem")].id)] = totemData[string_lower("Mana Spring Totem")].pulse,
    [5675] = totemData[string_lower("Mana Spring Totem")].pulse, -- Rank 1
    [10495] = totemData[string_lower("Mana Spring Totem")].pulse, -- Rank 2
    [10496] = totemData[string_lower("Mana Spring Totem")].pulse, -- Rank 3
    [10497] = totemData[string_lower("Mana Spring Totem")].pulse, -- Rank 4
    [GetSpellInfo(totemDataShared[string_lower("Tremor Totem")].id)] = 4, -- Tremor Totem
    [8143] = 4, -- Tremor Totem
    [GetSpellInfo(totemData[string_lower("Disease Cleansing Totem")].id)] = totemData[string_lower("Disease Cleansing Totem")].pulse,
    [8170] = totemData[string_lower("Disease Cleansing Totem")].pulse,
}

local totemNpcIdsToTotemData = {
    --fire
    [207576] = totemData[string_lower("Searing Totem")], --Lorgus Jett Corrupted Molten Fury Totem
    -- Water
    [5923] = totemData[string_lower("Poison Cleansing Totem")],
    [22487] = totemData[string_lower("Poison Cleansing Totem")],
    [5927] = totemData[string_lower("Fire Resistance Totem")],
    [7424] = totemData[string_lower("Fire Resistance Totem")],
    [7425] = totemData[string_lower("Fire Resistance Totem")],
    [15487] = totemData[string_lower("Fire Resistance Totem")],
    [31169] = totemData[string_lower("Fire Resistance Totem")],
    [31170] = totemData[string_lower("Fire Resistance Totem")],

    -- Earth
    -- Air
    [5924] = totemData[string_lower("Disease Cleansing Totem")],
    [5926] = totemData[string_lower("Frost Resistance Totem")],
    [7412] = totemData[string_lower("Frost Resistance Totem")],
    [7413] = totemData[string_lower("Frost Resistance Totem")],
    [15486] = totemData[string_lower("Frost Resistance Totem")],
    [31171] = totemData[string_lower("Frost Resistance Totem")],
    [31172] = totemData[string_lower("Frost Resistance Totem")],

    [7467] = totemData[string_lower("Nature Resistance Totem")],
    [7468] = totemData[string_lower("Nature Resistance Totem")],
    [7469] = totemData[string_lower("Nature Resistance Totem")],
    [15490] = totemData[string_lower("Nature Resistance Totem")],
    [31173] = totemData[string_lower("Nature Resistance Totem")],
    [31174] = totemData[string_lower("Nature Resistance Totem")],

    [3968] = totemData[string_lower("Sentry Totem")],
    [28938] = totemData[string_lower("Sentry Totem")],
    [40187] = totemData[string_lower("Sentry Totem")],
    [69505] = totemData[string_lower("Sentry Totem")],
    [70413] = totemData[string_lower("Sentry Totem")],
    [71145] = totemData[string_lower("Sentry Totem")],
    [147410] = totemData[string_lower("Sentry Totem")],

    [7486] = totemData[string_lower("Grace of Air Totem")],
    [7487] = totemData[string_lower("Grace of Air Totem")],
    [15463] = totemData[string_lower("Grace of Air Totem")],

    [9687] = totemData[string_lower("Windwall Totem")],
    [9688] = totemData[string_lower("Windwall Totem")],
    [9689] = totemData[string_lower("Windwall Totem")],
    [15492] = totemData[string_lower("Windwall Totem")],

    [15803] = totemData[string_lower("Tranquil Air Totem")],
    --[207397] = totemData[string_lower("Windfury Totem")], --Lorgus Jett Corrupted Windfury Totem
    --[207457] = {id = 8512,texture = select(3, GetSpellInfo(324)), color = {r = 0, g = 0, b = 0, a = 1}, npc=true, customText="KILL"}, --Lorgus Jett Corrupted Lightning Shield Totem
    [212157] = totemData[string_lower("Decoy Totem")]
}


Core:AddEntriesToTable(totemData, totemDataShared)
Core:AddEntriesToTable(totemNpcIdsToTotemData, totemNpcIdsToTotemDataShared)
Core:AddEntriesToTable(totemSpellIdToPulse, totemSpellIdToPulseShared)

function Core:GetTotemData()
    return totemData, totemNpcIdsToTotemData, totemSpellIdToPulse
end
