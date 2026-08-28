local Openings = LMION.Openings

local function add(id, familyName, leafAEntity, leafBEntity)
    Openings.registerDefinition(id, {
        kind = "largeGate",
        familyName = familyName,
        topology = "twoLeaves",
        leaves = {
            A = {
                id = "A",
                entity = leafAEntity,
                doubleDoorIndices = {
                    N = {1, 2},
                    W = {4, 3},
                },
            },
            B = {
                id = "B",
                entity = leafBEntity,
                doubleDoorIndices = {
                    N = {3, 4},
                    W = {2, 1},
                },
            },
        },
    })
end

--[[
A large gate is always two logical leaves. This is a Core fact, independent of
which gameplay modules are enabled. Vanilla may still construct the complete
four-member gate in one action; Build may expose A and B as separate recipes;
Pickup may transport either leaf. The A/B identity is stable across N/W rotation.

For the three vanilla Double* gate families, leaf A reuses the vanilla entity id
when Build temporarily narrows its SpriteConfig for per-leaf construction. With
Build absent the vanilla entity remains the normal complete-gate definition.
]]
add("DoubleDoor", "Large Wooden Gate", "DoubleDoor", "DoubleDoorB")
add("DoubleWireGate", "Large Chain-Link Gate", "DoubleWireGate", "DoubleWireGateB")
add("DoubleFenceGate", "Large Scrap Metal Gate", "DoubleFenceGate", "DoubleFenceGateB")
add("LargeFarmGate", "Large Farm Gate", "LargeFarmGateA", "LargeFarmGateB")
add(
    "LargeHardenedWoodenGate",
    "Large Hardened Wooden Gate",
    "LargeHardenedWoodenGateA",
    "LargeHardenedWoodenGateB"
)
add(
    "LargeWroughtIronGate",
    "Large Wrought Iron Gate",
    "LargeWroughtIronGateA",
    "LargeWroughtIronGateB"
)

return Openings
