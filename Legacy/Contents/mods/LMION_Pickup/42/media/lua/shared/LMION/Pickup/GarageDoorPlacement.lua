require "Moveables/ISMoveableSpriteProps"
require "LMION/Pickup/GarageDoorPickup"

local Pickup = LMION.Pickup
local Doors = LMION.Doors
local GarageDoor = Pickup.GarageDoor

local function collectParcels(character, fullType)
    local found = {}
    if character == nil or fullType == nil then
        return found
    end

    local inventory = character:getInventory()
    local items = inventory and inventory:getItems() or nil
    if items ~= nil then
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item ~= nil and item:getFullType() == fullType then
                found[#found + 1] = {item = item, source = inventory}
            end
        end
    end

    local square = character:getSquare()
    if square == nil then
        return found
    end

    local radius = ISMoveableSpriteProps.multiSpriteFloorRadius or 3
    local sx = square:getX()
    local sy = square:getY()
    local sz = square:getZ()

    for x = sx - radius, sx + radius do
        for y = sy - radius, sy + radius do
            local candidateSquare = getCell():getGridSquare(x, y, sz)
            local worldObjects = candidateSquare and candidateSquare:getWorldObjects() or nil
            if worldObjects ~= nil then
                for i = 0, worldObjects:size() - 1 do
                    local worldObject = worldObjects:get(i)
                    if instanceof(worldObject, "IsoWorldInventoryObject") then
                        local item = worldObject:getItem()
                        if item ~= nil and item:getFullType() == fullType then
                            found[#found + 1] = {item = item, source = "floor"}
                        end
                    end
                end
            end
        end
    end

    return found
end

local function consumeParcel(entry)
    local item = entry and entry.item or nil
    local source = entry and entry.source or nil
    if item == nil or source == nil then
        return
    end

    if source == "floor" then
        local worldItem = item:getWorldItem()
        local square = worldItem and worldItem:getSquare() or nil
        if square ~= nil and worldItem ~= nil then
            square:transmitRemoveItemFromSquare(worldItem)
            square:removeWorldObject(worldItem)
            item:setWorldItem(nil)
        end
        return
    end

    source:Remove(item)
    sendRemoveItemFromContainer(source, item)
end

local function getAvailableParts(character, family)
    if family == nil then
        return nil
    end

    return {
        start = collectParcels(character, family.parts[Doors.GarageRole.START].itemType),
        middle = collectParcels(character, family.parts[Doors.GarageRole.MIDDLE].itemType),
        finish = collectParcels(character, family.parts[Doors.GarageRole.END_].itemType),
    }
end

local function getMaximumAvailableLength(parts)
    if parts == nil or #parts.start < 1 or #parts.finish < 1 then
        return nil
    end

    local maximum = 2 + #parts.middle
    local lmionMaximum = Doors.getGarageMaxLength()
    if lmionMaximum ~= nil then
        maximum = math.min(maximum, lmionMaximum)
    end

    return maximum
end

function GarageDoor.getMaximumAvailableLength(character, familyId)
    local family = familyId and GarageDoor.Families[familyId] or nil
    return getMaximumAvailableLength(getAvailableParts(character, family))
end

function GarageDoor.clampPlacementLength(character, familyId, requestedLength)
    local maximum = GarageDoor.getMaximumAvailableLength(character, familyId)
    if maximum == nil then
        return nil
    end

    local requested = tonumber(requestedLength) or maximum
    return math.max(2, math.min(requested, maximum))
end

--[[
Build one variable-width garage plan from a START anchor.

This plan is deliberately independent from IsoSpriteGrid. The synthetic L3 grid
still exists for vanilla Moveables pickup/discovery, but it is not a placement
geometry source anymore.
]]
function GarageDoor.buildPlacementPlan(character, familyId, length, facing, startSquare)
    local family = familyId and GarageDoor.Families[familyId] or nil
    if family == nil
        or startSquare == nil
        or (facing ~= "N" and facing ~= "W") then
        return nil
    end

    local parts = getAvailableParts(character, family)
    local maximum = getMaximumAvailableLength(parts)
    length = tonumber(length)
    if maximum == nil or length == nil or length < 2 or length > maximum then
        return nil
    end

    local plan = {
        length = length,
        familyId = familyId,
        facing = facing,
    }
    local middleIndex = 1

    for position = 1, length do
        local role
        local parcel

        if position == 1 then
            role = Doors.GarageRole.START
            parcel = parts.start[1]
        elseif position == length then
            role = Doors.GarageRole.END_
            parcel = parts.finish[1]
        else
            role = Doors.GarageRole.MIDDLE
            parcel = parts.middle[middleIndex]
            middleIndex = middleIndex + 1
        end

        local part = family.parts[role]
        local spriteName = part and part.faces and part.faces[facing] or nil
        if parcel == nil or spriteName == nil then
            return nil
        end

        local x = startSquare:getX() + (facing == "N" and position - 1 or 0)
        local y = startSquare:getY() - (facing == "W" and position - 1 or 0)
        local square = getCell():getGridSquare(x, y, startSquare:getZ())
        if square == nil then
            return nil
        end

        plan[position] = {
            item = parcel.item,
            source = parcel.source,
            square = square,
            spriteName = spriteName,
            role = role,
        }
    end

    return plan
end

local function getSingleSegmentMoveProps(entry)
    local moveProps = entry and ISMoveableSpriteProps.new(entry.spriteName) or nil
    if moveProps == nil or not moveProps.isMoveable then
        return nil
    end

    -- Garage sprites intentionally retain their synthetic L3 SpriteGrid for
    -- vanilla Pickup discovery. This dedicated placement path treats every
    -- planned physical member as a single object instead.
    moveProps.isMultiSprite = false
    return moveProps
end

function GarageDoor.validatePlacementPlan(character, plan)
    if character == nil or plan == nil or plan.length == nil then
        return false
    end

    for position = 1, plan.length do
        local entry = plan[position]
        local moveProps = getSingleSegmentMoveProps(entry)
        if moveProps == nil
            or entry.item == nil
            or entry.square == nil
            or not moveProps:canPlaceMoveableInternal(character, entry.square, entry.item) then
            return false
        end
    end

    return true
end

function GarageDoor.getPlacementMoveProps(familyId, facing)
    local family = familyId and GarageDoor.Families[familyId] or nil
    local startPart = family and family.parts[Doors.GarageRole.START] or nil
    local spriteName = startPart and startPart.faces and startPart.faces[facing] or nil
    if spriteName == nil then
        return nil
    end

    return getSingleSegmentMoveProps({spriteName = spriteName})
end

local function removePlacedObjects(objects)
    for i = #objects, 1, -1 do
        local object = objects[i]
        local square = object and object:getSquare() or nil
        if object ~= nil and square ~= nil then
            square:transmitRemoveItemFromSquare(object)
            square:RecalcAllWithNeighbours(true)
        end
    end
end

-- Placement is transactional from LMION's point of view: parcels are consumed
-- only after every physical member has been created. If an unexpected member
-- creation failure occurs after pre-validation, remove members created by this
-- attempt and leave all parcels untouched.
function GarageDoor.placePlacementPlan(character, plan)
    if not GarageDoor.validatePlacementPlan(character, plan) then
        return nil
    end

    local placed = {}

    for position = 1, plan.length do
        local entry = plan[position]
        local moveProps = getSingleSegmentMoveProps(entry)
        if moveProps == nil then
            removePlacedObjects(placed)
            return nil
        end

        local object = moveProps:placeMoveableInternal(entry.square, entry.item, entry.spriteName)
        if object == nil then
            removePlacedObjects(placed)
            LMION.error("Pickup", "garage failed placing position " .. tostring(position))
            return nil
        end

        placed[position] = object
    end

    for position = 1, plan.length do
        consumeParcel(plan[position])
    end

    return placed
end

return GarageDoor
