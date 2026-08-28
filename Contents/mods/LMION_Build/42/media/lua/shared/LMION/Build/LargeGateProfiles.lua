local Build = LMION.Build
local Doors = LMION.Doors
local Openings = LMION.Openings

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
        baseId = "DoubleDoor",
        sourceIds = {"DoubleDoor", "DoubleDoorRight"},
        leftId = "DoubleDoor",
        rightId = "DoubleDoorRight",
        leftName = "Large Wooden Gate - Left Leaf",
        rightName = "Large Wooden Gate - Right Leaf",
    },
    {
        baseId = "DoubleWireGate",
        sourceIds = {"DoubleWireGate", "DoubleWireGateRight"},
        leftId = "DoubleWireGate",
        rightId = "DoubleWireGateRight",
        leftName = "Large Chain-Link Gate - Left Leaf",
        rightName = "Large Chain-Link Gate - Right Leaf",
    },
    {
        baseId = "DoubleFenceGate",
        sourceIds = {"DoubleFenceGate", "DoubleFenceGateRight"},
        leftId = "DoubleFenceGate",
        rightId = "DoubleFenceGateRight",
        leftName = "Large Scrap Metal Gate - Left Leaf",
        rightName = "Large Scrap Metal Gate - Right Leaf",
    },
    {
        baseId = "LargeFarmGate",
        sourceIds = {"LargeFarmGate", "LargeFarmGateLeft", "LargeFarmGateRight"},
        leftId = "LargeFarmGateLeft",
        rightId = "LargeFarmGateRight",
        leftName = "Large Farm Gate - Left Leaf",
        rightName = "Large Farm Gate - Right Leaf",
        removeId = "LargeFarmGate",
    },
    {
        baseId = "LargeHardenedWoodenGate",
        sourceIds = {"LargeHardenedWoodenGate", "LargeHardenedWoodenGateLeft", "LargeHardenedWoodenGateRight"},
        leftId = "LargeHardenedWoodenGateLeft",
        rightId = "LargeHardenedWoodenGateRight",
        leftName = "Large Hardened Wooden Gate - Left Leaf",
        rightName = "Large Hardened Wooden Gate - Right Leaf",
        removeId = "LargeHardenedWoodenGate",
    },
    {
        baseId = "LargeWroughtIronGate",
        sourceIds = {"LargeWroughtIronGate", "LargeWroughtIronGateLeft", "LargeWroughtIronGateRight"},
        leftId = "LargeWroughtIronGateLeft",
        rightId = "LargeWroughtIronGateRight",
        leftName = "Large Wrought Iron Gate - Left Leaf",
        rightName = "Large Wrought Iron Gate - Right Leaf",
        removeId = "LargeWroughtIronGate",
    },
}

local function registerTopologyExtensions()
    if Openings == nil or Openings.registerExtension == nil then
        return false
    end

    for _, family in ipairs(splitFamilies) do
        local aliases = {}
        if family.leftId ~= family.baseId then
            aliases[#aliases + 1] = family.leftId
        end
        if family.rightId ~= family.baseId then
            aliases[#aliases + 1] = family.rightId
        end

        Openings.registerExtension(
            family.baseId,
            "LMION_Build.largeGateSplit",
            {
                source = Build.ID or "LMION_Build",
                aliases = aliases,
                values = {
                    topology = "splitLeaves",
                    leaves = {
                        left = family.leftId,
                        right = family.rightId,
                    },
                },
            }
        )
    end

    return true
end

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

registerTopologyExtensions()
Build.installSplitLargeGateProfiles()

return Build
