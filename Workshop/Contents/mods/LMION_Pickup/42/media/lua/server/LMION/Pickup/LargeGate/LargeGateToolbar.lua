require "BuildingObjects/ISMoveableCursor"
require "Moveables/ISMoveablesAction"
require "Moveables/ISMoveableSpriteProps"

local LargeGatePickup = require "LMION/Pickup/LargeGate/LargeGatePickup"
local LargeGatePlacement = require "LMION/Pickup/LargeGate/LargeGatePlacement"
local PlacementActionUtils = require "LMION/Pickup/Common/PlacementActionUtils"


local function getIdentity(item)
    return item and LargeGatePickup.getParcelIdentity(item) or nil
end


local function getFacing(moveProps, fallback)
    return PlacementActionUtils.resolveFacing(
        moveProps,
        "lmionLargeGateFacing",
        fallback
    )
end


local function itemMatchesMoveProps(item, moveProps)
    local identity = getIdentity(item)

    return identity ~= nil
        and identity.definitionId == moveProps.lmionLargeGateDefinitionId
        and identity.leaf == moveProps.lmionLargeGateLeaf
        and identity.partIndex == moveProps.lmionLargeGatePart
end


local function findRepresentativeParcel(character, moveProps)
    local inventory = character and character:getInventory() or nil
    local items = inventory and inventory:getItems() or nil
    if items == nil or moveProps == nil then
        return nil
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if itemMatchesMoveProps(item, moveProps) then
            return item
        end
    end

    return nil
end


local function appendToolbarEntry(objects, item, seenLeaves)
    local identity = getIdentity(item)
    if identity == nil or identity.partIndex ~= 1 then
        return
    end

    local key = identity.definitionId .. "\0" .. identity.leaf
    if seenLeaves[key] then
        return
    end

    local moveProps = LargeGatePlacement.getMoveProps(item, "N")
    if moveProps == nil or not moveProps.isMoveable then
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


local function installFindInInventoryHook()
    local previous = ISMoveableSpriteProps.findInInventory

    ISMoveableSpriteProps.findInInventory = function(self, character, spriteName)
        if self.lmionLargeGateDefinitionId ~= nil then
            return findRepresentativeParcel(character, self)
        end

        return previous(self, character, spriteName)
    end
end


local function createToolbarAction(
    actionClass,
    character,
    square,
    mode,
    object,
    direction,
    item,
    moveCursor
)
    if mode ~= "place" or getIdentity(item) == nil then
        return nil
    end

    local facing = PlacementActionUtils.resolveToolbarFacing(
        direction,
        moveCursor,
        "lmionLargeGateFacing"
    )
    local moveProps = LargeGatePlacement.getMoveProps(item, facing)
    if moveProps == nil then
        return nil
    end

    return PlacementActionUtils.configureToolbar(
        ISBaseTimedAction.new(actionClass, character),
        character,
        square,
        mode,
        object,
        item,
        moveCursor,
        facing,
        moveProps,
        "lmionLargeGateFacing"
    )
end


local function installActionNewHook()
    local previous = ISMoveablesAction.new

    ISMoveablesAction.new = function(
        self,
        character,
        square,
        mode,
        origSpriteName,
        object,
        direction,
        item,
        moveCursor
    )
        local action = createToolbarAction(
            self,
            character,
            square,
            mode,
            object,
            direction,
            item,
            moveCursor
        )

        if action ~= nil then
            return action
        end

        return previous(
            self,
            character,
            square,
            mode,
            origSpriteName,
            object,
            direction,
            item,
            moveCursor
        )
    end
end


local function completeToolbarPlacement(action)
    local facing = getFacing(
        action.moveProps,
        action.lmionLargeGateFacing
    )

    return LargeGatePlacement.placeParcel(
        action.character,
        action.square,
        action.item,
        facing
    )
end


local function installActionCompleteHook()
    local previous = ISMoveablesAction.complete

    ISMoveablesAction.complete = function(self)
        if self.mode == "place" and getIdentity(self.item) ~= nil then
            return completeToolbarPlacement(self)
        end

        return previous(self)
    end
end


installInventoryListHook()
installFindInInventoryHook()
installActionNewHook()
installActionCompleteHook()

return LargeGatePlacement
