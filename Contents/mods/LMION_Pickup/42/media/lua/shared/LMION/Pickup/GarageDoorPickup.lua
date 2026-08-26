require "LMION/Pickup/GarageDoorMoveables"

local Pickup = LMION.Pickup
local GarageDoor = Pickup.GarageDoor
local segmentsBySprite = GarageDoor.SegmentsBySprite

local function getSegment(object)
    local sprite = object and object:getSprite() or nil
    local spriteName = sprite and sprite:getName() or nil
    return spriteName and segmentsBySprite[spriteName] or nil
end

local function getGarageMembers(source, familyId)
    if source == nil or not instanceof(source, "IsoDoor") or source:IsOpen() then
        return nil
    end

    local first = IsoDoor.getGarageDoorFirst(source)
    if first == nil or IsoDoor.getGarageDoorIndex(first) ~= 1 then
        return nil
    end

    local members = {}
    local current = first

    for expectedIndex = 1, 3 do
        if current == nil
            or not instanceof(current, "IsoDoor")
            or current:IsOpen()
            or IsoDoor.getGarageDoorIndex(current) ~= expectedIndex then
            return nil
        end

        local segment = getSegment(current)
        if segment == nil
            or segment.familyId ~= familyId
            or segment.partIndex ~= expectedIndex then
            return nil
        end

        members[expectedIndex] = {
            object = current,
            square = current:getSquare(),
            spriteName = current:getSprite():getName(),
        }

        if expectedIndex < 3 then
            current = IsoDoor.getGarageDoorNext(current)
        end
    end

    return members
end

GarageDoor.getMembers = getGarageMembers

--[[
Vanilla multi-sprite pickup drops each member as a world item. Garage transport is
instead three inventory parcels, so Pickup validates the whole garage but lets
vanilla perform the per-segment removal in single-sprite mode.
]]
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

    local wasMultiSprite = self.isMultiSprite
    self.isMultiSprite = false
    local canPickUp = Pickup._garageDoorPickupPreviousCanPickUpMoveable(self, character, square, selected)
    self.isMultiSprite = wasMultiSprite

    if not canPickUp then
        return false
    end

    for _, member in ipairs(members) do
        if member.object == nil or not member.object:isObjectNoContainerOrEmpty() then
            return false
        end
    end

    if character ~= nil and not ISMoveableDefinitions.cheat and not character:isMovablesCheat() then
        local family = GarageDoor.Families[self.lmionGarageFamily]
        local totalWeight = family and (family.partWeight * 3) or 60
        if not character:getInventory():hasRoomFor(character, totalWeight) then
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

    local items = {}
    for partIndex, member in ipairs(members) do
        local moveProps = ISMoveableSpriteProps.new(member.spriteName)
        moveProps.isMultiSprite = false
        items[partIndex] = moveProps:pickUpMoveableInternal(
            character,
            member.square,
            member.object,
            nil,
            member.spriteName,
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
