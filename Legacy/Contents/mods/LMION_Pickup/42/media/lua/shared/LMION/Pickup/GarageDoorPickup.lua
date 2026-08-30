require "LMION/Pickup/GarageDoorMoveables"

local Pickup = LMION.Pickup
local Doors = LMION.Doors
local GarageDoor = Pickup.GarageDoor
local segmentsBySprite = GarageDoor.SegmentsBySprite

local function getSegment(object)
    local sprite = object and object:getSprite() or nil
    local spriteName = sprite and sprite:getName() or nil
    return spriteName and segmentsBySprite[spriteName] or nil
end

local function getGarageMembers(source, familyId)
    local chain = Doors.getGarageChain(source)
    if chain == nil then
        return nil
    end

    local expectedOpen = source:IsOpen()
    local members = {}

    for position, object in ipairs(chain) do
        local segment = getSegment(object)
        local role = Doors.getGarageRole(object)

        if segment == nil
            or segment.familyId ~= familyId
            or segment.partIndex ~= role
            or segment.isOpen ~= expectedOpen then
            return nil
        end

        -- START and END are unique roles; every interior member must be MIDDLE.
        if position == 1 then
            if role ~= Doors.GarageRole.START then
                return nil
            end
        elseif position == #chain then
            if role ~= Doors.GarageRole.END_ then
                return nil
            end
        elseif role ~= Doors.GarageRole.MIDDLE then
            return nil
        end

        members[position] = {
            object = object,
            square = object:getSquare(),
            spriteName = object:getSprite():getName(),
            closedSpriteName = segment.closedSpriteName,
            role = role,
            isOpen = expectedOpen,
        }
    end

    if #members < 2 then
        return nil
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
    if family == nil then
        return false
    end

    local items = {}
    local totalParts = #members

    for position, member in ipairs(members) do
        local role = member.role
        local part = family.parts[role]
        if part == nil then
            return false
        end

        local moveProps = ISMoveableSpriteProps.new(member.spriteName)
        -- One parcel per physical member. Repeated middle members intentionally
        -- produce repeated Part2 items; there is no hidden garage bundle identity.
        moveProps.isMultiSprite = true
        moveProps.lmionGaragePart = role
        moveProps.customItem = part.itemType

        local item = moveProps:pickUpMoveableInternal(
            character,
            member.square,
            member.object,
            nil,
            member.closedSpriteName or member.spriteName,
            createItem,
            forceAllow
        )

        if item ~= nil and item.hasModData ~= nil and item:hasModData() then
            local modData = item:getModData()
            modData.lmionGaragePosition = position
            modData.lmionGarageSourceLength = totalParts
        end

        items[position] = item
    end

    if ISMoveableCursor ~= nil and ISMoveableCursor.clearCacheForAllPlayers ~= nil then
        ISMoveableCursor.clearCacheForAllPlayers()
    end

    return items
end

return GarageDoor
