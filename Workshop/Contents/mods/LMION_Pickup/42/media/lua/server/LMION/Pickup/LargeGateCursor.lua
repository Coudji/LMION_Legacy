require "BuildingObjects/ISMoveableCursor"
require "Moveables/ISMoveablesAction"

local LargeGateAdapter = require "LMION/Pickup/LargeGateAdapter"

local LargeGateCursor = {}


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


LMIONLargeGatePlacementAction = ISMoveablesAction:derive(
    "LMIONLargeGatePlacementAction"
)


function LMIONLargeGatePlacementAction:isValid()
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

    return LargeGateAdapter.canPlaceParcel(
        self.character,
        self.square,
        self.item,
        self.facing
    )
end


function LMIONLargeGatePlacementAction:complete()
    local doors = LargeGateAdapter.placeParcel(
        self.character,
        self.square,
        self.item,
        self.facing
    )

    if doors == nil then
        return false
    end

    buildUtil.setHaveConstruction(self.square, true)
    return true
end


function LMIONLargeGatePlacementAction:new(
    character,
    square,
    item,
    facing
)
    local o = ISBaseTimedAction.new(self, character)

    o.playerNum = character:getPlayerNum()
    o.square = square
    o.item = item
    o.facing = facing
    o.mode = "place"
    o.moveProps = LargeGateAdapter.getPlacementMoveProps(item, facing)
    o.origMoveProps = o.moveProps
    o.origSpriteName = o.moveProps and o.moveProps.spriteName or nil
    o.maxTime = o:getDuration()

    return o
end


LMIONLargeGatePlacementCursor = ISBuildingObject:derive(
    "LMIONLargeGatePlacementCursor"
)


function LMIONLargeGatePlacementCursor:isValid(square)
    return LargeGateAdapter.canPlaceParcel(
        self.character,
        square,
        self.item,
        self.facing
    )
end


function LMIONLargeGatePlacementCursor:render(x, y, z, square)
    if square == nil then
        return
    end

    local preview = LargeGateAdapter.getPlacementPreview(
        self.item,
        self.facing,
        square
    )
    if preview == nil then
        return
    end

    local valid = self:isValid(square)
    local r = valid and 0.5 or 1.0
    local g = valid and 1.0 or 0.0
    local b = valid and 0.5 or 0.0

    for partIndex = 1, 2 do
        local entry = preview[partIndex]
        local targetSquare = entry and entry.square or nil
        local sprite = entry
            and entry.spriteName
            and getSprite(entry.spriteName)
            or nil

        if targetSquare ~= nil and sprite ~= nil then
            sprite:RenderGhostTileColor(
                targetSquare:getX(),
                targetSquare:getY(),
                targetSquare:getZ(),
                0,
                0,
                r,
                g,
                b,
                0.8
            )
        end
    end
end


function LMIONLargeGatePlacementCursor:rotateMouse(x, y)
end


function LMIONLargeGatePlacementCursor:rotateKey(key)
    if getCore():isKey("Rotate building", key) then
        self.facing = self.facing == "N" and "W" or "N"
        getSoundManager():playUISound("UIObjectMenuObjectRotateOutline")
    end
end


function LMIONLargeGatePlacementCursor:create(x, y, z, north, sprite)
    local square = getCell():getGridSquare(x, y, z)

    if square == nil or not self:isValid(square) then
        return
    end

    local moveProps = LargeGateAdapter.getPlacementMoveProps(
        self.item,
        self.facing
    )
    local preview = LargeGateAdapter.getPlacementPreview(
        self.item,
        self.facing,
        square
    )
    local first = preview and preview[1] or nil
    local walkSprite = first and first.spriteName or nil

    if moveProps == nil or walkSprite == nil then
        return
    end

    if ISMoveableDefinitions.cheat
        or moveProps:walkToAndEquip(
            self.character,
            square,
            "place",
            walkSprite
        )
    then
        ISTimedActionQueue.add(
            LMIONLargeGatePlacementAction:new(
                self.character,
                square,
                self.item,
                self.facing
            )
        )
    end
end


function LMIONLargeGatePlacementCursor:new(character, item)
    local o = ISBuildingObject.new(self)

    o:init()
    o.character = character
    o.player = character:getPlayerNum()
    o.item = item
    o.facing = "N"
    o:setDragNilAfterPlace(true)
    o.noNeedHammer = true

    return o
end


function LargeGateCursor.open(item, character)
    if LargeGateAdapter.getParcelIdentity(item) == nil
        or character == nil
    then
        return false
    end

    local cursor = LMIONLargeGatePlacementCursor:new(character, item)
    getCell():setDrag(cursor, cursor.player)

    return true
end


return LargeGateCursor
