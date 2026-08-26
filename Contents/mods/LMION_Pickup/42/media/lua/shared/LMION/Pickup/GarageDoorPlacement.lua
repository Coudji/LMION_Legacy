require "Moveables/ISMoveableSpriteProps"
require "LMION/Pickup/GarageDoorPickup"

local Pickup = LMION.Pickup
local GarageDoor = Pickup.GarageDoor

local function isGarageMoveProps(moveProps)
    return moveProps ~= nil
        and moveProps.lmionGarageFamily ~= nil
        and moveProps.lmionGaragePart ~= nil
end

local function findInventoryItem(character, fullType)
    if character == nil or fullType == nil then
        return nil, nil
    end

    local inventory = character:getInventory()
    if inventory == nil then
        return nil, nil
    end

    local items = inventory:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item ~= nil and item:getFullType() == fullType then
            return item, inventory
        end
    end

    return nil, nil
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

--[[
The cursor square belongs to the current Moveables grid member, not necessarily
GarageDoor member 1. Convert that selected member back to the engine anchor.

B42.20.3 garage topology:
N: member 1 -> 2 -> 3 advances along +X.
W: member 1 -> 2 -> 3 advances along -Y.

The Industrial W artwork is therefore laid out in world +Y order as sprites
32, 33, 34 while their engine identities are members 3, 2, 1 respectively.
]]
local function getPlacementSquares(moveProps, square)
    if not isGarageMoveProps(moveProps) or square == nil then
        return nil
    end

    local facing = getCurrentFacing(moveProps)
    local partIndex = tonumber(moveProps.lmionGaragePart)
    if facing == nil or partIndex == nil or partIndex < 1 or partIndex > 3 then
        return nil
    end

    local firstX = square:getX()
    local firstY = square:getY()
    local z = square:getZ()

    if facing == "N" then
        firstX = firstX - (partIndex - 1)
    elseif facing == "W" then
        firstY = firstY + (partIndex - 1)
    else
        return nil
    end

    local squares = {}
    for expectedIndex = 1, 3 do
        local x = firstX
        local y = firstY

        if facing == "N" then
            x = x + (expectedIndex - 1)
        else
            y = y - (expectedIndex - 1)
        end

        local targetSquare = getCell():getGridSquare(x, y, z)
        if targetSquare == nil then
            return nil
        end

        squares[expectedIndex] = targetSquare
    end

    return squares
end

local function buildPlacementPlan(moveProps, character, square)
    local family = moveProps and GarageDoor.Families[moveProps.lmionGarageFamily] or nil
    local facing = getCurrentFacing(moveProps)
    local squares = getPlacementSquares(moveProps, square)
    if family == nil or facing == nil or squares == nil then
        return nil
    end

    local plan = {}
    for partIndex = 1, 3 do
        local part = family.parts[partIndex]
        local item, inventory = findInventoryItem(character, part and part.itemType)
        local spriteName = part and part.faces and part.faces[facing] or nil
        if item == nil or inventory == nil or spriteName == nil then
            return nil
        end

        plan[partIndex] = {
            item = item,
            inventory = inventory,
            square = squares[partIndex],
            spriteName = spriteName,
        }
    end

    return plan
end

GarageDoor.getPlacementSquares = getPlacementSquares
GarageDoor.buildPlacementPlan = buildPlacementPlan

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

    for partIndex = 1, 3 do
        local entry = plan[partIndex]
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

    local selectedPart = tonumber(self.lmionGaragePart) or 1
    if not forceAllow
        and not character:isMovablesCheat()
        and not ISMoveableDefinitions.cheat
        and not self:canPlaceMoveable(character, square, plan[selectedPart].item) then
        return false
    end

    local placed = {}
    for partIndex = 1, 3 do
        local entry = plan[partIndex]
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
            LMION.error("Pickup", "garage failed placing part " .. tostring(partIndex))
            return false
        end

        placed[partIndex] = object
    end

    for partIndex = 1, 3 do
        local entry = plan[partIndex]
        entry.inventory:Remove(entry.item)
        sendRemoveItemFromContainer(entry.inventory, entry.item)
    end

    if ISMoveableCursor ~= nil and ISMoveableCursor.clearCacheForAllPlayers ~= nil then
        ISMoveableCursor.clearCacheForAllPlayers()
    end

    return placed
end

return GarageDoor
