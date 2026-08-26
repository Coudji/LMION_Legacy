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

--[[
Large-gate previews always keep the two-square footprint. Most families render
one complete artwork member; the Farm Gate explicitly opts into both members.
]]
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
        end
    end

    local leafId = self.currentMoveProps.lmionLargeGateLeaf
    local leaf = leafSpecs[leafId]
    if leaf ~= nil and leaf.previewAllParts then
        for gridX = 0, spriteGrid:getWidth() - 1 do
            for gridY = 0, spriteGrid:getHeight() - 1 do
                local objectSprite = spriteGrid:getSprite(gridX, gridY)
                if objectSprite ~= nil then
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
                end
            end
        end
        return
    end

    local facing = self.currentMoveProps.lmionDoorFacing
    local visualPartIndex = leaf and leaf.visualPartIndex or nil
    local fullSpriteName = leaf
        and visualPartIndex
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
