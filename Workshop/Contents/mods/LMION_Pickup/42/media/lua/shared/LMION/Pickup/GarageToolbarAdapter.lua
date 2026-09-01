require "Moveables/ISMoveableSpriteProps"

local LMION = require "LMION/API"
local GaragePickup = require "LMION/Pickup/GaragePickup"
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


local function getRuntimeForSegment(segment)
    return segment
        and GaragePickup.getRuntime(segment.definitionId)
        or nil
end


local function getMovePropsSegment(moveProps, override)
    if moveProps == nil then
        return nil, nil
    end

    local segment = getSegment(override)
        or getSegment(moveProps.sprite)
        or getSegment(moveProps.spriteName)
    local runtime = getRuntimeForSegment(segment)

    if runtime == nil then
        return nil, nil
    end

    moveProps.lmionGarageDefinitionId = runtime.definitionId
    moveProps.lmionGarageFacing = segment.facing
    moveProps.lmionGarageRole = segment.role
    moveProps.lmionGarageIsOpen = segment.isOpen
    moveProps.facing = segment.facing

    return segment, runtime
end


function GarageToolbarAdapter.ensureMovePropsIdentity(moveProps, override)
    return getMovePropsSegment(moveProps, override)
end


local function getRoleFaces(runtime, role)
    if runtime == nil or role == nil then
        return nil
    end

    local north = runtime.geometry
        and runtime.geometry.N
        and runtime.geometry.N[role]
        or nil
    local west = runtime.geometry
        and runtime.geometry.W
        and runtime.geometry.W[role]
        or nil

    if north == nil or west == nil then
        return nil
    end

    return {
        N = north.closed,
        W = west.closed,
    }
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


local function installGrid(runtime, facing)
    if runtime == nil
        or runtime.geometry == nil
        or runtime.geometry[facing] == nil
    then
        return false
    end

    detachOldGrid(runtime, facing)

    local grid = nil

    if facing == "N" then
        grid = IsoSpriteGrid.new(3, 1)

        for index, role in ipairs(ROLES) do
            local sprite = getSprite(runtime.geometry.N[role].closed)
            if sprite == nil then
                return false
            end

            grid:setSprite(index - 1, 0, sprite)
        end
    elseif facing == "W" then
        grid = IsoSpriteGrid.new(1, 3)

        for index, role in ipairs(ROLES) do
            local sprite = getSprite(runtime.geometry.W[role].closed)
            if sprite == nil then
                return false
            end

            -- Vanilla garage indices advance toward decreasing Y when W-facing.
            grid:setSprite(0, 3 - index, sprite)
        end
    else
        return false
    end

    if not grid:validate() then
        return false
    end

    for _, role in ipairs(ROLES) do
        local sprite = getSprite(runtime.geometry[facing][role].closed)
        sprite:setSpriteGrid(grid)
    end

    runtimeSpriteGrids[runtime.definitionId .. ":" .. facing] = grid
    return true
end


function GarageToolbarAdapter.installRuntimeSpriteGrids()
    local definitionIds = LMION.getRegisteredDefinitionIds()
    local installedCount = 0
    local expectedCount = 0

    for index = 1, #definitionIds do
        local runtime = GaragePickup.getRuntime(definitionIds[index])

        if runtime ~= nil then
            for _, facing in ipairs(FACINGS) do
                expectedCount = expectedCount + 1
                if installGrid(runtime, facing) then
                    installedCount = installedCount + 1
                end
            end
        end
    end

    return installedCount, expectedCount
end


local function findParcel(character, definitionId, role)
    local inventory = character and character:getInventory() or nil
    local items = inventory and inventory:getItems() or nil

    if items == nil then
        return nil, nil
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        local identity = GaragePickup.getParcelIdentity(item)

        if identity ~= nil
            and identity.definitionId == definitionId
            and identity.role == role
        then
            return item, inventory
        end
    end

    return nil, nil
end


local function getRequestedRole(moveProps, requestedName)
    local segment, runtime = getMovePropsSegment(moveProps)
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


local function installMoveableHooks()
    local previousHasFaces = ISMoveableSpriteProps.hasFaces
    ISMoveableSpriteProps.hasFaces = function(self)
        local segment, runtime = getMovePropsSegment(self)
        local faces = runtime and getRoleFaces(runtime, segment.role) or nil

        if faces ~= nil then
            return faces.N ~= nil
                and faces.W ~= nil
                and faces.N ~= faces.W
        end

        return previousHasFaces(self)
    end

    local previousGetFaces = ISMoveableSpriteProps.getFaces
    ISMoveableSpriteProps.getFaces = function(self)
        local segment, runtime = getMovePropsSegment(self)
        local faces = runtime and getRoleFaces(runtime, segment.role) or nil

        if faces ~= nil then
            return faces
        end

        return previousGetFaces(self)
    end

    local previousGetIndexedFaces = ISMoveableSpriteProps.getIndexedFaces
    ISMoveableSpriteProps.getIndexedFaces = function(self)
        local segment, runtime = getMovePropsSegment(self)
        local faces = runtime and getRoleFaces(runtime, segment.role) or nil

        if faces ~= nil then
            return { faces.N, faces.W, faces.N, faces.W }
        end

        return previousGetIndexedFaces(self)
    end

    local previousFindInInventory = ISMoveableSpriteProps.findInInventory
    ISMoveableSpriteProps.findInInventory = function(
        self,
        character,
        spriteName
    )
        local segment, runtime = getMovePropsSegment(self, spriteName)

        if runtime ~= nil then
            local item = findParcel(
                character,
                runtime.definitionId,
                segment.role
            )
            return item
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

    local previousPlaceInternal = ISMoveableSpriteProps.placeMoveableInternal
    ISMoveableSpriteProps.placeMoveableInternal = function(
        self,
        square,
        item,
        spriteName
    )
        local segment, runtime = getMovePropsSegment(self, spriteName)

        if runtime == nil then
            return previousPlaceInternal(self, square, item, spriteName)
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

        local object = previousPlaceInternal(
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


function GarageToolbarAdapter.getMoveProps(item, facing)
    local identity = GaragePickup.getParcelIdentity(item)
    local runtime = identity and GaragePickup.getRuntime(identity.definitionId) or nil
    facing = facing == "W" and "W" or "N"

    if runtime == nil or identity.role ~= "START" then
        return nil
    end

    local part = runtime.geometry[facing].START
    local moveProps = part and ISMoveableSpriteProps.new(part.closed) or nil

    if moveProps == nil then
        return nil
    end

    getMovePropsSegment(moveProps, part.closed)
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
    Events.OnGameBoot.Add(
        GarageToolbarAdapter.installRuntimeSpriteGrids
    )

    -- Useful for in-world Lua reloads, where tile definitions are already live.
    GarageToolbarAdapter.installRuntimeSpriteGrids()

    installed = true
end


return GarageToolbarAdapter
