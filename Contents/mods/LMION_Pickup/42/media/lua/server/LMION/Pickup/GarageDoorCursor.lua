require "BuildingObjects/ISMoveableCursor"
require "LMION/Pickup/GarageDoorPickup"

local Pickup = LMION.Pickup
local GarageDoor = Pickup.GarageDoor

local function isGarageMoveProps(moveProps)
    return moveProps ~= nil and moveProps.lmionGarageFamily ~= nil
end

local function clearLegacyOutline(cursor)
    local objects = cursor and cursor.lmionGarageOutlinedObjects or nil
    if objects == nil then
        return
    end

    for _, object in ipairs(objects) do
        if object ~= nil then
            object:setOutlineHighlight(cursor.player, false)
        end
    end

    cursor.lmionGarageOutlinedObjects = nil
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

if Pickup._garageDoorOriginalRenderSpriteGrid == nil then
    Pickup._garageDoorOriginalRenderSpriteGrid = ISMoveableCursor.renderSpriteGrid
end

--[[
Pickup keeps the existing garage sprites untouched. Only the three floor squares
belonging to the resolved engine members are tinted, matching the usual Moveables
"this footprint will be taken" feedback without ghost-rendering the door itself.
]]
ISMoveableCursor.renderSpriteGrid = function(self, x, y, z, color)
    clearLegacyOutline(self)

    local mode = ISMoveableCursor.mode and ISMoveableCursor.mode[self.player] or nil
    if mode == "pickup"
        and isGarageMoveProps(self.origMoveProps)
        and isGarageMoveProps(self.currentMoveProps) then
        local square = self.currentSquare or getCell():getGridSquare(x, y, z)
        local selected = square and self.currentMoveProps:findOnSquare(square, self.currentMoveProps.spriteName) or nil
        local members = selected and GarageDoor.getMembers(selected, self.currentMoveProps.lmionGarageFamily) or nil

        if members ~= nil then
            renderFloorFootprint(members)
        end
        return
    end

    return Pickup._garageDoorOriginalRenderSpriteGrid(self, x, y, z, color)
end

--[[
An earlier experiment hooked clearCache to manage outlines. Restore the original
method when this file is hot-reloaded so that failed experiment leaves no cursor
behavior behind.
]]
if Pickup._garageDoorOriginalCursorClearCache ~= nil then
    ISMoveableCursor.clearCache = Pickup._garageDoorOriginalCursorClearCache
end

return GarageDoor
