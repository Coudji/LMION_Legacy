require "BuildingObjects/ISMoveableCursor"
require "Moveables/ISMoveablesAction"

local LMION = require "LMION/API"
local GaragePickup = require "LMION/Pickup/GaragePickup"
local GaragePlacement = require "LMION/Pickup/GaragePlacement"
local GarageToolbarAdapter = require "LMION/Pickup/GarageToolbarAdapter"

local TOOLBAR_LENGTH = 3


local function getIdentity(item)
    return item and GaragePickup.getParcelIdentity(item) or nil
end


local function getFacing(moveProps, fallback)
    local facing = moveProps and moveProps.lmionGarageFacing or nil

    if facing == "N" or facing == "W" then
        return facing
    end

    if fallback == "N" or fallback == "W" then
        return fallback
    end

    return "N"
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

    -- The synthetic W SpriteGrid is anchored on END. GaragePlacement always
    -- expects START, so walk back two topology steps for the fixed L3 toolbar.
    local offset = TOOLBAR_LENGTH - 1
    return getCell():getGridSquare(
        anchorSquare:getX() - (tonumber(step.x) or 0) * offset,
        anchorSquare:getY() - (tonumber(step.y) or 0) * offset,
        anchorSquare:getZ()
    )
end


local previousGetInventoryObjectList = ISMoveableCursor.getInventoryObjectList

ISMoveableCursor.getInventoryObjectList = function(self)
    local objects = previousGetInventoryObjectList(self)
    local inventory = self.character and self.character:getInventory() or nil
    local items = inventory and inventory:getItems() or nil
    local seen = {}

    if items == nil then
        return objects
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        local identity = getIdentity(item)

        if identity ~= nil
            and not seen[identity.definitionId]
            and hasCanonicalL3(self.character, identity.definitionId, item)
        then
            local moveProps = GarageToolbarAdapter.getMoveProps(item, "N")

            if moveProps ~= nil and moveProps.isMoveable then
                table.insert(objects, {
                    object = item,
                    moveProps = moveProps,
                })
                seen[identity.definitionId] = true
            end
        end
    end

    return objects
end


local previousActionNew = ISMoveablesAction.new

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
    local identity = mode == "place" and getIdentity(item) or nil

    if identity == nil then
        return previousActionNew(
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

    local facing = direction
    if facing ~= "N" and facing ~= "W" then
        facing = moveCursor
            and getFacing(moveCursor.currentMoveProps, "N")
            or "N"
    end

    local moveProps = GarageToolbarAdapter.getMoveProps(item, facing)
    if moveProps == nil then
        return previousActionNew(
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

    local o = ISBaseTimedAction.new(self, character)

    o.playerNum = character:getPlayerNum()
    o.square = square
    o.origSpriteName = moveProps.spriteName
    o.spriteFrame = 0
    o.mode = mode
    o.object = object
    o.direction = facing
    o.item = item
    o.moveProps = moveProps
    o.origMoveProps = moveProps
    o.moveCursor = moveCursor
    o.lmionGarageFacing = facing

    if isServer() then
        o.moveCursor = nil
    end

    o.maxTime = o:getDuration()
    return o
end


local previousActionComplete = ISMoveablesAction.complete

ISMoveablesAction.complete = function(self)
    local identity = self.mode == "place" and getIdentity(self.item) or nil

    if identity == nil then
        return previousActionComplete(self)
    end

    local facing = getFacing(self.moveProps, self.lmionGarageFacing)
    local startSquare = getStartSquare(self.square, facing)
    local plan = GaragePlacement.buildPlan(
        self.character,
        self.item,
        TOOLBAR_LENGTH,
        facing,
        startSquare
    )

    if plan == nil then
        return false
    end

    return GaragePlacement.placePlan(self.character, plan)
end


return GarageToolbarAdapter
