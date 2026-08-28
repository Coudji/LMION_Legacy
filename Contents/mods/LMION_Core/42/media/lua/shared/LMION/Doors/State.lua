local Doors = LMION.Doors

local function copyModData(object)
    if object == nil or object.getModData == nil then
        return nil
    end

    local modData = object:getModData()
    if modData == nil then
        return nil
    end

    return copyTable(modData)
end

local function getKeyId(object)
    return object ~= nil and object.getKeyId ~= nil and object:getKeyId() or nil
end

local function getLocked(object)
    return object ~= nil and object.isLocked ~= nil and object:isLocked() or nil
end

local function getLockedByKey(object)
    return object ~= nil and object.isLockedByKey ~= nil and object:isLockedByKey() or nil
end

function Doors.captureDoorState(object)
    if not Doors.isDoorObject(object) then
        return nil
    end

    local modData = object.getModData ~= nil and object:getModData() or nil
    local logicalMax = modData and tonumber(modData[Doors.MaxHealthModDataKey]) or nil

    return {
        representation = Doors.getDoorRepresentation(object),
        health = Doors.getHealth(object),
        maxHealth = Doors.getEffectiveMaxHealth(object),
        hasLogicalMaxOverride = logicalMax ~= nil,
        keyId = getKeyId(object),
        locked = getLocked(object),
        lockedByKey = getLockedByKey(object),
        modData = copyModData(object),
    }
end

function Doors.restoreDoorState(object, state)
    if not Doors.isDoorObject(object) or type(state) ~= "table" then
        return false
    end

    if state.modData ~= nil and object.setModData ~= nil then
        object:setModData(copyTable(state.modData))
    end

    if state.maxHealth ~= nil then
        if Doors.isThumpableDoor(object) then
            Doors.setEffectiveMaxHealth(object, state.maxHealth)
        elseif state.hasLogicalMaxOverride then
            Doors.setEffectiveMaxHealth(object, state.maxHealth)
        else
            local engineMax = object.getMaxHealth ~= nil and tonumber(object:getMaxHealth()) or nil
            if engineMax ~= tonumber(state.maxHealth) then
                -- IsoDoor cannot change its engine max. Preserve an exact state
                -- only when recreation produced a different engine maximum.
                Doors.setEffectiveMaxHealth(object, state.maxHealth)
            else
                Doors.clearEffectiveMaxHealthOverride(object)
            end
        end
    end

    if state.health ~= nil then
        Doors.setHealth(object, state.health)
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

return Doors
