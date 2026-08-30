LMION.Openings = LMION.Openings or {}
local Openings = LMION.Openings

Openings.Definitions = Openings.Definitions or {}
Openings.Extensions = Openings.Extensions or {}
Openings.Aliases = Openings.Aliases or {}

local function copyValue(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, child in pairs(value) do
        copy[copyValue(key)] = copyValue(child)
    end
    return copy
end

local function mergeInto(target, patch)
    for key, value in pairs(patch or {}) do
        if type(value) == "table" and type(target[key]) == "table" then
            mergeInto(target[key], value)
        else
            target[key] = copyValue(value)
        end
    end
end

local function rebuildAliases()
    local aliases = {}

    local function addAlias(alias, targetId)
        if type(alias) ~= "string" or alias == "" then
            return
        end

        local existing = aliases[alias]
        if existing ~= nil and existing ~= targetId then
            LMION.warn(
                "Openings",
                "alias '" .. alias .. "' already resolves to '" .. existing
                    .. "'; ignoring conflicting target '" .. targetId .. "'"
            )
            return
        end

        aliases[alias] = targetId
    end

    for id, definition in pairs(Openings.Definitions) do
        addAlias(id, id)
        for _, alias in ipairs(definition.aliases or {}) do
            addAlias(alias, id)
        end
    end

    for targetId, byId in pairs(Openings.Extensions) do
        for _, extension in pairs(byId) do
            for _, alias in ipairs(extension.aliases or {}) do
                addAlias(alias, targetId)
            end
        end
    end

    Openings.Aliases = aliases
end

local function orderedExtensions(targetId)
    local result = {}
    local byId = Openings.Extensions[targetId]

    if byId == nil then
        return result
    end

    for _, extension in pairs(byId) do
        result[#result + 1] = extension
    end

    table.sort(result, function(a, b)
        if a.priority == b.priority then
            return a.id < b.id
        end
        return a.priority < b.priority
    end)

    return result
end

function Openings.registerDefinition(id, definition)
    if type(id) ~= "string" or id == "" then
        LMION.error("Openings", "registerDefinition(): invalid id")
        return false
    end

    if type(definition) ~= "table" then
        LMION.error("Openings", "registerDefinition('" .. id .. "'): definition must be a table")
        return false
    end

    local stored = copyValue(definition)
    stored.id = id
    stored.aliases = stored.aliases or {}
    Openings.Definitions[id] = stored
    rebuildAliases()
    return true
end

function Openings.registerExtension(targetId, extensionId, extension)
    if type(targetId) ~= "string" or Openings.Definitions[targetId] == nil then
        LMION.error("Openings", "registerExtension(): unknown target '" .. tostring(targetId) .. "'")
        return false
    end

    if type(extensionId) ~= "string" or extensionId == "" then
        LMION.error("Openings", "registerExtension('" .. targetId .. "'): invalid extension id")
        return false
    end

    if type(extension) ~= "table" or type(extension.values) ~= "table" then
        LMION.error(
            "Openings",
            "registerExtension('" .. targetId .. "', '" .. extensionId .. "'): values must be a table"
        )
        return false
    end

    local stored = {
        id = extensionId,
        source = extension.source or "<unknown>",
        priority = tonumber(extension.priority) or 0,
        aliases = copyValue(extension.aliases or {}),
        values = copyValue(extension.values),
    }

    Openings.Extensions[targetId] = Openings.Extensions[targetId] or {}
    Openings.Extensions[targetId][extensionId] = stored
    rebuildAliases()

    LMION.log(
        "Openings",
        "registered extension '" .. extensionId .. "' from " .. tostring(stored.source)
            .. " for " .. targetId
    )
    return true
end

function Openings.resolveId(id)
    if type(id) ~= "string" or id == "" then
        return nil
    end
    return Openings.Aliases[id]
end

function Openings.getBaseDefinition(id)
    local resolved = Openings.resolveId(id)
    local definition = resolved and Openings.Definitions[resolved] or nil
    return definition and copyValue(definition) or nil
end

function Openings.getExtensions(id)
    local resolved = Openings.resolveId(id)
    if resolved == nil then
        return {}
    end
    return copyValue(orderedExtensions(resolved))
end

function Openings.getEffectiveDefinition(id)
    local resolved = Openings.resolveId(id)
    local base = resolved and Openings.Definitions[resolved] or nil
    if base == nil then
        return nil
    end

    local effective = copyValue(base)
    for _, extension in ipairs(orderedExtensions(resolved)) do
        mergeInto(effective, extension.values)
    end
    return effective
end

require "LMION/OpeningDefinitions/LargeGates"

return Openings
