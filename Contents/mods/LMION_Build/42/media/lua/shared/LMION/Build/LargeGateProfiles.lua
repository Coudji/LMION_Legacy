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

local splitFamilies = {
    {
        sourceIds = {"DoubleDoor", "DoubleDoorRight"},
        leftId = "DoubleDoor",
        rightId = "DoubleDoorRight",
        leftName = "Large Wooden Gate - Left Leaf",
        rightName = "Large Wooden Gate - Right Leaf",
    },
    {
        sourceIds = {"DoubleWireGate", "DoubleWireGateRight"},
        leftId = "DoubleWireGate",
        rightId = "DoubleWireGateRight",
        leftName = "Large Chain-Link Gate - Left Leaf",
        rightName = "Large Chain-Link Gate - Right Leaf",
    },
    {
        sourceIds = {"DoubleFenceGate", "DoubleFenceGateRight"},
        leftId = "DoubleFenceGate",
        rightId = "DoubleFenceGateRight",
        leftName = "Large Scrap Metal Gate - Left Leaf",
        rightName = "Large Scrap Metal Gate - Right Leaf",
    },
    {
        sourceIds = {"LargeFarmGate", "LargeFarmGateLeft", "LargeFarmGateRight"},
        leftId = "LargeFarmGateLeft",
        rightId = "LargeFarmGateRight",
        leftName = "Large Farm Gate - Left Leaf",
        rightName = "Large Farm Gate - Right Leaf",
        removeId = "LargeFarmGate",
    },
    {
        sourceIds = {"LargeHardenedWoodenGate", "LargeHardenedWoodenGateLeft", "LargeHardenedWoodenGateRight"},
        leftId = "LargeHardenedWoodenGateLeft",
        rightId = "LargeHardenedWoodenGateRight",
        leftName = "Large Hardened Wooden Gate - Left Leaf",
        rightName = "Large Hardened Wooden Gate - Right Leaf",
        removeId = "LargeHardenedWoodenGate",
    },
    {
        sourceIds = {"LargeWroughtIronGate", "LargeWroughtIronGateLeft", "LargeWroughtIronGateRight"},
        leftId = "LargeWroughtIronGateLeft",
        rightId = "LargeWroughtIronGateRight",
        leftName = "Large Wrought Iron Gate - Left Leaf",
        rightName = "Large Wrought Iron Gate - Right Leaf",
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

function Build.installSplitLargeGateProfiles()
    if Doors == nil or Doors.Profiles == nil then
        return false
    end

    local profiles = Doors.Profiles
    for _, family in ipairs(splitFamilies) do
        local source = findSourceProfile(profiles, family.sourceIds)
        if source ~= nil then
            profiles[family.leftId] = cloneProfile(source, family.leftId, family.leftName)
            profiles[family.rightId] = cloneProfile(source, family.rightId, family.rightName)
            if family.removeId ~= nil then
                profiles[family.removeId] = nil
            end
        end
    end

    return true
end

Build.installSplitLargeGateProfiles()

return Build
