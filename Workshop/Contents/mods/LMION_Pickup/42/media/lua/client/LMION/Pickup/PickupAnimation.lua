require "Moveables/ISMoveablesAction"

local function isLmionTransportAction(action)
    local moveProps = action and action.moveProps or nil
    if moveProps == nil then
        return false
    end

    return moveProps.lmionDefinitionId ~= nil
        or moveProps.lmionGarageDefinitionId ~= nil
        or moveProps.lmionLargeGateDefinitionId ~= nil
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

    if action.mode ~= "pickup" and action.mode ~= "place" then
        return nil
    end

    local tool = moveProps:hasTool(character, action.mode)
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

    local definitions = ISMoveableDefinitions
        and ISMoveableDefinitions:getInstance()
        or nil
    local toolDef = definitions
        and definitions.getToolDefinition(toolName)
        or nil

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
    addSound(
        character,
        character:getX(),
        character:getY(),
        character:getZ(),
        10,
        1
    )
end


local function isScrewdriverTool(toolName)
    return toolName == "Screwdriver"
        or toolName == "LMIONMetalScrewdriver"
end


local function isCrowbarTool(toolName)
    return toolName == "Crowbar"
        or toolName == "LMIONMetalCrowbar"
end


local function isHammerTool(toolName)
    return toolName == "Hammer"
        or toolName == "LMIONMetalHammer"
end


-- Presentation must follow LMION's resolved gameplay tool, not whichever item
-- happens to remain in the character's hands from the previous Moveables action.
-- This is especially visible when a frameless opening is picked up with a crowbar
-- and immediately reinstalled with a hammer.
if ISMoveablesAction._lmionPresentationOriginalStart == nil then
    ISMoveablesAction._lmionPresentationOriginalStart = ISMoveablesAction.start
end


ISMoveablesAction.start = function(self)
    if not isLmionTransportAction(self)
        or (self.mode ~= "pickup" and self.mode ~= "place")
    then
        ISMoveablesAction._lmionPresentationOriginalStart(self)
        return
    end

    local toolName = getActionToolName(self)
    local tool = getResolvedActionTool(self)

    -- walkToAndEquip() still owns pathing, inventory transfers and normal tool
    -- validation. At action start, make the already-resolved tool authoritative
    -- for the hand model so a stale crowbar/hammer cannot leak into presentation.
    equipResolvedToolNow(self, tool)

    ISMoveablesAction._lmionPresentationOriginalStart(self)

    if isScrewdriverTool(toolName) then
        self:setActionAnim("LMION_ScrewdriverHinge")
        if tool ~= nil then
            self:setOverrideHandModels(tool, nil)
        end
        return
    end

    if self.mode == "pickup" and isCrowbarTool(toolName) then
        self:setActionAnim("LMION_CrowbarPickupLow")
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
