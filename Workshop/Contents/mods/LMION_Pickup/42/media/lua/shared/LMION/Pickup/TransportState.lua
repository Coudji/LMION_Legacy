local TransportState = {}

local LEGACY_MEMBER_KEY = "lmionPickupMember"

local KEYS = {
    definitionId = "lmionPickupDefinitionId",
    entityId = "lmionPickupEntityId",
    facing = "lmionPickupFacing",
    health = "lmionPickupHealth",
    maxHealth = "lmionPickupMaxHealth",
    maxWasLogical = "lmionPickupMaxWasLogical",
    keyId = "lmionPickupKeyId",
    locked = "lmionPickupLocked",
    lockedByKey = "lmionPickupLockedByKey",
}


local function writeValue(modData, key, value)
    if value ~= nil then
        modData[key] = value
    end
end


function TransportState.write(item, state)
    if item == nil or type(state) ~= "table" then
        return false
    end

    local modData = item:getModData()

    -- Temporary cleanup for parcels created by the first paired-door slice.
    -- Member identity is now derived from entityId + Core topology.
    modData[LEGACY_MEMBER_KEY] = nil

    writeValue(modData, KEYS.definitionId, state.definitionId)
    writeValue(modData, KEYS.entityId, state.entityId)
    writeValue(modData, KEYS.facing, state.facing)
    writeValue(modData, KEYS.health, state.health)
    writeValue(modData, KEYS.maxHealth, state.maxHealth)
    writeValue(modData, KEYS.maxWasLogical, state.maxWasLogical)
    writeValue(modData, KEYS.keyId, state.keyId)
    writeValue(modData, KEYS.locked, state.locked)
    writeValue(modData, KEYS.lockedByKey, state.lockedByKey)

    return true
end


function TransportState.read(item)
    if item == nil or not item:hasModData() then
        return nil
    end

    local modData = item:getModData()
    local definitionId = modData[KEYS.definitionId]

    if type(definitionId) ~= "string" or definitionId == "" then
        return nil
    end

    return {
        definitionId = definitionId,
        entityId = modData[KEYS.entityId],
        facing = modData[KEYS.facing],
        health = tonumber(modData[KEYS.health]),
        maxHealth = tonumber(modData[KEYS.maxHealth]),
        maxWasLogical = modData[KEYS.maxWasLogical] == true,
        keyId = tonumber(modData[KEYS.keyId]),
        locked = modData[KEYS.locked],
        lockedByKey = modData[KEYS.lockedByKey],
    }
end


function TransportState.getDefinitionId(item)
    local state = TransportState.read(item)
    return state and state.definitionId or nil
end


function TransportState.clearFromObject(object)
    if object == nil or object.getModData == nil then
        return
    end

    local modData = object:getModData()
    if modData == nil then
        return
    end

    for _, key in pairs(KEYS) do
        modData[key] = nil
    end

    modData[LEGACY_MEMBER_KEY] = nil
end


return TransportState
