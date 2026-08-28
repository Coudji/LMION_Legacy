require "Moveables/ISMoveableSpriteProps"
require "LMION/Pickup/Doors/Registry"

local Pickup = LMION.Pickup
local Doors = LMION.Doors
local DoorMoveables = Pickup.DoorMoveables

local function getCanonicalClosedSpriteName(moveProps, profile, fallbackSpriteName)
    if moveProps == nil or profile == nil or profile.moveFaces == nil then
        return fallbackSpriteName
    end

    local facing = moveProps.facing or moveProps.lmionDoorFacing
    if facing == "N" and profile.moveFaces.N ~= nil then
        return profile.moveFaces.N
    end
    if facing == "W" and profile.moveFaces.W ~= nil then
        return profile.moveFaces.W
    end

    local sprite = fallbackSpriteName and getSprite(fallbackSpriteName) or moveProps.sprite
    local north = Doors.getNorthFromSprite(sprite)
    if north == true and profile.moveFaces.N ~= nil then
        return profile.moveFaces.N
    end
    if north == false and profile.moveFaces.W ~= nil then
        return profile.moveFaces.W
    end

    return fallbackSpriteName
end

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
Vanilla serializes a Moveable through instanceItem(). Pickup transports Core's
normalized door state, including the physical representation of the source door.

Door inventory identity is always canonicalized to the CLOSED N/W SpriteConfig
face so an open door is reinstalled as the normal closed transport identity.
]]
if Pickup._originalMoveableInstanceItem == nil then
    Pickup._originalMoveableInstanceItem = ISMoveableSpriteProps.instanceItem
end

ISMoveableSpriteProps.instanceItem = function(self, spriteNameOverride)
    local profile = self and (self.lmionDoorProfile or DoorMoveables.getProfileForMoveProps(self)) or nil
    local canonicalSpriteName = getCanonicalClosedSpriteName(self, profile, spriteNameOverride)
    local item = Pickup._originalMoveableInstanceItem(self, canonicalSpriteName)

    if item ~= nil and profile ~= nil then
        local modData = item:getModData()
        if self.lmionPendingHealth ~= nil then
            modData.lmionDoorHealth = self.lmionPendingHealth
        end
        if self.lmionPendingMaxHealth ~= nil then
            modData.lmionDoorMaxHealth = self.lmionPendingMaxHealth
            modData.lmionDoorMaxWasLogical = self.lmionPendingMaxWasLogical == true
        end
        if self.lmionPendingRepresentation ~= nil then
            modData.lmionDoorSourceRepresentation = self.lmionPendingRepresentation
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
    self.lmionPendingMaxWasLogical = nil
    self.lmionPendingRepresentation = nil

    if profile ~= nil and Doors.isDoorObject(object) then
        local state = Doors.captureDoorState(object)
        if state ~= nil then
            self.lmionPendingHealth = state.health
            self.lmionPendingMaxHealth = state.maxHealth
            self.lmionPendingMaxWasLogical = state.hasLogicalMaxOverride == true
            self.lmionPendingRepresentation = state.representation
        end
    end

    local item = Pickup._originalPickUpMoveableInternal(self, character, square, object, sprInstance, spriteName, createItem, rotating)
    self.lmionPendingHealth = nil
    self.lmionPendingMaxHealth = nil
    self.lmionPendingMaxWasLogical = nil
    self.lmionPendingRepresentation = nil
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

    local canonicalSpriteName = getCanonicalClosedSpriteName(self, profile, self.sprite and self.sprite:getName() or nil)
    local north = Doors.getNorthFromSprite(canonicalSpriteName)
    if not Doors.canPlaceDoorAt(square, north, profile.requiresFrame, profile.pairedFrameSide) then
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
    local savedMaxWasLogical = false
    local savedRepresentation = nil

    if profile ~= nil and item ~= nil and item:hasModData() then
        local modData = item:getModData()
        savedHealth = tonumber(modData.lmionDoorHealth)
        savedMaxHealth = tonumber(modData.lmionDoorMaxHealth)
        savedMaxWasLogical = modData.lmionDoorMaxWasLogical == true
        savedRepresentation = modData.lmionDoorSourceRepresentation
    end

    local canonicalSpriteName = getCanonicalClosedSpriteName(self, profile, spriteName)
    local result = Pickup._originalPlaceMoveableInternal(self, square, item, canonicalSpriteName)

    if profile == nil then
        return result
    end

    local door = Doors.isDoorObject(result) and result
        or DoorMoveables.findPlacedDoor(square, canonicalSpriteName)

    if door == nil then
        return result
    end

    if savedRepresentation ~= nil and Doors.restorePlacedRepresentation ~= nil then
        Pickup._largeGateSuppressToggleRemoval = true
        local ok, restored = pcall(Doors.restorePlacedRepresentation, door, savedRepresentation)
        Pickup._largeGateSuppressToggleRemoval = false

        if not ok then
            LMION.error("Pickup", "failed to restore door representation: " .. tostring(restored))
        elseif Doors.isDoorObject(restored) then
            door = restored
        end
    end

    -- Vanilla saves additional IsoThumpable fields in the Moveable item. Because
    -- vanilla initially created an IsoDoor for doorN/doorW, restore those fields
    -- after Core has recreated the intended IsoThumpable representation.
    if savedRepresentation == "IsoThumpable"
        and item ~= nil
        and item:hasModData()
        and Doors.isThumpableDoor(door)
        and self.restoreThumpableParameters ~= nil then
        self:restoreThumpableParameters(item:getModData(), door)
    end

    if savedMaxHealth ~= nil then
        Doors.restoreEffectiveMaxHealth(door, savedMaxHealth, savedMaxWasLogical)
    end
    if savedHealth ~= nil then
        Doors.setHealth(door, savedHealth)
    end

    if isServer() and door.transmitCompleteItemToClients ~= nil then
        door:transmitCompleteItemToClients()
    end

    return door
end

return DoorMoveables
