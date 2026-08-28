require "Moveables/ISMoveableSpriteProps"
require "LMION/Pickup/GarageDoorPickup"

local Pickup = LMION.Pickup
local Doors = LMION.Doors
local GarageDoor = Pickup.GarageDoor

GarageDoor.PlacementSelection = GarageDoor.PlacementSelection or {}

local function isGarageMoveProps(moveProps)
    return moveProps ~= nil
        and moveProps.lmionGarageFamily ~= nil
        and moveProps.lmionGaragePart ~= nil
end

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

local function getCurrentFacing(moveProps)
    if moveProps == nil then
        return nil
    end

    if moveProps.facing == "N" or moveProps.facing == "W" then
        return moveProps.facing
    end

    if moveProps.lmionGarageFacing == "N" or moveProps.lmionGarageFacing == "W" then
        return moveProps.lmionGarageFacing
    end

    return nil
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

local function getPlayerNumber(character)
    if character ~= nil and character.getPlayerNum ~= nil then
        return character:getPlayerNum()
    end
    return 0
end

local function getSelectedLength(character, familyId, maximum)
    if maximum == nil or maximum < 2 then
        return nil
    end

    local playerNum = getPlayerNumber(character)
    local selection = GarageDoor.PlacementSelection[playerNum]

    if selection == nil or selection.familyId ~= familyId then
        selection = {
            familyId = familyId,
            length = maximum,
        }
        GarageDoor.PlacementSelection[playerNum] = selection
    end

    selection.length = math.max(2, math.min(selection.length or maximum, maximum))
    return selection.length
end

function GarageDoor.adjustPlacementLength(character, familyId, delta)
    local family = familyId and GarageDoor.Families[familyId] or nil
    local parts = getAvailableParts(character, family)
    local maximum = getMaximumAvailableLength(parts)
    if family == nil or maximum == nil then
        return nil
    end

    local playerNum = getPlayerNumber(character)
    local current = getSelectedLength(character, familyId, maximum)
    local nextLength = math.max(2, math.min(maximum, current + delta))

    GarageDoor.PlacementSelection[playerNum] = {
        familyId = familyId,
        length = nextLength,
    }

    if ISMoveableCursor ~= nil and ISMoveableCursor.clearCacheForAllPlayers ~= nil then
        ISMoveableCursor.clearCacheForAllPlayers()
    end

    return nextLength
end

function GarageDoor.clearPlacementLength(character)
    GarageDoor.PlacementSelection[getPlayerNumber(character)] = nil
end

local function getAnchorPosition(role, length)
    if role == Doors.GarageRole.START then
        return 1
    elseif role == Doors.GarageRole.END_ then
        return length
    elseif role == Doors.GarageRole.MIDDLE then
        -- Repeated middle parcels have no unique bundle position. Treat a selected
        -- Middle parcel as the first interior position; the whole assembly remains
        -- freely placeable/rotatable from there.
        return 2
    end

    return nil
end

local function buildPlacementPlan(moveProps, character, square)
    local familyId = moveProps and moveProps.lmionGarageFamily or nil
    local family = familyId and GarageDoor.Families[familyId] or nil
    local facing = getCurrentFacing(moveProps)
    local selectedRole = tonumber(moveProps and moveProps.lmionGaragePart)
    if family == nil or facing == nil or selectedRole == nil or square == nil then
        return nil
    end

    local parts = getAvailableParts(character, family)
    local maximum = getMaximumAvailableLength(parts)
    local length = getSelectedLength(character, familyId, maximum)
    if length == nil then
        return nil
    end

    local anchorPosition = getAnchorPosition(selectedRole, length)
    if anchorPosition == nil then
        return nil
    end

    local startX = square:getX()
    local startY = square:getY()
    local z = square:getZ()

    if facing == "N" then
        startX = startX - (anchorPosition - 1)
    else
        startY = startY + (anchorPosition - 1)
    end

    local plan = {}
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

        local x = startX + (facing == "N" and position - 1 or 0)
        local y = startY - (facing == "W" and position - 1 or 0)
        local targetSquare = getCell():getGridSquare(x, y, z)
        if targetSquare == nil then
            return nil
        end

        plan[position] = {
            item = parcel.item,
            source = parcel.source,
            square = targetSquare,
            spriteName = spriteName,
            role = role,
        }
    end

    plan.length = length
    plan.familyId = familyId
    plan.facing = facing
    return plan
end

GarageDoor.buildPlacementPlan = buildPlacementPlan
GarageDoor.getMaximumAvailableLength = function(character, familyId)
    return getMaximumAvailableLength(getAvailableParts(character, GarageDoor.Families[familyId]))
end

if Pickup._garageDoorPlacementPreviousCanPlaceMoveable == nil then
    Pickup._garageDoorPlacementPreviousCanPlaceMoveable = ISMoveableSpriteProps.canPlaceMoveable
end

ISMoveableSpriteProps.canPlaceMoveable = function(self, character, square, item)
    if not isGarageMoveProps(self) or not self.isMultiSprite then
        return Pickup._garageDoorPlacementPreviousCanPlaceMoveable(self, character, square, item)
    end

    local plan = buildPlacementPlan(self, character, square)
    if plan == nil then
        return false
    end

    for position = 1, plan.length do
        local entry = plan[position]
        local moveProps = ISMoveableSpriteProps.new(entry.spriteName)
        if moveProps == nil or not moveProps.isMoveable then
            return false
        end

        local wasMultiSprite = moveProps.isMultiSprite
        moveProps.isMultiSprite = false
        local canPlace = moveProps:canPlaceMoveableInternal(character, entry.square, entry.item)
        moveProps.isMultiSprite = wasMultiSprite

        if not canPlace then
            return false
        end
    end

    return true
end

if Pickup._garageDoorPlacementPreviousPlaceMoveable == nil then
    Pickup._garageDoorPlacementPreviousPlaceMoveable = ISMoveableSpriteProps.placeMoveable
end

ISMoveableSpriteProps.placeMoveable = function(self, character, square, origSpriteName, forceAllow)
    if not isGarageMoveProps(self) or not self.isMultiSprite then
        return Pickup._garageDoorPlacementPreviousPlaceMoveable(self, character, square, origSpriteName, forceAllow)
    end

    local plan = buildPlacementPlan(self, character, square)
    if plan == nil then
        LMION.error("Pickup", "garage door placement plan is unavailable")
        return false
    end

    if not forceAllow
        and not character:isMovablesCheat()
        and not ISMoveableDefinitions.cheat
        and not self:canPlaceMoveable(character, square, plan[1].item) then
        return false
    end

    local placed = {}
    for position = 1, plan.length do
        local entry = plan[position]
        local moveProps = ISMoveableSpriteProps.new(entry.spriteName)
        if moveProps == nil or not moveProps.isMoveable then
            LMION.error("Pickup", "garage target move props missing for " .. tostring(entry.spriteName))
            return false
        end

        local wasMultiSprite = moveProps.isMultiSprite
        moveProps.isMultiSprite = false
        local object = moveProps:placeMoveableInternal(entry.square, entry.item, entry.spriteName)
        moveProps.isMultiSprite = wasMultiSprite

        if object == nil then
            LMION.error("Pickup", "garage failed placing position " .. tostring(position))
            return false
        end

        placed[position] = object
    end

    for position = 1, plan.length do
        consumeParcel(plan[position])
    end

    GarageDoor.clearPlacementLength(character)

    if ISMoveableCursor ~= nil and ISMoveableCursor.clearCacheForAllPlayers ~= nil then
        ISMoveableCursor.clearCacheForAllPlayers()
    end

    return placed
end

-- Vanilla's runtime garage SpriteGrid stays useful for inventory/facing discovery,
-- but it is permanently L3. Override only its cursor rendering for LMION garages so
-- the ghost reflects the actual selected variable-length placement plan.
if ISMoveableCursor ~= nil and Pickup._garageDoorPreviousRenderSpriteGrid == nil then
    Pickup._garageDoorPreviousRenderSpriteGrid = ISMoveableCursor.renderSpriteGrid

    ISMoveableCursor.renderSpriteGrid = function(self, x, y, z, color)
        local moveProps = self and self.currentMoveProps or nil
        if not isGarageMoveProps(moveProps)
            or ISMoveableCursor.mode[self.player] ~= "place" then
            return Pickup._garageDoorPreviousRenderSpriteGrid(self, x, y, z, color)
        end

        local square = getCell():getGridSquare(x, y, z)
        local plan = buildPlacementPlan(moveProps, self.character, square)
        if plan == nil then
            return Pickup._garageDoorPreviousRenderSpriteGrid(self, x, y, z, color)
        end

        for position = 1, plan.length do
            local entry = plan[position]
            local targetSquare = entry.square
            local tx = targetSquare:getX()
            local ty = targetSquare:getY()
            local tz = targetSquare:getZ()

            if targetSquare:getFloor() and targetSquare:getFloor():getSprite() then
                targetSquare:getFloor():getSprite():RenderGhostTileColor(tx, ty, tz, 0.75, 1, 0.75, 0.25)
            end

            local sprite = getSprite(entry.spriteName)
            if sprite ~= nil then
                sprite:RenderGhostTileColor(
                    tx,
                    ty,
                    tz,
                    0,
                    (self.yOffset or 0) * Core.getTileScale(),
                    color.r,
                    color.g,
                    color.b,
                    0.8
                )
            end
        end
    end
end

return GarageDoor
