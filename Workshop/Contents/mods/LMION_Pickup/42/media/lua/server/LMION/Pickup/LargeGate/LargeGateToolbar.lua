require "BuildingObjects/ISMoveableCursor"
require "Moveables/ISMoveablesAction"
require "Moveables/ISMoveableSpriteProps"

local LMION = require "LMION/API"
local LargeGatePickup = require "LMION/Pickup/LargeGate/LargeGatePickup"
local LargeGatePlacement = require "LMION/Pickup/LargeGate/LargeGatePlacement"
local ParcelUtils = require "LMION/Pickup/Common/ParcelUtils"
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


local function findMovePropsParcel(character, moveProps)
    if moveProps == nil then
        return nil
    end

    return findParcel(
        character,
        moveProps.lmionLargeGateDefinitionId,
        moveProps.lmionLargeGateLeaf,
        moveProps.lmionLargeGatePart,
        nil
    )
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


local function getToolbarAnchorMoveProps(identity, facing)
    if identity == nil then
        return nil
    end

    facing = facing == "W" and "W" or "N"

    local anchorSprite = LargeGatePickup.getPartSprite(
        identity.definitionId,
        facing,
        identity.leaf,
        1,
        false
    )
    local moveProps = anchorSprite
        and ISMoveableSpriteProps.new(anchorSprite)
        or nil

    if moveProps == nil or not moveProps.isMoveable then
        return nil
    end

    return moveProps
end


local function getSelectedPartSquare(anchorSquare, item, facing)
    local identity = getIdentity(item)
    if anchorSquare == nil or identity == nil then
        return nil
    end

    if identity.partIndex == 1 then
        return anchorSquare
    end

    local topology = LMION.getLargeGateTopology()
    local indices = topology
        and topology.leaves
        and topology.leaves[identity.leaf]
        and topology.leaves[identity.leaf].indices
        and topology.leaves[identity.leaf].indices[facing]
        or nil
    local layout = topology
        and topology.layout
        and topology.layout[facing]
        and topology.layout[facing].closed
        or nil

    if indices == nil or layout == nil then
        return nil
    end

    local anchorLogicalIndex = tonumber(indices[1])
    local selectedLogicalIndex = tonumber(indices[identity.partIndex])
    local anchorOffset = anchorLogicalIndex and layout[anchorLogicalIndex] or nil
    local selectedOffset = selectedLogicalIndex and layout[selectedLogicalIndex] or nil

    if anchorOffset == nil or selectedOffset == nil then
        return nil
    end

    return getCell():getGridSquare(
        anchorSquare:getX()
            + tonumber(selectedOffset[1])
            - tonumber(anchorOffset[1]),
        anchorSquare:getY()
            + tonumber(selectedOffset[2])
            - tonumber(anchorOffset[2]),
        anchorSquare:getZ()
    )
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

    -- The carried parcel selects the leaf, but vanilla must render and
    -- validate the multi-sprite placement from part 1, the SpriteGrid anchor.
    local moveProps = getToolbarAnchorMoveProps(identity, "N")
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

            return findMovePropsParcel(character, self)
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
    local identity = getIdentity(item)
    if mode ~= "place" or identity == nil then
        return nil
    end

    local facing = PlacementActionUtils.resolveToolbarFacing(
        direction,
        moveCursor,
        "lmionLargeGateFacing"
    )
    local moveProps = getToolbarAnchorMoveProps(identity, facing)
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
    local selectedSquare = getSelectedPartSquare(
        action.square,
        action.item,
        facing
    )

    if selectedSquare == nil then
        return false
    end

    return LargeGatePlacement.placeParcel(
        action.character,
        selectedSquare,
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
installInventoryLookupHooks()
installActionNewHook()
installActionCompleteHook()

return LargeGatePlacement
