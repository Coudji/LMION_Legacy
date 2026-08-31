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

    return door
end


return LargeGateRuntime
