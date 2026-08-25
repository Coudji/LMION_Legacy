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
    if ISMoveableCursor.mode[self.player] ~= "place"
        or not isLargeGateMoveProps(self.origMoveProps)
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

    -- Keep the real footprint visible at the intended placement position.
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

    -- Diagnostic: render the two SpriteGrid members far apart, so their image
    -- footprints cannot overlap. Member #1 is red and member #2 is blue.
    -- This shows exactly what each individual gate tile contains visually.
    local members = {}
    for gridX = 0, spriteGrid:getWidth() - 1 do
        for gridY = 0, spriteGrid:getHeight() - 1 do
            local sprite = spriteGrid:getSprite(gridX, gridY)
            if sprite ~= nil then
                members[#members + 1] = sprite
            end
        end
    end

    if members[1] ~= nil then
        members[1]:RenderGhostTileColor(
            x - 3,
            y,
            z,
            0,
            self.yOffset * Core.getTileScale(),
            1.0,
            0.15,
            0.15,
            0.85
        )
    end

    if members[2] ~= nil then
        members[2]:RenderGhostTileColor(
            x + 3,
            y,
            z,
            0,
            self.yOffset * Core.getTileScale(),
            0.15,
            0.35,
            1.0,
            0.85
        )
    end
end

LMION.log("Pickup", "large gate cursor diagnostic: separated red/blue sprite members")

return Pickup
