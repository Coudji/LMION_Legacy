local LMION = require "LMION/API"
local DisplayName = require "LMION/Core/DisplayName"
local MoveableAdapter = require "LMION/Pickup/MoveableAdapter"
local GaragePickup = require "LMION/Pickup/GaragePickup"
local LargeGatePickup = require "LMION/Pickup/LargeGatePickup"

local ParcelPresentation = {}

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


local function getDefinitionName(definitionId)
    local definition = definitionId
        and LMION.getEffectiveDefinition(definitionId)
        or nil

    return definition and DisplayName.get(definition) or nil
end


local function getSimpleName(identity)
    local displayName = getDefinitionName(identity.definitionId)
    if displayName == nil then
        return nil
    end

    if identity.member == "left" then
        return displayName
            .. " - "
            .. getTextOrFallback("UI_LMION_Parcel_Left", "Left")
    end

    if identity.member == "right" then
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


local function getGarageName(identity)
    local displayName = getDefinitionName(identity.definitionId)
    local roleSpec = identity.role and GARAGE_ROLE_KEYS[identity.role] or nil

    if displayName == nil then
        return nil
    end

    if roleSpec == nil then
        return displayName
    end

    return displayName
        .. " - "
        .. getTextOrFallback(roleSpec[1], roleSpec[2])
end


local function getLargeGateName(identity)
    local displayName = getDefinitionName(identity.definitionId)
    local leaf = identity.leaf
    local partIndex = tonumber(identity.partIndex)

    if displayName == nil then
        return nil
    end

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


local function finalizeItem(item)
    if item == nil or type(item) == "boolean" then
        return item
    end

    local name = nil

    local identity = MoveableAdapter.getParcelIdentity(item)
    if identity ~= nil then
        name = getSimpleName(identity)
    else
        identity = GaragePickup.getParcelIdentity(item)
        if identity ~= nil then
            name = getGarageName(identity)
        else
            identity = LargeGatePickup.getParcelIdentity(item)
            if identity ~= nil then
                name = getLargeGateName(identity)
            end
        end
    end

    if name == nil then
        return item
    end

    item:setName(name)
    item:setCustomName(true)

    if isClient() and sendItemStats ~= nil then
        sendItemStats(item)
    end

    return item
end


local function finalizeResult(result)
    if type(result) ~= "table" then
        return finalizeItem(result)
    end

    -- Garage and large-gate pickup return one item per physical segment.
    -- Finalize them only after their complete specialized pickup path returns.
    for index = 1, #result do
        finalizeItem(result[index])
    end

    return result
end


function ParcelPresentation.install()
    if installed then
        return
    end

    require "Moveables/ISMoveableSpriteProps"

    -- The generic Moveables path can still rewrite item presentation after
    -- pickUpMoveableInternal() returns. Garage and LargeGate bypass that outer
    -- vanilla path, which is why their names already survived. Finalize parcel
    -- names at the outermost pickup boundary so every LMION family follows the
    -- same rule and no later pickup step can restore "Door" / "Gate".
    local previousPickUp = ISMoveableSpriteProps.pickUpMoveable
    ISMoveableSpriteProps.pickUpMoveable = function(
        self,
        character,
        square,
        createItem,
        forceAllow
    )
        return finalizeResult(
            previousPickUp(
                self,
                character,
                square,
                createItem,
                forceAllow
            )
        )
    end

    installed = true
end


return ParcelPresentation
