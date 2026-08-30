local Doors = LMION.Doors

function Doors.getNorthFromSprite(sprite)
    if sprite == nil then
        return nil
    end

    if type(sprite) == "string" then
        sprite = getSprite(sprite)
    end

    local properties = sprite and sprite:getProperties() or nil
    if properties == nil then
        return nil
    end

    if properties:has(IsoFlagType.doorN) then
        return true
    end

    if properties:has(IsoFlagType.doorW) then
        return false
    end

    return nil
end

local function applyExplicitDoorState(object, options)
    if object == nil or options == nil then
        return object
    end

    local openSprite = options.openSpriteName and getSprite(options.openSpriteName) or nil
    local shouldBeOpen = options.isOpen == true

    if Doors.isIsoDoor(object) then
        if openSprite ~= nil and object.setOpenSprite ~= nil then
            object:setOpenSprite(openSprite)
        end
        if object.setOpen ~= nil then
            object:setOpen(shouldBeOpen)
        end
        if shouldBeOpen and openSprite ~= nil then
            object:setSprite(openSprite)
        end
        return object
    end

    return object
end

--[[
LMION reinstallation always ends with the canonical IsoDoor representation.
Vanilla Moveables already creates IsoDoor for ordinary doorN/doorW placement in
most cases; ensureCanonicalDoor is still the authoritative boundary in case an
engine/specialized path returns a temporary IsoThumpable.

Specialized placement may request an explicit logical open state. Core applies the
open sprite/state directly on the final IsoDoor without invoking collective
DoubleDoor toggles, so large-gate placement can recreate a coherent open leaf on
its already-resolved target squares without moving neighbouring members.
]]
function Doors.finalizePlacedDoor(object, options)
    if not Doors.isDoorObject(object) then
        return object
    end

    local door = Doors.ensureCanonicalDoor(object)
    if not Doors.isCanonicalDoor(door) then
        return object
    end

    return applyExplicitDoorState(door, options or {})
end

local function matchesFrameClass(properties, pairedFrameSide)
    local isDoubleDoor1 = properties ~= nil and properties:has(IsoFlagType.DoubleDoor1)
    local isDoubleDoor2 = properties ~= nil and properties:has(IsoFlagType.DoubleDoor2)

    if pairedFrameSide == 1 then
        return isDoubleDoor1
    end
    if pairedFrameSide == 2 then
        return isDoubleDoor2
    end

    return not isDoubleDoor1 and not isDoubleDoor2
end

function Doors.canPlaceDoorAt(square, north, requiresFrame, pairedFrameSide)
    if square == nil or north == nil then
        return false
    end

    local hasFrame = false
    local hasDoor = false

    local specialObjects = square:getSpecialObjects()
    for i = 0, specialObjects:size() - 1 do
        local object = specialObjects:get(i)

        if instanceof(object, "IsoThumpable") then
            if object:isDoorFrame() and object:getNorth() == north then
                local sprite = object:getSprite()
                local properties = sprite and sprite:getProperties() or nil
                if matchesFrameClass(properties, pairedFrameSide) then
                    hasFrame = true
                end
            end
            if object:isDoor() and object:getNorth() == north then
                hasDoor = true
            end
        end
    end

    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)

        if instanceof(object, "IsoObject") then
            local sprite = object:getSprite()
            local properties = sprite and sprite:getProperties() or nil
            local matchesOrientation = false

            if north and object:getType() == IsoObjectType.doorFrN then
                matchesOrientation = true
            elseif not north and object:getType() == IsoObjectType.doorFrW then
                matchesOrientation = true
            elseif properties ~= nil then
                if north and properties:has("DoorWallN") then
                    matchesOrientation = true
                elseif not north and properties:has("DoorWallW") then
                    matchesOrientation = true
                end
            end

            if matchesOrientation and matchesFrameClass(properties, pairedFrameSide) then
                hasFrame = true
            end
        end

        if instanceof(object, "IsoDoor") and object:getNorth() == north then
            hasDoor = true
        end
    end

    if requiresFrame == false then
        return not hasDoor
    end

    return hasFrame and not hasDoor
end

return Doors
