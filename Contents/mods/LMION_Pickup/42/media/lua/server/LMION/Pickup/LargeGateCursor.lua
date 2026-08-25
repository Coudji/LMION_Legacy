require "BuildingObjects/ISMoveableCursor"
require "LMION/Pickup/LargeGateMoveables"

local Pickup = LMION.Pickup
local leafSpecs = Pickup.LargeGateLeafSpecs or {}

local function isLargeGateMoveProps(moveProps)
    return moveProps ~= nil
        and moveProps.lmionLargeGateLeaf ~= nil
        and moveProps.lmionLargeGatePart ~= nil
        and moveProps.lmionDoorFaces ~= nil
end

if Pickup._largeGateOriginalRenderSpriteGrid == nil then
    Pickup._largeGateOriginalRenderSpriteGrid = ISMoveableCursor.renderSpriteGrid
end

ISMoveableCursor.renderSpriteGrid = function(self, x, y, z, color)
    if not isLargeGateMoveProps(self.origMoveProps)
        or not isLargeGateMoveProps(self.currentMoveProps) then
        return Pickup._largeGateOriginalRenderSpriteGrid(self, x, y, z, color)
    end

    local origGrid = self.origMoveProps.sprite and self.origMoveProps.sprite:getSpriteGrid() or nil
    local spriteGrid = self.currentMoveProps.sprite and self.currentMoveProps.sprite:getSpriteGrid() or nil
    if origGrid == nil or spriteGrid == nil then
        return Pickup._largeGateOriginalRenderSpriteGrid(self, x, y, z, color)
    end

    local xo = origGrid:getSpriteGridPosX(self.origMoveProps.sprite)
    local yo = origGrid:getSpriteGridPosY(self.origMoveProps.sprite)
    local wx = x - xo
    local wy = y - yo

    -- Keep vanilla's multisprite footprint rendering for both logical squares.
    for gridX = 0, spriteGrid:getWidth() - 1 do
        for gridY = 0, spriteGrid:getHeight() - 1 do
            local worldX = wx + gridX
            local worldY = wy + gridY
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
        end
    end

    -- The two gate leaves are authored asymmetrically. On the right leaf Part2
    -- already contains the complete visual leaf; on the left leaf the complete
    -- visual member is Part1. Keep both members in the SpriteGrid for Moveables
    -- logic, but render only the complete visual member in the ghost preview.
    local leafId = self.currentMoveProps.lmionLargeGateLeaf
    local leaf = leafSpecs[leafId]
    local facing = self.currentMoveProps.lmionDoorFacing
    local visualPartIndex = leafId == "left" and 1 or 2
    local fullSpriteName = leaf
        and leaf.parts
        and leaf.parts[visualPartIndex]
        and leaf.parts[visualPartIndex].faces
        and leaf.parts[visualPartIndex].faces[facing]
        or nil

    if fullSpriteName == nil then
        return
    end

    for gridX = 0, spriteGrid:getWidth() - 1 do
        for gridY = 0, spriteGrid:getHeight() - 1 do
            local objectSprite = spriteGrid:getSprite(gridX, gridY)
            if objectSprite ~= nil and objectSprite:getName() == fullSpriteName then
                objectSprite:RenderGhostTileColor(
                    wx + gridX,
                    wy + gridY,
                    z,
                    0,
                    self.yOffset * Core.getTileScale(),
                    color.r,
                    color.g,
                    color.b,
                    0.8
                )
                return
            end
        end
    end
end

return Pickup
