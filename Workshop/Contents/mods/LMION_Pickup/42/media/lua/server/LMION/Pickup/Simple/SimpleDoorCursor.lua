require "BuildingObjects/ISMoveableCursor"
require "Moveables/ISMoveablesAction"

local MoveableAdapter = require "LMION/Pickup/Simple/MoveableAdapter"
local GhostRender = require "LMION/Pickup/Common/GhostRender"
local ParcelUtils = require "LMION/Pickup/Common/ParcelUtils"
local PlacementActionUtils = require "LMION/Pickup/Common/PlacementActionUtils"
local PlacementCursorUtils = require "LMION/Pickup/Common/PlacementCursorUtils"
local PlacementRules = require "LMION/Pickup/Common/PlacementRules"


LMIONSimpleDoorPlacementAction = ISMoveablesAction:derive(
    "LMIONSimpleDoorPlacementAction"
)


function LMIONSimpleDoorPlacementAction:isValid()
    if not PlacementRules.isSameLevel(
        self.character,
        self.square
    ) then
        return false
    end

    if not PlacementRules.isCheat(self.character)
        and not PlacementRules.isSameOrAdjacent(
            self.character,
            self.square
        )
    then
        return false
    end

    if not PlacementRules.isSafehouseAllowed(
        self.character,
        self.square
    ) then
        return false
    end

    return MoveableAdapter.canPlaceParcel(
        self.character,
        self.square,
        self.item,
        self.facing
    )
end


function LMIONSimpleDoorPlacementAction:complete()
    local door = MoveableAdapter.placeParcel(
        self.square,
        self.item,
        self.facing
    )

    if door == nil then
        return false
    end

    ParcelUtils.consume(self.item)
    buildUtil.setHaveConstruction(self.square, true)

    return true
end


function LMIONSimpleDoorPlacementAction:new(
    character,
    square,
    item,
    definitionId,
    member,
    facing
)
    local moveProps = MoveableAdapter.getPlacementMoveProps(
        definitionId,
        facing,
        member
    )
    local o = PlacementActionUtils.configure(
        ISBaseTimedAction.new(self, character),
        character,
        square,
        item,
        facing,
        moveProps
    )

    o.definitionId = definitionId
    o.member = member

    return o
end


LMIONSimpleDoorPlacementCursor = ISBuildingObject:derive(
    "LMIONSimpleDoorPlacementCursor"
)


function LMIONSimpleDoorPlacementCursor:getSprite()
    return MoveableAdapter.getPlacementSpriteName(
        self.item,
        self.facing
    )
end


function LMIONSimpleDoorPlacementCursor:isValid(square)
    return MoveableAdapter.canPlaceParcel(
        self.character,
        square,
        self.item,
        self.facing
    )
end


function LMIONSimpleDoorPlacementCursor:render(x, y, z, square)
    local spriteName = self:getSprite()
    local sprite = spriteName and getSprite(spriteName) or nil

    GhostRender.sprite(sprite, square, self:isValid(square), 0.8)
end


function LMIONSimpleDoorPlacementCursor:rotateMouse(x, y)
end


function LMIONSimpleDoorPlacementCursor:rotateKey(key)
    PlacementCursorUtils.rotateFacing(self, key)
end


function LMIONSimpleDoorPlacementCursor:create(x, y, z, north, sprite)
    local square = getCell():getGridSquare(x, y, z)

    if square == nil or not self:isValid(square) then
        return
    end

    local moveProps = MoveableAdapter.getPlacementMoveProps(
        self.definitionId,
        self.facing,
        self.member
    )
    local spriteName = self:getSprite()

    if moveProps == nil or spriteName == nil then
        return
    end

    PlacementCursorUtils.queuePlacement(
        self.character,
        square,
        moveProps,
        spriteName,
        LMIONSimpleDoorPlacementAction:new(
            self.character,
            square,
            self.item,
            self.definitionId,
            self.member,
            self.facing
        )
    )
end


function LMIONSimpleDoorPlacementCursor:new(
    character,
    item,
    definitionId,
    member
)
    local o = PlacementCursorUtils.configure(
        ISBuildingObject.new(self),
        character,
        item,
        "N"
    )

    o.definitionId = definitionId
    o.member = member

    return o
end


function MoveableAdapter.openPlacementCursor(item, character)
    local identity = MoveableAdapter.getParcelIdentity(item)

    if identity == nil or character == nil then
        return false
    end

    local cursor = LMIONSimpleDoorPlacementCursor:new(
        character,
        item,
        identity.definitionId,
        identity.member
    )

    getCell():setDrag(cursor, cursor.player)
    return true
end


return MoveableAdapter
