local Profiles = {}

local function add(id, name, durabilityClass, worldMaxHealth, skill, health, skillBaseHealth, material1, material2, material3, materialType, doorSound, thumpSound, frame, pairedFrameSide)
    Profiles[id] = {
        id = id,
        fallbackName = name,
        class = durabilityClass,
        frame = frame,
        requiresFrame = frame == "standard" or frame == "paired",
        pairedFrameSide = pairedFrameSide,
        durability = {
            worldMaxHealth = worldMaxHealth,
            health = health,
            skillBaseHealth = skillBaseHealth,
            skill = skill,
        },
        materials = {
            primary = material1,
            secondary = material2,
            tertiary = material3,
            materialType = materialType,
        },
        sounds = {
            door = doorSound,
            thump = thumpSound,
        },
    }
end

--[[
Profile families are declarative modules. They receive the single registry writer
so profile construction stays centralized while navigation follows gameplay
families instead of one long catalog-like source file.
]]
local families = {
    "LMION/DoorProfiles/GarageDoors",
    "LMION/DoorProfiles/LargeGates",
    "LMION/DoorProfiles/PairedDoors",
    "LMION/DoorProfiles/Gates",
    "LMION/DoorProfiles/SlidingDoors",
    "LMION/DoorProfiles/WoodenDoors",
    "LMION/DoorProfiles/MetalDoors",
    "LMION/DoorProfiles/SpecialDoors",
}

for _, modulePath in ipairs(families) do
    local registerFamily = require(modulePath)
    if type(registerFamily) == "function" then
        registerFamily(add)
    end
end

return Profiles
