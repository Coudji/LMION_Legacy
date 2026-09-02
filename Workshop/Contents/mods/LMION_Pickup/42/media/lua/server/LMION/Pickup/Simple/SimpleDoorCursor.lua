require "BuildingObjects/ISMoveableCursor"
require "Moveables/ISMoveablesAction"

local MoveableAdapter = require "LMION/Pickup/Simple/MoveableAdapter"


local function consumeParcel(item)
    if item == nil then
        return false
    end

    local container = item.getContainer ~= nil and item:getContainer() or nil
    if container ~= nil then
        container:Remove(item)
        sendRemoveItemFromContainer(container, item)
        return true
    end

    local worldItem = item.getWorldItem ~= nil and item:getWorldItem() or nil
    local square = worldItem and worldItem:getSquare() or nil

    if worldItem ~= nil and square ~= nil then
        square:transmitRemoveItemFromSquare(worldItem)
        square:removeWorldObject(worldItem)
        item:setWorldItem(nil)
        return true
    end

    return false
end


local function isAdjacentToTarget(character, square)
    local playerSquare = character and character:getSquare() or nil

    if playerSquare == nil or square == nil then
        return false
    end

    if playerSquare:getZ() ~= square:getZ() then
        return false
    end

    if ISMoveableDefinitions.cheat or character:isMovablesCheat() then
        return true
    end

    return playerSquare == square or playerSquare:isAdjacentTo(square)
end


LMIONSimpleDoorPlacementAction = ISMoveablesAction:derive(
    "LMIONSimpleDoorPlacementAction"
)


function LMIONSimpleDoorPlacementAction:isValid()
    if not isAdjacentToTarget(self.character, self.square) then
        return false
    end

    if isClient()
        and SafeHouse.isSafeHouse(
            self.square,
            self.character:getUsername(),
            true
        )
        and not SafeHouse.isSafehouseAllowLoot(
            self.square,
            self.character
        )
    then
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

    consumeParcel(self.item)
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
    local o = ISBaseTimedAction.new(self, character)

    o.playerNum = character:getPlayerNum()
    o.square = square
    o.item = item
    o.definitionId = definitionId
    o.member = member
    o.facing = facing
    o.mode = "place"
    o.moveProps = MoveableAdapter.getPlacementMoveProps(
        definitionId,
        facing,
        member
    )
    o.origMoveProps = o.moveProps
    o.origSpriteName = o.moveProps and o.moveProps.spriteName or nil
    o.maxTime = o:getDuration()

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

    if sprite == nil or square == nil then
        return
    end

    local valid = self:isValid(square)
    local r = valid and 0.5 or 1.0
    local g = valid and 1.0 or 0.0
    local b = valid and 0.5 or 0.0

    sprite:RenderGhostTileColor(
        square:getX(),
        square:getY(),
        square:getZ(),
        0,
        0,
        r,
        g,
        b,
        0.8
    )
end


-- Dedicated placement starts in N. The parcel does not preserve its former
-- orientation because placement orientation is a player choice.
function LMIONSimpleDoorPlacementCursor:rotateMouse(x, y)
end


function LMIONSimpleDoorPlacementCursor:rotateKey(key)
    if getCore():isKey("Rotate building", key) then
        self.facing = self.facing == "N" and "W" or "N"
        getSoundManager():playUISound("UIObjectMenuObjectRotateOutline")
    end
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

    if ISMoveableDefinitions.cheat
        or moveProps:walkToAndEquip(
            self.character,
            square,
            "place",
            spriteName
        )
    then
        ISTimedActionQueue.add(
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
end


function LMIONSimpleDoorPlacementCursor:new(
    character,
    item,
    definitionId,
    member
)
    local o = ISBuildingObject.new(self)

    o:init()
    o.character = character
    o.player = character:getPlayerNum()
    o.item = item
    o.definitionId = definitionId
    o.member = member
    o.facing = "N"
    o:setDragNilAfterPlace(true)
    o.noNeedHammer = true

    return o
end


-- Public handoff consumed by the client inventory context-menu hook at
-- OnGameStart. The client never requires this server-tree file directly.
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
