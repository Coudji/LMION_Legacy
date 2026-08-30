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


function Diagnostics.logBootstrap(API)
    logStats(API, "built-in bootstrap complete")
end


function Diagnostics.logGameBoot(API)
    logStats(API, "OnGameBoot registry snapshot")

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
