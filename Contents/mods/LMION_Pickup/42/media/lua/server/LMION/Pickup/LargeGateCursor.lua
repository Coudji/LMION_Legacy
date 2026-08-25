require "BuildingObjects/ISMoveableCursor"
require "LMION/Pickup/LargeGateMoveables"

local Pickup = LMION.Pickup

local function isLargeGateMoveProps(moveProps)
    return moveProps ~= nil
        and moveProps.lmionLargeGateLeaf ~= nil
        and moveProps.lmionLargeGatePart ~= nil
        and moveProps.lmionDoorFaces ~= nil
end

if Pickup._largeGateOriginalGetFaces == nil then
    Pickup._largeGateOriginalGetFaces = ISMoveableSpriteProps.getFaces
end

ISMoveableSpriteProps.getFaces = function(self)
    if isLargeGateMoveProps(self) then
        return {
            N = self.lmionDoorFaces.N,
            W = self.lmionDoorFaces.W,
        }
    end

    return Pickup._largeGateOriginalGetFaces(self)
end

if Pickup._largeGateOriginalHasFaces == nil then
    Pickup._largeGateOriginalHasFaces = ISMoveableSpriteProps.hasFaces
end

ISMoveableSpriteProps.hasFaces = function(self)
    if isLargeGateMoveProps(self) then
        return self.lmionDoorFaces.N ~= nil and self.lmionDoorFaces.W ~= nil
    end

    return Pickup._largeGateOriginalHasFaces(self)
end

if Pickup._largeGateOriginalGetIndexedFaces == nil then
    Pickup._largeGateOriginalGetIndexedFaces = ISMoveableSpriteProps.getIndexedFaces
end

ISMoveableSpriteProps.getIndexedFaces = function(self)
    if isLargeGateMoveProps(self) then
        local n = self.lmionDoorFaces.N
        local w = self.lmionDoorFaces.W
        return {n, w, n, w}
    end

    return Pickup._largeGateOriginalGetIndexedFaces(self)
end

if Pickup._largeGateOriginalGetFaceIndex == nil then
    Pickup._largeGateOriginalGetFaceIndex = ISMoveableSpriteProps.getFaceIndex
end

ISMoveableSpriteProps.getFaceIndex = function(self)
    if isLargeGateMoveProps(self) then
        if self.spriteName == self.lmionDoorFaces.N then
            return 1
        end
        if self.spriteName == self.lmionDoorFaces.W then
            return 2
        end
        return -1
    end

    return Pickup._largeGateOriginalGetFaceIndex(self)
end

local function renderLargeGateLeaf(self, x, y, z)
    if self == nil or ISMoveableCursor.mode[self.player] ~= "place" then
        return false
    end

    local moveProps = self.currentMoveProps
    if not isLargeGateMoveProps(moveProps) then
        return false
    end

    local leaf = Pickup.LargeGateLeafSpecs and Pickup.LargeGateLeafSpecs[moveProps.lmionLargeGateLeaf] or nil
    local facing = moveProps.lmionDoorFacing
    local partIndex = tonumber(moveProps.lmionLargeGatePart)
    if leaf == nil or facing == nil or partIndex == nil then
        return false
    end

    local dx = 0
    local dy = 0
    if facing == "N" then
        dx = 1
    elseif facing == "W" then
        dy = -1
    else
        return false
    end

    local anchorX = x
    local anchorY = y
    if partIndex == 2 then
        anchorX = anchorX - dx
        anchorY = anchorY - dy
    elseif partIndex ~= 1 then
        return false
    end

    local color = self.colorMod or ISMoveableSpriteProps.invalidColor or {r=1, g=0, b=0}
    local yOffset = (self.yOffset or 0) * Core.getTileScale()

    for index = 1, 2 do
        local spriteName = leaf.parts[index].faces[facing]
        local sprite = spriteName and getSprite(spriteName) or nil
        if sprite == nil then
            return false
        end

        local worldX = anchorX + ((index - 1) * dx)
        local worldY = anchorY + ((index - 1) * dy)
        local square = getCell():getGridSquare(worldX, worldY, z)
        if square ~= nil and square:getFloor() ~= nil and square:getFloor():getSprite() ~= nil then
            square:getFloor():getSprite():RenderGhostTileColor(
                worldX,
                worldY,
                z,
                0.75,
                1,
                0.75,
                0.25
            )
        end

        sprite:RenderGhostTileColor(
            worldX,
            worldY,
            z,
            0,
            yOffset,
            color.r,
            color.g,
            color.b,
            0.8
        )
    end

    return true
end

if Pickup._largeGateOriginalCursorRender == nil then
    Pickup._largeGateOriginalCursorRender = ISMoveableCursor.render
end

ISMoveableCursor.render = function(self, x, y, z, square)
    if renderLargeGateLeaf(self, x, y, z) then
        return
    end

    return Pickup._largeGateOriginalCursorRender(self, x, y, z, square)
end

return Pickup
