require "BuildingObjects/ISMoveableCursor"
require "Moveables/ISMoveablesAction"

local LMION = require "LMION/API"
local GaragePickup = require "LMION/Pickup/Garage/GaragePickup"
local GaragePlacement = require "LMION/Pickup/Garage/GaragePlacement"
local GarageToolbarAdapter = require "LMION/Pickup/Garage/GarageToolbarAdapter"
local MoveablesActionRouter = require "LMION/Pickup/Common/MoveablesActionRouter"
local MoveableToolbarRouter = require "LMION/Pickup/Common/MoveableToolbarRouter"
local PlacementActionUtils = require "LMION/Pickup/Common/PlacementActionUtils"

local TOOLBAR_LENGTH = 3


local function getIdentity(item)
    return item and GaragePickup.getParcelIdentity(item) or nil
end


local function getFacing(moveProps, fallback)
    return PlacementActionUtils.resolveFacing(
        moveProps,
        "lmionGarageFacing",
        fallback
    )
end


local function hasCanonicalL3(character, definitionId, preferred)
    local maximum = GaragePlacement.getMaximumAvailableLength(
        character,
        definitionId,
        preferred
    )

    return maximum ~= nil and maximum >= TOOLBAR_LENGTH
end


local function getStartSquare(anchorSquare, facing)
    if anchorSquare == nil then
        return nil
    end

    if facing == "N" then
        return anchorSquare
    end

    local topology = LMION.getGarageTopology()
    local step = topology and topology.step and topology.step.W or nil

    if step == nil then
        return nil
    end

    local offset = TOOLBAR_LENGTH - 1
    return getCell():getGridSquare(
        anchorSquare:getX() - (tonumber(step.x) or 0) * offset,
        anchorSquare:getY() - (tonumber(step.y) or 0) * offset,
        anchorSquare:getZ()
    )
end


MoveableToolbarRouter.register("GarageToolbar", {
    getEntries = function(cursor)
        local entries = {}
        local inventory = cursor.character and cursor.character:getInventory() or nil
        local items = inventory and inventory:getItems() or nil
        local seen = {}

        if items == nil then
            return entries
        end

        for index = 0, items:size() - 1 do
            local item = items:get(index)
            local identity = getIdentity(item)

            if identity ~= nil
                and not seen[identity.definitionId]
                and hasCanonicalL3(
                    cursor.character,
                    identity.definitionId,
                    item
                )
            then
                local moveProps = GarageToolbarAdapter.getMoveProps(item, "N")

                if moveProps ~= nil and moveProps.isMoveable then
                    entries[#entries + 1] = {
                        object = item,
                        moveProps = moveProps,
                    }
                    seen[identity.definitionId] = true
                end
            end
        end

        return entries
    end,
})


MoveablesActionRouter.register("GarageToolbar", {
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
            "lmionGarageFacing"
        )
        local moveProps = GarageToolbarAdapter.getMoveProps(item, facing)

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
            "lmionGarageFacing"
        )
    end,

    matchesComplete = function(action)
        return action.mode == "place" and getIdentity(action.item) ~= nil
    end,

    complete = function(action)
        local facing = getFacing(action.moveProps, action.lmionGarageFacing)
        local startSquare = getStartSquare(action.square, facing)
        local plan = GaragePlacement.buildPlan(
            action.character,
            action.item,
            TOOLBAR_LENGTH,
            facing,
            startSquare
        )

        if plan == nil then
            return false
        end

        return GaragePlacement.placePlan(action.character, plan)
    end,
})


return GarageToolbarAdapter
