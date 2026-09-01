require "BuildingObjects/ISMoveableCursor"

local GaragePickup = require "LMION/Pickup/GaragePickup"
local GarageToolbarAdapter = require "LMION/Pickup/GarageToolbarAdapter"


local function getIdentity(item)
    return item and GaragePickup.getParcelIdentity(item) or nil
end


local function hasRole(character, definitionId, role)
    local inventory = character and character:getInventory() or nil
    local items = inventory and inventory:getItems() or nil

    if items == nil then
        return false
    end

    for index = 0, items:size() - 1 do
        local identity = getIdentity(items:get(index))

        if identity ~= nil
            and identity.definitionId == definitionId
            and identity.role == role
        then
            return true
        end
    end

    return false
end


local function hasCanonicalL3(character, definitionId)
    return hasRole(character, definitionId, "START")
        and hasRole(character, definitionId, "MIDDLE")
        and hasRole(character, definitionId, "END")
end


local function findStartParcel(character, definitionId)
    local inventory = character and character:getInventory() or nil
    local items = inventory and inventory:getItems() or nil

    if items == nil then
        return nil
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        local identity = getIdentity(item)

        if identity ~= nil
            and identity.definitionId == definitionId
            and identity.role == "START"
        then
            return item
        end
    end

    return nil
end


local previousGetInventoryObjectList = ISMoveableCursor.getInventoryObjectList

ISMoveableCursor.getInventoryObjectList = function(self)
    local objects = previousGetInventoryObjectList(self)
    local items = self.character:getInventory():getItems()
    local seen = {}

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        local identity = getIdentity(item)

        if identity ~= nil
            and identity.role == "START"
            and not seen[identity.definitionId]
            and hasCanonicalL3(self.character, identity.definitionId)
        then
            local representative = findStartParcel(
                self.character,
                identity.definitionId
            )
            local moveProps = representative
                and GarageToolbarAdapter.getMoveProps(representative, "N")
                or nil

            if moveProps ~= nil and moveProps.isMoveable then
                table.insert(objects, {
                    object = representative,
                    moveProps = moveProps,
                })
                seen[identity.definitionId] = true
            end
        end
    end

    return objects
end


return GarageToolbarAdapter
