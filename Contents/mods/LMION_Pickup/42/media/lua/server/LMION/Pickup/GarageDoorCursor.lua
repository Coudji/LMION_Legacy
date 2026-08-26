require "BuildingObjects/ISMoveableCursor"
require "LMION/Pickup/GarageDoorPickup"

local Pickup = LMION.Pickup
local GarageDoor = Pickup.GarageDoor

local function isGarageMoveProps(moveProps)
    return moveProps ~= nil and moveProps.lmionGarageFamily ~= nil
end

if Pickup._garageDoorOriginalRenderSpriteGrid == nil then
    Pickup._garageDoorOriginalRenderSpriteGrid = ISMoveableCursor.renderSpriteGrid
end

--[[
The runtime SpriteGrid exists to give Moveables a rotatable 3-tile placement
footprint. Its W ordering is a placement concern and must not be used as the
source of truth for a pickup highlight. During pickup, render the three physical
world members with their actual sprites and coordinates so the preview can never
swap garage end-cap sprites while hovering an existing door.
]]
ISMoveableCursor.renderSpriteGrid = function(self, x, y, z, color)
    local mode = ISMoveableCursor.mode and ISMoveableCursor.mode[self.player] or nil
    if mode ~= "pickup"
        or not isGarageMoveProps(self.origMoveProps)
        or not isGarageMoveProps(self.currentMoveProps) then
        return Pickup._garageDoorOriginalRenderSpriteGrid(self, x, y, z, color)
    end

    local square = self.currentSquare or getCell():getGridSquare(x, y, z)
    local selected = square and self.currentMoveProps:findOnSquare(square, self.currentMoveProps.spriteName) or nil
    local members = selected and GarageDoor.getMembers(selected, self.currentMoveProps.lmionGarageFamily) or nil

    if members == nil then
        return Pickup._garageDoorOriginalRenderSpriteGrid(self, x, y, z, color)
    end

    for _, member in ipairs(members) do
        local memberSquare = member.square
        if memberSquare ~= nil then
            local floor = memberSquare:getFloor()
            local floorSprite = floor and floor:getSprite() or nil
            if floorSprite ~= nil then
                floorSprite:RenderGhostTileColor(
                    memberSquare:getX(),
                    memberSquare:getY(),
                    memberSquare:getZ(),
                    0.75,
                    1,
                    0.75,
                    0.25
                )
            end

            local objectSprite = member.object and member.object:getSprite() or nil
            if objectSprite ~= nil then
                objectSprite:RenderGhostTileColor(
                    memberSquare:getX(),
                    memberSquare:getY(),
                    memberSquare:getZ(),
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
end

return GarageDoor
