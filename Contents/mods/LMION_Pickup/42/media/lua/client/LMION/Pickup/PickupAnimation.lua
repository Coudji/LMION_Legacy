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

local function getResolvedPlaceTool(action)
    local moveProps = action and action.moveProps or nil
    local character = action and action.character or nil
    if moveProps == nil or character == nil then
        return nil
    end

    local tool = moveProps:hasTool(character, "place")
    if tool == nil or tool == false or tool == true then
        return nil
    end

    return tool
end

local function restartHammerSound(action)
    local moveProps = action and action.moveProps or nil
    local character = action and action.character or nil
    local toolName = moveProps and moveProps.placeTool or nil
    if character == nil or toolName == nil then
        return
    end

    if action.sound ~= nil and action.sound ~= 0 then
        character:stopOrTriggerSound(action.sound)
        action.sound = nil
    end

    local definitions = ISMoveableDefinitions and ISMoveableDefinitions:getInstance() or nil
    local toolDef = definitions and definitions.getToolDefinition(toolName) or nil
    if toolDef ~= nil and toolDef.sound ~= nil then
        action.sound = character:playSound(toolDef.sound)
    end
end

--[[
Vanilla Moveables gives ordinary Pickup/Place no dedicated action animation.
LMION adds presentation only when the configured tool strongly implies one:

- Screwdriver Pickup reuses the vanilla Disassemble animation.
- Hammer Place reuses the vanilla Build animation.

For placement, walkToAndEquip() may leave the previously held pickup tool visible
until its queued equip action finishes. Do not copy the current primary-hand model
for the animation. Resolve the actual configured place tool through Moveables and
use that item as the hand model during the placement action.

Vanilla starts the configured Moveables sound before LMION applies presentation.
B42 can return a non-zero sound handle even when no audible hammer loop is heard,
so LMION explicitly restarts the same configured hammer sound for hammer placement.
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
        local hammer = getResolvedPlaceTool(self)

        self:setActionAnim("Build")
        if hammer ~= nil then
            self:setOverrideHandModels(hammer, nil)
        end

        restartHammerSound(self)
    end
end

return Pickup
