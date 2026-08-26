require "Moveables/ISMoveableSpriteProps"
require "LMION/Pickup/Doors/Registry"

local Pickup = LMION.Pickup
local Doors = LMION.Doors
local DoorMoveables = Pickup.DoorMoveables

if Pickup._originalMoveableSpritePropsNew == nil then
    Pickup._originalMoveableSpritePropsNew = ISMoveableSpriteProps.new
end

ISMoveableSpriteProps.new = function(sprite)
    local moveProps = Pickup._originalMoveableSpritePropsNew(sprite)

    local resolvedSprite = sprite
    if type(resolvedSprite) == "string" then
        resolvedSprite = getSprite(resolvedSprite)
    end

    DoorMoveables.applyProfileToMoveProps(moveProps, resolvedSprite)
    return moveProps
end

if Pickup._originalMoveableHasFaces == nil then
    Pickup._originalMoveableHasFaces = ISMoveableSpriteProps.hasFaces
end

ISMoveableSpriteProps.hasFaces = function(self)
    if self ~= nil and self.lmionDoorFaces ~= nil and self.lmionDoorFacing ~= nil then
        return self.lmionDoorFaces.N ~= nil
            and self.lmionDoorFaces.W ~= nil
            and self.lmionDoorFaces.N ~= self.lmionDoorFaces.W
    end

    return Pickup._originalMoveableHasFaces(self)
end

if Pickup._originalMoveableGetFaces == nil then
    Pickup._originalMoveableGetFaces = ISMoveableSpriteProps.getFaces
end

ISMoveableSpriteProps.getFaces = function(self)
    if self ~= nil and self.lmionDoorFaces ~= nil and self.lmionDoorFacing ~= nil then
        return {
            N = self.lmionDoorFaces.N,
            W = self.lmionDoorFaces.W,
        }
    end

    return Pickup._originalMoveableGetFaces(self)
end

--[[
Vanilla serializes a Moveable through instanceItem(). LMION captures door health
just before vanilla removes the IsoDoor, then injects that state into the item
created by vanilla instead of inventing a parallel serialization path.
]]
if Pickup._originalMoveableInstanceItem == nil then
    Pickup._originalMoveableInstanceItem = ISMoveableSpriteProps.instanceItem
end

ISMoveableSpriteProps.instanceItem = function(self, spriteNameOverride)
    local item = Pickup._originalMoveableInstanceItem(self, spriteNameOverride)
    local profile = self and (self.lmionDoorProfile or DoorMoveables.getProfileForMoveProps(self)) or nil

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
    local profile = self and (self.lmionDoorProfile or DoorMoveables.getProfileForMoveProps(self)) or nil

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
    local profile = self and (self.lmionDoorProfile or DoorMoveables.getProfileForMoveProps(self)) or nil
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
    local profile = self and (self.lmionDoorProfile or DoorMoveables.getProfileForMoveProps(self)) or nil
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
            door = DoorMoveables.findPlacedDoor(square, spriteName)
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

return DoorMoveables
