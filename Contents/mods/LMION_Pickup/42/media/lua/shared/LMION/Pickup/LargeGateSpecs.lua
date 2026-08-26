require "LMION/Pickup/LargeGateProfiles"

local Pickup = LMION.Pickup
local LargeGate = Pickup.LargeGate or {}
Pickup.LargeGate = LargeGate

--[[
Large-gate transport data lives here so sprite/index topology stays separate from
Moveables hooks, runtime SpriteGrid lifecycle and placement code.
]]
local leaves = {
    doubleWireLeft = {
        visualPartIndex = 1,
        indices = {N = {1, 2}, W = {4, 3}},
        parts = {
            [1] = {itemType = "Base.LMION_DoubleWireGateLeft_Part1", faces = {N = "fixtures_doors_fences_01_66", W = "fixtures_doors_fences_01_65"}},
            [2] = {itemType = "Base.LMION_DoubleWireGateLeft_Part2", faces = {N = "fixtures_doors_fences_01_67", W = "fixtures_doors_fences_01_64"}},
        },
    },
    doubleWireRight = {
        visualPartIndex = 2,
        indices = {N = {3, 4}, W = {2, 1}},
        parts = {
            [1] = {itemType = "Base.LMION_DoubleWireGateRight_Part1", faces = {N = "fixtures_doors_fences_01_74", W = "fixtures_doors_fences_01_73"}},
            [2] = {itemType = "Base.LMION_DoubleWireGateRight_Part2", faces = {N = "fixtures_doors_fences_01_75", W = "fixtures_doors_fences_01_72"}},
        },
    },
    doubleFenceLeft = {
        visualPartIndex = 1,
        indices = {N = {1, 2}, W = {4, 3}},
        parts = {
            [1] = {itemType = "Base.LMION_DoubleFenceGateLeft_Part1", faces = {N = "fixtures_doors_fences_01_82", W = "fixtures_doors_fences_01_81"}},
            [2] = {itemType = "Base.LMION_DoubleFenceGateLeft_Part2", faces = {N = "fixtures_doors_fences_01_83", W = "fixtures_doors_fences_01_80"}},
        },
    },
    doubleFenceRight = {
        visualPartIndex = 2,
        indices = {N = {3, 4}, W = {2, 1}},
        parts = {
            [1] = {itemType = "Base.LMION_DoubleFenceGateRight_Part1", faces = {N = "fixtures_doors_fences_01_90", W = "fixtures_doors_fences_01_89"}},
            [2] = {itemType = "Base.LMION_DoubleFenceGateRight_Part2", faces = {N = "fixtures_doors_fences_01_91", W = "fixtures_doors_fences_01_88"}},
        },
    },
    doubleDoorLeft = {
        visualPartIndex = 1,
        indices = {N = {1, 2}, W = {4, 3}},
        parts = {
            [1] = {itemType = "Base.LMION_DoubleDoorLeft_Part1", faces = {N = "fixtures_doors_fences_01_98", W = "fixtures_doors_fences_01_97"}},
            [2] = {itemType = "Base.LMION_DoubleDoorLeft_Part2", faces = {N = "fixtures_doors_fences_01_99", W = "fixtures_doors_fences_01_96"}},
        },
    },
    doubleDoorRight = {
        visualPartIndex = 2,
        indices = {N = {3, 4}, W = {2, 1}},
        parts = {
            [1] = {itemType = "Base.LMION_DoubleDoorRight_Part1", faces = {N = "fixtures_doors_fences_01_106", W = "fixtures_doors_fences_01_105"}},
            [2] = {itemType = "Base.LMION_DoubleDoorRight_Part2", faces = {N = "fixtures_doors_fences_01_107", W = "fixtures_doors_fences_01_104"}},
        },
    },
    largeFarmLeft = {
        visualPartIndex = 1,
        previewAllParts = true,
        indices = {N = {1, 2}, W = {4, 3}},
        parts = {
            [1] = {itemType = "Base.LMION_LargeFarmGateLeft_Part1", faces = {N = "fixtures_doors_fences_01_114", W = "fixtures_doors_fences_01_113"}},
            [2] = {itemType = "Base.LMION_LargeFarmGateLeft_Part2", faces = {N = "fixtures_doors_fences_01_115", W = "fixtures_doors_fences_01_112"}},
        },
    },
    largeFarmRight = {
        visualPartIndex = 2,
        previewAllParts = true,
        indices = {N = {3, 4}, W = {2, 1}},
        parts = {
            [1] = {itemType = "Base.LMION_LargeFarmGateRight_Part1", faces = {N = "fixtures_doors_fences_01_122", W = "fixtures_doors_fences_01_121"}},
            [2] = {itemType = "Base.LMION_LargeFarmGateRight_Part2", faces = {N = "fixtures_doors_fences_01_123", W = "fixtures_doors_fences_01_120"}},
        },
    },
    largeHardenedWoodLeft = {
        visualPartIndex = 1,
        indices = {N = {1, 2}, W = {4, 3}},
        parts = {
            [1] = {itemType = "Base.LMION_LargeHardenedWoodenGateLeft_Part1", faces = {N = "fixtures_doors_fences_01_50", W = "fixtures_doors_fences_01_49"}},
            [2] = {itemType = "Base.LMION_LargeHardenedWoodenGateLeft_Part2", faces = {N = "fixtures_doors_fences_01_51", W = "fixtures_doors_fences_01_48"}},
        },
    },
    largeHardenedWoodRight = {
        visualPartIndex = 2,
        indices = {N = {3, 4}, W = {2, 1}},
        parts = {
            [1] = {itemType = "Base.LMION_LargeHardenedWoodenGateRight_Part1", faces = {N = "fixtures_doors_fences_01_58", W = "fixtures_doors_fences_01_57"}},
            [2] = {itemType = "Base.LMION_LargeHardenedWoodenGateRight_Part2", faces = {N = "fixtures_doors_fences_01_59", W = "fixtures_doors_fences_01_56"}},
        },
    },
    largeWroughtIronLeft = {
        visualPartIndex = 1,
        indices = {N = {1, 2}, W = {4, 3}},
        parts = {
            [1] = {itemType = "Base.LMION_LargeWroughtIronGateLeft_Part1", faces = {N = "fixtures_doors_fences_01_34", W = "fixtures_doors_fences_01_33"}},
            [2] = {itemType = "Base.LMION_LargeWroughtIronGateLeft_Part2", faces = {N = "fixtures_doors_fences_01_35", W = "fixtures_doors_fences_01_32"}},
        },
    },
    largeWroughtIronRight = {
        visualPartIndex = 2,
        indices = {N = {3, 4}, W = {2, 1}},
        parts = {
            [1] = {itemType = "Base.LMION_LargeWroughtIronGateRight_Part1", faces = {N = "fixtures_doors_fences_01_42", W = "fixtures_doors_fences_01_41"}},
            [2] = {itemType = "Base.LMION_LargeWroughtIronGateRight_Part2", faces = {N = "fixtures_doors_fences_01_43", W = "fixtures_doors_fences_01_40"}},
        },
    },
}

local segmentsBySprite = {}
for leafId, leaf in pairs(leaves) do
    for partIndex, part in pairs(leaf.parts) do
        for facing, spriteName in pairs(part.faces) do
            segmentsBySprite[spriteName] = {
                leafId = leafId,
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

--[[ Keep the established public alias used by placement, cursor and debug code. ]]
Pickup.LargeGateLeafSpecs = leaves

return LargeGate
