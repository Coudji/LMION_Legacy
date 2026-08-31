local LargeGatePickup = require "LMION/Pickup/LargeGatePickup"

local ParcelPresentation = {}

local installed = false


local function finalize(item)
    local identity = LargeGatePickup.getParcelIdentity(item)
    if identity == nil then
        return item
    end

    local runtime = LargeGatePickup.getRuntime(identity.definitionId)
    if runtime == nil then
        return item
    end

    -- Vanilla/Legacy instanceItem() owns the Moveable/flatpack presentation.
    -- Component transfer may still rewrite LMION-owned display/balance fields,
    -- so restore only those after pickup completes.
    item:setActualWeight(runtime.weight)
    item:setWeight(runtime.weight)
    item:setName(
        runtime.displayName
            .. " "
            .. tostring(identity.leaf)
            .. " ("
            .. tostring(identity.partIndex)
            .. "/2)"
    )
    item:setCustomName(true)

    if isClient() and sendItemStats ~= nil then
        sendItemStats(item)
    end

    return item
end


function ParcelPresentation.install()
    if installed then
        return
    end

    require "Moveables/ISMoveableSpriteProps"

    local previousInternal = ISMoveableSpriteProps.pickUpMoveableInternal
    ISMoveableSpriteProps.pickUpMoveableInternal = function(
        self,
        character,
        square,
        object,
        sprInstance,
        spriteName,
        createItem,
        rotating
    )
        local item = previousInternal(
            self,
            character,
            square,
            object,
            sprInstance,
            spriteName,
            createItem,
            rotating
        )

        return finalize(item)
    end

    installed = true
end


return ParcelPresentation
