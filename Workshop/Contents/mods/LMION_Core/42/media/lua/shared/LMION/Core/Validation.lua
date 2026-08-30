local Validation = {}

local RESERVED_EXTENSION_FIELDS = {
    id = true,
    defaultId = true,
    definitionId = true,
    extensionId = true,
    inherits = true,
}


local function fail(message)
    error("LMION: " .. message, 3)
end


local function requireTable(value, label)
    if type(value) ~= "table" then
        fail(label .. " must be a table")
    end
end


local function requireStringField(value, field, label)
    local fieldValue = value[field]

    if type(fieldValue) ~= "string" or fieldValue == "" then
        fail(label .. " is missing a valid " .. field)
    end

    return fieldValue
end


local function rejectLegacyId(value, label)
    if value.id ~= nil then
        fail(label .. " must use its explicit identity field instead of id")
    end
end


function Validation.definitionDefault(value)
    requireTable(value, "definition default")
    rejectLegacyId(value, "definition default")

    requireStringField(value, "defaultId", "definition default")
    requireTable(value.defaults, "definition default defaults")

    if value.definitionId ~= nil then
        fail("definition default must use defaultId, not definitionId")
    end

    if value.inherits ~= nil then
        fail("definition defaults cannot inherit from another definition default")
    end

    return value
end


function Validation.definition(value)
    requireTable(value, "definition")
    rejectLegacyId(value, "definition")

    requireStringField(value, "definitionId", "definition")

    if value.defaultId ~= nil then
        fail("definition must use definitionId, not defaultId")
    end

    if value.inherits ~= nil
        and (type(value.inherits) ~= "string" or value.inherits == "")
    then
        fail("definition inherits must be a non-empty defaultId")
    end

    return value
end


function Validation.extension(value)
    requireTable(value, "extension")
    rejectLegacyId(value, "extension")

    requireStringField(value, "extensionId", "extension")
    requireTable(value.target, "extension target")
    requireStringField(value.target, "id", "extension target")
    requireTable(value.patch, "extension patch")

    if value.priority ~= nil then
        fail("extensions do not support priority; load order decides conflicts")
    end

    if value.target.type ~= "default" and value.target.type ~= "definition" then
        fail("extension target.type must be 'default' or 'definition'")
    end

    for field in pairs(RESERVED_EXTENSION_FIELDS) do
        if value.patch[field] ~= nil then
            fail("extension patch cannot replace reserved field " .. field)
        end
    end

    return value
end


function Validation.content(value)
    requireTable(value, "content")

    if value.defaults ~= nil then
        requireTable(value.defaults, "content defaults")
    end

    if value.definitions ~= nil then
        requireTable(value.definitions, "content definitions")
    end

    if value.extensions ~= nil then
        requireTable(value.extensions, "content extensions")
    end

    return value
end


return Validation
