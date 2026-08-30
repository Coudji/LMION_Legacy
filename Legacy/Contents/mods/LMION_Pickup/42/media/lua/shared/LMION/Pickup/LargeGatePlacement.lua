require "Moveables/ISMoveableSpriteProps"
require "LMION/Pickup/LargeGateMoveables"
require "LMION/Pickup/LargeGateOpenState"

local Pickup = LMION.Pickup
local Doors = LMION.Doors
local LargeGate = Pickup.LargeGate
local leafSpecs = Pickup.LargeGateLeafSpecs or {}
local layouts = LargeGate.OpenStateLayout or {}
local openSegmentsBySprite = LargeGate.OpenSegmentsBySprite or {}

local openSpriteByClosedSprite = {}
for openSpriteName, segment in pairs(openSegmentsBySprite) do
    if segment ~= nil and segment.closedSpriteName ~= nil then
        openSpriteByClosedSprite[segment.closedSpriteName] = openSpriteName
    end
end

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

local function getPartnerLeaf(leaf)
    if leaf == nil then
        return nil, nil
    end

    local wantedLeaf = leaf.leaf == "A" and "B" or "A"
    for leafId, candidate in pairs(leafSpecs) do
        if candidate.familyId == leaf.familyId and candidate.leaf == wantedLeaf then
            return leafId, candidate
        end
    end

    return nil, nil
end

local function findDoorWithSprite(square, spriteName, shouldBeOpen)
    if square == nil or spriteName == nil then
        return nil
    end

    local objects = square:getSpecialObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        local sprite = object and object:getSprite() or nil
        if Doors.isDoorObject(object)
            and sprite ~= nil
            and sprite:getName() == spriteName
            and object:IsOpen() == shouldBeOpen then
            return object
        end
    end

    return nil
end

local function hasRecognizedPartnerObject(square, partnerLeaf, facing)
    if square == nil or partnerLeaf == nil then
        return false
    end

    local objects = square:getSpecialObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        local sprite = object and object:getSprite() or nil
        local spriteName = sprite and sprite:getName() or nil
        if Doors.isDoorObject(object) and spriteName ~= nil then
            for partIndex = 1, 2 do
                local closedSpriteName = partnerLeaf.parts[partIndex].faces[facing]
                local openSpriteName = openSpriteByClosedSprite[closedSpriteName]
                if spriteName == closedSpriteName or spriteName == openSpriteName then
                    return true
                end
            end
        end
    end

    return false
end

local function getGateAnchor(leaf, facing, closedSquares)
    local layout = layouts[facing] and layouts[facing].closed or nil
    local logicalIndex = leaf and leaf.indices[facing] and leaf.indices[facing][1] or nil
    local part1Square = closedSquares and closedSquares[1] or nil
    local offset = layout and logicalIndex and layout[logicalIndex] or nil
    if part1Square == nil or offset == nil then
        return nil
    end

    return {
        x = part1Square:getX() - offset[1],
        y = part1Square:getY() - offset[2],
        z = part1Square:getZ(),
    }
end

local function getStateSquaresForLeaf(leaf, facing, anchor, state)
    local layout = layouts[facing] and layouts[facing][state] or nil
    local indices = leaf and leaf.indices[facing] or nil
    if layout == nil or indices == nil or anchor == nil then
        return nil
    end

    local squares = {}
    for partIndex, logicalIndex in ipairs(indices) do
        local offset = layout[logicalIndex]
        if offset == nil then
            return nil
        end

        local square = getCell():getGridSquare(anchor.x + offset[1], anchor.y + offset[2], anchor.z)
        if square == nil then
            return nil
        end
        squares[partIndex] = square
    end

    return squares
end

local function matchesPartnerState(partnerLeaf, facing, anchor, state)
    local squares = getStateSquaresForLeaf(partnerLeaf, facing, anchor, state)
    if squares == nil then
        return false
    end

    local shouldBeOpen = state == "open"
    for partIndex = 1, 2 do
        local closedSpriteName = partnerLeaf.parts[partIndex].faces[facing]
        local spriteName = shouldBeOpen and openSpriteByClosedSprite[closedSpriteName] or closedSpriteName
        if spriteName == nil or findDoorWithSprite(squares[partIndex], spriteName, shouldBeOpen) == nil then
            return false
        end
    end

    return true
end

local function detectPartnerState(leaf, facing, anchor)
    local _, partnerLeaf = getPartnerLeaf(leaf)
    if partnerLeaf == nil then
        return "none", nil
    end

    if matchesPartnerState(partnerLeaf, facing, anchor, "closed") then
        return "closed", partnerLeaf
    end
    if matchesPartnerState(partnerLeaf, facing, anchor, "open") then
        return "open", partnerLeaf
    end

    local closedSquares = getStateSquaresForLeaf(partnerLeaf, facing, anchor, "closed") or {}
    local openSquares = getStateSquaresForLeaf(partnerLeaf, facing, anchor, "open") or {}
    for partIndex = 1, 2 do
        if hasRecognizedPartnerObject(closedSquares[partIndex], partnerLeaf, facing)
            or hasRecognizedPartnerObject(openSquares[partIndex], partnerLeaf, facing) then
            return "incoherent", partnerLeaf
        end
    end

    return "none", partnerLeaf
end

local function buildPlacementPlan(moveProps, character, square)
    local leaf = moveProps and leafSpecs[moveProps.lmionLargeGateLeaf] or nil
    local closedSquares = getPlacementSquares(moveProps, square)
    if leaf == nil or closedSquares == nil then
        return nil
    end

    local facing = moveProps.lmionDoorFacing
    local anchor = getGateAnchor(leaf, facing, closedSquares)
    if anchor == nil then
        return nil
    end

    local partnerState = detectPartnerState(leaf, facing, anchor)
    if partnerState == "incoherent" then
        return nil
    end

    local targetState = partnerState == "open" and "open" or "closed"
    local targetSquares = targetState == "open"
        and getStateSquaresForLeaf(leaf, facing, anchor, "open")
        or closedSquares
    if targetSquares == nil then
        return nil
    end

    local plan = {
        targetState = targetState,
        partnerState = partnerState,
        anchor = anchor,
    }

    for partIndex = 1, 2 do
        local part = leaf.parts[partIndex]
        local item, source = findParcel(character, part.itemType)
        local closedSpriteName = part.faces[facing]
        local openSpriteName = openSpriteByClosedSprite[closedSpriteName]
        if item == nil or source == nil or closedSpriteName == nil then
            return nil
        end
        if targetState == "open" and openSpriteName == nil then
            return nil
        end

        plan[partIndex] = {
            item = item,
            source = source,
            square = targetSquares[partIndex],
            spriteName = closedSpriteName,
            closedSpriteName = closedSpriteName,
            openSpriteName = openSpriteName,
            isOpen = targetState == "open",
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
        local moveProps = ISMoveableSpriteProps.new(entry.closedSpriteName)
        if moveProps == nil or not moveProps.isMoveable then
            return false
        end

        moveProps.lmionPlacementSpriteName = entry.closedSpriteName
        moveProps.lmionPlacementClosedSpriteName = entry.closedSpriteName
        moveProps.lmionPlacementOpenSpriteName = entry.openSpriteName
        moveProps.lmionPlacementIsOpen = entry.isOpen

        if not moveProps:canPlaceMoveableInternal(character, entry.square, entry.item) then
            return false
        end

        -- Open placement uses target squares outside the normal closed two-tile
        -- sprite grid. Respect ordinary Moveables occupancy rules there as well.
        if entry.isOpen and not moveProps:isFreeTile(entry.square) then
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
        LMION.error("Pickup", "large gate placement plan is unavailable or partner topology is incoherent")
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
        local moveProps = ISMoveableSpriteProps.new(entry.closedSpriteName)
        if moveProps == nil or not moveProps.isMoveable then
            LMION.error("Pickup", "large gate target move props missing for " .. tostring(entry.closedSpriteName))
            return false
        end

        moveProps.lmionPlacementSpriteName = entry.closedSpriteName
        moveProps.lmionPlacementClosedSpriteName = entry.closedSpriteName
        moveProps.lmionPlacementOpenSpriteName = entry.openSpriteName
        moveProps.lmionPlacementIsOpen = entry.isOpen

        local wasMultiSprite = moveProps.isMultiSprite
        moveProps.isMultiSprite = false
        local object = moveProps:placeMoveableInternal(entry.square, entry.item, entry.closedSpriteName)
        moveProps.isMultiSprite = wasMultiSprite

        if object == nil then
            LMION.error("Pickup", "large gate failed placing part " .. tostring(partIndex))
            return false
        end

        placed[partIndex] = object
    end

    for partIndex = 1, 2 do
        local entry = plan[partIndex]
        consumeParcel(entry.item, entry.source)
    end

    if ISMoveableCursor ~= nil and ISMoveableCursor.clearCacheForAllPlayers ~= nil then
        ISMoveableCursor.clearCacheForAllPlayers()
    end

    return placed
end

return Pickup
