require "BuildingObjects/ISMoveableCursor"
require "LMION/Pickup/GarageDoorPickup"

local Pickup = LMION.Pickup

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

if Pickup._garageDoorOriginalRenderSpriteGrid == nil then
    Pickup._garageDoorOriginalRenderSpriteGrid = ISMoveableCursor.renderSpriteGrid
end

--[[
Pickup mode is intentionally visually neutral. The garage runtime SpriteGrid is
needed for placement and rotation, but vanilla's multi-sprite ghost rendering
must not redraw an existing garage while the player is merely selecting it.
]]
ISMoveableCursor.renderSpriteGrid = function(self, x, y, z, color)
    clearLegacyOutline(self)

    local mode = ISMoveableCursor.mode and ISMoveableCursor.mode[self.player] or nil
    if mode == "pickup"
        and isGarageMoveProps(self.origMoveProps)
        and isGarageMoveProps(self.currentMoveProps) then
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

return Pickup.GarageDoor
