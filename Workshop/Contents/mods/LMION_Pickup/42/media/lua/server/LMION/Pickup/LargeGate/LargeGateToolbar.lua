require "BuildingObjects/ISMoveableCursor"
require "Moveables/ISMoveableSpriteProps"

local LargeGatePickup = require "LMION/Pickup/LargeGate/LargeGatePickup"
local ParcelUtils = require "LMION/Pickup/Common/ParcelUtils"


local function getIdentity(item)
    return item and LargeGatePickup.getParcelIdentity(item) or nil
end


local function findParcel(character, definitionId, leaf, partIndex, preferred)
    return ParcelUtils.findNearbyItem(
        character,
        function(item)
            local identity = getIdentity(item)

            return identity ~= nil
                and identity.definitionId == definitionId
                and identity.leaf == leaf
                and identity.partIndex == partIndex
        end,
        preferred
    )
end


local function getLeafAnchorMoveProps(item, facing)
    local identity = getIdentity(item)
    if identity == nil then
        return nil
    end

    facing = facing == "W" and "W" or "N"

    local spriteName = LargeGatePickup.getPartSprite(
        identity.definitionId,
        facing,
        identity.leaf,
        1,
        false
    )
    local moveProps = spriteName and ISMoveableSpriteProps.new(spriteName) or nil

    if moveProps == nil or not moveProps.isMoveable then
        return nil
    end

    return moveProps
end


local function getRequestedPart(requestedName)
    local partIndex = tonumber(
        string.match(requestedName or "", "%((%d+)/2%)$")
    )

    if partIndex == 1 or partIndex == 2 then
        return partIndex
    end

    return nil
end


local function appendToolbarEntry(objects, item, seenLeaves)
    local identity = getIdentity(item)
    if identity == nil then
        return
    end

    local key = identity.definitionId .. "\0" .. identity.leaf
    if seenLeaves[key] then
        return
    end

    -- The toolbar represents a leaf, not the parcel currently carried.
    -- Part 1 is the vanilla SpriteGrid anchor for both N and W faces.
    local moveProps = getLeafAnchorMoveProps(item, "N")
    if moveProps == nil then
        return
    end

    objects[#objects + 1] = {
        object = item,
        moveProps = moveProps,
    }
    seenLeaves[key] = true
end


local function appendToolbarEntries(cursor, objects)
    local inventory = cursor.character and cursor.character:getInventory() or nil
    local items = inventory and inventory:getItems() or nil
    if items == nil then
        return objects
    end

    local seenLeaves = {}
    for index = 0, items:size() - 1 do
        appendToolbarEntry(objects, items:get(index), seenLeaves)
    end

    return objects
end


local function installInventoryListHook()
    local previous = ISMoveableCursor.getInventoryObjectList

    ISMoveableCursor.getInventoryObjectList = function(self)
        return appendToolbarEntries(self, previous(self))
    end
end


local function installInventoryLookupHooks()
    local previousFind = ISMoveableSpriteProps.findInInventory

    ISMoveableSpriteProps.findInInventory = function(self, character, spriteName)
        if self.lmionLargeGateDefinitionId ~= nil then
            local segment = spriteName and LargeGatePickup.getSegment(spriteName) or nil

            if segment ~= nil
                and segment.definitionId == self.lmionLargeGateDefinitionId
                and segment.leaf == self.lmionLargeGateLeaf
            then
                return findParcel(
                    character,
                    segment.definitionId,
                    segment.leaf,
                    segment.partIndex,
                    nil
                )
            end

            return findParcel(
                character,
                self.lmionLargeGateDefinitionId,
                self.lmionLargeGateLeaf,
                self.lmionLargeGatePart,
                nil
            )
        end

        return previousFind(self, character, spriteName)
    end

    local previousFindMulti = ISMoveableSpriteProps.findInInventoryMultiSprite

    ISMoveableSpriteProps.findInInventoryMultiSprite = function(
        self,
        character,
        requestedName
    )
        if self.lmionLargeGateDefinitionId ~= nil then
            local partIndex = getRequestedPart(requestedName)
            if partIndex == nil then
                return nil
            end

            return findParcel(
                character,
                self.lmionLargeGateDefinitionId,
                self.lmionLargeGateLeaf,
                partIndex,
                nil
            )
        end

        return previousFindMulti(self, character, requestedName)
    end
end


installInventoryListHook()
installInventoryLookupHooks()

return true
