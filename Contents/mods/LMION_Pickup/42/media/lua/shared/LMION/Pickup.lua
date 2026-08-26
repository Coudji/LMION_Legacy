require "LMION/Core"

LMION.Pickup = LMION.Pickup or {}
local Pickup = LMION.Pickup

Pickup.ID = "LMION_Pickup"
Pickup.VERSION = "0.0.8-dev"

--[[ Keep the bootstrap explicit so the ownership and load order of each hook is visible. ]]
require "LMION/Pickup/DoorProfiles"
require "LMION/Pickup/ToolDefinitions"
require "LMION/Pickup/DoorMoveables"
require "LMION/Pickup/LargeGateProfiles"
require "LMION/Pickup/LargeGateSpecs"
require "LMION/Pickup/LargeGateRuntime"
require "LMION/Pickup/LargeGateMoveables"
require "LMION/Pickup/LargeGatePlacement"

LMION.registerModule(Pickup.ID, Pickup)
LMION.log("Pickup", "loaded " .. Pickup.VERSION)

return Pickup
