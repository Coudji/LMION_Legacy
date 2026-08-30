local EntityIndex = require "LMION/Core/EntityIndex"
local Resolver = require "LMION/Core/Resolver"

local ObjectLookup = {}


local function requireObject(object)
    if object == nil then
        error("LMION: object lookup requires a world object", 3)
    end
end


function ObjectLookup.getEntityId(object)
    requireObject(object)

    local entityScript = object:getEntityScript()

    if entityScript == nil then
        return nil
    end

    local entityId = entityScript:getFullName()

    if type(entityId) ~= "string" or entityId == "" then
        return nil
    end

    return entityId
end


function ObjectLookup.getDefinitionId(object)
    local entityId = ObjectLookup.getEntityId(object)

    if entityId == nil then
        return nil
    end

    return EntityIndex.getDefinitionId(entityId)
end


function ObjectLookup.getEffectiveDefinition(object)
    local definitionId = ObjectLookup.getDefinitionId(object)

    if definitionId == nil then
        return nil
    end

    return Resolver.resolveDefinition(definitionId)
end


return ObjectLookup
