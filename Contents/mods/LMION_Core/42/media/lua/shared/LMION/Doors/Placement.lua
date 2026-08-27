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

local function hasPairedFrameSide(properties, pairedFrameSide)
    if pairedFrameSide == nil then
        return true
    end
    if properties == nil then
        return false
    end

    if pairedFrameSide == 1 then
        return properties:has(IsoFlagType.DoubleDoor1)
    end
    if pairedFrameSide == 2 then
        return properties:has(IsoFlagType.DoubleDoor2)
    end

    return false
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
                if hasPairedFrameSide(properties, pairedFrameSide) then
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

            if matchesOrientation and hasPairedFrameSide(properties, pairedFrameSide) then
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
