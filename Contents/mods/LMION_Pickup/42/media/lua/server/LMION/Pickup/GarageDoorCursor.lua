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

local function renderOpenPickupFootprint(self, x, y, z)
    local mode = ISMoveableCursor.mode and ISMoveableCursor.mode[self.player] or nil
    if mode ~= "pickup"
        or not isGarageMoveProps(self.currentMoveProps)
        or self.currentMoveProps.lmionGarageIsOpen ~= true then
        return
    end

    local square = self.currentSquare or getCell():getGridSquare(x, y, z)
    local selected = square and self.currentMoveProps:findOnSquare(square, self.currentMoveProps.spriteName) or nil
    local members = selected and GarageDoor.getMembers(selected, self.currentMoveProps.lmionGarageFamily) or nil

    if members ~= nil then
        renderFloorFootprint(members)
    end
end

-- Open garage sprites intentionally have no synthetic closed SpriteGrid. Vanilla
-- therefore does not call renderSpriteGrid() for them; tint their real unchanged
-- three-square footprint from the cursor's general render path.
if Pickup._garageDoorOriginalRender == nil then
    Pickup._garageDoorOriginalRender = ISMoveableCursor.render
end

ISMoveableCursor.render = function(self, x, y, z, square)
    local result = Pickup._garageDoorOriginalRender(self, x, y, z, square)
    renderOpenPickupFootprint(self, x, y, z)
    return result
end

if Pickup._garageDoorOriginalRenderSpriteGrid == nil then
    Pickup._garageDoorOriginalRenderSpriteGrid = ISMoveableCursor.renderSpriteGrid
end

-- Closed garage pickup keeps the tested synthetic SpriteGrid path. Only the three
-- floor squares belonging to the resolved engine members are tinted.
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

if Pickup._garageDoorOriginalCursorClearCache ~= nil then
    ISMoveableCursor.clearCache = Pickup._garageDoorOriginalCursorClearCache
end

return GarageDoor
