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

LMION.Doors.register("Base.LogDoor", {
    sourceEntity = "Base.LogDoor",
    closedSprites = {
        north = "walls_logs_41",
        west = "walls_logs_40",
    },
})

LMION.Doors.register("Base.FossoilDoor", {
    sourceEntity = "Base.FossoilDoor",
    closedSprites = {
        north = "location_shop_fossoil_01_61",
        west = "location_shop_fossoil_01_60",
    },
})

LMION.Doors.register("Base.Gas2GoDoor", {
    sourceEntity = "Base.Gas2GoDoor",
    closedSprites = {
        north = "location_shop_gas2go_01_61",
        west = "location_shop_gas2go_01_60",
    },
})

LMION.log("Doors", "registered door models: " .. tostring(LMION.Doors.getCount()))
