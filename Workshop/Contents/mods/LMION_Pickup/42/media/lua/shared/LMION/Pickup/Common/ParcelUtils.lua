local ParcelUtils = {}


function ParcelUtils.getSource(item)
    if item == nil then
        return nil
    end

    local worldItem = item.getWorldItem ~= nil and item:getWorldItem() or nil
    if worldItem ~= nil and worldItem:getSquare() ~= nil then
        return "floor"
    end

    local container = item.getContainer ~= nil and item:getContainer() or nil
    if container ~= nil then
        return container
    end

    return nil
end


function ParcelUtils.consume(item, source)
    if item == nil then
        return false
    end

    source = ParcelUtils.getSource(item) or source
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
