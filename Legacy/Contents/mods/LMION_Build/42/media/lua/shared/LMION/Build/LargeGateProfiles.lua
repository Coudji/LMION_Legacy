local Build = LMION.Build
local Doors = LMION.Doors

local function cloneProfile(source, id, fallbackName)
    if source == nil then
        return nil
    end

    return {
        id = id,
        fallbackName = fallbackName,
        class = source.class,
        frame = source.frame,
        requiresFrame = source.requiresFrame,
        durability = source.durability,
        materials = source.materials,
        sounds = source.sounds,
    }
end

--[[
Core owns the permanent A/B topology. Build only installs gameplay profiles for
its constructible leaf GameEntities. The three vanilla Double* families reuse the
base entity as leaf A after Build narrows that SpriteConfig; the other families
use explicit A/B entities and suppress the unsplit base profile while Build is
active to avoid ambiguous sprite ownership in the Core profile registry.
]]
local leafFamilies = {
    {
        baseId = "DoubleDoor",
        sourceIds = {"DoubleDoor", "DoubleDoorB"},
        aId = "DoubleDoor",
        bId = "DoubleDoorB",
        aName = "Large Wooden Gate A",
        bName = "Large Wooden Gate B",
    },
    {
        baseId = "DoubleWireGate",
        sourceIds = {"DoubleWireGate", "DoubleWireGateB"},
        aId = "DoubleWireGate",
        bId = "DoubleWireGateB",
        aName = "Large Chain-Link Gate A",
        bName = "Large Chain-Link Gate B",
    },
    {
        baseId = "DoubleFenceGate",
        sourceIds = {"DoubleFenceGate", "DoubleFenceGateB"},
        aId = "DoubleFenceGate",
        bId = "DoubleFenceGateB",
        aName = "Large Scrap Metal Gate A",
        bName = "Large Scrap Metal Gate B",
    },
    {
        baseId = "LargeFarmGate",
        sourceIds = {"LargeFarmGate", "LargeFarmGateA", "LargeFarmGateB"},
        aId = "LargeFarmGateA",
        bId = "LargeFarmGateB",
        aName = "Large Farm Gate A",
        bName = "Large Farm Gate B",
        removeId = "LargeFarmGate",
    },
    {
        baseId = "LargeHardenedWoodenGate",
        sourceIds = {"LargeHardenedWoodenGate", "LargeHardenedWoodenGateA", "LargeHardenedWoodenGateB"},
        aId = "LargeHardenedWoodenGateA",
        bId = "LargeHardenedWoodenGateB",
        aName = "Large Hardened Wooden Gate A",
        bName = "Large Hardened Wooden Gate B",
        removeId = "LargeHardenedWoodenGate",
    },
    {
        baseId = "LargeWroughtIronGate",
        sourceIds = {"LargeWroughtIronGate", "LargeWroughtIronGateA", "LargeWroughtIronGateB"},
        aId = "LargeWroughtIronGateA",
        bId = "LargeWroughtIronGateB",
        aName = "Large Wrought Iron Gate A",
        bName = "Large Wrought Iron Gate B",
        removeId = "LargeWroughtIronGate",
    },
}

local function findSourceProfile(profiles, ids)
    for _, id in ipairs(ids) do
        if profiles[id] ~= nil then
            return profiles[id]
        end
    end
    return nil
end

function Build.installLargeGateLeafProfiles()
    if Doors == nil or Doors.Profiles == nil then
        return false
    end

    local profiles = Doors.Profiles
    for _, family in ipairs(leafFamilies) do
        local source = findSourceProfile(profiles, family.sourceIds)
        if source ~= nil then
            profiles[family.aId] = cloneProfile(source, family.aId, family.aName)
            profiles[family.bId] = cloneProfile(source, family.bId, family.bName)
            if family.removeId ~= nil then
                profiles[family.removeId] = nil
            end
        end
    end

    return true
end

Build.installLargeGateLeafProfiles()

return Build
