local DisplayName = {}

local TRANSLATION_PREFIX = "UI_LMION_Definition_"


local function getDefinitionAndId(value)
    if type(value) == "table" then
        local definitionId = value.definitionId
        if type(definitionId) == "string" and definitionId ~= "" then
            return value, definitionId
        end
        return value, nil
    end

    if type(value) == "string" and value ~= "" then
        return nil, value
    end

    return nil, nil
end


local function getTranslationKey(definition, definitionId)
    if definition ~= nil
        and type(definition.displayNameKey) == "string"
        and definition.displayNameKey ~= ""
    then
        return definition.displayNameKey
    end

    return TRANSLATION_PREFIX .. definitionId:gsub("[^%w]", "_")
end


local function getTranslatedName(key)
    if type(key) ~= "string" or key == "" then
        return nil
    end

    if getTextOrNull ~= nil then
        local value = getTextOrNull(key)
        if type(value) == "string" and value ~= "" then
            return value
        end
    end

    return nil
end


local function prettifyDefinitionId(definitionId)
    local token = definitionId:match("([^.]+)$") or definitionId
    token = token:gsub("_", " ")
    token = token:gsub("(%l)(%u)", "%1 %2")
    token = token:gsub("(%a)(%d)", "%1 %2")
    token = token:gsub("(%d)(%a)", "%1 %2")
    return token
end


function DisplayName.get(value)
    local definition, definitionId = getDefinitionAndId(value)
    if definitionId == nil then
        return nil
    end

    local translated = getTranslatedName(
        getTranslationKey(definition, definitionId)
    )
    if translated ~= nil then
        return translated
    end

    if definition ~= nil
        and type(definition.displayName) == "string"
        and definition.displayName ~= ""
    then
        return definition.displayName
    end

    return prettifyDefinitionId(definitionId)
end


function DisplayName.getTranslationKey(value)
    local definition, definitionId = getDefinitionAndId(value)
    if definitionId == nil then
        return nil
    end

    return getTranslationKey(definition, definitionId)
end


return DisplayName
