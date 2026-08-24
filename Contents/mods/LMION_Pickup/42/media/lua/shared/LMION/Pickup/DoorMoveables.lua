require "Moveables/ISMoveableSpriteProps"
require "LMION/Core"
require "LMION/Pickup/DoorProfiles"

local Pickup = LMION.Pickup
local Doors = LMION.Doors
local Profiles = Pickup.DoorProfiles

local spriteProfiles = nil

local function buildSpriteProfiles()
    if spriteProfiles ~= nil then
        return
    end

    spriteProfiles = {}

    local scripts = ScriptManager.instance:getAllGameEntities()
    for i = 0, scripts:size() - 1 do
        local script = scripts:get(i)
        local profile = Profiles.entities[script:getName()]

        if profile ~= nil then
            local spriteConfig = script:getComponentScriptFor(ComponentType.SpriteConfig)
            if spriteConfig ~= nil then
                local tileNames = spriteConfig:getAllTileNames()
                for j = 0, tileNames:size() - 1 do
                    spriteProfiles[tileNames:get(j)] = profile
                end
            end
        end
    end
end

local function getProfileForSprite(sprite)
    if sprite == nil then
        return nil
    end

    if type(sprite) == "string" then
        sprite = getSprite(sprite)
    end

    if sprite == nil or sprite:getName() == nil then
        return nil
    end

    buildSpriteProfiles()
    return spriteProfiles[sprite:getName()]
end

local function getProfileForMoveProps(moveProps, sprite)
    if moveProps == nil then
        return nil
    end

    return getProfileForSprite(sprite or moveProps.sprite)
end

local function getProfileDisplayName(profile)
    if profile == nil or profile.itemType == nil then
        return profile and profile.id or nil
    end

    local scriptItem = ScriptManager.instance:FindItem(profile.itemType)
    if scriptItem ~= nil then
        return scriptItem:getDisplayName()
    end

    return profile.id
end

local function applyProfileToMoveProps(moveProps, sprite)
    local profile = getProfileForMoveProps(moveProps, sprite)
    if profile == nil then
        return nil
    end

    moveProps.name = getProfileDisplayName(profile) or moveProps.name
    moveProps.customItem = profile.itemType or moveProps.customItem
    moveProps.type = profile.moveType or "Object"
    moveProps.pickUpTool = profile.pickUpTool
    moveProps.placeTool = profile.placeTool
    moveProps.pickUpLevel = profile.pickUpLevel or 0
    moveProps.rawWeight = profile.pickUpWeight or moveProps.rawWeight
    moveProps.weight = moveProps.rawWeight and (moveProps.rawWeight / 10) or moveProps.weight
    moveProps.canBreak = profile.pickUpTool ~= nil and profile.canBreak == true
    moveProps.lmionDoorProfile = profile

    return profile
end

local function markDoorSpriteMoveable(sprite)
    if sprite == nil then
        return false
    end

    local properties = sprite:getProperties()
    if properties == nil then
        return false
    end

    properties:set("IsMoveAble")
    return true
end

local function configureKnownDoorSprites()
    spriteProfiles = nil
    buildSpriteProfiles()

    local configured = 0
    for spriteName, _ in pairs(spriteProfiles) do
        local sprite = getSprite(spriteName)
        if markDoorSpriteMoveable(sprite) then
            configured = configured + 1
        end
    end

    LMION.log("Pickup", "configured " .. tostring(configured) .. " framed 1x1 door sprites for Moveables")
end

local function findPlacedDoor(square, spriteName)
    if square == nil or spriteName == nil then
        return nil
    end

    local objects = square:getSpecialObjects()
    for i = objects:size() - 1, 0, -1 do
        local object = objects:get(i)
        local sprite = object and object:getSprite() or nil
        if instanceof(object, "IsoDoor")
            and sprite ~= nil
            and sprite:getName() == spriteName then
            return object
        end
    end

    return nil
end

if Pickup._doorMoveablesConfigureHandler ~= nil then
    Events.OnLoadedTileDefinitions.Remove(Pickup._doorMoveablesConfigureHandler)
end

Pickup._doorMoveablesConfigureHandler = configureKnownDoorSprites
Events.OnLoadedTileDefinitions.Add(Pickup._doorMoveablesConfigureHandler)

if Pickup._originalMoveableSpritePropsNew == nil then
    Pickup._originalMoveableSpritePropsNew = ISMoveableSpriteProps.new
end

ISMoveableSpriteProps.new = function(sprite)
    local moveProps = Pickup._originalMoveableSpritePropsNew(sprite)

    local resolvedSprite = sprite
    if type(resolvedSprite) == "string" then
        resolvedSprite = getSprite(resolvedSprite)
    end

    applyProfileToMoveProps(moveProps, resolvedSprite)
    return moveProps
end

if Pickup._originalMoveableInstanceItem == nil then
    Pickup._originalMoveableInstanceItem = ISMoveableSpriteProps.instanceItem
end

ISMoveableSpriteProps.instanceItem = function(self, spriteNameOverride)
    local item = Pickup._originalMoveableInstanceItem(self, spriteNameOverride)
    local profile = self and (self.lmionDoorProfile or getProfileForMoveProps(self)) or nil

    if item ~= nil and profile ~= nil then
        if self.lmionPendingHealth ~= nil then
            item:getModData().lmionDoorHealth = self.lmionPendingHealth
        end

        if self.lmionPendingMaxHealth ~= nil then
            item:getModData().lmionDoorMaxHealth = self.lmionPendingMaxHealth
        end
    end

    return item
end

if Pickup._originalPickUpMoveableInternal == nil then
    Pickup._originalPickUpMoveableInternal = ISMoveableSpriteProps.pickUpMoveableInternal
end

ISMoveableSpriteProps.pickUpMoveableInternal = function(self, character, square, object, sprInstance, spriteName, createItem, rotating)
    local profile = self and (self.lmionDoorProfile or getProfileForMoveProps(self)) or nil

    self.lmionPendingHealth = nil
    self.lmionPendingMaxHealth = nil

    if profile ~= nil and object ~= nil and instanceof(object, "IsoDoor") then
        self.lmionPendingHealth = object:getHealth()

        local modData = object:getModData()
        if modData ~= nil then
            self.lmionPendingMaxHealth = tonumber(modData[Doors.MaxHealthModDataKey])
        end
    end

    local item = Pickup._originalPickUpMoveableInternal(self, character, square, object, sprInstance, spriteName, createItem, rotating)
    self.lmionPendingHealth = nil
    self.lmionPendingMaxHealth = nil
    return item
end

if Pickup._originalCanPlaceMoveableInternal == nil then
    Pickup._originalCanPlaceMoveableInternal = ISMoveableSpriteProps.canPlaceMoveableInternal
end

ISMoveableSpriteProps.canPlaceMoveableInternal = function(self, character, square, item, forceTypeObject)
    local profile = self and (self.lmionDoorProfile or getProfileForMoveProps(self)) or nil
    if profile == nil then
        return Pickup._originalCanPlaceMoveableInternal(self, character, square, item, forceTypeObject)
    end

    if square == nil or square:isVehicleIntersecting() then
        return false
    end

    local north = Doors.getNorthFromSprite(self.sprite)
    if not Doors.canPlaceDoorAt(square, north, profile.requiresFrame) then
        return false
    end

    if character ~= nil and instanceof(character, "IsoPlayer") then
        if not ISMoveableDefinitions.cheat and not character:isMovablesCheat() then
            local hasSkill = self:hasRequiredSkill(character, "place")
            local hasTool = not self.placeTool or self:hasTool(character, "place")
            if not hasSkill or not hasTool then
                return false
            end
        end
    end

    return true
end

if Pickup._originalPlaceMoveableInternal == nil then
    Pickup._originalPlaceMoveableInternal = ISMoveableSpriteProps.placeMoveableInternal
end

ISMoveableSpriteProps.placeMoveableInternal = function(self, square, item, spriteName)
    local profile = self and (self.lmionDoorProfile or getProfileForMoveProps(self)) or nil
    local savedHealth = nil
    local savedMaxHealth = nil

    if profile ~= nil and item ~= nil and item:hasModData() then
        local modData = item:getModData()
        savedHealth = tonumber(modData.lmionDoorHealth)
        savedMaxHealth = tonumber(modData.lmionDoorMaxHealth)
    end

    local result = Pickup._originalPlaceMoveableInternal(self, square, item, spriteName)

    if profile ~= nil and (savedHealth ~= nil or savedMaxHealth ~= nil) then
        local door = nil

        if result ~= nil and instanceof(result, "IsoDoor") then
            door = result
        else
            door = findPlacedDoor(square, spriteName)
        end

        if door ~= nil then
            if savedMaxHealth ~= nil then
                Doors.setEffectiveMaxHealth(door, savedMaxHealth)
            end

            if savedHealth ~= nil then
                door:setHealth(math.max(0, savedHealth))
            end

            if isServer() then
                door:transmitCompleteItemToClients()
            end
        end
    end

    return result
end

return Pickup
