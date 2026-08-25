require "BuildingObjects/ISMoveableCursor"
require "LMION/Pickup/LargeGateMoveables"

local Pickup = LMION.Pickup

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

            local objectSprite = spriteGrid:getSprite(gridX, gridY)
            if objectSprite ~= nil then
                -- Gate tiles overlap graphically at the leaf joint. Vanilla's
                -- translucent multisprite preview (alpha 0.8) makes that joint
                -- look like the centre tile was rendered twice. Keep the normal
                -- placement tint but render the gate itself opaque so overlapping
                -- pixels occlude one another just like the real IsoDoor sprites.
                objectSprite:RenderGhostTileColor(
                    worldX,
                    worldY,
                    z,
                    0,
                    self.yOffset * Core.getTileScale(),
                    color.r,
                    color.g,
                    color.b,
                    1.0
                )
            end
        end
    end
end

return Pickup
