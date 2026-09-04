local ParcelUtils = {}


function ParcelUtils.getSource(item)
    if item == nil then
        return nil
    end

    local container = item.getContainer ~= nil and item:getContainer() or nil
    if container ~= nil then
        return container
    end

    local worldItem = item.getWorldItem ~= nil and item:getWorldItem() or nil
    if worldItem ~= nil and worldItem:getSquare() ~= nil then
        return "floor"
    end

    return nil
end


function ParcelUtils.findNearbyItem(character, matches, preferred)
    if character == nil or type(matches) ~= "function" then
        return nil, nil
    end

    if preferred ~= nil and matches(preferred) then
        local source = ParcelUtils.getSource(preferred)
        if source ~= nil then
            return preferred, source
        end
    end

    local inventory = character:getInventory()
    local items = inventory and inventory:getItems() or nil

    if items ~= nil then
        for index = 0, items:size() - 1 do
            local item = items:get(index)
            if matches(item) then
                return item, inventory
            end
        end
    end

    local playerSquare = character:getSquare()
    if playerSquare == nil then
        return nil, nil
    end

    local radius = ISMoveableSpriteProps.multiSpriteFloorRadius or 3
    local z = playerSquare:getZ()

    for x = playerSquare:getX() - radius, playerSquare:getX() + radius do
        for y = playerSquare:getY() - radius, playerSquare:getY() + radius do
            local square = getCell():getGridSquare(x, y, z)
            local worldObjects = square and square:getWorldObjects() or nil

            if worldObjects ~= nil then
                for index = 0, worldObjects:size() - 1 do
                    local worldObject = worldObjects:get(index)
                    if instanceof(worldObject, "IsoWorldInventoryObject") then
                        local item = worldObject:getItem()
                        if matches(item) then
                            return item, "floor"
                        end
                    end
                end
            end
        end
    end

    return nil, nil
end


function ParcelUtils.consume(item, source)
    if item == nil then
        return false
    end

    source = source or ParcelUtils.getSource(item)
    if source == nil then
        return false
    end

    if source == "floor" then
        local worldItem = item.getWorldItem ~= nil and item:getWorldItem() or nil
        local square = worldItem and worldItem:getSquare() or nil

        if worldItem == nil or square == nil then
            return false
        end

        square:transmitRemoveItemFromSquare(worldItem)
        square:removeWorldObject(worldItem)
        item:setWorldItem(nil)
        return true
    end

    source:Remove(item)
    sendRemoveItemFromContainer(source, item)
    return true
end


return ParcelUtils
