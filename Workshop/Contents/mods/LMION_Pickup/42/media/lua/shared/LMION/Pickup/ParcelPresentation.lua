local LargeGatePickup = require "LMION/Pickup/LargeGatePickup"

local ParcelPresentation = {}

local installed = false


local function applyVanillaFlatpack(item, identity)
    local state = identity and identity.state or nil
    local spriteName = state and state.spriteName or nil

    if item == nil
        or type(spriteName) ~= "string"
        or spriteName == ""
        or item.ReadFromWorldSprite == nil
    then
        return
    end

    -- Vanilla Moveable.ReadFromWorldSprite() detects SpriteGrid members and
    -- applies the standard furniture flatpack presentation (Item_Flatpack,
    -- tint and Flatpack modData). Legacy Large Gate parcels relied on this
    -- exact path too; keep LMION transport semantics separate from visuals.
    item:ReadFromWorldSprite(spriteName)
end


local function finalize(item)
    local identity = LargeGatePickup.getParcelIdentity(item)
    if identity == nil then
        return item
    end

    local runtime = LargeGatePickup.getRuntime(identity.definitionId)
    if runtime == nil then
        return item
    end

    applyVanillaFlatpack(item, identity)

    -- ReadFromWorldSprite() deliberately rewrites vanilla Moveable
    -- presentation fields. LMION owns the transported opening identity and
    -- balance values, so restore those afterwards.
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
