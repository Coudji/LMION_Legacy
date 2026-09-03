require "BuildingObjects/ISMoveableCursor"
require "Moveables/ISMoveablesAction"
require "Moveables/ISMoveableSpriteProps"

local LargeGatePickup = require "LMION/Pickup/LargeGate/LargeGatePickup"
local LargeGatePlacement = require "LMION/Pickup/LargeGate/LargeGatePlacement"
local MoveablesActionRouter = require "LMION/Pickup/Common/MoveablesActionRouter"
local MoveableToolbarRouter = require "LMION/Pickup/Common/MoveableToolbarRouter"
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


local function getToolbarMoveProps(item, facing)
    local identity = getIdentity(item)
    facing = facing == "W" and "W" or "N"

    if identity == nil then
        return nil
    end

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


local function getSelectedPartSquare(anchorPartSquare, item, facing)
    local identity = getIdentity(item)
    local runtime = identity and LargeGatePickup.getRuntime(identity.definitionId) or nil

    if anchorPartSquare == nil
        or runtime == nil
        or (facing ~= "N" and facing ~= "W")
    then
        return nil
    end

    if identity.partIndex == 1 then
        return anchorPartSquare
    end

    local indices = runtime.topology
        and runtime.topology.leaves
        and runtime.topology.leaves[identity.leaf]
        and runtime.topology.leaves[identity.leaf].indices
        and runtime.topology.leaves[identity.leaf].indices[facing]
        or nil
    local layout = runtime.topology
        and runtime.topology.layout
        and runtime.topology.layout[facing]
        and runtime.topology.layout[facing].closed
        or nil
    local firstIndex = indices and tonumber(indices[1]) or nil
    local selectedIndex = indices and tonumber(indices[identity.partIndex]) or nil
    local firstOffset = firstIndex and layout and layout[firstIndex] or nil
    local selectedOffset = selectedIndex and layout and layout[selectedIndex] or nil

    if firstOffset == nil or selectedOffset == nil then
        return nil
    end

    return getCell():getGridSquare(
        anchorPartSquare:getX()
            - tonumber(firstOffset[1])
            + tonumber(selectedOffset[1]),
        anchorPartSquare:getY()
            - tonumber(firstOffset[2])
            + tonumber(selectedOffset[2]),
        anchorPartSquare:getZ()
    )
end


MoveableToolbarRouter.register("LargeGateToolbar", {
    getEntries = function(cursor)
        local entries = {}
        local inventory = cursor.character and cursor.character:getInventory() or nil
        local items = inventory and inventory:getItems() or nil
        local seenLeaves = {}

        if items == nil then
            return entries
        end

        for index = 0, items:size() - 1 do
            local item = items:get(index)
            local identity = getIdentity(item)

            if identity ~= nil then
                local key = identity.definitionId .. "\0" .. identity.leaf

                if not seenLeaves[key] then
                    local moveProps = getToolbarMoveProps(item, "N")

                    if moveProps ~= nil then
                        entries[#entries + 1] = {
                            object = item,
                            moveProps = moveProps,
                        }
                        seenLeaves[key] = true
                    end
                end
            end
        end

        return entries
    end,
})


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
        local moveProps = getToolbarMoveProps(item, facing)

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
    end,
})


return LargeGatePlacement
