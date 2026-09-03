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


local function findRepresentativeParcel(character, moveProps)
    local definitionId = moveProps and moveProps.lmionLargeGateDefinitionId or nil
    local leaf = moveProps and moveProps.lmionLargeGateLeaf or nil
    local partIndex = moveProps and moveProps.lmionLargeGatePart or nil
    local items = character and character:getInventory():getItems() or nil

    if items == nil then
        return nil
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        local identity = getIdentity(item)

        if identity ~= nil
            and identity.definitionId == definitionId
            and identity.leaf == leaf
            and identity.partIndex == partIndex
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
    local seenLeaves = {}

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        local identity = getIdentity(item)

        if identity ~= nil and identity.partIndex == 1 then
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

    local moveProps = LargeGatePlacement.getMoveProps(item, facing)
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
end


local previousActionComplete = ISMoveablesAction.complete
ISMoveablesAction.complete = function(self)
    local identity = self.mode == "place" and getIdentity(self.item) or nil

    if identity == nil then
        return previousActionComplete(self)
    end

    local facing = getFacing(self.moveProps, self.lmionLargeGateFacing)

    return LargeGatePlacement.placeParcel(
        self.character,
        self.square,
        self.item,
        facing
    )
end


return LargeGatePlacement
