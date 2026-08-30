require "LMION/Pickup/LargeGateProfiles"

local Pickup = LMION.Pickup
local LargeGate = Pickup.LargeGate or {}
Pickup.LargeGate = LargeGate

local function coreIndices(familyId, leafId)
    local definition = LMION.Openings and LMION.Openings.getBaseDefinition
        and LMION.Openings.getBaseDefinition(familyId)
        or nil
    local leaf = definition and definition.leaves and definition.leaves[leafId] or nil
    local indices = leaf and leaf.doubleDoorIndices or nil

    if indices == nil then
        error("LMION Pickup: missing Core large-gate topology for " .. tostring(familyId) .. " leaf " .. tostring(leafId))
    end

    return indices
end

local leaves = {
    doubleWireA = {
        familyId = "DoubleWireGate",
        leaf = "A",
        visualPartIndex = 1,
        indices = coreIndices("DoubleWireGate", "A"),
        parts = {
            [1] = {itemType = "Base.LMION_DoubleWireGateA_Part1", faces = {N = "fixtures_doors_fences_01_66", W = "fixtures_doors_fences_01_65"}},
            [2] = {itemType = "Base.LMION_DoubleWireGateA_Part2", faces = {N = "fixtures_doors_fences_01_67", W = "fixtures_doors_fences_01_64"}},
        },
    },
    doubleWireB = {
        familyId = "DoubleWireGate",
        leaf = "B",
        visualPartIndex = 2,
        indices = coreIndices("DoubleWireGate", "B"),
        parts = {
            [1] = {itemType = "Base.LMION_DoubleWireGateB_Part1", faces = {N = "fixtures_doors_fences_01_74", W = "fixtures_doors_fences_01_73"}},
            [2] = {itemType = "Base.LMION_DoubleWireGateB_Part2", faces = {N = "fixtures_doors_fences_01_75", W = "fixtures_doors_fences_01_72"}},
        },
    },
    doubleFenceA = {
        familyId = "DoubleFenceGate",
        leaf = "A",
        visualPartIndex = 1,
        indices = coreIndices("DoubleFenceGate", "A"),
        parts = {
            [1] = {itemType = "Base.LMION_DoubleFenceGateA_Part1", faces = {N = "fixtures_doors_fences_01_82", W = "fixtures_doors_fences_01_81"}},
            [2] = {itemType = "Base.LMION_DoubleFenceGateA_Part2", faces = {N = "fixtures_doors_fences_01_83", W = "fixtures_doors_fences_01_80"}},
        },
    },
    doubleFenceB = {
        familyId = "DoubleFenceGate",
        leaf = "B",
        visualPartIndex = 2,
        indices = coreIndices("DoubleFenceGate", "B"),
        parts = {
            [1] = {itemType = "Base.LMION_DoubleFenceGateB_Part1", faces = {N = "fixtures_doors_fences_01_90", W = "fixtures_doors_fences_01_89"}},
            [2] = {itemType = "Base.LMION_DoubleFenceGateB_Part2", faces = {N = "fixtures_doors_fences_01_91", W = "fixtures_doors_fences_01_88"}},
        },
    },
    doubleDoorA = {
        familyId = "DoubleDoor",
        leaf = "A",
        visualPartIndex = 1,
        indices = coreIndices("DoubleDoor", "A"),
        parts = {
            [1] = {itemType = "Base.LMION_DoubleDoorA_Part1", faces = {N = "fixtures_doors_fences_01_98", W = "fixtures_doors_fences_01_97"}},
            [2] = {itemType = "Base.LMION_DoubleDoorA_Part2", faces = {N = "fixtures_doors_fences_01_99", W = "fixtures_doors_fences_01_96"}},
        },
    },
    doubleDoorB = {
        familyId = "DoubleDoor",
        leaf = "B",
        visualPartIndex = 2,
        indices = coreIndices("DoubleDoor", "B"),
        parts = {
            [1] = {itemType = "Base.LMION_DoubleDoorB_Part1", faces = {N = "fixtures_doors_fences_01_106", W = "fixtures_doors_fences_01_105"}},
            [2] = {itemType = "Base.LMION_DoubleDoorB_Part2", faces = {N = "fixtures_doors_fences_01_107", W = "fixtures_doors_fences_01_104"}},
        },
    },
    largeFarmA = {
        familyId = "LargeFarmGate",
        leaf = "A",
        visualPartIndex = 1,
        previewAllParts = true,
        indices = coreIndices("LargeFarmGate", "A"),
        parts = {
            [1] = {itemType = "Base.LMION_LargeFarmGateA_Part1", faces = {N = "fixtures_doors_fences_01_114", W = "fixtures_doors_fences_01_113"}},
            [2] = {itemType = "Base.LMION_LargeFarmGateA_Part2", faces = {N = "fixtures_doors_fences_01_115", W = "fixtures_doors_fences_01_112"}},
        },
    },
    largeFarmB = {
        familyId = "LargeFarmGate",
        leaf = "B",
        visualPartIndex = 2,
        previewAllParts = true,
        indices = coreIndices("LargeFarmGate", "B"),
        parts = {
            [1] = {itemType = "Base.LMION_LargeFarmGateB_Part1", faces = {N = "fixtures_doors_fences_01_122", W = "fixtures_doors_fences_01_121"}},
            [2] = {itemType = "Base.LMION_LargeFarmGateB_Part2", faces = {N = "fixtures_doors_fences_01_123", W = "fixtures_doors_fences_01_120"}},
        },
    },
    largeHardenedWoodA = {
        familyId = "LargeHardenedWoodenGate",
        leaf = "A",
        visualPartIndex = 1,
        indices = coreIndices("LargeHardenedWoodenGate", "A"),
        parts = {
            [1] = {itemType = "Base.LMION_LargeHardenedWoodenGateA_Part1", faces = {N = "fixtures_doors_fences_01_50", W = "fixtures_doors_fences_01_49"}},
            [2] = {itemType = "Base.LMION_LargeHardenedWoodenGateA_Part2", faces = {N = "fixtures_doors_fences_01_51", W = "fixtures_doors_fences_01_48"}},
        },
    },
    largeHardenedWoodB = {
        familyId = "LargeHardenedWoodenGate",
        leaf = "B",
        visualPartIndex = 2,
        indices = coreIndices("LargeHardenedWoodenGate", "B"),
        parts = {
            [1] = {itemType = "Base.LMION_LargeHardenedWoodenGateB_Part1", faces = {N = "fixtures_doors_fences_01_58", W = "fixtures_doors_fences_01_57"}},
            [2] = {itemType = "Base.LMION_LargeHardenedWoodenGateB_Part2", faces = {N = "fixtures_doors_fences_01_59", W = "fixtures_doors_fences_01_56"}},
        },
    },
    largeWroughtIronA = {
        familyId = "LargeWroughtIronGate",
        leaf = "A",
        visualPartIndex = 1,
        indices = coreIndices("LargeWroughtIronGate", "A"),
        parts = {
            [1] = {itemType = "Base.LMION_LargeWroughtIronGateA_Part1", faces = {N = "fixtures_doors_fences_01_34", W = "fixtures_doors_fences_01_33"}},
            [2] = {itemType = "Base.LMION_LargeWroughtIronGateA_Part2", faces = {N = "fixtures_doors_fences_01_35", W = "fixtures_doors_fences_01_32"}},
        },
    },
    largeWroughtIronB = {
        familyId = "LargeWroughtIronGate",
        leaf = "B",
        visualPartIndex = 2,
        indices = coreIndices("LargeWroughtIronGate", "B"),
        parts = {
            [1] = {itemType = "Base.LMION_LargeWroughtIronGateB_Part1", faces = {N = "fixtures_doors_fences_01_42", W = "fixtures_doors_fences_01_41"}},
            [2] = {itemType = "Base.LMION_LargeWroughtIronGateB_Part2", faces = {N = "fixtures_doors_fences_01_43", W = "fixtures_doors_fences_01_40"}},
        },
    },
}

local segmentsBySprite = {}
for leafId, leaf in pairs(leaves) do
    for partIndex, part in pairs(leaf.parts) do
        for facing, spriteName in pairs(part.faces) do
            segmentsBySprite[spriteName] = {
                leafId = leafId,
                familyId = leaf.familyId,
                leaf = leaf.leaf,
                partIndex = partIndex,
                facing = facing,
                itemType = part.itemType,
                faces = part.faces,
            }
        end
    end
end

LargeGate.Leaves = leaves
LargeGate.SegmentsBySprite = segmentsBySprite
LargeGate.GridFacingSpecs = {
    N = {width = 2, height = 1, partOrder = {1, 2}},
    W = {width = 1, height = 2, partOrder = {1, 2}},
}

Pickup.LargeGateLeafSpecs = leaves

return LargeGate
