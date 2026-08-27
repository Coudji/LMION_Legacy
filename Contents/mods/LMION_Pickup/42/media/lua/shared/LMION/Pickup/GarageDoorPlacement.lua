require "Moveables/ISMoveableSpriteProps"
require "LMION/Pickup/GarageDoorPickup"

local Pickup = LMION.Pickup
local GarageDoor = Pickup.GarageDoor

local function isGarageMoveProps(moveProps)
    return moveProps ~= nil
        and moveProps.lmionGarageFamily ~= nil
        and moveProps.lmionGaragePart ~= nil
end

local function findParcel(character, fullType)
    if character == nil or fullType == nil then
        return nil, nil
    end

    local inventory = character:getInventory()
    local items = inventory and inventory:getItems() or nil
    if items ~= nil then
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item ~= nil and item:getFullType() == fullType then
                return item, inventory
            end
        end
    end

    local square = character:getSquare()
    if square == nil then
        return nil, nil
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
                            return item, "floor"
                        end
                    end
                end
            end
        end
    end

    return nil, nil
end

local function consumeParcel(item, source)
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

local function getPlacementSquares(moveProps, square)
    if not isGarageMoveProps(moveProps) or square == nil then
        return nil
    end

    local family = GarageDoor.Families[moveProps.lmionGarageFamily]
    local facing = getCurrentFacing(moveProps)
    local sprite = moveProps.sprite
    local grid = sprite and sprite:getSpriteGrid() or nil
    local order = family and family.gridPartOrder and family.gridPartOrder[facing] or nil

    if family == nil or facing == nil or grid == nil or order == nil then
        return nil
    end

    local gridX = grid:getSpriteGridPosX(sprite)
    local gridY = grid:getSpriteGridPosY(sprite)
    if gridX == nil or gridY == nil or gridX < 0 or gridY < 0 then
        return nil
    end

    local originX = square:getX() - gridX
    local originY = square:getY() - gridY
    local z = square:getZ()
    local squares = {}

    for slot, partIndex in ipairs(order) do
        local x = originX + (facing == "N" and slot - 1 or 0)
        local y = originY + (facing == "W" and slot - 1 or 0)
        local targetSquare = getCell():getGridSquare(x, y, z)
        if targetSquare == nil then
            return nil
        end

        squares[partIndex] = targetSquare
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
        local item, source = findParcel(character, part and part.itemType)
        local spriteName = part and part.faces and part.faces[facing] or nil
        if item == nil or source == nil or spriteName == nil then
            return nil
        end

        plan[partIndex] = {
            item = item,
            source = source,
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
        consumeParcel(entry.item, entry.source)
    end

    if ISMoveableCursor ~= nil and ISMoveableCursor.clearCacheForAllPlayers ~= nil then
        ISMoveableCursor.clearCacheForAllPlayers()
    end

    return placed
end

return GarageDoor
