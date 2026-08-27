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

local function restartBlowTorchSound(action)
    local character = action and action.character or nil
    if character == nil then
        return
    end

    stopActionSound(action)
    action.sound = character:getEmitter():playSound("BlowTorch")

    local radius = 20 * character:getWeldingSoundMod()
    addSound(character, character:getX(), character:getY(), character:getZ(), radius, radius)
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

local function getScrapDefinition(action)
    local moveProps = action and action.moveProps or nil
    local material = moveProps and moveProps.material or nil
    if material == nil then
        return nil
    end

    local definitions = ISMoveableDefinitions and ISMoveableDefinitions:getInstance() or nil
    return definitions and definitions.getScrapDefinition(material) or nil
end

local function scrapUsesBlowTorch(action)
    local scrapDef = getScrapDefinition(action)
    local tools = scrapDef and scrapDef.tools or nil
    if tools == nil then
        return false
    end

    for _, fullType in ipairs(tools) do
        if fullType == "Base.BlowTorch" then
            return true
        end
    end

    return false
end

local function findUsableBlowTorch(character)
    local inventory = character and character:getInventory() or nil
    if inventory == nil then
        return nil
    end

    return inventory:getFirstTypeEvalRecurse("Base.BlowTorch", function(item)
        return item ~= nil and item:getCurrentUsesFloat() >= 0.1
    end)
end

local function forceBlowTorchPresentation(action, blowTorch)
    if action == nil or blowTorch == nil then
        return
    end

    local moveProps = action.moveProps
    local object = moveProps and moveProps.object or nil
    local isFloor = object ~= nil and object:isFloor()

    action:setActionAnim(isFloor and "BlowTorchFloor" or "BlowTorch")
    action:setOverrideHandModels(blowTorch, nil)
end

--[[
LMION presentation follows the gameplay tool contract instead of whatever item
happened to remain in the character's hands from the previous Moveables action.

Transport:
- Screwdriver Pickup/Place: LMION_ScrewdriverHinge -> vanilla Bob_IdleMakingLow,
  with the real screwdriver in the primary hand.
- Crowbar Pickup: LMION_CrowbarPickupLow -> vanilla Bob_IdleLeverOpenLow,
  with the real crowbar kept one-handed and the crowbar sound.
- Hammer Place: vanilla Build animation and configured Hammering sound.

Scrap:
Vanilla Moveables gets the ScrapDefinition from moveProps.material, so LMION keeps
that definition authoritative for tools, skill, duration, welding protection and
tool consumption.

However, ISMoveablesAction.start() does NOT choose its welding animation from that
ScrapDefinition. It separately checks character:hasEquippedTag(ItemTag.BLOW_TORCH)
and falls back to Disassemble + a fake Screwdriver model when the check fails.
Therefore, when the actual ScrapDefinition requires Base.BlowTorch, LMION equips the
real usable torch before vanilla start(), then re-applies BlowTorch/BlowTorchFloor,
the real hand model and the same BlowTorch emitter sound used by vanilla welding
actions. The ScrapDefinition remains the gameplay authority.
]]
if Pickup._pickupPresentationOriginalActionStart == nil then
    Pickup._pickupPresentationOriginalActionStart = ISMoveablesAction.start
end

ISMoveablesAction.start = function(self)
    if isLmionTransportAction(self) and self.mode == "scrap" and scrapUsesBlowTorch(self) then
        local blowTorch = findUsableBlowTorch(self.character)
        equipResolvedToolNow(self, blowTorch)
        Pickup._pickupPresentationOriginalActionStart(self)
        forceBlowTorchPresentation(self, blowTorch)
        restartBlowTorchSound(self)
        return
    end

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

return Pickup
