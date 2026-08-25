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

if Pickup._largeGateOriginalCursorRender == nil then
    Pickup._largeGateOriginalCursorRender = ISMoveableCursor.render
end

ISMoveableCursor.render = function(self, x, y, z, square)
    local moveProps = self and self.currentMoveProps or nil
    if ISMoveableCursor.mode[self.player] == "place"
        and isLargeGateMoveProps(moveProps)
        and self.origMoveProps ~= nil
        and self.origMoveProps.sprite ~= nil
        and self.origMoveProps.sprite:getSpriteGrid() ~= nil
        and moveProps.sprite ~= nil
        and moveProps.sprite:getSpriteGrid() ~= nil then
        local color = ISMoveableCursor.invalidColor
        if self.canCreate then
            color = ISMoveableCursor.validColor
        end
        self:renderSpriteGrid(x, y, z, color)
        return
    end

    return Pickup._largeGateOriginalCursorRender(self, x, y, z, square)
end

return Pickup
