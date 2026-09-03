local MultiSquarePickupInternal = {}

local function isSupportedDoorSegment(moveProps, object, square)
    return moveProps ~= nil
        and object ~= nil
        and square ~= nil
        and moveProps.type == "Object"
        and moveProps.canBreak == false
        and instanceof(object, "IsoDoor")
        and object:getSquare() == square
        and object:isObjectNoContainerOrEmpty()
end

function MultiSquarePickupInternal.pickUpDoorSegment(
    moveProps,
    character,
    square,
    object,
    spriteName,
    createItem
)
    if not isSupportedDoorSegment(moveProps, object, square) then
        return nil, false
    end

    local item = moveProps:instanceItem(spriteName)
    if item == nil then
        return nil, true
    end

    -- GameEntityFactory.TransferComponents() explicitly refuses multi-square
    -- SpriteConfigs and only emits a WARN. LMION persists the transport state
    -- itself, so skip that unsupported vanilla step while keeping the useful
    -- Moveables pickup sequence for this tightly-scoped IsoDoor segment case.
    if createItem then
        if moveProps.isMultiSprite then
            square:AddWorldInventoryItem(
                item,
                ZombRandFloat(0.1, 0.9),
                ZombRandFloat(0.1, 0.9),
                0
            )
        else
            character:getInventory():AddItem(item)
            sendAddItemToContainer(character:getInventory(), item)
        end
    end

    triggerEvent("OnObjectAboutToBeRemoved", object)
    square:transmitRemoveItemFromSquare(object)
    square:RecalcProperties()
    square:RecalcAllWithNeighbours(true)

    triggerEvent("OnContainerUpdate")
    IsoGenerator.updateGenerator(square)

    return item, true
end

return MultiSquarePickupInternal
