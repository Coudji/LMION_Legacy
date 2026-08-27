require "Moveables/ISMoveablesAction"

local Pickup = LMION.Pickup

local function isLmionTransportAction(action)
    local moveProps = action and action.moveProps or nil
    if moveProps == nil then
        return false
    end

    return moveProps.lmionDoorProfile ~= nil
        or moveProps.lmionGarageFamily ~= nil
        or moveProps.lmionLargeGateLeaf ~= nil
end

local function isLmionScrewdriverPickup(action)
    local moveProps = action and action.moveProps or nil
    return action ~= nil
        and action.mode == "pickup"
        and moveProps ~= nil
        and moveProps.pickUpTool == "Screwdriver"
        and isLmionTransportAction(action)
end

local function isLmionHammerPlace(action)
    local moveProps = action and action.moveProps or nil
    if action == nil or action.mode ~= "place" or moveProps == nil then
        return false
    end

    return isLmionTransportAction(action)
        and (moveProps.placeTool == "Hammer" or moveProps.placeTool == "LMIONMetalHammer")
end

local function ensureHammerSound(action)
    if action.sound ~= nil and action.sound ~= 0 then
        return
    end

    local moveProps = action.moveProps
    local toolName = moveProps and moveProps.placeTool or nil
    if toolName == nil then
        return
    end

    local definitions = ISMoveableDefinitions and ISMoveableDefinitions:getInstance() or nil
    local toolDef = definitions and definitions.getToolDefinition(toolName) or nil
    if toolDef == nil or toolDef.sound == nil then
        return
    end

    action.sound = action.character:playSound(toolDef.sound)
end

--[[
Vanilla Moveables gives ordinary Pickup/Place no dedicated action animation.
LMION adds presentation only when the configured tool strongly implies one:

- Screwdriver Pickup reuses the vanilla Disassemble animation.
- Hammer Place reuses the vanilla Build animation.

walkToAndEquip() has already equipped the configured Pickup/Place tool before the
ISMoveablesAction starts. Keep that real primary-hand item visible rather than
forcing a decorative model.

Vanilla also starts the configured tool sound in ISMoveablesAction:start(). The
hammer path below only supplies the same tool-definition sound as a fallback if
that vanilla call returned no active sound handle, avoiding duplicate playback.
]]
if Pickup._pickupPresentationOriginalActionStart == nil then
    Pickup._pickupPresentationOriginalActionStart = ISMoveablesAction.start
end

ISMoveablesAction.start = function(self)
    Pickup._pickupPresentationOriginalActionStart(self)

    if isLmionScrewdriverPickup(self) then
        self:setActionAnim(CharacterActionAnims.Disassemble)
        return
    end

    if isLmionHammerPlace(self) then
        self:setActionAnim("Build")
        self:setOverrideHandModels(self.character:getPrimaryHandItem(), nil)
        ensureHammerSound(self)
    end
end

return Pickup
