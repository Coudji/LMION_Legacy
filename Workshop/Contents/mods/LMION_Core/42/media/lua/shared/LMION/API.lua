local DoorRuntime = require "LMION/Core/DoorRuntime"
local EntityIndex = require "LMION/Core/EntityIndex"
local GaragePolicy = require "LMION/Core/GaragePolicy"
local GarageRuntime = require "LMION/Core/GarageRuntime"
local GarageTopology = require "LMION/Core/GarageTopology"
local LargeGateRuntime = require "LMION/Core/LargeGateRuntime"
local LargeGateTopology = require "LMION/Core/LargeGateTopology"
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


local function invalidateIndexes()
    EntityIndex.invalidate()
    GarageRuntime.invalidate()
end


function API.registerDefault(definitionDefault)
    Validation.definitionDefault(definitionDefault)

    local defaultId = Registry.registerDefault(definitionDefault)
    invalidateIndexes()

    return defaultId
end


function API.registerDefinition(definition)
    Validation.definition(definition)

    local definitionId = Registry.registerDefinition(definition)
    invalidateIndexes()

    return definitionId
end


function API.registerExtension(extension)
    Validation.extension(extension)

    local extensionId = Registry.registerExtension(extension)
    invalidateIndexes()

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


function API.getLargeGateTopology()
    return LargeGateTopology.get()
end


function API.getGarageTopology()
    return GarageTopology.get()
end


function API.getGarageMaxLength()
    return GaragePolicy.getMaxLength()
end


function API.isGarageLengthAllowed(length)
    return GaragePolicy.isLengthAllowed(length)
end


function API.getGarageSegmentBySprite(spriteName)
    return GarageRuntime.getSegmentBySprite(spriteName)
end


function API.getGarageSegmentForObject(object)
    return GarageRuntime.getSegmentForObject(object)
end


function API.getGarageChain(object)
    return GarageRuntime.getChain(object)
end


function API.isDoorObject(object)
    return DoorRuntime.isDoorObject(object)
end


function API.captureDoorState(object)
    return DoorRuntime.captureState(object)
end


function API.restoreDoorState(object, state)
    return DoorRuntime.restoreState(object, state)
end


function API.canPlaceDoorAt(square, facing, frame, pairedFrameSide)
    return DoorRuntime.canPlaceAt(
        square,
        facing,
        frame,
        pairedFrameSide
    )
end


function API.finalizePlacedDoor(object, definition, facing, member)
    return DoorRuntime.finalizePlacedDoor(
        object,
        definition,
        facing,
        member
    )
end


function API.finalizePlacedLargeGatePart(
    object,
    definition,
    facing,
    leaf,
    partIndex,
    isOpen
)
    return LargeGateRuntime.finalizePart(
        object,
        definition,
        facing,
        leaf,
        partIndex,
        isOpen
    )
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
