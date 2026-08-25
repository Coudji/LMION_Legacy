require "Moveables/ISMoveableSpriteProps"
require "LMION/Pickup/LargeGateMoveables"

local Pickup = LMION.Pickup
local leafSpecs = Pickup.LargeGateLeafSpecs or {}

local function isLargeGateMoveProps(moveProps)
    return moveProps ~= nil
        and moveProps.lmionLargeGateLeaf ~= nil
        and moveProps.lmionLargeGatePart ~= nil
        and moveProps.lmionDoorFaces ~= nil
end

local function getLeafAnchorFaces(moveProps)
    local leaf = moveProps and leafSpecs[moveProps.lmionLargeGateLeaf] or nil
    if leaf == nil then
        return nil
    end

    return {
        N = leaf.parts[1].faces.N,
        W = leaf.parts[1].faces.W,
    }
end

local function isGridAnchor(moveProps)
    if not isLargeGateMoveProps(moveProps) or not moveProps.isMultiSprite then
        return false
    end

    local sprite = moveProps.sprite
    local grid = sprite and sprite:getSpriteGrid() or nil
    return grid ~= nil and grid:getAnchorSprite() == sprite
end

if Pickup._largeGatePlacementPreviousGetFaces == nil then
    Pickup._largeGatePlacementPreviousGetFaces = ISMoveableSpriteProps.getFaces
end

ISMoveableSpriteProps.getFaces = function(self)
    if isGridAnchor(self) then
        return getLeafAnchorFaces(self) or {}
    end

    return Pickup._largeGatePlacementPreviousGetFaces(self)
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

local function getPlacementSquares(moveProps, square)
    if not isLargeGateMoveProps(moveProps) or square == nil then
        return nil
    end

    local facing = moveProps.lmionDoorFacing
    local partIndex = tonumber(moveProps.lmionLargeGatePart)
    if facing == nil or partIndex == nil then
        return nil
    end

    local dx = 0
    local dy = 0
    if facing == "N" then
        dx = 1
    elseif facing == "W" then
        dy = 1
    else
        return nil
    end

    local part1X = square:getX()
    local part1Y = square:getY()

    if partIndex == 2 then
        part1X = part1X - dx
        part1Y = part1Y - dy
    elseif partIndex ~= 1 then
        return nil
    end

    local z = square:getZ()
    local part1Square = getCell():getGridSquare(part1X, part1Y, z)
    local part2Square = getCell():getGridSquare(part1X + dx, part1Y + dy, z)
    if part1Square == nil or part2Square == nil then
        return nil
    end

    return {
        [1] = part1Square,
        [2] = part2Square,
    }
end

local function buildPlacementPlan(moveProps, character, square)
    local leaf = moveProps and leafSpecs[moveProps.lmionLargeGateLeaf] or nil
    local squares = getPlacementSquares(moveProps, square)
    if leaf == nil or squares == nil then
        return nil
    end

    local facing = moveProps.lmionDoorFacing
    local plan = {}
    for partIndex = 1, 2 do
        local part = leaf.parts[partIndex]
        local item, inventory = findInventoryItem(character, part.itemType)
        local spriteName = part.faces[facing]
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

Pickup.getLargeGatePlacementSquares = getPlacementSquares
Pickup.buildLargeGatePlacementPlan = buildPlacementPlan

if Pickup._largeGatePlacementPreviousCanPlaceMoveable == nil then
    Pickup._largeGatePlacementPreviousCanPlaceMoveable = ISMoveableSpriteProps.canPlaceMoveable
end

ISMoveableSpriteProps.canPlaceMoveable = function(self, character, square, item)
    if not isLargeGateMoveProps(self) or not self.isMultiSprite then
        return Pickup._largeGatePlacementPreviousCanPlaceMoveable(self, character, square, item)
    end

    local plan = buildPlacementPlan(self, character, square)
    if plan == nil then
        return false
    end

    for partIndex = 1, 2 do
        local entry = plan[partIndex]
        local moveProps = ISMoveableSpriteProps.new(entry.spriteName)
        if moveProps == nil
            or not moveProps.isMoveable
            or not moveProps:canPlaceMoveableInternal(character, entry.square, entry.item) then
            return false
        end
    end

    return true
end

if Pickup._largeGatePlacementPreviousPlaceMoveable == nil then
    Pickup._largeGatePlacementPreviousPlaceMoveable = ISMoveableSpriteProps.placeMoveable
end

ISMoveableSpriteProps.placeMoveable = function(self, character, square, origSpriteName, forceAllow)
    if not isLargeGateMoveProps(self) or not self.isMultiSprite then
        return Pickup._largeGatePlacementPreviousPlaceMoveable(self, character, square, origSpriteName, forceAllow)
    end

    local plan = buildPlacementPlan(self, character, square)
    if plan == nil then
        LMION.error("Pickup", "large gate placement plan is unavailable")
        return false
    end

    if not forceAllow
        and not character:isMovablesCheat()
        and not ISMoveableDefinitions.cheat
        and not self:canPlaceMoveable(character, square, plan[tonumber(self.lmionLargeGatePart) or 1].item) then
        return false
    end

    local placed = {}
    for partIndex = 1, 2 do
        local entry = plan[partIndex]
        local moveProps = ISMoveableSpriteProps.new(entry.spriteName)
        if moveProps == nil or not moveProps.isMoveable then
            LMION.error("Pickup", "large gate target move props missing for " .. tostring(entry.spriteName))
            return false
        end

        local wasMultiSprite = moveProps.isMultiSprite
        moveProps.isMultiSprite = false
        local object = moveProps:placeMoveableInternal(entry.square, entry.item, entry.spriteName)
        moveProps.isMultiSprite = wasMultiSprite

        if object == nil then
            LMION.error("Pickup", "large gate failed placing part " .. tostring(partIndex))
            return false
        end

        placed[partIndex] = object
    end

    for partIndex = 1, 2 do
        local entry = plan[partIndex]
        entry.inventory:Remove(entry.item)
        sendRemoveItemFromContainer(entry.inventory, entry.item)
    end

    if ISMoveableCursor ~= nil and ISMoveableCursor.clearCacheForAllPlayers ~= nil then
        ISMoveableCursor.clearCacheForAllPlayers()
    end

    return placed
end

return Pickup
