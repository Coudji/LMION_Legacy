local LargeGatePickup = require "LMION/Pickup/LargeGatePickup"

local ParcelPresentation = {}

local installed = false


local function applyVanillaFlatpack(item)
    local identity = LargeGatePickup.getParcelIdentity(item)
    local state = identity and identity.state or nil
    local spriteName = state and state.spriteName or nil

    if item == nil
        or type(spriteName) ~= "string"
        or spriteName == ""
        or item.ReadFromWorldSprite == nil
    then
        return item
    end

    -- Keep the same ordering as vanilla/Legacy ISMoveableSpriteProps:instanceItem():
    -- ReadFromWorldSprite() must run before TransferComponents() and before the
    -- IsoWorldInventoryObject is created. For SpriteGrid members Java applies
    -- Item_Flatpack + modData.Flatpack, which also selects the Flatpack ground
    -- model through InventoryItem:getWorldStaticItem().
    item:ReadFromWorldSprite(spriteName)
    return item
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

    -- Vanilla component transfer may rewrite presentation fields. LMION owns
    -- the transported opening name and balance values, so restore them last.
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

    -- LargeGatePickup installs its instanceItem() wrapper first. Wrap that
    -- result here so the LMION transport identity already exists when we ask
    -- vanilla Moveable to derive its Flatpack presentation.
    local previousInstanceItem = ISMoveableSpriteProps.instanceItem
    ISMoveableSpriteProps.instanceItem = function(self, spriteNameOverride)
        return applyVanillaFlatpack(
            previousInstanceItem(self, spriteNameOverride)
        )
    end

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
