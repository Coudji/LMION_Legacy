require "BuildingObjects/ISMoveableCursor"
require "LMION/Pickup/LargeGateOpenState"

local Pickup = LMION.Pickup
local LargeGate = Pickup.LargeGate
local leafSpecs = Pickup.LargeGateLeafSpecs or {}

local function isLargeGateMoveProps(moveProps)
    return moveProps ~= nil
        and moveProps.lmionLargeGateLeaf ~= nil
        and moveProps.lmionLargeGatePart ~= nil
        and moveProps.lmionDoorFaces ~= nil
end

local function renderFloorFootprint(members)
    for _, member in ipairs(members) do
        local square = member.square
        local floor = square and square:getFloor() or nil
        local floorSprite = floor and floor:getSprite() or nil

        if floorSprite ~= nil then
            floorSprite:RenderGhostTileColor(
                square:getX(),
                square:getY(),
                square:getZ(),
                0.75,
                1,
                0.75,
                0.25
            )
        end
    end
end

if Pickup._largeGateOriginalRenderSpriteGrid == nil then
    Pickup._largeGateOriginalRenderSpriteGrid = ISMoveableCursor.renderSpriteGrid
end

--[[
Open large gates do not occupy their closed SpriteGrid footprint. During Pickup,
resolve the real two-member leaf through the engine-aware open-state resolver and
highlight only those physical floor squares. Closed Pickup and placement keep the
existing tested SpriteGrid rendering path.
]]
ISMoveableCursor.renderSpriteGrid = function(self, x, y, z, color)
    local mode = ISMoveableCursor.mode and ISMoveableCursor.mode[self.player] or nil
    if mode == "pickup"
        and self.currentMoveProps ~= nil
        and self.currentMoveProps.lmionLargeGateIsOpen == true
        and isLargeGateMoveProps(self.currentMoveProps) then
        local square = self.currentSquare or getCell():getGridSquare(x, y, z)
        local selected = square and self.currentMoveProps:findOnSquare(square, self.currentMoveProps.spriteName) or nil
        local members = selected
            and LargeGate.getOpenAwareLeafMembers
            and LargeGate.getOpenAwareLeafMembers(selected, self.currentMoveProps.lmionLargeGateLeaf)
            or nil

        if members ~= nil then
            renderFloorFootprint(members)
        end
        return
    end

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
