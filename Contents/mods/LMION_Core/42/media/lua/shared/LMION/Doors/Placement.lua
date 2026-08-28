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

    if Doors.isThumpableDoor(object) then
        if openSprite ~= nil then
            object:setOpenSprite(openSprite)
        end
        if shouldBeOpen ~= object:IsOpen() then
            object:ToggleDoorSilent()
        end
    end

    return object
end

--[[
Vanilla Moveables always creates an IsoDoor when the placed sprite has doorN/doorW,
even when the object picked up was an IsoThumpable door. Pickup stores the source
representation; Core owns restoring that representation after vanilla placement.

Specialized placement may also request an explicit logical open state. The object
is first created from its CLOSED sprite on the already-resolved target square, then
Core applies the open sprite/state without calling the collective DoubleDoor toggle.
That avoids moving or recreating neighbouring members during placement.
]]
function Doors.restorePlacedRepresentation(object, representation, options)
    if not Doors.isDoorObject(object) then
        return object
    end

    options = options or {}

    if representation ~= "IsoThumpable" or not Doors.isIsoDoor(object) then
        return applyExplicitDoorState(object, options)
    end

    local square = object:getSquare()
    local currentSprite = object:getSprite()
    local closedSprite = options.closedSpriteName and getSprite(options.closedSpriteName) or currentSprite
    local openSprite = options.openSpriteName and getSprite(options.openSpriteName) or nil
    local spriteName = closedSprite and closedSprite:getName() or nil
    local north = object.getNorth ~= nil and object:getNorth() or Doors.getNorthFromSprite(closedSprite)
    if square == nil or spriteName == nil or north == nil then
        return object
    end

    local insertIndex = object.getObjectIndex ~= nil and object:getObjectIndex() or -1
    local objectName = object.getName ~= nil and object:getName() or nil

    local replacement = IsoThumpable.new(getCell(), square, spriteName, north)

    if GameEntityFactory ~= nil and GameEntityFactory.TransferComponents ~= nil then
        GameEntityFactory.TransferComponents(object, replacement)
    end

    replacement:setIsDoor(true)
    replacement:setClosedSprite(closedSprite)
    if openSprite ~= nil then
        replacement:setOpenSprite(openSprite)
    elseif object.getOpenSprite ~= nil and object:getOpenSprite() ~= nil then
        replacement:setOpenSprite(object:getOpenSprite())
    end

    applyExplicitDoorState(replacement, options)

    square:transmitRemoveItemFromSquare(object)
    if insertIndex >= 0 then
        square:AddSpecialObject(replacement, insertIndex)
    else
        square:AddSpecialObject(replacement)
    end

    if objectName ~= nil and replacement.setName ~= nil then
        replacement:setName(objectName)
    end

    if isServer ~= nil and isServer() and replacement.transmitCompleteItemToClients ~= nil then
        replacement:transmitCompleteItemToClients()
    end

    square:RecalcProperties()
    square:RecalcAllWithNeighbours(true)
    triggerEvent("OnObjectAdded", replacement)

    return replacement
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
