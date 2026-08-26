require "BuildingObjects/ISMoveableCursor"
require "LMION/Pickup/GarageDoorPickup"

local Pickup = LMION.Pickup
local GarageDoor = Pickup.GarageDoor

local function isGarageMoveProps(moveProps)
    return moveProps ~= nil and moveProps.lmionGarageFamily ~= nil
end

local function clearGarageOutline(cursor)
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

local function outlineGarageMembers(cursor, members, color)
    local outlined = {}

    for _, member in ipairs(members) do
        local object = member.object
        if object ~= nil then
            object:setOutlineHighlightCol(cursor.player, color.r, color.g, color.b, 1)
            object:setOutlineHighlight(cursor.player, true)
            outlined[#outlined + 1] = object
        end
    end

    cursor.lmionGarageOutlinedObjects = outlined
end

if Pickup._garageDoorOriginalRenderSpriteGrid == nil then
    Pickup._garageDoorOriginalRenderSpriteGrid = ISMoveableCursor.renderSpriteGrid
end

--[[
Vanilla Moveables renders ghost sprites for multi-tile previews. That is useful
while placing or rotating a garage door, but unnecessary while picking up an
existing one and can visually reorder the W-facing end panels. Pickup therefore
outlines the three real IsoDoor objects in place and never redraws their sprites.
]]
ISMoveableCursor.renderSpriteGrid = function(self, x, y, z, color)
    clearGarageOutline(self)

    local mode = ISMoveableCursor.mode and ISMoveableCursor.mode[self.player] or nil
    if mode ~= "pickup"
        or not isGarageMoveProps(self.origMoveProps)
        or not isGarageMoveProps(self.currentMoveProps) then
        return Pickup._garageDoorOriginalRenderSpriteGrid(self, x, y, z, color)
    end

    local square = self.currentSquare or getCell():getGridSquare(x, y, z)
    local selected = square and self.currentMoveProps:findOnSquare(square, self.currentMoveProps.spriteName) or nil
    local members = selected and GarageDoor.getMembers(selected, self.currentMoveProps.lmionGarageFamily) or nil

    if members ~= nil then
        outlineGarageMembers(self, members, color)
    end
end

if Pickup._garageDoorOriginalCursorClearCache == nil and ISMoveableCursor.clearCache ~= nil then
    Pickup._garageDoorOriginalCursorClearCache = ISMoveableCursor.clearCache
end

if Pickup._garageDoorOriginalCursorClearCache ~= nil then
    ISMoveableCursor.clearCache = function(self, ...)
        clearGarageOutline(self)
        return Pickup._garageDoorOriginalCursorClearCache(self, ...)
    end
end

return GarageDoor
