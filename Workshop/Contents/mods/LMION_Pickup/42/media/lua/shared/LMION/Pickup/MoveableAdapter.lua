local LMION = require "LMION/API"
local ToolAdapter = require "LMION/Pickup/ToolAdapter"
local TransportState = require "LMION/Pickup/TransportState"

local MoveableAdapter = {}

local PARCEL_ITEM = "Base.LMION_OpeningParcel"

local installed = false
local runtimeByDefinitionId = {}
local spriteEntries = {}


local function isEmptyTable(value)
    return type(value) == "table" and next(value) == nil
end


local function getExactGeometry(definition)
    local geometry = definition and definition.geometry or nil
    local north = type(geometry) == "table" and geometry.N or nil
    local west = type(geometry) == "table" and geometry.W or nil

    if type(north) ~= "table" or type(west) ~= "table" then
        return nil
    end

    for _, face in ipairs({ north, west }) do
        if type(face.closed) ~= "string"
            or face.closed == ""
            or type(face.open) ~= "string"
            or face.open == ""
        then
            return nil
        end
    end

    return geometry
end


local function buildRuntime(definition)
    if type(definition) ~= "table"
        or type(definition.definitionId) ~= "string"
        or definition.definitionId == ""
        or type(definition.entity) ~= "string"
        or definition.entity == ""
        or definition.topology ~= nil
    then
        return nil
    end

    local geometry = getExactGeometry(definition)
    if geometry == nil then
        return nil
    end

    if definition.frame ~= "standard" and definition.frame ~= false then
        return nil
    end

    local pickup = definition.pickup
    local replacement = definition.replacement
    local packages = type(pickup) == "table" and pickup.packages or nil
    local packageWeight = type(packages) == "table"
        and tonumber(packages.weight)
        or nil

    if type(packages) ~= "table"
        or tonumber(packages.count) ~= 1
        or packageWeight == nil
        or packageWeight <= 0
        or tonumber(pickup.breakChance or 0) ~= 0
    then
        return nil
    end

    if type(replacement) ~= "table"
        or tonumber(replacement.packages) ~= 1
        or not isEmptyTable(replacement.materials or {})
    then
        return nil
    end

    local tools, toolError = ToolAdapter.resolve(definition)
    if tools == nil then
        print(
            "[LMION:Pickup] skipped "
                .. definition.definitionId
                .. ": "
                .. tostring(toolError)
        )
        return nil
    end

    return {
        definitionId = definition.definitionId,
        entity = definition.entity,
        definition = definition,
        geometry = geometry,
        frame = definition.frame,
        weight = packageWeight,
        skillLevel = tools.level,
        pickUpTool = tools.pickUpTool,
        placeTool = tools.placeTool,
    }
end


local function addSpriteMapping(target, runtime, facing, isOpen, spriteName)
    local existing = target[spriteName]

    if existing ~= nil then
        if existing.definitionId ~= runtime.definitionId
            or existing.facing ~= facing
        then
            error(
                "LMION: Pickup sprite "
                    .. spriteName
                    .. " is ambiguous between "
                    .. existing.definitionId
                    .. " and "
                    .. runtime.definitionId,
                3
            )
        end

        return
    end

    target[spriteName] = {
        definitionId = runtime.definitionId,
        facing = facing,
        isOpen = isOpen,
    }
end


local function markSpriteMoveable(spriteName)
    local sprite = getSprite(spriteName)
    local properties = sprite and sprite:getProperties() or nil

    if properties ~= nil then
        properties:set("IsMoveAble")
    end
end


function MoveableAdapter.refresh()
    local nextRuntimeByDefinitionId = {}
    local nextSpriteEntries = {}
    local definitionIds = LMION.getRegisteredDefinitionIds()
    local supportedDefinitions = 0

    for index = 1, #definitionIds do
        local definitionId = definitionIds[index]
        local definition = LMION.getEffectiveDefinition(definitionId)
        local runtime = buildRuntime(definition)

        if runtime ~= nil then
            nextRuntimeByDefinitionId[definitionId] = runtime
            supportedDefinitions = supportedDefinitions + 1

            for _, facing in ipairs({ "N", "W" }) do
                local face = runtime.geometry[facing]

                addSpriteMapping(
                    nextSpriteEntries,
                    runtime,
                    facing,
                    false,
                    face.closed
                )
                addSpriteMapping(
                    nextSpriteEntries,
                    runtime,
                    facing,
                    true,
                    face.open
                )
            end
        end
    end

    runtimeByDefinitionId = nextRuntimeByDefinitionId
    spriteEntries = nextSpriteEntries

    local spriteCount = 0
    for spriteName in pairs(spriteEntries) do
        spriteCount = spriteCount + 1
        markSpriteMoveable(spriteName)
    end

    return {
        definitions = supportedDefinitions,
        sprites = spriteCount,
    }
end


local function getSpriteName(sprite)
    if type(sprite) == "string" then
        return sprite
    end

    return sprite ~= nil and sprite:getName() or nil
end


local function applyMoveProps(moveProps, sprite)
    if moveProps == nil then
        return moveProps
    end

    local spriteName = getSpriteName(sprite)
        or getSpriteName(moveProps.sprite)
    local entry = spriteName and spriteEntries[spriteName] or nil
    local runtime = entry
        and runtimeByDefinitionId[entry.definitionId]
        or nil

    if runtime == nil then
        return moveProps
    end

    moveProps.isMoveable = true
    moveProps.customItem = PARCEL_ITEM
    moveProps.type = "Object"
    moveProps.pickUpTool = runtime.pickUpTool
    moveProps.placeTool = runtime.placeTool
    moveProps.pickUpLevel = runtime.skillLevel
    moveProps.rawWeight = runtime.weight * 10
    moveProps.weight = runtime.weight
    moveProps.canBreak = false
    moveProps.facing = entry.facing

    moveProps.lmionDefinitionId = runtime.definitionId
    moveProps.lmionFacing = entry.facing

    return moveProps
end


local function getRuntime(moveProps)
    local definitionId = moveProps and moveProps.lmionDefinitionId or nil
    return definitionId and runtimeByDefinitionId[definitionId] or nil
end


local function getClosedSprite(runtime, facing)
    local face = runtime
        and runtime.geometry
        and runtime.geometry[facing]
        or nil

    return face and face.closed or nil
end


local function hasPlacementRequirements(moveProps, character)
    if character == nil or not instanceof(character, "IsoGameCharacter") then
        return false
    end

    local hasSkill = moveProps:hasRequiredSkill(character, "place")
    if not hasSkill then
        return false
    end

    if moveProps.placeTool ~= nil
        and not moveProps:hasTool(character, "place")
    then
        return false
    end

    return true
end


local function installMoveableHooks()
    require "Moveables/ISMoveableSpriteProps"

    local previousNew = ISMoveableSpriteProps.new
    ISMoveableSpriteProps.new = function(sprite)
        return applyMoveProps(previousNew(sprite), sprite)
    end

    local previousHasFaces = ISMoveableSpriteProps.hasFaces
    ISMoveableSpriteProps.hasFaces = function(self)
        if getRuntime(self) ~= nil then
            return true
        end

        return previousHasFaces(self)
    end

    local previousGetFaces = ISMoveableSpriteProps.getFaces
    ISMoveableSpriteProps.getFaces = function(self)
        local runtime = getRuntime(self)

        if runtime ~= nil then
            return {
                N = runtime.geometry.N.closed,
                W = runtime.geometry.W.closed,
            }
        end

        return previousGetFaces(self)
    end

    local previousGetIndexedFaces = ISMoveableSpriteProps.getIndexedFaces
    ISMoveableSpriteProps.getIndexedFaces = function(self)
        local runtime = getRuntime(self)

        if runtime ~= nil then
            return {
                runtime.geometry.N.closed,
                runtime.geometry.W.closed,
                runtime.geometry.N.closed,
                runtime.geometry.W.closed,
            }
        end

        return previousGetIndexedFaces(self)
    end

    local previousCanPickUpMoveable = ISMoveableSpriteProps.canPickUpMoveable
    ISMoveableSpriteProps.canPickUpMoveable = function(self, character, square, object)
        local runtime = getRuntime(self)

        if runtime ~= nil then
            if object == nil
                or not LMION.isDoorObject(object)
                or LMION.getDefinitionIdForObject(object) ~= runtime.definitionId
            then
                return false
            end
        end

        return previousCanPickUpMoveable(self, character, square, object)
    end

    local previousInstanceItem = ISMoveableSpriteProps.instanceItem
    ISMoveableSpriteProps.instanceItem = function(self, spriteNameOverride)
        local runtime = getRuntime(self)

        if runtime == nil then
            return previousInstanceItem(self, spriteNameOverride)
        end

        local closedSprite = getClosedSprite(runtime, self.lmionFacing)
        local item = previousInstanceItem(
            self,
            closedSprite or spriteNameOverride
        )

        if item ~= nil then
            item:setActualWeight(runtime.weight)
            item:setWeight(runtime.weight)

            local state = self.lmionPendingTransportState or {
                definitionId = runtime.definitionId,
                entityId = runtime.entity,
                facing = self.lmionFacing,
            }

            TransportState.write(item, state)
        end

        return item
    end

    local previousPickUpMoveableInternal = ISMoveableSpriteProps.pickUpMoveableInternal
    ISMoveableSpriteProps.pickUpMoveableInternal = function(
        self,
        character,
        square,
        object,
        sprInstance,
        spriteName,
        createItem,
        rotating
    )
        local runtime = getRuntime(self)
        self.lmionPendingTransportState = nil

        if runtime ~= nil
            and object ~= nil
            and LMION.isDoorObject(object)
            and LMION.getDefinitionIdForObject(object) == runtime.definitionId
        then
            local state = LMION.captureDoorState(object) or {}

            state.definitionId = runtime.definitionId
            state.entityId = LMION.getEntityIdForObject(object)
            state.facing = self.lmionFacing

            self.lmionPendingTransportState = state
        end

        local item = previousPickUpMoveableInternal(
            self,
            character,
            square,
            object,
            sprInstance,
            spriteName,
            createItem,
            rotating
        )

        self.lmionPendingTransportState = nil

        return item
    end

    local previousCanPlaceMoveableInternal = ISMoveableSpriteProps.canPlaceMoveableInternal
    ISMoveableSpriteProps.canPlaceMoveableInternal = function(
        self,
        character,
        square,
        item,
        forceTypeObject
    )
        local runtime = getRuntime(self)

        if runtime == nil then
            return previousCanPlaceMoveableInternal(
                self,
                character,
                square,
                item,
                forceTypeObject
            )
        end

        if item == nil
            or TransportState.getDefinitionId(item) ~= runtime.definitionId
        then
            return false
        end

        if not hasPlacementRequirements(self, character) then
            return false
        end

        return LMION.canPlaceDoorAt(
            square,
            self.lmionFacing,
            runtime.frame,
            nil
        )
    end

    local previousPlaceMoveableInternal = ISMoveableSpriteProps.placeMoveableInternal
    ISMoveableSpriteProps.placeMoveableInternal = function(
        self,
        square,
        item,
        spriteName
    )
        local runtime = getRuntime(self)

        if runtime == nil then
            return previousPlaceMoveableInternal(
                self,
                square,
                item,
                spriteName
            )
        end

        local state = TransportState.read(item)
        if state == nil or state.definitionId ~= runtime.definitionId then
            return nil
        end

        local closedSprite = getClosedSprite(runtime, self.lmionFacing)
        if closedSprite == nil then
            return nil
        end

        local object = previousPlaceMoveableInternal(
            self,
            square,
            item,
            closedSprite
        )

        if object == nil then
            return nil
        end

        local door = LMION.finalizePlacedDoor(
            object,
            runtime.definition,
            self.lmionFacing
        )

        if door == nil then
            return object
        end

        TransportState.clearFromObject(door)
        LMION.restoreDoorState(door, state)

        if isServer() then
            door:transmitCompleteItemToClients()
        end

        return door
    end
end


function MoveableAdapter.install()
    if installed then
        return
    end

    ToolAdapter.install()
    MoveableAdapter.refresh()
    installMoveableHooks()

    local function refreshAfterTileDefinitions()
        MoveableAdapter.refresh()
    end

    local function reportAtGameBoot()
        local stats = MoveableAdapter.refresh()

        print(
            "[LMION:Pickup] simple 1x1 registry ready: "
                .. tostring(stats.definitions)
                .. " definitions, "
                .. tostring(stats.sprites)
                .. " sprites"
        )
    end

    Events.OnLoadedTileDefinitions.Add(refreshAfterTileDefinitions)
    Events.OnGameBoot.Add(reportAtGameBoot)

    installed = true
end


return MoveableAdapter
