require "Moveables/ISMoveableDefinitions"

LMION.Pickup = LMION.Pickup or {}
local Pickup = LMION.Pickup

local function registerToolDefinitions()
    local definitions = ISMoveableDefinitions:getInstance()

    definitions.removeToolDefinition("LMIONMetalScrewdriver")
    definitions.removeToolDefinition("LMIONMetalCrowbar")
    definitions.removeToolDefinition("LMIONMetalHammer")

    -- Metal doors are still removed/reinstalled through their hinges with a real
    -- screwdriver. Keep MetalWelding as the governing transport perk without
    -- inheriting vanilla's Woodwork-based Screwdriver tool definition.
    definitions.addToolDefinition(
        "LMIONMetalScrewdriver",
        {"Base.Screwdriver"},
        Perks.MetalWelding,
        100,
        "Dismantle",
        true
    )

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
