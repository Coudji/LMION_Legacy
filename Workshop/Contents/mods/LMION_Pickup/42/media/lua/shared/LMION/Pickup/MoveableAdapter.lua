local LMION = require "LMION/API"
local ToolAdapter = require "LMION/Pickup/ToolAdapter"
local TransportState = require "LMION/Pickup/TransportState"

local MoveableAdapter = {}

local PARCEL_ITEM = "Base.LMION_OpeningParcel"
local FACINGS = { "N", "W" }
local PAIRED_MEMBERS = { "left", "right" }

local installed = false
local runtimeByDefinitionId = {}
local spriteEntries = {}


local function isEmptyTable(value)
    if type(value) ~= "table" then
        return false
    end

    for _ in pairs(value) do
        return false
    end

    return true
end


local function isGeometryFace(face)
    return type(face) == "table"
        and type(face.closed) == "string"
        and face.closed ~= ""
        and type(face.open) == "string"
        and face.open ~= ""
end


local function getSimpleGeometry(definition)
    local geometry = definition and definition.geometry or nil
    local north = type(geometry) == "table" and geometry.N or nil
    local west = type(geometry) == "table" and geometry.W or nil

    if not isGeometryFace(north) or not isGeometryFace(west) then
        return nil
    end

    return geometry
end


local function getPairedGeometry(definition)
    local topology = definition and definition.topology or nil
    if type(topology) ~= "table"
        or topology.type ~= "paired"
        or type(topology.left) ~= "string"
        or topology.left == ""
        or type(topology.right) ~= "string"
        or topology.right == ""
    then
        return nil
    end

    local geometry = definition.geometry
    if type(geometry) ~= "table" then
        return nil
    end

    for _, facing in ipairs(FACINGS) do
        local face = geometry[facing]
        if type(face) ~= "table" then
            return nil
        end

        for _, member in ipairs(PAIRED_MEMBERS) do
            if not isGeometryFace(face[member]) then
                return nil
            end
        end
    end

    return geometry
end


local function buildRuntime(definition)
    if type(definition) ~= "table"
        or type(definition.definitionId) ~= "string"
        or definition.definitionId == ""
    then
        return nil
    end

    local topology = definition.topology
    local kind = nil
    local geometry = nil
    local entities = nil

    if topology == nil then
        if type(definition.entity) ~= "string" or definition.entity == "" then
            return nil
        end

        geometry = getSimpleGeometry(definition)
        kind = "simple"
        entities = { default = definition.entity }
    elseif type(topology) == "table" and topology.type == "paired" then
        geometry = getPairedGeometry(definition)
        kind = "paired"
        entities = {
            left = topology.left,
            right = topology.right,
        }
    else
        return nil
    end

    if geometry == nil then
        return nil
    end

    if kind == "paired" then
        if definition.frame ~= "standard" then
            return nil
        end
    elseif definition.frame ~= "standard" and definition.frame ~= false then
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
        definition = definition,
        kind = kind,
        entities = entities,
        geometry = geometry,
        frame = definition.frame,
        weight = packageWeight,
        skillLevel = tools.level,
        pickUpTool = tools.pickUpTool,
        placeTool = tools.placeTool,
    }
end


local function getGeometryFace(runtime, facing, member)
    local face = runtime and runtime.geometry[facing] or nil
    if face == nil then
        return nil
    end

    if runtime.kind == "paired" then
        return face[member]
    end

    return member == nil and face or nil
end


local function getEntityForMember(runtime, member)
    if runtime == nil then
        return nil
    end

    if runtime.kind == "paired" then
        return runtime.entities[member]
    end

    return member == nil and runtime.entities.default or nil
end


local function getMemberForEntity(runtime, entityId)
    if runtime == nil or type(entityId) ~= "string" or entityId == "" then
        return nil
    end

    if runtime.kind ~= "paired" then
        return nil
    end

    if entityId == runtime.entities.left then
        return "left"
    end

    if entityId == runtime.entities.right then
        return "right"
    end

    return nil
end


local function hasEntityIdentity(runtime, entityId)
    if runtime == nil or type(entityId) ~= "string" or entityId == "" then
        return false
    end

    if runtime.kind == "paired" then
        return getMemberForEntity(runtime, entityId) ~= nil
    end

    return entityId == runtime.entities.default
end


local function getRuntimeForEntity(entityId)
    local definitionId = LMION.getDefinitionIdByEntity(entityId)
    local runtime = definitionId and runtimeByDefinitionId[definitionId] or nil

    if runtime == nil or not hasEntityIdentity(runtime, entityId) then
        return nil
    end

    return runtime
end


local function getPairedFrameSide(runtime, member)
    if runtime == nil or runtime.kind ~= "paired" then
        return nil
    end

    if member == "left" then
        return 1
    end

    if member == "right" then
        return 2
    end

    return nil
end


local function getObjectMember(runtime, object)
    if runtime == nil or runtime.kind ~= "paired" then
        return nil
    end

    return getMemberForEntity(
        runtime,
        LMION.getEntityIdForObject(object)
    )
end


local function addSpriteMapping(
    target,
    runtime,
    facing,
    member,
    isOpen,
    spriteName
)
    local existing = target[spriteName]

    if existing ~= nil then
        if existing.definitionId ~= runtime.definitionId
            or existing.facing ~= facing
            or existing.member ~= member
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
        member = member,
        isOpen = isOpen,
    }
end


local function addRuntimeSprites(target, runtime)
    local members = runtime.kind == "paired"
        and PAIRED_MEMBERS
        or { false }

    for _, facing in ipairs(FACINGS) do
        for _, memberValue in ipairs(members) do
            local member = memberValue or nil
            local face = getGeometryFace(runtime, facing, member)

            addSpriteMapping(
                target,
                runtime,
                facing,
                member,
                false,
                face.closed
            )
            addSpriteMapping(
                target,
                runtime,
                facing,
                member,
                true,
                face.open
            )
        end
    end
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
            addRuntimeSprites(nextSpriteEntries, runtime)
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
    moveProps.lmionMember = entry.member

    return moveProps
end


local function getRuntime(moveProps)
    local definitionId = moveProps and moveProps.lmionDefinitionId or nil
    return definitionId and runtimeByDefinitionId[definitionId] or nil
end


local function getClosedSprite(runtime, facing, member)
    local face = getGeometryFace(runtime, facing, member)
    return face and face.closed or nil
end


function MoveableAdapter.getParcelIdentity(item)
    local state = TransportState.read(item)
    local runtime = state and getRuntimeForEntity(state.entityId) or nil

    if runtime == nil then
        return nil
    end

    return {
        definitionId = runtime.definitionId,
        entityId = state.entityId,
        member = getMemberForEntity(runtime, state.entityId),
    }
end


function MoveableAdapter.getPlacementSpriteName(item, facing)
    local identity = MoveableAdapter.getParcelIdentity(item)
    if identity == nil or (facing ~= "N" and facing ~= "W") then
        return nil
    end

    local runtime = runtimeByDefinitionId[identity.definitionId]
    return getClosedSprite(runtime, facing, identity.member)
end


function MoveableAdapter.getPlacementMoveProps(definitionId, facing, member)
    if facing ~= "N" and facing ~= "W" then
        return nil
    end

    local runtime = runtimeByDefinitionId[definitionId]
    local spriteName = getClosedSprite(runtime, facing, member)
    local moveProps = spriteName and ISMoveableSpriteProps.new(spriteName) or nil

    if moveProps == nil or runtime == nil then
        return nil
    end

    moveProps.lmionDefinitionId = definitionId
    moveProps.lmionFacing = facing
    moveProps.lmionMember = member
    moveProps.facing = facing

    return moveProps
end


function MoveableAdapter.canPlaceParcel(character, square, item, facing)
    local identity = MoveableAdapter.getParcelIdentity(item)
    if identity == nil or (facing ~= "N" and facing ~= "W") then
        return false
    end

    local moveProps = MoveableAdapter.getPlacementMoveProps(
        identity.definitionId,
        facing,
        identity.member
    )

    return moveProps ~= nil
        and moveProps:canPlaceMoveableInternal(
            character,
            square,
            item
        )
end


function MoveableAdapter.placeParcel(square, item, facing)
    local identity = MoveableAdapter.getParcelIdentity(item)
    if identity == nil or (facing ~= "N" and facing ~= "W") then
        return nil
    end

    local moveProps = MoveableAdapter.getPlacementMoveProps(
        identity.definitionId,
        facing,
        identity.member
    )
    local spriteName = MoveableAdapter.getPlacementSpriteName(item, facing)

    if moveProps == nil or spriteName == nil then
        return nil
    end

    return moveProps:placeMoveableInternal(
        square,
        item,
        spriteName
    )
end


local function hasPlacementRequirements(moveProps, character)
    if character == nil or not instanceof(character, "IsoPlayer") then
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
                N = getClosedSprite(runtime, "N", self.lmionMember),
                W = getClosedSprite(runtime, "W", self.lmionMember),
            }
        end

        return previousGetFaces(self)
    end

    local previousGetIndexedFaces = ISMoveableSpriteProps.getIndexedFaces
    ISMoveableSpriteProps.getIndexedFaces = function(self)
        local runtime = getRuntime(self)

        if runtime ~= nil then
            local north = getClosedSprite(runtime, "N", self.lmionMember)
            local west = getClosedSprite(runtime, "W", self.lmionMember)

            return { north, west, north, west }
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

            if runtime.kind == "paired"
                and getObjectMember(runtime, object) ~= self.lmionMember
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

        local closedSprite = getClosedSprite(
            runtime,
            self.lmionFacing,
            self.lmionMember
        )
        local item = previousInstanceItem(
            self,
            closedSprite or spriteNameOverride
        )

        if item ~= nil then
            item:setActualWeight(runtime.weight)
            item:setWeight(runtime.weight)

            local state = self.lmionPendingTransportState or {
                entityId = getEntityForMember(runtime, self.lmionMember),
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
            local entityId = LMION.getEntityIdForObject(object)

            if hasEntityIdentity(runtime, entityId) then
                local captured = LMION.captureDoorState(object) or {}

                self.lmionPendingTransportState = {
                    entityId = entityId,
                    health = captured.health,
                    maxHealth = captured.maxHealth,
                }
            end
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

        local state = item and TransportState.read(item) or nil
        local stateRuntime = state and getRuntimeForEntity(state.entityId) or nil
        local member = stateRuntime and getMemberForEntity(stateRuntime, state.entityId) or nil

        if stateRuntime ~= runtime or member ~= self.lmionMember then
            return false
        end

        if not hasPlacementRequirements(self, character) then
            return false
        end

        return LMION.canPlaceDoorAt(
            square,
            self.lmionFacing,
            runtime.frame,
            getPairedFrameSide(runtime, member)
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
        local stateRuntime = state and getRuntimeForEntity(state.entityId) or nil
        local member = stateRuntime and getMemberForEntity(stateRuntime, state.entityId) or nil

        if stateRuntime ~= runtime or member ~= self.lmionMember then
            return nil
        end

        local closedSprite = getClosedSprite(
            runtime,
            self.lmionFacing,
            member
        )
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
            self.lmionFacing,
            member
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
            "[LMION:Pickup] door registry ready: "
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
