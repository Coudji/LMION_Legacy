local Openings = LMION.Openings

local function add(id, familyName)
    Openings.registerDefinition(id, {
        kind = "largeGate",
        familyName = familyName,
        topology = "complete",
    })
end

add("DoubleDoor", "Large Wooden Gate")
add("DoubleWireGate", "Large Chain-Link Gate")
add("DoubleFenceGate", "Large Scrap Metal Gate")
add("LargeFarmGate", "Large Farm Gate")
add("LargeHardenedWoodenGate", "Large Hardened Wooden Gate")
add("LargeWroughtIronGate", "Large Wrought Iron Gate")

return Openings
