require "LMION/Pickup/GarageDoorMoveables"

local Pickup = LMION.Pickup
local GarageDoor = Pickup.GarageDoor
local segmentsBySprite = GarageDoor.SegmentsBySprite
local TRACE_PREFIX = "[LMION][GarageTrace][Pickup] "

local function trace(message)
    print(TRACE_PREFIX .. tostring(message))
end

local function squareText(square)
    if square == nil then
        return "nil"
    end
    return tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ())
end

local function objectText(object)
    if object == nil then
        return "nil"
    end

    local sprite = object:getSprite()
    local spriteName = sprite and sprite:getName() or nil
    local properties = sprite and sprite:getProperties() or nil
    local rawIndex = properties and properties:get("GarageDoor") or nil
    local normalizedIndex = instanceof(object, "IsoDoor") and IsoDoor.getGarageDoorIndex(object) or nil

    return table.concat({
        "object=" .. tostring(object),
        "sprite=" .. tostring(spriteName),
        "square=" .. squareText(object:getSquare()),
        "north=" .. tostring(instanceof(object, "IsoDoor") and object:getNorth() or nil),
        "open=" .. tostring(instanceof(object, "IsoDoor") and object:IsOpen() or nil),
        "garageRaw=" .. tostring(rawIndex),
        "garageIndex=" .. tostring(normalizedIndex),
    }, " ")
end

local function getSegment(object)
    local sprite = object and object:getSprite() or nil
    local spriteName = sprite and sprite:getName() or nil
    return spriteName and segmentsBySprite[spriteName] or nil
end

local function traceSquareGarageCandidates(square, label)
    if square == nil then
        trace(label .. " square=nil")
        return
    end

    local objects = square:getSpecialObjects()
    trace(label .. " square=" .. squareText(square) .. " specialObjectCount=" .. tostring(objects:size()))
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        trace(label .. " objectIndex=" .. tostring(i) .. " " .. objectText(object))
    end
end

local function findGarageMember(square, north, expectedIndex, familyId)
    if square == nil then
        return nil
    end

    local objects = square:getSpecialObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if object ~= nil
            and instanceof(object, "IsoDoor")
            and not object:IsOpen()
            and object:getNorth() == north
            and IsoDoor.getGarageDoorIndex(object) == expectedIndex then
            local segment = getSegment(object)
            if segment ~= nil and segment.familyId == familyId then
                return object
            end
        end
    end

    return nil
end

local function getGarageMembers(source, familyId)
    if source == nil or not instanceof(source, "IsoDoor") or source:IsOpen() then
        trace("RESOLVE_ABORT source invalid " .. objectText(source))
        return nil
    end

    local sourceIndex = IsoDoor.getGarageDoorIndex(source)
    if sourceIndex == nil or sourceIndex < 1 or sourceIndex > 3 then
        trace("RESOLVE_ABORT bad sourceIndex=" .. tostring(sourceIndex) .. " " .. objectText(source))
        return nil
    end

    local sourceSegment = getSegment(source)
    if sourceSegment == nil or sourceSegment.familyId ~= familyId then
        trace("RESOLVE_ABORT segment mismatch sourceSegment=" .. tostring(sourceSegment and sourceSegment.familyId)
            .. " expectedFamily=" .. tostring(familyId) .. " " .. objectText(source))
        return nil
    end

    local sourceSquare = source:getSquare()
    if sourceSquare == nil then
        trace("RESOLVE_ABORT source square nil")
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

    trace("RESOLVE_BEGIN source={" .. objectText(source) .. "} family=" .. tostring(familyId)
        .. " computedFirst=" .. tostring(firstX) .. "," .. tostring(firstY) .. "," .. tostring(z))

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
        traceSquareGarageCandidates(square, "RESOLVE_CANDIDATES expectedIndex=" .. tostring(expectedIndex))

        local object = findGarageMember(square, north, expectedIndex, familyId)
        if object == nil then
            trace("RESOLVE_ABORT no member expectedIndex=" .. tostring(expectedIndex)
                .. " target=" .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z))
            return nil
        end

        trace("RESOLVE_MEMBER expectedIndex=" .. tostring(expectedIndex) .. " " .. objectText(object))
        members[expectedIndex] = {
            object = object,
            square = square,
            spriteName = object:getSprite():getName(),
            engineIndex = expectedIndex,
        }
    end

    local first = IsoDoor.getGarageDoorFirst(source)
    trace("ENGINE_FIRST " .. objectText(first))
    for expectedIndex = 1, 3 do
        local object = members[expectedIndex].object
        trace("ENGINE_LINK part=" .. tostring(expectedIndex)
            .. " prev={" .. objectText(IsoDoor.getGarageDoorPrev(object)) .. "}"
            .. " next={" .. objectText(IsoDoor.getGarageDoorNext(object)) .. "}")
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

    trace("================ CAN_PICKUP BEGIN ================")
    trace("MOVE_PROPS family=" .. tostring(self.lmionGarageFamily)
        .. " part=" .. tostring(self.lmionGaragePart)
        .. " facing=" .. tostring(self.facing)
        .. " lmionFacing=" .. tostring(self.lmionGarageFacing)
        .. " spriteName=" .. tostring(self.spriteName)
        .. " isMultiSprite=" .. tostring(self.isMultiSprite)
        .. " square=" .. squareText(square))

    local selected = object
    if selected == nil and square ~= nil then
        selected = self:findOnSquare(square, self.spriteName)
    end
    trace("SELECTED " .. objectText(selected))

    local members = getGarageMembers(selected, self.lmionGarageFamily)
    if members == nil then
        trace("CAN_PICKUP=false reason=members_nil")
        trace("================ CAN_PICKUP END ==================")
        return false
    end

    local previousCanPickUp = Pickup._garageDoorPreviousCanPickUpMoveable
        or Pickup._garageDoorPickupPreviousCanPickUpMoveable

    local wasMultiSprite = self.isMultiSprite
    self.isMultiSprite = false
    local canPickUp = previousCanPickUp(self, character, square, selected)
    self.isMultiSprite = wasMultiSprite
    trace("PREVIOUS_VALIDATOR result=" .. tostring(canPickUp))

    if not canPickUp then
        trace("CAN_PICKUP=false reason=previous_validator")
        trace("================ CAN_PICKUP END ==================")
        return false
    end

    for partIndex, member in ipairs(members) do
        local empty = member.object ~= nil and member.object:isObjectNoContainerOrEmpty()
        trace("MEMBER_EMPTY part=" .. tostring(partIndex) .. " result=" .. tostring(empty)
            .. " " .. objectText(member.object))
        if not empty then
            trace("CAN_PICKUP=false reason=member_not_empty part=" .. tostring(partIndex))
            trace("================ CAN_PICKUP END ==================")
            return false
        end
    end

    trace("CAN_PICKUP=true")
    trace("================ CAN_PICKUP END ==================")
    return true
end

if Pickup._garageDoorPickupPreviousPickUpMoveable == nil then
    Pickup._garageDoorPickupPreviousPickUpMoveable = ISMoveableSpriteProps.pickUpMoveable
end

ISMoveableSpriteProps.pickUpMoveable = function(self, character, square, createItem, forceAllow)
    if self == nil or self.lmionGarageFamily == nil then
        return Pickup._garageDoorPickupPreviousPickUpMoveable(self, character, square, createItem, forceAllow)
    end

    trace("================ PICKUP BEGIN ====================")
    trace("INPUT family=" .. tostring(self.lmionGarageFamily)
        .. " part=" .. tostring(self.lmionGaragePart)
        .. " facing=" .. tostring(self.facing)
        .. " spriteName=" .. tostring(self.spriteName)
        .. " square=" .. squareText(square)
        .. " createItem=" .. tostring(createItem)
        .. " forceAllow=" .. tostring(forceAllow))

    local selected = self:findOnSquare(square, self.spriteName)
    trace("SELECTED " .. objectText(selected))
    if selected == nil then
        trace("PICKUP_ABORT selected=nil")
        trace("================ PICKUP END ======================")
        return false
    end

    if not forceAllow
        and not character:isMovablesCheat()
        and not ISMoveableDefinitions.cheat
        and not self:canPickUpMoveable(character, square, selected) then
        trace("PICKUP_ABORT canPickUp=false")
        trace("================ PICKUP END ======================")
        return false
    end

    local members = getGarageMembers(selected, self.lmionGarageFamily)
    if members == nil then
        trace("PICKUP_ABORT members=nil after validation")
        trace("================ PICKUP END ======================")
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

        trace("REMOVE_PART_INPUT part=" .. tostring(partIndex)
            .. " expectedItemType=" .. tostring(moveProps.customItem)
            .. " " .. objectText(member.object))

        items[partIndex] = moveProps:pickUpMoveableInternal(
            character,
            member.square,
            member.object,
            nil,
            member.spriteName,
            createItem,
            forceAllow
        )

        local item = items[partIndex]
        local modData = item and item:hasModData() and item:getModData() or nil
        trace("REMOVE_PART_OUTPUT part=" .. tostring(partIndex)
            .. " item=" .. tostring(item)
            .. " fullType=" .. tostring(item and item:getFullType())
            .. " worldSprite=" .. tostring(item and item:getWorldSprite())
            .. " parcelFamily=" .. tostring(modData and modData.lmionGarageFamily)
            .. " parcelPart=" .. tostring(modData and modData.lmionGaragePart)
            .. " health=" .. tostring(modData and modData.lmionDoorHealth)
            .. " maxHealth=" .. tostring(modData and modData.lmionDoorMaxHealth))
    end

    if ISMoveableCursor ~= nil and ISMoveableCursor.clearCacheForAllPlayers ~= nil then
        ISMoveableCursor.clearCacheForAllPlayers()
    end

    trace("================ PICKUP END ======================")
    return items
end

return GarageDoor
