require "BuildingObjects/ISMoveableCursor"
require "Moveables/ISMoveablesAction"

local LMION = require "LMION/API"
local GaragePickup = require "LMION/Pickup/Garage/GaragePickup"
local GaragePlacement = require "LMION/Pickup/Garage/GaragePlacement"
local PlacementCursorUtils = require "LMION/Pickup/Common/PlacementCursorUtils"
local PlacementRules = require "LMION/Pickup/Common/PlacementRules"


local function renderFloor(square, valid)
    local floor = square and square:getFloor() or nil
    local sprite = floor and floor:getSprite() or nil

    if sprite == nil then
        return
    end

    local r = valid == false and 1.0 or 0.5
    local g = valid == false and 0.0 or 1.0
    local b = valid == false and 0.0 or 0.5

    sprite:RenderGhostTileColor(
        square:getX(),
        square:getY(),
        square:getZ(),
        0,
        0,
        r,
        g,
        b,
        0.25
    )
end


local function isGarageMoveProps(moveProps)
    return moveProps ~= nil
        and moveProps.lmionGarageDefinitionId ~= nil
end


local function getPickupChain(cursor, x, y, z)
    if ISMoveableCursor.mode[cursor.player] ~= "pickup" then
        return nil
    end

    local moveProps = cursor.currentMoveProps
    if not isGarageMoveProps(moveProps) then
        return nil
    end

    local square = cursor.currentSquare or getCell():getGridSquare(x, y, z)
    local selected = square
        and moveProps:findOnSquare(square, moveProps.spriteName)
        or nil
    local chain = selected and LMION.getGarageChain(selected) or nil

    if chain == nil
        or chain.definitionId ~= moveProps.lmionGarageDefinitionId
    then
        return nil
    end

    return chain
end


local function renderPickupFootprint(cursor, x, y, z)
    local chain = getPickupChain(cursor, x, y, z)
    if chain == nil then
        return false
    end

    for position = 1, chain.length do
        local object = chain.members[position]
        renderFloor(object and object:getSquare() or nil, true)
    end

    return true
end


if ISMoveableCursor._lmionGarageOriginalRender == nil then
    ISMoveableCursor._lmionGarageOriginalRender = ISMoveableCursor.render
end


ISMoveableCursor.render = function(self, x, y, z, square)
    local result = ISMoveableCursor._lmionGarageOriginalRender(
        self,
        x,
        y,
        z,
        square
    )

    local moveProps = self.currentMoveProps
    if isGarageMoveProps(moveProps)
        and moveProps.lmionGarageIsOpen == true
    then
        renderPickupFootprint(self, x, y, z)
    end

    return result
end


if ISMoveableCursor._lmionGarageOriginalRenderSpriteGrid == nil then
    ISMoveableCursor._lmionGarageOriginalRenderSpriteGrid =
        ISMoveableCursor.renderSpriteGrid
end


ISMoveableCursor.renderSpriteGrid = function(self, x, y, z, color)
    local mode = ISMoveableCursor.mode and ISMoveableCursor.mode[self.player] or nil

    if mode == "pickup"
        and isGarageMoveProps(self.origMoveProps)
        and isGarageMoveProps(self.currentMoveProps)
    then
        renderPickupFootprint(self, x, y, z)
        return
    end

    return ISMoveableCursor._lmionGarageOriginalRenderSpriteGrid(
        self,
        x,
        y,
        z,
        color
    )
end


local function getWidthKey(optionId, fallback)
    if PZAPI ~= nil and PZAPI.ModOptions ~= nil then
        local options = PZAPI.ModOptions:getOptions("LMION_GaragePlacement")
        local option = options and options:getOption(optionId) or nil

        if option ~= nil then
            return option:getValue()
        end
    end

    return fallback
end


local function isAdjacentToPlan(character, plan)
    if character == nil or plan == nil then
        return false
    end

    if PlacementRules.isCheat(character) then
        return true
    end

    for position = 1, plan.length do
        local square = plan[position] and plan[position].square or nil
        if PlacementRules.isSameOrAdjacent(character, square) then
            return true
        end
    end

    return false
end


local function isSafehouseAllowed(character, plan)
    if plan == nil then
        return false
    end

    for position = 1, plan.length do
        local square = plan[position] and plan[position].square or nil
        if not PlacementRules.isSafehouseAllowed(character, square) then
            return false
        end
    end

    return true
end


LMIONGaragePlacementAction = ISMoveablesAction:derive(
    "LMIONGaragePlacementAction"
)


function LMIONGaragePlacementAction:getPlan()
    return GaragePlacement.buildPlan(
        self.character,
        self.item,
        self.length,
        self.facing,
        self.square
    )
end


function LMIONGaragePlacementAction:isValid()
    local plan = self:getPlan()

    return plan ~= nil
        and GaragePlacement.validatePlan(self.character, plan)
        and isAdjacentToPlan(self.character, plan)
        and isSafehouseAllowed(self.character, plan)
end


function LMIONGaragePlacementAction:complete()
    local plan = self:getPlan()
    if plan == nil then
        return false
    end

    return GaragePlacement.placePlan(self.character, plan)
end


function LMIONGaragePlacementAction:new(
    character,
    square,
    item,
    length,
    facing
)
    local o = ISBaseTimedAction.new(self, character)

    o.playerNum = character:getPlayerNum()
    o.square = square
    o.item = item
    o.length = length
    o.facing = facing
    o.mode = "place"
    o.moveProps = GaragePlacement.getMoveProps(item, facing)
    o.origMoveProps = o.moveProps
    o.origSpriteName = o.moveProps and o.moveProps.spriteName or nil
    o.maxTime = o:getDuration()

    return o
end


LMIONGaragePlacementCursor = ISBuildingObject:derive(
    "LMIONGaragePlacementCursor"
)


function LMIONGaragePlacementCursor:getMaximumLength()
    return GaragePlacement.getMaximumAvailableLength(
        self.character,
        self.definitionId,
        self.item
    )
end


function LMIONGaragePlacementCursor:getPlan(square)
    return GaragePlacement.buildPlan(
        self.character,
        self.item,
        self.selectedLength,
        self.facing,
        square
    )
end


function LMIONGaragePlacementCursor:isValid(square)
    local maximum = self:getMaximumLength()
    if maximum == nil then
        return false
    end

    self.selectedLength = math.max(
        2,
        math.min(self.selectedLength, maximum)
    )

    local plan = self:getPlan(square)
    return plan ~= nil
        and GaragePlacement.validatePlan(self.character, plan)
end


function LMIONGaragePlacementCursor:render(x, y, z, square)
    if square == nil then
        return
    end

    local plan = self:getPlan(square)
    if plan == nil then
        return
    end

    local valid = GaragePlacement.validatePlan(self.character, plan)

    for position = 1, plan.length do
        local entry = plan[position]
        local entryValid = valid and entry.valid == true
        renderFloor(entry.square, entryValid)

        local sprite = entry.spriteName and getSprite(entry.spriteName) or nil
        if sprite ~= nil then
            local r = entryValid and 0.5 or 1.0
            local g = entryValid and 1.0 or 0.0
            local b = entryValid and 0.5 or 0.0

            sprite:RenderGhostTileColor(
                entry.square:getX(),
                entry.square:getY(),
                entry.square:getZ(),
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


function LMIONGaragePlacementCursor:rotateMouse(x, y)
end


function LMIONGaragePlacementCursor:rotateKey(key)
    local decreaseKey = getWidthKey(
        "GarageWidthDecrease",
        Keyboard.KEY_SUBTRACT
    )
    local increaseKey = getWidthKey(
        "GarageWidthIncrease",
        Keyboard.KEY_ADD
    )

    if key == decreaseKey then
        local previous = self.selectedLength
        self.selectedLength = math.max(2, self.selectedLength - 1)

        if self.selectedLength ~= previous then
            getSoundManager():playUISound("UIObjectMenuObjectRotateOutline")
        end
        return
    end

    if key == increaseKey then
        local maximum = self:getMaximumLength()
        if maximum ~= nil then
            local previous = self.selectedLength
            self.selectedLength = math.min(
                maximum,
                self.selectedLength + 1
            )

            if self.selectedLength ~= previous then
                getSoundManager():playUISound("UIObjectMenuObjectRotateOutline")
            end
        end
        return
    end

    PlacementCursorUtils.rotateFacing(self, key)
end


function LMIONGaragePlacementCursor:create(x, y, z, north, sprite)
    local square = getCell():getGridSquare(x, y, z)
    local plan = square and self:getPlan(square) or nil

    if plan == nil
        or not GaragePlacement.validatePlan(self.character, plan)
    then
        return
    end

    local moveProps = GaragePlacement.getMoveProps(self.item, self.facing)
    local equipSprite = plan[1] and plan[1].spriteName or nil

    if moveProps == nil or equipSprite == nil then
        return
    end

    if ISMoveableDefinitions.cheat
        or moveProps:walkToAndEquip(
            self.character,
            square,
            "place",
            equipSprite
        )
    then
        ISTimedActionQueue.add(
            LMIONGaragePlacementAction:new(
                self.character,
                square,
                self.item,
                self.selectedLength,
                self.facing
            )
        )
    end
end


function LMIONGaragePlacementCursor:new(character, item)
    local identity = GaragePickup.getParcelIdentity(item)
    if identity == nil then
        return nil
    end

    local maximum = GaragePlacement.getMaximumAvailableLength(
        character,
        identity.definitionId,
        item
    )
    if maximum == nil then
        return nil
    end

    local segment = identity.state
        and LMION.getGarageSegmentBySprite(identity.state.spriteName)
        or nil
    local facing = segment and segment.facing == "W" and "W" or "N"
    local o = PlacementCursorUtils.configure(
        ISBuildingObject.new(self),
        character,
        item,
        facing
    )

    o.definitionId = identity.definitionId
    o.selectedLength = maximum

    return o
end


function GaragePlacement.openPlacementCursor(item, character)
    if character == nil or GaragePickup.getParcelIdentity(item) == nil then
        return false
    end

    local cursor = LMIONGaragePlacementCursor:new(character, item)
    if cursor == nil then
        return false
    end

    getCell():setDrag(cursor, cursor.player)
    return true
end


return GaragePlacement
