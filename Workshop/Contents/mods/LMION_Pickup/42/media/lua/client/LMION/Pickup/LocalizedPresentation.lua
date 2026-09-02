require "Moveables/ISMoveableSpriteProps"

local LMION = require "LMION/API"
local DisplayName = require "LMION/Core/DisplayName"

local installed = false


local function getTextOrFallback(key, fallback)
    if getTextOrNull ~= nil then
        local value = getTextOrNull(key)
        if type(value) == "string" and value ~= "" then
            return value
        end
    end

    return fallback
end


local function getDefinitionId(moveProps)
    if moveProps == nil then
        return nil
    end

    return moveProps.lmionDefinitionId
        or moveProps.lmionGarageDefinitionId
        or moveProps.lmionLargeGateDefinitionId
end


local function getDisplayName(moveProps)
    local definitionId = getDefinitionId(moveProps)
    if type(definitionId) ~= "string" or definitionId == "" then
        return nil
    end

    local definition = LMION.getEffectiveDefinition(definitionId)
    return definition and DisplayName.get(definition) or nil
end


local function getMoveableName(moveProps, displayName)
    if moveProps.lmionGarageDefinitionId ~= nil
        or moveProps.lmionLargeGateDefinitionId ~= nil
    then
        return displayName
    end

    if moveProps.lmionMember == "left" then
        return displayName
            .. " - "
            .. getTextOrFallback("UI_LMION_Parcel_Left", "Left")
    end

    if moveProps.lmionMember == "right" then
        return displayName
            .. " - "
            .. getTextOrFallback("UI_LMION_Parcel_Right", "Right")
    end

    return displayName
end


local function applyMoveableName(moveProps)
    local displayName = getDisplayName(moveProps)
    if displayName ~= nil then
        moveProps.name = getMoveableName(moveProps, displayName)
    end

    return moveProps
end


local function install()
    if installed then
        return
    end

    local previousNew = ISMoveableSpriteProps.new
    ISMoveableSpriteProps.new = function(sprite)
        return applyMoveableName(previousNew(sprite))
    end

    installed = true
    print("[LMION:Pickup] localized moveable names installed")
end


Events.OnGameStart.Add(install)
