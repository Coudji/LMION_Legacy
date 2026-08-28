local Openings = LMION.Openings

local function add(id, familyName, aliases)
    Openings.registerDefinition(id, {
        kind = "largeGate",
        familyName = familyName,
        topology = "complete",
        aliases = aliases or {},
    })
end

-- Core owns stable family identity. Left/right ids may remain present in a save
-- even when the module that activates split-leaf gameplay is disabled, so they
-- must resolve to the canonical family independently from active extensions.
add("DoubleDoor", "Large Wooden Gate", {"DoubleDoorRight"})
add("DoubleWireGate", "Large Chain-Link Gate", {"DoubleWireGateRight"})
add("DoubleFenceGate", "Large Scrap Metal Gate", {"DoubleFenceGateRight"})
add("LargeFarmGate", "Large Farm Gate", {"LargeFarmGateLeft", "LargeFarmGateRight"})
add(
    "LargeHardenedWoodenGate",
    "Large Hardened Wooden Gate",
    {"LargeHardenedWoodenGateLeft", "LargeHardenedWoodenGateRight"}
)
add(
    "LargeWroughtIronGate",
    "Large Wrought Iron Gate",
    {"LargeWroughtIronGateLeft", "LargeWroughtIronGateRight"}
)

return Openings
