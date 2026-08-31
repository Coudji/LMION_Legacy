local DoorRuntime = require "LMION/Core/DoorRuntime"

local LargeGateRuntime = {}


local function getPartGeometry(definition, facing, leaf, partIndex)
    local topology = definition and definition.topology or nil
    local geometry = definition and definition.geometry or nil

    if type(topology) ~= "table"
        or topology.type ~= "largeGate"
        or (leaf ~= "A" and leaf ~= "B")
        or (partIndex ~= 1 and partIndex ~= 2)
        or (facing ~= "N" and facing ~= "W")
    then
        return nil
    end

    local face = type(geometry) == "table" and geometry[facing] or nil
    local leafGeometry = type(face) == "table" and face[leaf] or nil
    local part = type(leafGeometry) == "table" and leafGeometry[partIndex] or nil

    if type(part) ~= "table"
        or type(part.closed) ~= "string"
        or part.closed == ""
        or type(part.open) ~= "string"
        or part.open == ""
    then
        return nil
    end

    return part
end


function LargeGateRuntime.finalizePlacedPart(
    object,
    definition,
    facing,
    leaf,
    partIndex,
    isOpen
)
    if not DoorRuntime.isDoorObject(object) then
        return nil
    end

    local geometry = getPartGeometry(
        definition,
        facing,
        leaf,
        partIndex
    )
    if geometry == nil then
        return nil
    end

    local door = DoorRuntime.ensureCanonicalDoor(object)
    if door == nil then
        return nil
    end

    local closedSprite = getSprite(geometry.closed)
    local openSprite = getSprite(geometry.open)
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
