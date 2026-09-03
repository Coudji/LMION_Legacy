require "Moveables/ISMoveableSpriteProps"

local LMION = require "LMION/API"
local GaragePickup = require "LMION/Pickup/Garage/GaragePickup"
local GaragePlacement = require "LMION/Pickup/Garage/GaragePlacement"
local TransportState = require "LMION/Pickup/TransportState"

local GarageToolbarAdapter = {}

local FACINGS = { "N", "W" }
local ROLES = { "START", "MIDDLE", "END" }

local installed = false
local runtimeSpriteGrids = {}


local function getSpriteName(value)
    if type(value) == "string" then
        return value
    end

    return value ~= nil and value:getName() or nil
end


local function getSegment(value)
    local spriteName = getSpriteName(value)
    return spriteName and LMION.getGarageSegmentBySprite(spriteName) or nil
end


local function getRuntime(segment)
    return segment
        and GaragePickup.getRuntime(segment.definitionId)
        or nil
end


local function ensureMovePropsIdentity(moveProps)
    if moveProps == nil then
        return nil, nil
    end

    local segment = getSegment(moveProps.sprite)
        or getSegment(moveProps.spriteName)
    local runtime = getRuntime(segment)

    if runtime == nil then
        return nil, nil
    end

    moveProps.lmionGarageDefinitionId = runtime.definitionId
    moveProps.lmionGarageFacing = segment.facing
    moveProps.lmionGarageRole = segment.role
    moveProps.lmionGarageIsOpen = segment.isOpen
    moveProps.facing = segment.facing
    moveProps.name = runtime.displayName

    return segment, runtime
end


function GarageToolbarAdapter.ensureMovePropsIdentity(moveProps)
    return ensureMovePropsIdentity(moveProps)
end


local function getRotationFaces(runtime, segment)
    if runtime == nil or segment == nil then
        return nil
    end

    local topology = LMION.getGarageTopology()
    local roleIndex = topology
        and topology.roles
        and topology.roles[segment.role]
        or nil
    local oppositeRole = roleIndex
        and topology.roleNames
        and topology.roleNames[4 - roleIndex]
        or nil

    if oppositeRole == nil then
        return nil
    end

    if segment.facing == "N" then
        return {
            N = runtime.geometry.N[segment.role].closed,
            W = runtime.geometry.W[oppositeRole].closed,
        }
    end

    if segment.facing == "W" then
        return {
            N = runtime.geometry.N[oppositeRole].closed,
            W = runtime.geometry.W[segment.role].closed,
        }
    end

    return nil
end


local function detachOldGrid(runtime, facing)
    local key = runtime.definitionId .. ":" .. facing
    local oldGrid = runtimeSpriteGrids[key]

    if oldGrid == nil then
        return
    end

    for _, role in ipairs(ROLES) do
        local part = runtime.geometry[facing][role]
        local sprite = part and getSprite(part.closed) or nil

        if sprite ~= nil and sprite:getSpriteGrid() == oldGrid then
            sprite:setSpriteGrid(nil)
        end
    end
end


local function tileDefinitionsAreReady()
    local definitionIds = LMION.getRegisteredDefinitionIds()

    for index = 1, #definitionIds do
        local runtime = GaragePickup.getRuntime(definitionIds[index])
        if runtime ~= nil then
            local part = runtime.geometry.N.START
            local sprite = part and getSprite(part.closed) or nil
            local properties = sprite and sprite:getProperties() or nil

            return properties ~= nil
                and properties:has("GarageDoor")
                and tonumber(properties:get("GarageDoor")) == 1
        end
    end

    return false
end


local function validateRuntimeSprites(runtime)
    local topology = LMION.getGarageTopology()

    if runtime == nil
        or runtime.geometry == nil
        or topology == nil
        or topology.roles == nil
    then
        return false
    end

    for _, facing in ipairs(FACINGS) do
        local face = runtime.geometry[facing]
        if face == nil then
            return false
        end

        for _, role in ipairs(ROLES) do
            local part = face[role]
            local closedSprite = part and getSprite(part.closed) or nil
            local openSprite = part and getSprite(part.open) or nil
            local properties = closedSprite and closedSprite:getProperties() or nil
            local rawRole = nil

            if properties ~= nil and properties:has("GarageDoor") then
                rawRole = tonumber(properties:get("GarageDoor"))
            end

            if closedSprite == nil
                or openSprite == nil
                or rawRole ~= topology.roles[role]
            then
                return false
            end
        end
    end

    return true
end


local function installGrid(runtime, facing)
    if runtime == nil
        or runtime.geometry == nil
        or runtime.geometry[facing] == nil
        or IsoSpriteGrid == nil
    then
        return false
    end

    local sprites = {}
    for _, role in ipairs(ROLES) do
        local part = runtime.geometry[facing][role]
        local sprite = part and getSprite(part.closed) or nil
        if sprite == nil then
            return false
        end
        sprites[role] = sprite
    end

    detachOldGrid(runtime, facing)

    local grid = nil
    if facing == "N" then
        grid = IsoSpriteGrid.new(3, 1)
        grid:setSprite(0, 0, sprites.START)
        grid:setSprite(1, 0, sprites.MIDDLE)
        grid:setSprite(2, 0, sprites.END)
    elseif facing == "W" then
        grid = IsoSpriteGrid.new(1, 3)
        grid:setSprite(0, 0, sprites.END)
        grid:setSprite(0, 1, sprites.MIDDLE)
        grid:setSprite(0, 2, sprites.START)
    else
        return false
    end

    if not grid:validate() then
        return false
    end

    for _, role in ipairs(ROLES) do
        sprites[role]:setSpriteGrid(grid)
    end

    runtimeSpriteGrids[runtime.definitionId .. ":" .. facing] = grid
    return true
end


function GarageToolbarAdapter.installRuntimeSpriteGrids()
    if not tileDefinitionsAreReady() then
        return 0, 0
    end

    local definitionIds = LMION.getRegisteredDefinitionIds()
    local installedCount = 0
    local expectedCount = 0

    for index = 1, #definitionIds do
        local runtime = GaragePickup.getRuntime(definitionIds[index])

        if runtime ~= nil then
            expectedCount = expectedCount + #FACINGS

            if validateRuntimeSprites(runtime) then
                for _, facing in ipairs(FACINGS) do
                    if installGrid(runtime, facing) then
                        installedCount = installedCount + 1
                    end
                end
            end
        end
    end

    return installedCount, expectedCount
end


local function findParcel(character, definitionId, role)
    return GaragePlacement.findAvailableParcel(
        character,
        definitionId,
        role,
        nil
    )
end


local function getRequestedRole(moveProps, requestedName)
    local segment, runtime = ensureMovePropsIdentity(moveProps)
    if runtime == nil then
        return nil, nil
    end

    local gridIndex = tonumber(
        string.match(requestedName or "", "%((%d+)/3%)$")
    )

    if gridIndex == nil or gridIndex < 1 or gridIndex > 3 then
        return nil, runtime
    end

    if segment.facing == "W" then
        gridIndex = 4 - gridIndex
    end

    local topology = LMION.getGarageTopology()
    local role = topology
        and topology.roleNames
        and topology.roleNames[gridIndex]
        or nil

    return role, runtime
end


local function removePlacedObject(object)
    local square = object and object:getSquare() or nil
    if object == nil or square == nil then
        return
    end

    square:transmitRemoveItemFromSquare(object)
    square:RecalcAllWithNeighbours(true)
end


local function installFaceHooks()
    local previousHasFaces = ISMoveableSpriteProps.hasFaces
    ISMoveableSpriteProps.hasFaces = function(self)
        local segment, runtime = ensureMovePropsIdentity(self)
        local faces = getRotationFaces(runtime, segment)

        if faces ~= nil then
            return faces.N ~= nil
                and faces.W ~= nil
                and faces.N ~= faces.W
        end

        return previousHasFaces(self)
    end

    local previousGetFaces = ISMoveableSpriteProps.getFaces
    ISMoveableSpriteProps.getFaces = function(self)
        local segment, runtime = ensureMovePropsIdentity(self)
        local faces = getRotationFaces(runtime, segment)

        if faces ~= nil then
            return faces
        end

        return previousGetFaces(self)
    end

    local previousGetIndexedFaces = ISMoveableSpriteProps.getIndexedFaces
    ISMoveableSpriteProps.getIndexedFaces = function(self)
        local segment, runtime = ensureMovePropsIdentity(self)
        local faces = getRotationFaces(runtime, segment)

        if faces ~= nil then
            return { faces.N, faces.W, faces.N, faces.W }
        end

        return previousGetIndexedFaces(self)
    end
end


local function installInventoryHooks()
    local previousFindInInventory = ISMoveableSpriteProps.findInInventory
    ISMoveableSpriteProps.findInInventory = function(
        self,
        character,
        spriteName
    )
        local anchorSegment, runtime = ensureMovePropsIdentity(self)

        if runtime ~= nil then
            local requestedSegment = getSegment(spriteName)
            local role = anchorSegment.role

            if requestedSegment ~= nil then
                if requestedSegment.definitionId ~= runtime.definitionId then
                    return nil
                end
                role = requestedSegment.role
            end

            return findParcel(character, runtime.definitionId, role)
        end

        return previousFindInInventory(self, character, spriteName)
    end

    local previousFindMulti = ISMoveableSpriteProps.findInInventoryMultiSprite
    ISMoveableSpriteProps.findInInventoryMultiSprite = function(
        self,
        character,
        requestedName
    )
        local role, runtime = getRequestedRole(self, requestedName)

        if runtime ~= nil and role ~= nil then
            return findParcel(character, runtime.definitionId, role)
        end

        if runtime ~= nil then
            return nil
        end

        return previousFindMulti(self, character, requestedName)
    end
end


local function installPlaceInternalHook()
    local previous = ISMoveableSpriteProps.placeMoveableInternal

    ISMoveableSpriteProps.placeMoveableInternal = function(
        self,
        square,
        item,
        spriteName
    )
        local anchorSegment, runtime = ensureMovePropsIdentity(self)

        if runtime == nil or self.isMultiSprite ~= true then
            return previous(self, square, item, spriteName)
        end

        local segment = getSegment(spriteName) or anchorSegment
        if segment == nil
            or segment.definitionId ~= runtime.definitionId
            or segment.facing ~= anchorSegment.facing
        then
            return nil
        end

        if item ~= nil then
            local identity = GaragePickup.getParcelIdentity(item)
            if identity == nil
                or identity.definitionId ~= runtime.definitionId
                or identity.role ~= segment.role
            then
                return nil
            end
        end

        local object = previous(
            self,
            square,
            item,
            segment.closedSprite
        )

        if object == nil then
            return nil
        end

        local door = LMION.finalizePlacedGarageSegment(
            object,
            runtime.definition,
            segment.facing,
            segment.role
        )

        if door == nil then
            removePlacedObject(object)
            return nil
        end

        TransportState.clearFromObject(door)

        if item ~= nil then
            LMION.restoreDoorState(door, TransportState.read(item))
        end

        if isServer() then
            door:transmitCompleteItemToClients()
        end

        return door
    end
end


local function installMoveableHooks()
    installFaceHooks()
    installInventoryHooks()
    installPlaceInternalHook()
end


function GarageToolbarAdapter.getMoveProps(item, facing)
    local identity = GaragePickup.getParcelIdentity(item)
    local runtime = identity and GaragePickup.getRuntime(identity.definitionId) or nil
    facing = facing == "W" and "W" or "N"

    if runtime == nil then
        return nil
    end

    local anchorRole = facing == "W" and "END" or "START"
    local part = runtime.geometry[facing][anchorRole]
    local moveProps = part and ISMoveableSpriteProps.new(part.closed) or nil
    local grid = moveProps
        and moveProps.sprite
        and moveProps.sprite:getSpriteGrid()
        or nil

    if moveProps == nil
        or grid == nil
        or grid:getAnchorSprite() ~= moveProps.sprite
    then
        return nil
    end

    ensureMovePropsIdentity(moveProps)
    return moveProps
end


function GarageToolbarAdapter.install()
    if installed then
        return
    end

    installMoveableHooks()

    Events.OnLoadedTileDefinitions.Add(
        GarageToolbarAdapter.installRuntimeSpriteGrids
    )
    Events.OnGameBoot.Add(function()
        local ready, expected = GarageToolbarAdapter.installRuntimeSpriteGrids()
        print(
            "[LMION:Pickup] garage toolbar grids: "
                .. tostring(ready)
                .. "/"
                .. tostring(expected)
        )
    end)

    if tileDefinitionsAreReady() then
        GarageToolbarAdapter.installRuntimeSpriteGrids()
    end

    installed = true
end


return GarageToolbarAdapter
