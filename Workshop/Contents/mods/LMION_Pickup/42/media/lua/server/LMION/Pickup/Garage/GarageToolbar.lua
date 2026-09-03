require "BuildingObjects/ISMoveableCursor"
require "Moveables/ISMoveablesAction"

local LMION = require "LMION/API"
local GaragePickup = require "LMION/Pickup/Garage/GaragePickup"
local GaragePlacement = require "LMION/Pickup/Garage/GaragePlacement"
local GarageToolbarAdapter = require "LMION/Pickup/Garage/GarageToolbarAdapter"
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


local function appendToolbarEntry(cursor, objects, item, seen)
    local identity = getIdentity(item)
    if identity == nil or seen[identity.definitionId] then
        return
    end

    if not hasCanonicalL3(cursor.character, identity.definitionId, item) then
        return
    end

    local moveProps = GarageToolbarAdapter.getMoveProps(item, "N")
    if moveProps == nil or not moveProps.isMoveable then
        return
    end

    objects[#objects + 1] = {
        object = item,
        moveProps = moveProps,
    }
    seen[identity.definitionId] = true
end


local function appendToolbarEntries(cursor, objects)
    local inventory = cursor.character and cursor.character:getInventory() or nil
    local items = inventory and inventory:getItems() or nil
    if items == nil then
        return objects
    end

    local seen = {}
    for index = 0, items:size() - 1 do
        appendToolbarEntry(cursor, objects, items:get(index), seen)
    end

    return objects
end


local function installInventoryListHook()
    local previous = ISMoveableCursor.getInventoryObjectList

    ISMoveableCursor.getInventoryObjectList = function(self)
        return appendToolbarEntries(self, previous(self))
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
        "lmionGarageFacing"
    )
    local moveProps = GarageToolbarAdapter.getMoveProps(item, facing)
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
        "lmionGarageFacing"
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
installActionNewHook()
installActionCompleteHook()

return GarageToolbarAdapter
