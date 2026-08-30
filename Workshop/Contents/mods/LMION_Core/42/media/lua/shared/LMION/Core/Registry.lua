local TableUtils = require "LMION/Core/TableUtils"

local Registry = {}

local defaultsById = {}
local definitionsById = {}
local defaultIds = {}
local definitionIds = {}
local extensions = {}
local extensionIds = {}


function Registry.registerDefault(definitionDefault)
    local defaultId = definitionDefault.defaultId

    if defaultsById[defaultId] ~= nil then
        error("LMION: definition default already registered: " .. defaultId, 2)
    end

    defaultsById[defaultId] = TableUtils.deepCopy(definitionDefault)
    defaultIds[#defaultIds + 1] = defaultId

    return defaultId
end


function Registry.registerDefinition(definition)
    local definitionId = definition.definitionId

    if definitionsById[definitionId] ~= nil then
        error("LMION: definition already registered: " .. definitionId, 2)
    end

    definitionsById[definitionId] = TableUtils.deepCopy(definition)
    definitionIds[#definitionIds + 1] = definitionId

    return definitionId
end


function Registry.registerExtension(extension)
    local extensionId = extension.extensionId

    if extensionIds[extensionId] then
        error("LMION: extension already registered: " .. extensionId, 2)
    end

    local stored = TableUtils.deepCopy(extension)

    extensionIds[extensionId] = true
    extensions[#extensions + 1] = stored

    return extensionId
end


function Registry.getDefault(defaultId)
    return defaultsById[defaultId]
end


function Registry.getDefinition(definitionId)
    return definitionsById[definitionId]
end


function Registry.getDefaultIds()
    return TableUtils.deepCopy(defaultIds)
end


function Registry.getDefinitionIds()
    return TableUtils.deepCopy(definitionIds)
end


function Registry.getExtensions()
    return extensions
end


function Registry.getRegistrationStats()
    return {
        defaults = #defaultIds,
        definitions = #definitionIds,
        extensions = #extensions,
    }
end


return Registry
