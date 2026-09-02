require "BuildingObjects/ISMoveableCursor"
require "Moveables/ISMoveablesAction"

local LargeGatePickup = require "LMION/Pickup/LargeGate/LargeGatePickup"
local LargeGatePlacement = require "LMION/Pickup/LargeGate/LargeGatePlacement"
local PlacementActionUtils = require "LMION/Pickup/Common/PlacementActionUtils"
local PlacementCursorUtils = require "LMION/Pickup/Common/PlacementCursorUtils"
local PlacementRules = require "LMION/Pickup/Common/PlacementRules"


local function isAdjacentToPlan(character, plan)
    if character == nil or plan == nil then
        return false
    end

    if PlacementRules.isCheat(character) then
        return true
    end

    for partIndex = 1, 2 do
        local square = plan[partIndex] and plan[partIndex].square or nil
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

    for partIndex = 1, 2 do
        local square = plan[partIndex] and plan[partIndex].square or nil
        if not PlacementRules.isSafehouseAllowed(character, square) then
            return false
        end
    end

    return true
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

    return plan ~= nil
        and plan.valid == true
        and isAdjacentToPlan(self.character, plan)
        and isSafehouseAllowed(self.character, plan)
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
    return PlacementActionUtils.configure(
        ISBaseTimedAction.new(self, character),
        character,
        square,
        item,
        facing,
        LargeGatePlacement.getMoveProps(item, facing)
    )
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


local function renderPreviewPart(entry, planValid)
    if entry == nil or entry.square == nil then
        return
    end

    local sprite = entry.sprite and getSprite(entry.sprite) or nil
    if sprite == nil then
        return
    end

    local valid = planValid and entry.valid == true
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


local spriteModelCache = {}


local function hasSpriteModel(entry)
    local spriteName = entry and entry.sprite or nil
    if type(spriteName) ~= "string" or spriteName == "" then
        return false
    end

    local cached = spriteModelCache[spriteName]
    if cached ~= nil then
        return cached
    end

    local sprite = getSprite(spriteName)
    if sprite == nil or IsoObject == nil or IsoObject.new == nil then
        spriteModelCache[spriteName] = false
        return false
    end

    local okObject, probe = pcall(
        IsoObject.new,
        getCell(),
        entry.square,
        sprite
    )
    local okModel, model = false, nil

    if okObject and probe ~= nil and probe.getSpriteModel ~= nil then
        okModel, model = pcall(probe.getSpriteModel, probe)
    end

    local result = okModel and model ~= nil
    spriteModelCache[spriteName] = result
    return result
end


local function findPartByLogicalIndex(plan, wantedIndex)
    local runtime = plan and plan.runtime or nil
    local topology = runtime and runtime.topology or nil
    local leaf = plan and plan.leaf or nil
    local facing = plan and plan.facing or nil
    local indices = topology
        and topology.leaves
        and topology.leaves[leaf]
        and topology.leaves[leaf].indices
        and topology.leaves[leaf].indices[facing]
        or nil

    if indices == nil then
        return nil
    end

    for partIndex = 1, 2 do
        if tonumber(indices[partIndex]) == wantedIndex then
            return partIndex
        end
    end

    return nil
end


local function shouldRenderPreviewPart(plan, partIndex)
    local runtime = plan and plan.runtime or nil
    local topology = runtime and runtime.topology or nil
    local leaf = plan and plan.leaf or nil
    local facing = plan and plan.facing or nil
    local indices = topology
        and topology.leaves
        and topology.leaves[leaf]
        and topology.leaves[leaf].indices
        and topology.leaves[leaf].indices[facing]
        or nil

    if indices == nil then
        return true
    end

    local logicalIndex = tonumber(indices[partIndex])
    local modelOwnerIndex = nil

    if logicalIndex == 2 then
        modelOwnerIndex = 1
    elseif logicalIndex == 3 then
        modelOwnerIndex = 4
    else
        return true
    end

    local modelOwnerPart = findPartByLogicalIndex(plan, modelOwnerIndex)
    return modelOwnerPart == nil
        or not hasSpriteModel(plan.preview[modelOwnerPart])
end


function LMIONLargeGatePlacementCursor:render(x, y, z, square)
    if square == nil then
        return
    end

    local plan = self:getPlan(square)
    local preview = plan and plan.preview or nil
    if preview == nil then
        return
    end

    for partIndex = 1, 2 do
        local entry = preview[partIndex]
        if entry ~= nil then
            renderFloor(
                entry.square,
                plan.valid == true and entry.valid == true
            )
        end
    end

    for partIndex = 1, 2 do
        if shouldRenderPreviewPart(plan, partIndex) then
            renderPreviewPart(preview[partIndex], plan.valid == true)
        end
    end
end


function LMIONLargeGatePlacementCursor:rotateMouse(x, y)
end


function LMIONLargeGatePlacementCursor:rotateKey(key)
    PlacementCursorUtils.rotateFacing(self, key)
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

    return PlacementCursorUtils.configure(
        ISBuildingObject.new(self),
        character,
        item,
        "N"
    )
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
