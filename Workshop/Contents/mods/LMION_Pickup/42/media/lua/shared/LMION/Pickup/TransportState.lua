local TransportState = {}

local KEYS = {
    entityId = "lmionPickupEntityId",
    health = "lmionPickupHealth",
    maxHealth = "lmionPickupMaxHealth",
}

local OBSOLETE_KEYS = {
    "lmionPickupDefinitionId",
    "lmionPickupMember",
    "lmionPickupFacing",
    "lmionPickupMaxWasLogical",
    "lmionPickupKeyId",
    "lmionPickupLocked",
    "lmionPickupLockedByKey",
}


local function clearState(modData)
    for _, key in pairs(KEYS) do
        modData[key] = nil
    end

    for _, key in ipairs(OBSOLETE_KEYS) do
        modData[key] = nil
    end
end


local function writeValue(modData, key, value)
    if value ~= nil then
        modData[key] = value
    end
end


function TransportState.write(item, state)
    if item == nil or type(state) ~= "table" then
        return false
    end

    local entityId = state.entityId
    if type(entityId) ~= "string" or entityId == "" then
        return false
    end

    local modData = item:getModData()
    clearState(modData)

    writeValue(modData, KEYS.entityId, entityId)
    writeValue(modData, KEYS.health, state.health)
    writeValue(modData, KEYS.maxHealth, state.maxHealth)

    return true
end


function TransportState.read(item)
    if item == nil or not item:hasModData() then
        return nil
    end

    local modData = item:getModData()
    local entityId = modData[KEYS.entityId]

    if type(entityId) ~= "string" or entityId == "" then
        return nil
    end

    return {
        entityId = entityId,
        health = tonumber(modData[KEYS.health]),
        maxHealth = tonumber(modData[KEYS.maxHealth]),
    }
end


function TransportState.clearFromObject(object)
    if object == nil or object.getModData == nil then
        return
    end

    local modData = object:getModData()
    if modData ~= nil then
        clearState(modData)
    end
end


return TransportState
