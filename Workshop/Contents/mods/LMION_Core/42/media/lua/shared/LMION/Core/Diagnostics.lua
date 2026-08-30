local EntityIndex = require "LMION/Core/EntityIndex"
local GameEntityValidation = require "LMION/Core/GameEntityValidation"

local Diagnostics = {}


local function describeDefinition(definition)
    if definition.entity ~= nil then
        return definition.entity
    end

    local topology = definition.topology

    if type(topology) == "table" then
        if topology.left ~= nil and topology.right ~= nil then
            return tostring(topology.left) .. " + " .. tostring(topology.right)
        end

        if topology.type ~= nil then
            return "topology=" .. tostring(topology.type)
        end
    end

    return "no entity mapping yet"
end


local function logStats(API, label)
    local stats = API.getRegistrationStats()

    print(
        "[LMION:Core] "
            .. label
            .. ": "
            .. tostring(stats.defaults)
            .. " defaults, "
            .. tostring(stats.definitions)
            .. " definitions, "
            .. tostring(stats.extensions)
            .. " extensions"
    )
end


local function logEntityIndex()
    local stats = EntityIndex.rebuild()

    print(
        "[LMION:Core] GameEntity index ready: "
            .. tostring(stats.entities)
            .. " entities -> "
            .. tostring(stats.definitions)
            .. " definitions"
    )
end


local function logGameEntityValidation()
    local result = GameEntityValidation.validate()

    if not result.available then
        print(
            "[LMION:Core] ERROR: PZ GameEntity validation unavailable: "
                .. tostring(result.error)
        )
        return
    end

    print(
        "[LMION:Core] PZ GameEntity validation: "
            .. tostring(result.found)
            .. "/"
            .. tostring(result.total)
            .. " found"
    )

    for index = 1, #result.missing do
        local missing = result.missing[index]

        print(
            "[LMION:Core] ERROR: missing GameEntity "
                .. missing.entityId
                .. " referenced by "
                .. missing.definitionId
        )
    end
end


function Diagnostics.logBootstrap(API)
    logStats(API, "built-in bootstrap complete")
end


function Diagnostics.logGameBoot(API)
    logStats(API, "OnGameBoot registry snapshot")
    logEntityIndex()
    logGameEntityValidation()

    local definitionIds = API.getRegisteredDefinitionIds()

    for index = 1, #definitionIds do
        local definitionId = definitionIds[index]
        local definition = API.getEffectiveDefinition(definitionId)

        print(
            "[LMION:Catalog] "
                .. definitionId
                .. " -> "
                .. describeDefinition(definition)
        )
    end
end


return Diagnostics
