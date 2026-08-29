require "BuildingObjects/ISMoveableCursor"
require "Moveables/ISMoveablesAction"
require "LMION/Pickup/GarageDoorPlacement"

local Pickup = LMION.Pickup
local GarageDoor = Pickup.GarageDoor

local function ensureGarageMoveProps(moveProps)
    if moveProps ~= nil and GarageDoor.ensureMovePropsIdentity ~= nil then
        GarageDoor.ensureMovePropsIdentity(moveProps)
    end
    return moveProps
end

local function isGarageMoveProps(moveProps)
    moveProps = ensureGarageMoveProps(moveProps)
    return moveProps ~= nil
        and moveProps.lmionGarageFamily ~= nil
        and moveProps.lmionGaragePart ~= nil
end

local function renderFloorSquare(square)
    local floor = square and square:getFloor() or nil
    local floorSprite = floor and floor:getSprite() or nil
    if floorSprite ~= nil then
        floorSprite:RenderGhostTileColor(
            square:getX(),
            square:getY(),
            square:getZ(),
            0.75,
            1,
            0.75,
            0.25
        )
    end
end

local function renderFloorFootprint(members)
    for _, member in ipairs(members) do
        renderFloorSquare(member.square)
    end
end

-- Keep the proven variable-chain pickup highlighting on vanilla ISMoveableCursor.
-- Placement is deliberately NOT handled by ISMoveableCursor anymore.
local function renderOpenPickupFootprint(self, x, y, z)
    local moveProps = ensureGarageMoveProps(self.currentMoveProps)
    local mode = ISMoveableCursor.mode and ISMoveableCursor.mode[self.player] or nil
    if mode ~= "pickup"
        or not isGarageMoveProps(moveProps)
        or moveProps.lmionGarageIsOpen ~= true then
        return
    end

    local square = self.currentSquare or getCell():getGridSquare(x, y, z)
    local selected = square and moveProps:findOnSquare(square, moveProps.spriteName) or nil
    local members = selected and GarageDoor.getMembers(selected, moveProps.lmionGarageFamily) or nil

    if members ~= nil then
        renderFloorFootprint(members)
    end
end

if Pickup._garageDoorOriginalRender == nil then
    Pickup._garageDoorOriginalRender = ISMoveableCursor.render
end

ISMoveableCursor.render = function(self, x, y, z, square)
    local result = Pickup._garageDoorOriginalRender(self, x, y, z, square)
    renderOpenPickupFootprint(self, x, y, z)
    return result
end

if Pickup._garageDoorOriginalRenderSpriteGrid == nil then
    Pickup._garageDoorOriginalRenderSpriteGrid = ISMoveableCursor.renderSpriteGrid
end

ISMoveableCursor.renderSpriteGrid = function(self, x, y, z, color)
    local mode = ISMoveableCursor.mode and ISMoveableCursor.mode[self.player] or nil
    local origMoveProps = ensureGarageMoveProps(self.origMoveProps)
    local currentMoveProps = ensureGarageMoveProps(self.currentMoveProps)

    if mode == "pickup"
        and isGarageMoveProps(origMoveProps)
        and isGarageMoveProps(currentMoveProps) then
        local square = self.currentSquare or getCell():getGridSquare(x, y, z)
        local selected = square and currentMoveProps:findOnSquare(square, currentMoveProps.spriteName) or nil
        local members = selected and GarageDoor.getMembers(selected, currentMoveProps.lmionGarageFamily) or nil

        if members ~= nil then
            renderFloorFootprint(members)
        end
        return
    end

    return Pickup._garageDoorOriginalRenderSpriteGrid(self, x, y, z, color)
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

-- Dedicated timed action -----------------------------------------------------

LMIONGaragePlacementAction = ISMoveablesAction:derive("LMIONGaragePlacementAction")

function LMIONGaragePlacementAction:isValid()
    local playerSquare = self.character and self.character:getSquare() or nil
    if playerSquare == nil or self.square == nil or playerSquare:getZ() ~= self.square:getZ() then
        return false
    end

    local plan = GarageDoor.buildPlacementPlan(
        self.character,
        self.familyId,
        self.length,
        self.facing,
        self.square
    )
    if plan == nil or not GarageDoor.validatePlacementPlan(self.character, plan) then
        return false
    end

    if not ISMoveableDefinitions.cheat and not self.character:isMovablesCheat() then
        local adjacent = false
        for position = 1, plan.length do
            local targetSquare = plan[position].square
            if targetSquare == playerSquare or playerSquare:isAdjacentTo(targetSquare) then
                adjacent = true
                break
            end
        end
        if not adjacent then
            return false
        end
    end

    if isClient() and SafeHouse.isSafeHouse(self.square, self.character:getUsername(), true) then
        if not SafeHouse.isSafehouseAllowLoot(self.square, self.character) then
            return false
        end
    end

    return true
end

function LMIONGaragePlacementAction:complete()
    local plan = GarageDoor.buildPlacementPlan(
        self.character,
        self.familyId,
        self.length,
        self.facing,
        self.square
    )

    if plan == nil then
        return false
    end

    local placed = GarageDoor.placePlacementPlan(self.character, plan)
    if placed == nil then
        return false
    end

    for position = 1, plan.length do
        buildUtil.setHaveConstruction(plan[position].square, true)
    end

    return true
end

function LMIONGaragePlacementAction:new(character, square, familyId, length, facing)
    local o = ISBaseTimedAction.new(self, character)
    o.playerNum = character:getPlayerNum()
    o.square = square
    o.familyId = familyId
    o.length = length
    o.facing = facing
    o.mode = "place"
    o.moveProps = GarageDoor.getPlacementMoveProps(familyId, facing)
    o.origMoveProps = o.moveProps
    o.origSpriteName = o.moveProps and o.moveProps.spriteName or nil
    o.maxTime = o:getDuration()
    return o
end

-- Dedicated cursor ----------------------------------------------------------

LMIONGaragePlacementCursor = ISBuildingObject:derive("LMIONGaragePlacementCursor")

function LMIONGaragePlacementCursor:getSprite()
    local family = GarageDoor.Families[self.familyId]
    local startPart = family and family.parts[LMION.Doors.GarageRole.START] or nil
    return startPart and startPart.faces and startPart.faces[self.facing] or nil
end

function LMIONGaragePlacementCursor:getMaximumLength()
    return GarageDoor.getMaximumAvailableLength(self.character, self.familyId)
end

function LMIONGaragePlacementCursor:getPlan(square)
    return GarageDoor.buildPlacementPlan(
        self.character,
        self.familyId,
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

    self.selectedLength = math.max(2, math.min(self.selectedLength, maximum))
    local plan = self:getPlan(square)
    return plan ~= nil and GarageDoor.validatePlacementPlan(self.character, plan)
end

function LMIONGaragePlacementCursor:render(x, y, z, square)
    local plan = self:getPlan(square)
    if plan == nil then
        return
    end

    local valid = GarageDoor.validatePlacementPlan(self.character, plan)
    local r = valid and 0.5 or 1.0
    local g = valid and 1.0 or 0.0
    local b = valid and 0.5 or 0.0

    for position = 1, plan.length do
        local entry = plan[position]
        renderFloorSquare(entry.square)

        local sprite = getSprite(entry.spriteName)
        if sprite ~= nil then
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

-- Garage orientation is only N/W. Mouse-drag rotation would run the generic
-- four-direction ISBuildingObject state machine, so this dedicated cursor uses
-- explicit key rotation only.
function LMIONGaragePlacementCursor:rotateMouse(x, y)
end

function LMIONGaragePlacementCursor:rotateKey(key)
    local decreaseKey = getWidthKey("GarageWidthDecrease", Keyboard.KEY_SUBTRACT)
    local increaseKey = getWidthKey("GarageWidthIncrease", Keyboard.KEY_ADD)

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
            self.selectedLength = math.min(maximum, self.selectedLength + 1)
            if self.selectedLength ~= previous then
                getSoundManager():playUISound("UIObjectMenuObjectRotateOutline")
            end
        end
        return
    end

    if getCore():isKey("Rotate building", key) then
        self.facing = self.facing == "N" and "W" or "N"
        getSoundManager():playUISound("UIObjectMenuObjectRotateOutline")
    end
end

function LMIONGaragePlacementCursor:create(x, y, z, north, sprite)
    local square = getCell():getGridSquare(x, y, z)
    local plan = self:getPlan(square)
    if plan == nil or not GarageDoor.validatePlacementPlan(self.character, plan) then
        return
    end

    local moveProps = GarageDoor.getPlacementMoveProps(self.familyId, self.facing)
    if moveProps == nil then
        return
    end

    if ISMoveableDefinitions.cheat
        or moveProps:walkToAndEquip(self.character, square, "place", plan[1].spriteName) then
        ISTimedActionQueue.add(
            LMIONGaragePlacementAction:new(
                self.character,
                square,
                self.familyId,
                self.selectedLength,
                self.facing
            )
        )
    end
end

function LMIONGaragePlacementCursor:new(character, familyId, initialFacing)
    local o = ISBuildingObject.new(self)
    o:init()
    o.character = character
    o.player = character:getPlayerNum()
    o.familyId = familyId
    o.facing = initialFacing == "W" and "W" or "N"
    o.selectedLength = GarageDoor.getMaximumAvailableLength(character, familyId) or 2
    o:setDragNilAfterPlace(true)
    o.noNeedHammer = true
    return o
end

-- Public handoff used by the client-side inventory context-menu hook.
function GarageDoor.openPlacementCursor(item, character)
    local identity = GarageDoor.getParcelIdentity(item)
    if identity == nil or character == nil then
        return false
    end

    local facing = "N"
    local worldSpriteName = item.getWorldSprite and item:getWorldSprite() or nil
    local segment = worldSpriteName and GarageDoor.SegmentsBySprite[worldSpriteName] or nil
    if segment ~= nil and (segment.facing == "N" or segment.facing == "W") then
        facing = segment.facing
    end

    local maximum = GarageDoor.getMaximumAvailableLength(character, identity.familyId)
    if maximum == nil then
        return false
    end

    local cursor = LMIONGaragePlacementCursor:new(character, identity.familyId, facing)
    getCell():setDrag(cursor, cursor.player)

    LMION.log(
        "Pickup",
        "garage placement cursor opened family=" .. tostring(identity.familyId)
            .. " selected=L" .. tostring(cursor.selectedLength)
            .. " max=L" .. tostring(maximum)
    )
    return true
end

LMION.log("Pickup", "dedicated variable-width garage placement cursor ready")

return GarageDoor
