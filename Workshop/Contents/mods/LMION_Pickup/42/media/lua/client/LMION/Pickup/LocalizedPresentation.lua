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


local function getGenericParcelName(moveProps, displayName)
    local member = moveProps and moveProps.lmionMember or nil

    if member == "left" then
        return displayName
            .. " - "
            .. getTextOrFallback("UI_LMION_Parcel_Left", "Left")
    end

    if member == "right" then
        return displayName
            .. " - "
            .. getTextOrFallback("UI_LMION_Parcel_Right", "Right")
    end

    return displayName
end


local GARAGE_ROLE_KEYS = {
    START = { "UI_LMION_Parcel_Start", "Start" },
    MIDDLE = { "UI_LMION_Parcel_Middle", "Middle" },
    END = { "UI_LMION_Parcel_End", "End" },
}


local function getGarageParcelName(moveProps, displayName)
    local role = moveProps and moveProps.lmionGarageRole or nil
    local roleSpec = role and GARAGE_ROLE_KEYS[role] or nil

    if roleSpec == nil then
        return displayName
    end

    return displayName
        .. " - "
        .. getTextOrFallback(roleSpec[1], roleSpec[2])
end


local function getLargeGateParcelName(moveProps, displayName)
    local leaf = moveProps and moveProps.lmionLargeGateLeaf or nil
    local partIndex = moveProps and tonumber(moveProps.lmionLargeGatePart) or nil

    if (leaf ~= "A" and leaf ~= "B") or partIndex == nil then
        return displayName
    end

    return displayName
        .. " "
        .. leaf
        .. " ("
        .. tostring(partIndex)
        .. "/2)"
end


local function getParcelName(moveProps, displayName)
    if moveProps.lmionGarageDefinitionId ~= nil then
        return getGarageParcelName(moveProps, displayName)
    end

    if moveProps.lmionLargeGateDefinitionId ~= nil then
        return getLargeGateParcelName(moveProps, displayName)
    end

    return getGenericParcelName(moveProps, displayName)
end


local function applyMoveableName(moveProps)
    local displayName = getDisplayName(moveProps)
    if displayName ~= nil then
        moveProps.name = displayName
    end

    return moveProps
end


local function applyParcelName(moveProps, item)
    if item == nil then
        return item
    end

    local displayName = getDisplayName(moveProps)
    if displayName == nil then
        return item
    end

    item:setName(getParcelName(moveProps, displayName))
    item:setCustomName(true)
    return item
end


local function install()
    if installed then
        return
    end

    local previousNew = ISMoveableSpriteProps.new
    ISMoveableSpriteProps.new = function(sprite)
        return applyMoveableName(previousNew(sprite))
    end

    local previousInstanceItem = ISMoveableSpriteProps.instanceItem
    ISMoveableSpriteProps.instanceItem = function(self, spriteNameOverride)
        return applyParcelName(
            self,
            previousInstanceItem(self, spriteNameOverride)
        )
    end

    installed = true
    print("[LMION:Pickup] localized moveable names installed")
end


Events.OnGameStart.Add(install)
