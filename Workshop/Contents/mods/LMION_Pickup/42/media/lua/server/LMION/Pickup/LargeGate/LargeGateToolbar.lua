require "BuildingObjects/ISMoveableCursor"
require "Moveables/ISMoveablesAction"
require "Moveables/ISMoveableSpriteProps"

local LargeGatePickup = require "LMION/Pickup/LargeGate/LargeGatePickup"
local LargeGatePlacement = require "LMION/Pickup/LargeGate/LargeGatePlacement"
local MoveablesActionRouter = require "LMION/Pickup/Common/MoveablesActionRouter"
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
    if character == nil or moveProps == nil then
        return nil
    end

    local inventory = character:getInventory()
    local items = inventory and inventory:getItems() or nil

    if items ~= nil then
        for index = 0, items:size() - 1 do
            local item = items:get(index)
            if itemMatchesMoveProps(item, moveProps) then
                return item, inventory
            end
        end
    end

    local playerSquare = character:getSquare()
    if playerSquare == nil then
        return nil
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
                        if itemMatchesMoveProps(item, moveProps) then
                            return item, "floor"
                        end
                    end
                end
            end
        end
    end

    return nil
end


local previousGetInventoryObjectList = ISMoveableCursor.getInventoryObjectList
ISMoveableCursor.getInventoryObjectList = function(self)
    local objects = previousGetInventoryObjectList(self)
    local items = self.character:getInventory():getItems()
    local seenLeaves = {}

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        local identity = getIdentity(item)

        if identity ~= nil then
            local key = identity.definitionId .. "\0" .. identity.leaf

            if not seenLeaves[key] then
                local moveProps = LargeGatePlacement.getMoveProps(item, "N")

                if moveProps ~= nil and moveProps.isMoveable then
                    table.insert(objects, {
                        object = item,
                        moveProps = moveProps,
                    })
                    seenLeaves[key] = true
                end
            end
        end
    end

    return objects
end


local previousFindInInventory = ISMoveableSpriteProps.findInInventory
ISMoveableSpriteProps.findInInventory = function(self, character, spriteName)
    if self.lmionLargeGateDefinitionId ~= nil then
        return findRepresentativeParcel(character, self)
    end

    return previousFindInInventory(self, character, spriteName)
end


MoveablesActionRouter.register("LargeGateToolbar", {
    matchesNew = function(mode, item)
        return mode == "place" and getIdentity(item) ~= nil
    end,

    createAction = function(
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
            ISBaseTimedAction.new(self, character),
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
    end,

    matchesComplete = function(action)
        return action.mode == "place" and getIdentity(action.item) ~= nil
    end,

    complete = function(action)
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
    end,
})


return LargeGatePlacement
