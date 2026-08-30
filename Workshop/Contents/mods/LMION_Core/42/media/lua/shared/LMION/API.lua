local EntityIndex = require "LMION/Core/EntityIndex"
local ObjectLookup = require "LMION/Core/ObjectLookup"
local Registry = require "LMION/Core/Registry"
local Resolver = require "LMION/Core/Resolver"
local Validation = require "LMION/Core/Validation"

local API = {}


local function registerList(list, register)
    if list == nil then
        return
    end

    for index = 1, #list do
        register(list[index])
    end
end


function API.registerDefault(definitionDefault)
    Validation.definitionDefault(definitionDefault)

    local defaultId = Registry.registerDefault(definitionDefault)
    EntityIndex.invalidate()

    return defaultId
end


function API.registerDefinition(definition)
    Validation.definition(definition)

    local definitionId = Registry.registerDefinition(definition)
    EntityIndex.invalidate()

    return definitionId
end


function API.registerExtension(extension)
    Validation.extension(extension)

    local extensionId = Registry.registerExtension(extension)
    EntityIndex.invalidate()

    return extensionId
end


function API.registerContent(content)
    Validation.content(content)

    registerList(content.defaults, API.registerDefault)
    registerList(content.definitions, API.registerDefinition)
    registerList(content.extensions, API.registerExtension)
end


function API.getEffectiveDefault(defaultId)
    return Resolver.resolveDefault(defaultId)
end


function API.getEffectiveDefinition(definitionId)
    return Resolver.resolveDefinition(definitionId)
end


function API.getDefinitionIdByEntity(entityId)
    return EntityIndex.getDefinitionId(entityId)
end


function API.getEffectiveDefinitionByEntity(entityId)
    local definitionId = EntityIndex.getDefinitionId(entityId)

    if definitionId == nil then
        return nil
    end

    return Resolver.resolveDefinition(definitionId)
end


function API.getEntityIdForObject(object)
    return ObjectLookup.getEntityId(object)
end


function API.getDefinitionIdForObject(object)
    return ObjectLookup.getDefinitionId(object)
end


function API.getEffectiveDefinitionForObject(object)
    return ObjectLookup.getEffectiveDefinition(object)
end


function API.getRegisteredDefaultIds()
    return Registry.getDefaultIds()
end


function API.getRegisteredDefinitionIds()
    return Registry.getDefinitionIds()
end


function API.getRegistrationStats()
    return Registry.getRegistrationStats()
end


return API
