require "BuildingObjects/ISMoveableCursor"
require "Moveables/ISMoveablesAction"

local LargeGatePickup = require "LMION/Pickup/LargeGatePickup"
local LargeGatePlacement = require "LMION/Pickup/LargeGatePlacement"


local function isAdjacentToPlan(character, plan)
    local playerSquare = character and character:getSquare() or nil
    if playerSquare == nil or plan == nil then
        return false
    end

    if ISMoveableDefinitions.cheat or character:isMovablesCheat() then
        return true
    end

    for partIndex = 1, 2 do
        local square = plan[partIndex] and plan[partIndex].square or nil
        if square ~= nil
            and playerSquare:getZ() == square:getZ()
            and (playerSquare == square or playerSquare:isAdjacentTo(square))
        then
            return true
        end
    end

    return false
end


LMIONLargeGatePlacementAction = ISMoveablesAction:derive(
    "LMIONLargeGatePlacementAction"
)


function LMIONLargeGatePlacementAction:isValid()
    local plan = LargeGatePlacement.getPreview(
        self.character,
        self.square,
        self.item,
        self.facing
    )

    if plan == nil or not plan.valid or not isAdjacentToPlan(self.character, plan) then
        return false
    end

    if isClient() then
        for partIndex = 1, 2 do
            local square = plan[partIndex].square
            if SafeHouse.isSafeHouse(
                square,
                self.character:getUsername(),
                true
            ) and not SafeHouse.isSafehouseAllowLoot(
                square,
                self.character
            ) then
                return false
            end
        end
    end

    return true
end


function LMIONLargeGatePlacementAction:complete()
    return LargeGatePlacement.placeParcel(
        self.character,
        self.square,
        self.item,
        self.facing
    )
end


function LMIONLargeGatePlacementAction:new(character, square, item, facing)
    local o = ISBaseTimedAction.new(self, character)

    o.playerNum = character:getPlayerNum()
    o.square = square
    o.item = item
    o.facing = facing
    o.mode = "place"
    o.moveProps = LargeGatePlacement.getMoveProps(item, facing)
    o.origMoveProps = o.moveProps
    o.origSpriteName = o.moveProps and o.moveProps.spriteName or nil
    o.maxTime = o:getDuration()

    return o
end


LMIONLargeGatePlacementCursor = ISBuildingObject:derive(
    "LMIONLargeGatePlacementCursor"
)


function LMIONLargeGatePlacementCursor:getPlan(square)
    return LargeGatePlacement.getPreview(
        self.character,
        square,
        self.item,
        self.facing
    )
end


function LMIONLargeGatePlacementCursor:isValid(square)
    local plan = self:getPlan(square)
    return plan ~= nil and plan.valid == true
end


local function renderFloor(square, valid)
    local floor = square and square:getFloor() or nil
    local sprite = floor and floor:getSprite() or nil
    if sprite == nil then
        return
    end

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
        0.25
    )
end


local function renderPart(entry, planValid)
    if entry == nil or entry.square == nil then
        return
    end

    local sprite = entry.displaySprite and getSprite(entry.displaySprite) or nil
    local valid = planValid and entry.valid

    renderFloor(entry.square, valid)

    if sprite == nil then
        return
    end

    local r = valid and 0.5 or 1.0
    local g = valid and 1.0 or 0.0
    local b = valid and 0.5 or 0.0

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


function LMIONLargeGatePlacementCursor:render(x, y, z, square)
    if square == nil then
        return
    end

    local plan = self:getPlan(square)
    if plan == nil then
        return
    end

    renderPart(plan[1], plan.valid)
    renderPart(plan[2], plan.valid)
end


function LMIONLargeGatePlacementCursor:rotateMouse(x, y)
    -- Inventory placement deliberately does not inherit Moveables click-drag
    -- rotation. R is the single rotation control for LMION inventory placement.
end


function LMIONLargeGatePlacementCursor:rotateKey(key)
    if getCore():isKey("Rotate building", key) then
        self.facing = self.facing == "N" and "W" or "N"
        getSoundManager():playUISound("UIObjectMenuObjectRotateOutline")
    end
end


function LMIONLargeGatePlacementCursor:create(x, y, z, north, sprite)
    local square = getCell():getGridSquare(x, y, z)
    local plan = square and self:getPlan(square) or nil

    if plan == nil or not plan.valid then
        return
    end

    local moveProps = LargeGatePlacement.getMoveProps(self.item, self.facing)
    local equipSprite = moveProps and moveProps.spriteName or nil

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
    local identity = LargeGatePickup.getParcelIdentity(item)
    if identity == nil then
        return nil
    end

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


function LargeGatePlacement.openPlacementCursor(item, character)
    if character == nil or LargeGatePickup.getParcelIdentity(item) == nil then
        return false
    end

    local cursor = LMIONLargeGatePlacementCursor:new(character, item)
    if cursor == nil then
        return false
    end

    getCell():setDrag(cursor, cursor.player)
    return true
end


local function renderPickupFootprint(cursor, x, y, z)
    if ISMoveableCursor.mode[cursor.player] ~= "pickup" then
        return
    end

    local moveProps = cursor.currentMoveProps
    local definitionId = moveProps and moveProps.lmionLargeGateDefinitionId or nil
    local leaf = moveProps and moveProps.lmionLargeGateLeaf or nil
    local facing = moveProps and moveProps.lmionLargeGateFacing or nil
    local runtime = definitionId and LargeGatePickup.getRuntime(definitionId) or nil

    if runtime == nil
        or (leaf ~= "A" and leaf ~= "B")
        or (facing ~= "N" and facing ~= "W")
        or IsoDoor == nil
        or IsoDoor.getDoubleDoorObject == nil
    then
        return
    end

    local square = cursor.currentSquare or getCell():getGridSquare(x, y, z)
    local selected = square
        and moveProps:findOnSquare(square, moveProps.spriteName)
        or nil
    if selected == nil then
        return
    end

    local indices = runtime.topology.leaves[leaf].indices[facing]

    for partIndex = 1, 2 do
        local ok, object = pcall(
            IsoDoor.getDoubleDoorObject,
            selected,
            tonumber(indices[partIndex])
        )
        local targetSquare = ok and object and object:getSquare() or nil
        local floor = targetSquare and targetSquare:getFloor() or nil
        local floorSprite = floor and floor:getSprite() or nil

        if floorSprite ~= nil then
            floorSprite:RenderGhostTileColor(
                targetSquare:getX(),
                targetSquare:getY(),
                targetSquare:getZ(),
                0.75,
                1,
                0.75,
                0.25
            )
        end
    end
end


if ISMoveableCursor._lmionLargeGateOriginalRender == nil then
    ISMoveableCursor._lmionLargeGateOriginalRender = ISMoveableCursor.render
end


ISMoveableCursor.render = function(self, x, y, z, square)
    local result = ISMoveableCursor._lmionLargeGateOriginalRender(
        self,
        x,
        y,
        z,
        square
    )

    renderPickupFootprint(self, x, y, z)
    return result
end


return LargeGatePlacement
