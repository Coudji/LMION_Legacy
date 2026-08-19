--[[
    Let Me In... Or Not - Core door models.

    Start small: only facts we actually need for shared placement-facing
    identity. Do not add gameplay classifications that belong to Build or Pickup.
]]

require "LMION/Doors"

LMION.Doors.register("Base.WoodenDoorLvl3", {
    sourceEntity = "Base.WoodenDoorLvl3",
    closedSprites = {
        north = "carpentry_01_57",
        west = "carpentry_01_56",
    },
})

LMION.log("Doors", "registered door models: " .. tostring(LMION.Doors.getCount()))
