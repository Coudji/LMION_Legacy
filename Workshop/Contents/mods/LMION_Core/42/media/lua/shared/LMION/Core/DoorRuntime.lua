local DoorRuntime = {}

local MAX_HEALTH_MOD_DATA_KEY = "lmionDoorMaxHealth"


function DoorRuntime.isIsoDoor(object)
    return object ~= nil and instanceof(object, "IsoDoor")
end


function DoorRuntime.isThumpableDoor(object)
    return object ~= nil
        and instanceof(object, "IsoThumpable")
        and object.isDoor ~= nil
        and object:isDoor()
end


function DoorRuntime.isDoorObject(object)
    return DoorRuntime.isIsoDoor(object)
        or DoorRuntime.isThumpableDoor(object)
end


local function getHealth(object)
    if not DoorRuntime.isDoorObject(object) or object.getHealth == nil then
        return nil
    end

    return tonumber(object:getHealth())
end


local function setHealth(object, value)
    if not DoorRuntime.isDoorObject(object) or object.setHealth == nil then
        return nil
    end

    local health = tonumber(value)
    if health == nil then
        return nil
    end

    health = math.max(0, math.floor(health))
    object:setHealth(health)

    return health
end


local function hasMaxHealthOverride(object)
    if object == nil or object.getModData == nil then
        return false
    end

    local modData = object:getModData()

    return modData ~= nil
        and tonumber(modData[MAX_HEALTH_MOD_DATA_KEY]) ~= nil
end


local function clearMaxHealthOverride(object)
    if object == nil or object.getModData == nil then
        return
    end

    local modData = object:getModData()
    if modData ~= nil then
        modData[MAX_HEALTH_MOD_DATA_KEY] = nil
    end
end


local function setEffectiveMaxHealth(object, value)
    if not DoorRuntime.isDoorObject(object) then
        return nil
    end

    local maxHealth = tonumber(value)
    if maxHealth == nil then
        return nil
    end

    maxHealth = math.max(0, math.floor(maxHealth))

    if DoorRuntime.isThumpableDoor(object)
        and object.setMaxHealth ~= nil
    then
        object:setMaxHealth(maxHealth)
        clearMaxHealthOverride(object)
        return maxHealth
    end

    if object.getModData ~= nil then
        object:getModData()[MAX_HEALTH_MOD_DATA_KEY] = maxHealth
        return maxHealth
    end

    return nil
end


local function getEffectiveMaxHealth(object)
    if not DoorRuntime.isDoorObject(object) then
        return nil
    end

    if object.getModData ~= nil then
        local modData = object:getModData()
        local logicalMax = modData
            and tonumber(modData[MAX_HEALTH_MOD_DATA_KEY])
            or nil

        if logicalMax ~= nil then
            return logicalMax
        end
    end

    if object.getMaxHealth ~= nil then
        return tonumber(object:getMaxHealth())
    end

    return nil
end


local function restoreEffectiveMaxHealth(object, value, hadLogicalOverride)
    if not DoorRuntime.isDoorObject(object) then
        return nil
    end

    local maxHealth = tonumber(value)
    if maxHealth == nil then
        return nil
    end

    if DoorRuntime.isThumpableDoor(object) then
        return setEffectiveMaxHealth(object, maxHealth)
    end

    local engineMaxHealth = object.getMaxHealth ~= nil
        and tonumber(object:getMaxHealth())
        or nil

    if hadLogicalOverride == true or engineMaxHealth ~= maxHealth then
        return setEffectiveMaxHealth(object, maxHealth)
    end

    clearMaxHealthOverride(object)

    return engineMaxHealth
end


local function getKeyId(object)
    return object ~= nil
        and object.getKeyId ~= nil
        and object:getKeyId()
        or nil
end


local function getLocked(object)
    return object ~= nil
        and object.isLocked ~= nil
        and object:isLocked()
        or nil
end


local function getLockedByKey(object)
    return object ~= nil
        and object.isLockedByKey ~= nil
        and object:isLockedByKey()
        or nil
end


function DoorRuntime.captureState(object)
    if not DoorRuntime.isDoorObject(object) then
        return nil
    end

    return {
        health = getHealth(object),
        maxHealth = getEffectiveMaxHealth(object),
        maxWasLogical = hasMaxHealthOverride(object),
        keyId = getKeyId(object),
        locked = getLocked(object),
        lockedByKey = getLockedByKey(object),
    }
end


function DoorRuntime.restoreState(object, state)
    if not DoorRuntime.isDoorObject(object)
        or type(state) ~= "table"
    then
        return false
    end

    if state.maxHealth ~= nil then
        restoreEffectiveMaxHealth(
            object,
            state.maxHealth,
            state.maxWasLogical == true
        )
    end

    if state.health ~= nil then
        setHealth(object, state.health)
    end

    if state.keyId ~= nil and object.setKeyId ~= nil then
        object:setKeyId(state.keyId)
    end

    if state.locked ~= nil and object.setIsLocked ~= nil then
        object:setIsLocked(state.locked)
    end

    if state.lockedByKey ~= nil and object.setLockedByKey ~= nil then
        object:setLockedByKey(state.lockedByKey)
    end

    return true
end


local function recreateGameEntity(object)
    if object == nil
        or GameEntityFactory == nil
        or GameEntityFactory.CreateIsoEntityFromCellLoading == nil
    then
        return
    end

    local properties = object:getProperties()

    if properties ~= nil
        and properties:has(IsoFlagType.EntityScript)
    then
        GameEntityFactory.CreateIsoEntityFromCellLoading(object)
    end
end


function DoorRuntime.ensureCanonicalDoor(object)
    if DoorRuntime.isIsoDoor(object) then
        return object
    end

    if not DoorRuntime.isThumpableDoor(object) then
        return nil
    end

    local square = object:getSquare()
    local sprite = object:getSprite()
    local north = object.getNorth ~= nil and object:getNorth() or nil

    if square == nil or sprite == nil or north == nil then
        error("LMION: cannot canonicalize incomplete door object", 2)
    end

    local state = DoorRuntime.captureState(object)
    local objectName = object.getName ~= nil and object:getName() or nil
    local door = IsoDoor.new(getCell(), square, sprite, north)

    if objectName ~= nil and door.setName ~= nil then
        door:setName(objectName)
    end

    DoorRuntime.restoreState(door, state)
    recreateGameEntity(door)

    square:AddSpecialObject(door)
    square:transmitRemoveItemFromSquare(object)

    return door
end


local function matchesFrameClass(properties, pairedFrameSide)
    local isDoubleDoor1 = properties ~= nil
        and properties:has(IsoFlagType.DoubleDoor1)
    local isDoubleDoor2 = properties ~= nil
        and properties:has(IsoFlagType.DoubleDoor2)

    if pairedFrameSide == 1 then
        return isDoubleDoor1
    end

    if pairedFrameSide == 2 then
        return isDoubleDoor2
    end

    return not isDoubleDoor1 and not isDoubleDoor2
end


function DoorRuntime.canPlaceAt(square, facing, frame, pairedFrameSide)
    if square == nil or (facing ~= "N" and facing ~= "W") then
        return false
    end

    if frame ~= false and frame ~= "standard" then
        return false
    end

    if square.isVehicleIntersecting ~= nil
        and square:isVehicleIntersecting()
    then
        return false
    end

    local north = facing == "N"
    local hasFrame = false
    local hasDoor = false
    local specialObjects = square:getSpecialObjects()

    for index = 0, specialObjects:size() - 1 do
        local object = specialObjects:get(index)

        if DoorRuntime.isThumpableDoor(object)
            and object:getNorth() == north
        then
            hasDoor = true
        elseif instanceof(object, "IsoThumpable")
            and object:isDoorFrame()
            and object:getNorth() == north
        then
            local sprite = object:getSprite()
            local properties = sprite and sprite:getProperties() or nil

            if matchesFrameClass(properties, pairedFrameSide) then
                hasFrame = true
            end
        end
    end

    local objects = square:getObjects()

    for index = 0, objects:size() - 1 do
        local object = objects:get(index)

        if DoorRuntime.isIsoDoor(object)
            and object:getNorth() == north
        then
            hasDoor = true
        end

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

            if matchesOrientation
                and matchesFrameClass(properties, pairedFrameSide)
            then
                hasFrame = true
            end
        end
    end

    if frame == false then
        return not hasDoor
    end

    return hasFrame and not hasDoor
end


function DoorRuntime.finalizePlacedDoor(object, definition, facing)
    if not DoorRuntime.isDoorObject(object)
        or type(definition) ~= "table"
        or (facing ~= "N" and facing ~= "W")
    then
        return nil
    end

    local geometry = definition.geometry
    local face = type(geometry) == "table" and geometry[facing] or nil

    if type(face) ~= "table"
        or type(face.closed) ~= "string"
        or type(face.open) ~= "string"
    then
        return nil
    end

    local door = DoorRuntime.ensureCanonicalDoor(object)
    if door == nil then
        return nil
    end

    local closedSprite = getSprite(face.closed)
    local openSprite = getSprite(face.open)

    if closedSprite ~= nil then
        door:setSprite(closedSprite)
    end

    if openSprite ~= nil and door.setOpenSprite ~= nil then
        door:setOpenSprite(openSprite)
    end

    if door.setOpen ~= nil then
        door:setOpen(false)
    end

    return door
end


return DoorRuntime
