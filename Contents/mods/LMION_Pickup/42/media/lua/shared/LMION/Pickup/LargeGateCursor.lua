require "BuildingObjects/ISMoveableCursor"
require "LMION/Pickup/LargeGateMoveables"

local Pickup = LMION.Pickup

local function renderLargeGateGrid(self, x, y, z, color)
    local moveProps = self and self.currentMoveProps or nil
    if moveProps == nil or moveProps.lmionLargeGateLeaf == nil then
        return false
    end

    local sprite = moveProps.sprite
    local grid = sprite and sprite:getSpriteGrid() or nil
    if grid == nil then
        return false
    end

    local offsetX = grid:getSpriteGridPosX(sprite)
    local offsetY = grid:getSpriteGridPosY(sprite)
    local baseX = x - offsetX
    local baseY = y - offsetY
    local yOffset = (self.yOffset or 0) * Core.getTileScale()

    for gridX = 0, grid:getWidth() - 1 do
        for gridY = 0, grid:getHeight() - 1 do
            local worldX = baseX + gridX
            local worldY = baseY + gridY
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

            local ghostSprite = grid:getSprite(gridX, gridY)
            if ghostSprite ~= nil then
                ghostSprite:RenderGhostTileColor(
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
        end
    end

    return true
end

if Pickup._largeGateOriginalRenderSpriteGrid == nil then
    Pickup._largeGateOriginalRenderSpriteGrid = ISMoveableCursor.renderSpriteGrid
end

ISMoveableCursor.renderSpriteGrid = function(self, x, y, z, color)
    if renderLargeGateGrid(self, x, y, z, color) then
        return
    end

    return Pickup._largeGateOriginalRenderSpriteGrid(self, x, y, z, color)
end

return Pickup
