require "LMION/Pickup/GarageDoorMoveables"

local Pickup = LMION.Pickup
local GarageDoor = Pickup.GarageDoor
local segmentsBySprite = GarageDoor.SegmentsBySprite

local function getSegment(object)
    local sprite = object and object:getSprite() or nil
    local spriteName = sprite and sprite:getName() or nil
    return spriteName and segmentsBySprite[spriteName] or nil
end

local function findGarageMember(square, north, expectedIndex, familyId, expectedOpen)
    if square == nil then
        return nil
    end

    local objects = square:getSpecialObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if object ~= nil
            and instanceof(object, "IsoDoor")
            and object:IsOpen() == expectedOpen
            and object:getNorth() == north
            and IsoDoor.getGarageDoorIndex(object) == expectedIndex then
            local segment = getSegment(object)
            if segment ~= nil
                and segment.familyId == familyId
                and segment.partIndex == expectedIndex
                and segment.isOpen == expectedOpen then
                return object
            end
        end
    end

    return nil
end

--[[
GarageDoor index 1/2/3 is the authoritative member identity. Open and closed
states occupy the same three squares; only the sprite/state changes. Starting
from any selected member, reconstruct the complete chain and require every
member to belong to the same family and the same open/closed state.
]]
local function getGarageMembers(source, familyId)
    if source == nil or not instanceof(source, "IsoDoor") then
        return nil
    end

    local sourceIndex = IsoDoor.getGarageDoorIndex(source)
    if sourceIndex == nil or sourceIndex < 1 or sourceIndex > 3 then
        return nil
    end

    local sourceSegment = getSegment(source)
    if sourceSegment == nil or sourceSegment.familyId ~= familyId then
        return nil
    end

    local expectedOpen = source:IsOpen()
    if sourceSegment.isOpen ~= expectedOpen then
        return nil
    end

    local sourceSquare = source:getSquare()
    if sourceSquare == nil then
        return nil
    end

    local north = source:getNorth()
    local firstX = sourceSquare:getX()
    local firstY = sourceSquare:getY()
    local z = sourceSquare:getZ()

    if north then
        firstX = firstX - (sourceIndex - 1)
    else
        firstY = firstY + (sourceIndex - 1)
    end

    local members = {}
    for expectedIndex = 1, 3 do
        local x = firstX
        local y = firstY

        if north then
            x = x + (expectedIndex - 1)
        else
            y = y - (expectedIndex - 1)
        end

        local square = getCell():getGridSquare(x, y, z)
        local object = findGarageMember(square, north, expectedIndex, familyId, expectedOpen)
        if object == nil then
            return nil
        end

        local segment = getSegment(object)
        members[expectedIndex] = {
            object = object,
            square = square,
            spriteName = object:getSprite():getName(),
            closedSpriteName = segment and segment.closedSpriteName or nil,
            engineIndex = expectedIndex,
            isOpen = expectedOpen,
        }
    end

    return members
end

GarageDoor.getMembers = getGarageMembers

if Pickup._garageDoorPickupPreviousCanPickUpMoveable == nil then
    Pickup._garageDoorPickupPreviousCanPickUpMoveable = ISMoveableSpriteProps.canPickUpMoveable
end

ISMoveableSpriteProps.canPickUpMoveable = function(self, character, square, object)
    if self == nil or self.lmionGarageFamily == nil then
        return Pickup._garageDoorPickupPreviousCanPickUpMoveable(self, character, square, object)
    end

    local selected = object
    if selected == nil and square ~= nil then
        selected = self:findOnSquare(square, self.spriteName)
    end

    local members = getGarageMembers(selected, self.lmionGarageFamily)
    if members == nil then
        return false
    end

    local previousCanPickUp = Pickup._garageDoorPreviousCanPickUpMoveable
        or Pickup._garageDoorPickupPreviousCanPickUpMoveable

    local wasMultiSprite = self.isMultiSprite
    self.isMultiSprite = false
    local canPickUp = previousCanPickUp(self, character, square, selected)
    self.isMultiSprite = wasMultiSprite

    if not canPickUp then
        return false
    end

    for _, member in ipairs(members) do
        if member.object == nil or not member.object:isObjectNoContainerOrEmpty() then
            return false
        end
    end

    return true
end

if Pickup._garageDoorPickupPreviousPickUpMoveable == nil then
    Pickup._garageDoorPickupPreviousPickUpMoveable = ISMoveableSpriteProps.pickUpMoveable
end

ISMoveableSpriteProps.pickUpMoveable = function(self, character, square, createItem, forceAllow)
    if self == nil or self.lmionGarageFamily == nil then
        return Pickup._garageDoorPickupPreviousPickUpMoveable(self, character, square, createItem, forceAllow)
    end

    local selected = self:findOnSquare(square, self.spriteName)
    if selected == nil then
        return false
    end

    if not forceAllow
        and not character:isMovablesCheat()
        and not ISMoveableDefinitions.cheat
        and not self:canPickUpMoveable(character, square, selected) then
        return false
    end

    local members = getGarageMembers(selected, self.lmionGarageFamily)
    if members == nil then
        return false
    end

    local family = GarageDoor.Families[self.lmionGarageFamily]
    local items = {}

    for partIndex, member in ipairs(members) do
        local moveProps = ISMoveableSpriteProps.new(member.spriteName)
        moveProps.isMultiSprite = false
        moveProps.lmionGaragePart = partIndex

        if family ~= nil and family.parts[partIndex] ~= nil then
            moveProps.customItem = family.parts[partIndex].itemType
        end

        items[partIndex] = moveProps:pickUpMoveableInternal(
            character,
            member.square,
            member.object,
            nil,
            member.closedSpriteName or member.spriteName,
            createItem,
            forceAllow
        )
    end

    if ISMoveableCursor ~= nil and ISMoveableCursor.clearCacheForAllPlayers ~= nil then
        ISMoveableCursor.clearCacheForAllPlayers()
    end

    return items
end

return GarageDoor
