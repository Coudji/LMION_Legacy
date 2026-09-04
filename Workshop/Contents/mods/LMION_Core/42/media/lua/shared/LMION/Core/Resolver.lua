local DoorTypes = require "LMION/Core/DoorTypes"
local Registry = require "LMION/Core/Registry"
local TableUtils = require "LMION/Core/TableUtils"

local Resolver = {}


local function applyExtensions(targetType, targetId, target)
    local extensions = Registry.getExtensions()

    for index = 1, #extensions do
        local extension = extensions[index]

        if extension.target.type == targetType
            and extension.target.id == targetId
        then
            TableUtils.deepMerge(target, extension.patch)
        end
    end

    return target
end


local function applyDoorTypeCharacteristics(target)
    if type(target) ~= "table" then
        return target
    end

    local frame = DoorTypes.getFrame(target.doorType)
    if frame ~= nil then
        target.frame = frame
    end

    return target
end


function Resolver.resolveDefault(defaultId)
    local rawDefault = Registry.getDefault(defaultId)

    if rawDefault == nil then
        error("LMION: unknown definition default: " .. tostring(defaultId), 2)
    end

    local effectiveDefault = TableUtils.deepCopy(rawDefault)

    applyExtensions(
        "default",
        defaultId,
        effectiveDefault.defaults
    )
    applyDoorTypeCharacteristics(effectiveDefault.defaults)

    return effectiveDefault
end


function Resolver.resolveDefinition(definitionId)
    local rawDefinition = Registry.getDefinition(definitionId)

    if rawDefinition == nil then
        error("LMION: unknown definition: " .. tostring(definitionId), 2)
    end

    local effectiveDefinition = {}

    if rawDefinition.inherits ~= nil then
        local inheritedDefault = Registry.getDefault(rawDefinition.inherits)

        if inheritedDefault == nil then
            error(
                "LMION: definition "
                    .. definitionId
                    .. " inherits unknown definition default "
                    .. rawDefinition.inherits,
                2
            )
        end

        local effectiveDefault = Resolver.resolveDefault(rawDefinition.inherits)

        TableUtils.deepMerge(
            effectiveDefinition,
            effectiveDefault.defaults
        )
    end

    TableUtils.deepMerge(effectiveDefinition, rawDefinition)

    applyExtensions(
        "definition",
        definitionId,
        effectiveDefinition
    )
    applyDoorTypeCharacteristics(effectiveDefinition)

    return effectiveDefinition
end


return Resolver
