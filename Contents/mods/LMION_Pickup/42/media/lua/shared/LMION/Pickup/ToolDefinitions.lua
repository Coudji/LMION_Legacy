require "Moveables/ISMoveableDefinitions"

LMION.Pickup = LMION.Pickup or {}
local Pickup = LMION.Pickup

local function registerToolDefinitions()
    local definitions = ISMoveableDefinitions:getInstance()

    definitions.removeToolDefinition("LMIONMetalCrowbar")
    definitions.removeToolDefinition("LMIONMetalHammer")
    definitions.removeToolDefinition("LMIONMetalBlowTorch")

    definitions.addToolDefinition(
        "LMIONMetalCrowbar",
        {"Tag.Crowbar", "Crowbar"},
        Perks.MetalWelding,
        150,
        "Hammering",
        true
    )

    definitions.addToolDefinition(
        "LMIONMetalHammer",
        {"Base.Hammer"},
        Perks.MetalWelding,
        75,
        "Hammering",
        true
    )
end

registerToolDefinitions()

if Pickup._toolDefinitionsBootHandler ~= nil then
    Events.OnGameBoot.Remove(Pickup._toolDefinitionsBootHandler)
end

Pickup._toolDefinitionsBootHandler = registerToolDefinitions
Events.OnGameBoot.Add(Pickup._toolDefinitionsBootHandler)

return Pickup
