require "Moveables/ISMoveablesAction"

local Pickup = LMION.Pickup

local METAL_HAMMER_HIT_INTERVAL_MS = 900
local METAL_HAMMER_WORLD_SOUND_INTERVAL_MS = 6000

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

local function hardStopActionSound(action)
    local character = action and action.character or nil
    if character ~= nil and action.sound ~= nil and action.sound ~= 0 then
        character:getEmitter():stopSound(action.sound)
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

local function isMetalHammerTool(toolName)
    return toolName == "LMIONMetalHammer"
end

local function playMetalHammerHit(action)
    local character = action and action.character or nil
    if character == nil then
        return
    end

    character:playSound("SmithingHammerHit")
    action.lmionMetalHammerNextHit = getTimestampMs() + METAL_HAMMER_HIT_INTERVAL_MS
end

local function startMetalHammerSound(action)
    local character = action and action.character or nil
    if character == nil then
        return
    end

    -- Vanilla Moveables starts the LMIONMetalHammer tool sound before LMION
    -- applies its metal presentation. stopOrTriggerSound() can let that FMOD
    -- event reach its cue/release, so kill it immediately here to prevent the
    -- carpentry Hammering sound from overlapping SmithingHammerHit.
    hardStopActionSound(action)

    local now = getTimestampMs()
    action.lmionMetalHammerNextWorldSound = now + METAL_HAMMER_WORLD_SOUND_INTERVAL_MS
    playMetalHammerHit(action)
end

local function updateMetalHammerSound(action)
    if not isLmionTransportAction(action)
        or action.mode ~= "place"
        or not isMetalHammerTool(getActionToolName(action)) then
        return
    end

    local character = action.character
    if character == nil then
        return
    end

    local now = getTimestampMs()
    if action.lmionMetalHammerNextHit == nil or now >= action.lmionMetalHammerNextHit then
        playMetalHammerHit(action)
    end

    if action.lmionMetalHammerNextWorldSound == nil or now >= action.lmionMetalHammerNextWorldSound then
        addSound(character, character:getX(), character:getY(), character:getZ(), 10, 5)
        action.lmionMetalHammerNextWorldSound = now + METAL_HAMMER_WORLD_SOUND_INTERVAL_MS
    end
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
  with the real crowbar kept one-handed and the vanilla crowbar sound. Wood/metal
  crowbar sound differentiation is intentionally deferred until an event is chosen.
- Wooden Hammer Place: vanilla Build animation and configured Hammering sound.
- Metal Hammer Place: vanilla Build animation with SmithingHammerHit pulses instead
  of the carpentry Hammering loop. The initial Moveables world-noise pulse is kept,
  then refreshed periodically for zombie attraction.

Scrap:
Vanilla Moveables gets the ScrapDefinition from moveProps.material, so LMION keeps
that definition authoritative for tools, skill, duration, welding protection, sound
lifecycle and tool consumption.

However, ISMoveablesAction.start() does NOT choose its welding animation from that
ScrapDefinition. It separately checks character:hasEquippedTag(ItemTag.BLOW_TORCH)
and falls back to Disassemble + a fake Screwdriver model when the check fails.
Therefore, when the actual ScrapDefinition requires Base.BlowTorch, LMION equips the
real usable torch before vanilla start(), then re-applies BlowTorch/BlowTorchFloor
and the real hand model after vanilla start().
]]
if Pickup._pickupPresentationOriginalActionStart == nil then
    Pickup._pickupPresentationOriginalActionStart = ISMoveablesAction.start
end

if Pickup._pickupPresentationOriginalActionUpdate == nil then
    Pickup._pickupPresentationOriginalActionUpdate = ISMoveablesAction.update
end

ISMoveablesAction.update = function(self)
    Pickup._pickupPresentationOriginalActionUpdate(self)
    updateMetalHammerSound(self)
end

ISMoveablesAction.start = function(self)
    if isLmionTransportAction(self) and self.mode == "scrap" and scrapUsesBlowTorch(self) then
        local blowTorch = findUsableBlowTorch(self.character)
        equipResolvedToolNow(self, blowTorch)
        Pickup._pickupPresentationOriginalActionStart(self)
        forceBlowTorchPresentation(self, blowTorch)
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

        if isMetalHammerTool(toolName) then
            startMetalHammerSound(self)
        else
            restartConfiguredToolSound(self)
        end
    end
end

return Pickup
