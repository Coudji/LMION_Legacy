local Registry = require "LMION/Core/Registry"
local Resolver = require "LMION/Core/Resolver"
local TableUtils = require "LMION/Core/TableUtils"

local EntityIndex = {}

local entityToDefinitionId = {}
local entityIds = {}
local mappedDefinitionCount = 0
local dirty = true


local function requireEntityId(entityId, definitionId, field)
    if type(entityId) ~= "string" or entityId == "" then
        error(
            "LMION: definition "
                .. tostring(definitionId)
                .. " has an invalid GameEntity in "
                .. tostring(field),
            3
        )
    end

    return entityId
end


local function addMapping(index, ids, definitionId, entityId, field)
    entityId = requireEntityId(entityId, definitionId, field)

    local existingDefinitionId = index[entityId]

    if existingDefinitionId ~= nil and existingDefinitionId ~= definitionId then
        error(
            "LMION: GameEntity "
                .. entityId
                .. " is claimed by both "
                .. existingDefinitionId
                .. " and "
                .. definitionId,
            3
        )
    end

    if existingDefinitionId == nil then
        index[entityId] = definitionId
        ids[#ids + 1] = entityId
    end
end


local function indexDefinition(index, ids, definitionId, definition)
    local before = #ids

    if definition.entity ~= nil then
        addMapping(index, ids, definitionId, definition.entity, "entity")
    end

    local topology = definition.topology

    if type(topology) == "table" then
        if topology.left ~= nil then
            addMapping(index, ids, definitionId, topology.left, "topology.left")
        end

        if topology.right ~= nil then
            addMapping(index, ids, definitionId, topology.right, "topology.right")
        end
    end

    return #ids > before
end


local function ensureBuilt()
    if dirty then
        EntityIndex.rebuild()
    end
end


function EntityIndex.invalidate()
    dirty = true
end


function EntityIndex.rebuild()
    local nextIndex = {}
    local nextEntityIds = {}
    local nextMappedDefinitionCount = 0
    local definitionIds = Registry.getDefinitionIds()

    for index = 1, #definitionIds do
        local definitionId = definitionIds[index]
        local definition = Resolver.resolveDefinition(definitionId)

        if indexDefinition(
            nextIndex,
            nextEntityIds,
            definitionId,
            definition
        ) then
            nextMappedDefinitionCount = nextMappedDefinitionCount + 1
        end
    end

    entityToDefinitionId = nextIndex
    entityIds = nextEntityIds
    mappedDefinitionCount = nextMappedDefinitionCount
    dirty = false

    return EntityIndex.getStats()
end


function EntityIndex.getDefinitionId(entityId)
    if type(entityId) ~= "string" or entityId == "" then
        error("LMION: entityId must be a non-empty string", 2)
    end

    ensureBuilt()

    return entityToDefinitionId[entityId]
end


function EntityIndex.getEntityIds()
    ensureBuilt()

    return TableUtils.deepCopy(entityIds)
end


function EntityIndex.getStats()
    ensureBuilt()

    return {
        entities = #entityIds,
        definitions = mappedDefinitionCount,
    }
end


return EntityIndex
