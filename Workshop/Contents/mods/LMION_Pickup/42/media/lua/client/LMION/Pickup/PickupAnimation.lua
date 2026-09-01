require "Moveables/ISMoveablesAction"
require "Moveables/ISMoveableSpriteProps"
require "TimedActions/ISEquipWeaponAction"


local function isLmionTransportMoveProps(moveProps)
    return moveProps ~= nil
        and (moveProps.lmionDefinitionId ~= nil
            or moveProps.lmionGarageDefinitionId ~= nil
            or moveProps.lmionLargeGateDefinitionId ~= nil)
end


local function isLmionTransportAction(action)
    return isLmionTransportMoveProps(action and action.moveProps or nil)
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


local function getResolvedMovePropsTool(moveProps, character, mode)
    if moveProps == nil
        or character == nil
        or (mode ~= "pickup" and mode ~= "place")
    then
        return nil
    end

    local tool = moveProps:hasTool(character, mode)
    if tool == nil or tool == false or tool == true then
        return nil
    end

    return tool
end


local function getResolvedActionTool(action)
    return getResolvedMovePropsTool(
        action and action.moveProps or nil,
        action and action.character or nil,
        action and action.mode or nil
    )
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


local function sameInventoryItem(first, second)
    if first == second then
        return true
    end

    if first == nil
        or second == nil
        or first.getID == nil
        or second.getID == nil
    then
        return false
    end

    return first:getID() == second:getID()
end


local function markQueuedEquipAction(character, firstNewIndex, tool, mode)
    local timedQueue = character
        and ISTimedActionQueue.getTimedActionQueue(character)
        or nil
    local queue = timedQueue and timedQueue.queue or nil

    if queue == nil or tool == nil then
        return
    end

    for index = firstNewIndex, #queue do
        local action = queue[index]

        if action ~= nil
            and action.Type == "ISEquipWeaponAction"
            and sameInventoryItem(action.item, tool)
        then
            action.lmionTransportEquip = true
            action.lmionTransportMode = mode
        end
    end
end


-- Vanilla walkToAndEquip() correctly selects and queues the gameplay tool, but
-- non-hotbar ISEquipWeaponAction keeps rendering the previously held item until
-- complete(). Mark only the equip action created for an LMION transport action so
-- its presentation can show the tool being equipped instead of a stale crowbar,
-- hammer or screwdriver.
if ISMoveableSpriteProps._lmionPresentationOriginalWalkToAndEquip == nil then
    ISMoveableSpriteProps._lmionPresentationOriginalWalkToAndEquip =
        ISMoveableSpriteProps.walkToAndEquip
end


ISMoveableSpriteProps.walkToAndEquip = function(
    self,
    character,
    square,
    mode,
    origSpriteName
)
    if not isLmionTransportMoveProps(self)
        or (mode ~= "pickup" and mode ~= "place")
    then
        return ISMoveableSpriteProps._lmionPresentationOriginalWalkToAndEquip(
            self,
            character,
            square,
            mode,
            origSpriteName
        )
    end

    local tool = getResolvedMovePropsTool(self, character, mode)
    local timedQueue = character
        and ISTimedActionQueue.getTimedActionQueue(character)
        or nil
    local queue = timedQueue and timedQueue.queue or nil
    local firstNewIndex = (queue and #queue or 0) + 1

    local result = ISMoveableSpriteProps._lmionPresentationOriginalWalkToAndEquip(
        self,
        character,
        square,
        mode,
        origSpriteName
    )

    if result and tool ~= nil then
        markQueuedEquipAction(character, firstNewIndex, tool, mode)
    end

    return result
end


-- ISEquipWeaponAction normally swaps the real hand item only in complete(). That
-- is correct gameplay, but during its animation it leaves the old tool visible.
-- For the LMION equip action marked above, keep vanilla timing/transfer semantics
-- and only override the displayed hand model with the target tool.
if ISEquipWeaponAction._lmionPresentationOriginalStart == nil then
    ISEquipWeaponAction._lmionPresentationOriginalStart = ISEquipWeaponAction.start
end


ISEquipWeaponAction.start = function(self)
    local showTargetTool = self.lmionTransportEquip == true
        and self.item ~= nil
        and not self:isAlreadyEquipped(self.item)

    ISEquipWeaponAction._lmionPresentationOriginalStart(self)

    if showTargetTool then
        self:setOverrideHandModels(
            self.item,
            self.twoHands and self.item or nil
        )
    end
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
    -- for the real hand state as well as the presentation.
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
