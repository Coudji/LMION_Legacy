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

local function getActionToolName(action)
    local moveProps = action and action.moveProps or nil
    if moveProps == nil then
        return nil
    end

    if action.mode == "pickup" then
        return moveProps.pickUpTool
    end
    if action.mode == "place" then
        return moveProps.placeTool
    end
    return nil
end

local function getResolvedActionTool(action)
    local moveProps = action and action.moveProps or nil
    local character = action and action.character or nil
    if moveProps == nil or character == nil then
        return nil
    end

    local mode = action.mode
    if mode ~= "pickup" and mode ~= "place" then
        return nil
    end

    local tool = moveProps:hasTool(character, mode)
    if tool == nil or tool == false or tool == true then
        return nil
    end

    return tool
end

local function equipResolvedToolNow(action, tool)
    local character = action and action.character or nil
    if character == nil or tool == nil then
        return
    end

    local oldPrimary = character:getPrimaryHandItem()
    local oldSecondary = character:getSecondaryHandItem()

    if oldSecondary == oldPrimary and oldPrimary ~= tool then
        character:setSecondaryHandItem(nil)
    end

    if oldPrimary ~= tool then
        character:setPrimaryHandItem(tool)
    end
end

local function stopActionSound(action)
    local character = action and action.character or nil
    if character ~= nil and action.sound ~= nil and action.sound ~= 0 then
        character:stopOrTriggerSound(action.sound)
    end
    action.sound = nil
end

local function restartConfiguredToolSound(action)
    local character = action and action.character or nil
    local toolName = getActionToolName(action)
    if character == nil or toolName == nil then
        return
    end

    local definitions = ISMoveableDefinitions and ISMoveableDefinitions:getInstance() or nil
    local toolDef = definitions and definitions.getToolDefinition(toolName) or nil
    if toolDef == nil or toolDef.sound == nil then
        return
    end

    stopActionSound(action)
    action.sound = character:playSound(toolDef.sound)
end

local function restartCrowbarSound(action)
    local character = action and action.character or nil
    if character == nil then
        return
    end

    stopActionSound(action)
    action.sound = character:playSound("BeginRemoveBarricadePlankCrowbar")
    addSound(character, character:getX(), character:getY(), character:getZ(), 10, 1)
end

local function isScrewdriverTool(toolName)
    return toolName == "Screwdriver" or toolName == "LMIONMetalScrewdriver"
end

local function isCrowbarTool(toolName)
    return toolName == "Crowbar" or toolName == "LMIONMetalCrowbar"
end

local function isHammerTool(toolName)
    return toolName == "Hammer" or toolName == "LMIONMetalHammer"
end

--[[
LMION transport presentation follows the gameplay tool contract instead of using
whatever item happened to remain in the character's hands from the previous move:

- Screwdriver Pickup/Place: Disassemble animation with the real screwdriver.
- Crowbar Pickup: vanilla RemoveBarricade/CrowbarMid animation and crowbar sound.
- Hammer Place: vanilla Build animation and configured Hammering sound.

walkToAndEquip() normally queues the required Moveables tool before the action, but
specialized multi-part placement can leave the previous tool visible until that
queued equip completes. Resolve the configured tool again when ISMoveablesAction
starts and make it the real primary-hand item immediately; the queued vanilla equip
then becomes harmless/idempotent.

Scrap remains fully vanilla. Metal scrap definitions already own BlowTorch animation,
sound, and the welding-mask requirement.
]]
if Pickup._pickupPresentationOriginalActionStart == nil then
    Pickup._pickupPresentationOriginalActionStart = ISMoveablesAction.start
end

ISMoveablesAction.start = function(self)
    if not isLmionTransportAction(self)
        or (self.mode ~= "pickup" and self.mode ~= "place") then
        Pickup._pickupPresentationOriginalActionStart(self)
        return
    end

    local toolName = getActionToolName(self)
    local tool = getResolvedActionTool(self)
    equipResolvedToolNow(self, tool)

    Pickup._pickupPresentationOriginalActionStart(self)

    if isScrewdriverTool(toolName) then
        self:setActionAnim(CharacterActionAnims.Disassemble)
        if tool ~= nil then
            self:setOverrideHandModels(tool, nil)
        end
        return
    end

    if self.mode == "pickup" and isCrowbarTool(toolName) then
        self:setActionAnim("RemoveBarricade")
        self:setAnimVariable("RemoveBarricade", "CrowbarMid")
        if tool ~= nil then
            self:setOverrideHandModels(tool, nil)
        end
        restartCrowbarSound(self)
        return
    end

    if self.mode == "place" and isHammerTool(toolName) then
        self:setActionAnim("Build")
        if tool ~= nil then
            self:setOverrideHandModels(tool, nil)
        end
        restartConfiguredToolSound(self)
    end
end

return Pickup
