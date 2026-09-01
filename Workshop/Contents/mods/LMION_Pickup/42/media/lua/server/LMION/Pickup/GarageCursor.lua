require "BuildingObjects/ISMoveableCursor"

local LMION = require "LMION/API"


local function renderFloor(square)
    local floor = square and square:getFloor() or nil
    local sprite = floor and floor:getSprite() or nil

    if sprite == nil then
        return
    end

    sprite:RenderGhostTileColor(
        square:getX(),
        square:getY(),
        square:getZ(),
        0.75,
        1,
        0.75,
        0.25
    )
end


local function renderPickupFootprint(cursor, x, y, z)
    if ISMoveableCursor.mode[cursor.player] ~= "pickup" then
        return
    end

    local moveProps = cursor.currentMoveProps
    if moveProps == nil or moveProps.lmionGarageDefinitionId == nil then
        return
    end

    local square = cursor.currentSquare or getCell():getGridSquare(x, y, z)
    local selected = square
        and moveProps:findOnSquare(square, moveProps.spriteName)
        or nil
    local chain = selected and LMION.getGarageChain(selected) or nil

    if chain == nil
        or chain.definitionId ~= moveProps.lmionGarageDefinitionId
    then
        return
    end

    for position = 1, chain.length do
        local object = chain.members[position]
        renderFloor(object and object:getSquare() or nil)
    end
end


if ISMoveableCursor._lmionGarageOriginalRender == nil then
    ISMoveableCursor._lmionGarageOriginalRender = ISMoveableCursor.render
end


ISMoveableCursor.render = function(self, x, y, z, square)
    local result = ISMoveableCursor._lmionGarageOriginalRender(
        self,
        x,
        y,
        z,
        square
    )

    renderPickupFootprint(self, x, y, z)
    return result
end
