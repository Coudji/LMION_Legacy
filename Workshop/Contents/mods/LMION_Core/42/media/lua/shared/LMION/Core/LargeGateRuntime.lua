local DoorRuntime = require "LMION/Core/DoorRuntime"

local LargeGateRuntime = {}


local function getPart(definition, facing, leaf, partIndex)
    local geometry = definition and definition.geometry or nil

    if (facing ~= "N" and facing ~= "W")
        or (leaf ~= "A" and leaf ~= "B")
        or (partIndex ~= 1 and partIndex ~= 2)
    then
        return nil
    end

    local face = type(geometry) == "table" and geometry[facing] or nil
    local parts = type(face) == "table" and face[leaf] or nil
    local part = type(parts) == "table" and parts[partIndex] or nil

    if type(part) ~= "table"
        or type(part.closed) ~= "string"
        or type(part.open) ~= "string"
    then
        return nil
    end

    return part
end


local function refreshSquare(door)
    local square = door and door:getSquare() or nil
    if square == nil then
        return
    end

    -- placeMoveableInternal() recalculates the square while the temporary
    -- closed sprite is still installed. Large-gate open placement then swaps
    -- the final IsoDoor to its open sprite/state without using ToggleDoor().
    -- Recalculate again so collision/door-edge properties match the final
    -- sprite instead of the temporary closed representation.
    square:RecalcProperties()
    square:RecalcAllWithNeighbours(true)
end


function LargeGateRuntime.finalizePart(
    object,
    definition,
    facing,
    leaf,
    partIndex,
    isOpen
)
    local part = getPart(definition, facing, leaf, partIndex)
    if part == nil or not DoorRuntime.isDoorObject(object) then
        return nil
    end

    local door = DoorRuntime.ensureCanonicalDoor(object)
    if door == nil then
        return nil
    end

    local closedSprite = getSprite(part.closed)
    local openSprite = getSprite(part.open)
    local shouldOpen = isOpen == true

    if openSprite ~= nil and door.setOpenSprite ~= nil then
        door:setOpenSprite(openSprite)
    end

    if door.setOpen ~= nil then
        door:setOpen(shouldOpen)
    end

    local targetSprite = shouldOpen and openSprite or closedSprite
    if targetSprite ~= nil then
        door:setSprite(targetSprite)
    end

    refreshSquare(door)

    return door
end


return LargeGateRuntime
