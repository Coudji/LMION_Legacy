local LMION = require "LMION/API"
local ToolAdapter = require "LMION/Pickup/ToolAdapter"
local TransportState = require "LMION/Pickup/TransportState"

local LargeGatePickup = {}

local PARCEL_ITEM = "Base.LMION_OpeningParcel"
local FACINGS = { "N", "W" }
local LEAVES = { "A", "B" }

local installed = false
local runtimeByDefinitionId = {}
local segmentBySprite = {}


local function isPart(part)
    return type(part) == "table"
        and type(part.closed) == "string"
        and part.closed ~= ""
        and type(part.open) == "string"
        and part.open ~= ""
end


local function buildRuntime(definition)
    local topology = LMION.getLargeGateTopology()
    local geometry = definition and definition.geometry or nil
    local pickup = definition and definition.pickup or nil
    local packages = type(pickup) == "table" and pickup.packages or nil

    if type(definition) ~= "table"
        or type(definition.definitionId) ~= "string"
        or type(definition.displayName) ~= "string"
        or definition.displayName == ""
        or type(topology) ~= "table"
        or definition.frame ~= false
        or type(geometry) ~= "table"
        or type(packages) ~= "table"
        or tonumber(packages.count) ~= 2
        or tonumber(packages.weight) == nil
        or tonumber(packages.weight) <= 0
        or tonumber(pickup.breakChance or 0) ~= 0
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

    for _, facing in ipairs(FACINGS) do
        local face = geometry[facing]
        if type(face) ~= "table" then
            return nil
        end

        for _, leaf in ipairs(LEAVES) do
            local leafSpec = topology.leaves and topology.leaves[leaf] or nil
            local indices = leafSpec and leafSpec.indices and leafSpec.indices[facing] or nil
            local parts = face[leaf]

            if type(indices) ~= "table"
                or #indices ~= 2
                or type(parts) ~= "table"
                or not isPart(parts[1])
                or not isPart(parts[2])
            then
                return nil
            end
        end
    end

    return {
        definitionId = definition.definitionId,
        displayName = definition.displayName,
        definition = definition,
        topology = topology,
        geometry = geometry,
        weight = tonumber(packages.weight),
        skillLevel = tools.level,
        pickUpTool = tools.pickUpTool,
        placeTool = tools.placeTool,
    }
end


local function addSegment(target, runtime, facing, leaf, partIndex, isOpen, spriteName)
    if target[spriteName] ~= nil then
        error("LMION: duplicate Large Gate sprite " .. tostring(spriteName), 3)
    end

    target[spriteName] = {
        definitionId = runtime.definitionId,
        facing = facing,
        leaf = leaf,
        partIndex = partIndex,
        logicalIndex = tonumber(
            runtime.topology.leaves[leaf].indices[facing][partIndex]
        ),
        isOpen = isOpen,
    }
end


function LargeGatePickup.refresh()
    local nextRuntime = {}
    local nextSegments = {}
    local definitionIds = LMION.getRegisteredDefinitionIds()
    local supported = 0

    for index = 1, #definitionIds do
        local definition = LMION.getEffectiveDefinition(definitionIds[index])
        local runtime = buildRuntime(definition)

        if runtime ~= nil then
            nextRuntime[runtime.definitionId] = runtime
            supported = supported + 1

            for _, facing in ipairs(FACINGS) do
                for _, leaf in ipairs(LEAVES) do
                    local parts = runtime.geometry[facing][leaf]
                    for partIndex = 1, 2 do
                        addSegment(nextSegments, runtime, facing, leaf, partIndex, false, parts[partIndex].closed)
                        addSegment(nextSegments, runtime, facing, leaf, partIndex, true, parts[partIndex].open)
                    end
                end
            end
        end
    end

    runtimeByDefinitionId = nextRuntime
    segmentBySprite = nextSegments

    local sprites = 0
    for spriteName in pairs(segmentBySprite) do
        local sprite = getSprite(spriteName)
        local properties = sprite and sprite:getProperties() or nil
        if properties ~= nil then
            properties:set("IsMoveAble")
        end
        sprites = sprites + 1
    end

    return { definitions = supported, sprites = sprites }
end


local function getSpriteName(value)
    if type(value) == "string" then
        return value
    end
    return value ~= nil and value:getName() or nil
end


local function getRuntime(moveProps)
    local definitionId = moveProps and moveProps.lmionLargeGateDefinitionId or nil
    return definitionId and runtimeByDefinitionId[definitionId] or nil
end


local function getSegmentForObject(runtime, object)
    if runtime == nil or not LMION.isDoorObject(object) then
        return nil
    end

    local sprite = object:getSprite()
    local segment = sprite and segmentBySprite[sprite:getName()] or nil
    if segment == nil or segment.definitionId ~= runtime.definitionId then
        return nil
    end

    if IsoDoor == nil or IsoDoor.getDoubleDoorIndex == nil then
        return nil
    end

    local ok, logicalIndex = pcall(IsoDoor.getDoubleDoorIndex, object)
    logicalIndex = ok and tonumber(logicalIndex) or nil

    if logicalIndex ~= segment.logicalIndex then
        return nil
    end

    return segment
end


local function getLeafMembers(runtime, source, segment)
    if IsoDoor == nil or IsoDoor.getDoubleDoorObject == nil then
        return nil
    end

    local indices = runtime.topology.leaves[segment.leaf].indices[segment.facing]
    local members = {}

    for partIndex = 1, 2 do
        local ok, object = pcall(
            IsoDoor.getDoubleDoorObject,
            source,
            tonumber(indices[partIndex])
        )
        if not ok then
            return nil
        end

        local memberSegment = getSegmentForObject(runtime, object)
        if memberSegment == nil
            or memberSegment.leaf ~= segment.leaf
            or memberSegment.partIndex ~= partIndex
            or memberSegment.facing ~= segment.facing
            or memberSegment.isOpen ~= segment.isOpen
        then
            return nil
        end

        members[partIndex] = object
    end

    return members
end


function LargeGatePickup.getRuntime(definitionId)
    return runtimeByDefinitionId[definitionId]
end


function LargeGatePickup.getSegment(spriteName)
    return type(spriteName) == "string" and segmentBySprite[spriteName] or nil
end


function LargeGatePickup.getParcelIdentity(item)
    local state = item and TransportState.read(item) or nil
    local segment = state and LargeGatePickup.getSegment(state.spriteName) or nil

    if segment == nil or state == nil then
        return nil
    end

    return {
        definitionId = segment.definitionId,
        leaf = segment.leaf,
        partIndex = segment.partIndex,
        state = state,
    }
end


function LargeGatePickup.getPartSprite(definitionId, facing, leaf, partIndex, isOpen)
    local runtime = runtimeByDefinitionId[definitionId]
    local face = runtime and runtime.geometry[facing] or nil
    local parts = type(face) == "table" and face[leaf] or nil
    local part = type(parts) == "table" and parts[partIndex] or nil

    if not isPart(part) then
        return nil
    end

    return isOpen and part.open or part.closed
end


local function getParcelName(runtime, leaf, partIndex)
    return runtime.displayName
        .. " "
        .. tostring(leaf)
        .. " ("
        .. tostring(partIndex)
        .. "/2)"
end


local function applyMoveProps(moveProps, sprite)
    if moveProps == nil then
        return moveProps
    end

    local spriteName = getSpriteName(sprite) or getSpriteName(moveProps.sprite)
    local segment = spriteName and segmentBySprite[spriteName] or nil
    local runtime = segment and runtimeByDefinitionId[segment.definitionId] or nil

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
    moveProps.facing = segment.facing

    moveProps.lmionLargeGateDefinitionId = runtime.definitionId
    moveProps.lmionLargeGateFacing = segment.facing
    moveProps.lmionLargeGateLeaf = segment.leaf
    moveProps.lmionLargeGatePart = segment.partIndex
    moveProps.lmionLargeGateIsOpen = segment.isOpen

    return moveProps
end


local function applyFlatpackPresentation(item)
    if item == nil then
        return nil
    end

    -- Reproduce only the visual state that Moveable.ReadFromWorldSprite()
    -- applies to SpriteGrid furniture. Do not call ReadFromWorldSprite() here:
    -- it would also bind the transported gate sprite as this item's worldSprite.
    local texture = Texture ~= nil
        and Texture.getSharedTexture ~= nil
        and Texture.getSharedTexture("Item_Flatpack")
        or nil

    if texture ~= nil and item.setTexture ~= nil then
        item:setTexture(texture)
    end

    local modData = item:getModData()
    if modData ~= nil then
        modData.Flatpack = "true"
    end

    return item
end


local function installHooks()
    require "Moveables/ISMoveableSpriteProps"

    local previousNew = ISMoveableSpriteProps.new
    ISMoveableSpriteProps.new = function(sprite)
        return applyMoveProps(previousNew(sprite), sprite)
    end

    local previousCanPickUp = ISMoveableSpriteProps.canPickUpMoveable
    ISMoveableSpriteProps.canPickUpMoveable = function(self, character, square, object)
        local runtime = getRuntime(self)
        if runtime == nil then
            return previousCanPickUp(self, character, square, object)
        end

        local selected = object
            or (square and self:findOnSquare(square, self.spriteName) or nil)
        local segment = getSegmentForObject(runtime, selected)
        if segment == nil
            or segment.leaf ~= self.lmionLargeGateLeaf
            or segment.partIndex ~= self.lmionLargeGatePart
        then
            return false
        end

        local wasMultiSprite = self.isMultiSprite
        self.isMultiSprite = false
        local canPickUp = previousCanPickUp(self, character, square, selected)
        self.isMultiSprite = wasMultiSprite

        if not canPickUp then
            return false
        end

        local members = getLeafMembers(runtime, selected, segment)
        if members == nil then
            return false
        end

        return members[1]:isObjectNoContainerOrEmpty()
            and members[2]:isObjectNoContainerOrEmpty()
            and character:getInventory():hasRoomFor(character, runtime.weight * 2)
    end

    local previousInstanceItem = ISMoveableSpriteProps.instanceItem
    ISMoveableSpriteProps.instanceItem = function(self, spriteNameOverride)
        local runtime = getRuntime(self)
        if runtime == nil then
            return previousInstanceItem(self, spriteNameOverride)
        end

        -- One ScriptItem type, unlimited per-instance identities. Core geometry
        -- and TransportState describe what the parcel carries; the Moveable
        -- itself stays a flatpack and never receives the gate's worldSprite.
        local item = applyFlatpackPresentation(instanceItem(PARCEL_ITEM))
        if item ~= nil then
            item:setActualWeight(runtime.weight)
            item:setWeight(runtime.weight)
            item:setName(getParcelName(
                runtime,
                self.lmionLargeGateLeaf,
                self.lmionLargeGatePart
            ))
            item:setCustomName(true)
            TransportState.write(item, self.lmionLargeGatePendingState or {})
        end

        return item
    end

    local previousInternal = ISMoveableSpriteProps.pickUpMoveableInternal
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
        self.lmionLargeGatePendingState = nil

        if runtime ~= nil and object ~= nil then
            local captured = LMION.captureDoorState(object) or {}
            local entityId = LMION.getEntityIdForObject(object)
            if type(entityId) ~= "string" or entityId == "" then
                entityId = nil
            end

            self.lmionLargeGatePendingState = {
                entityId = entityId,
                spriteName = LargeGatePickup.getPartSprite(
                    runtime.definitionId,
                    self.lmionLargeGateFacing,
                    self.lmionLargeGateLeaf,
                    self.lmionLargeGatePart,
                    false
                ),
                health = captured.health,
                maxHealth = captured.maxHealth,
            }
        end

        local item = previousInternal(
            self,
            character,
            square,
            object,
            sprInstance,
            spriteName,
            createItem,
            rotating
        )

        self.lmionLargeGatePendingState = nil
        return item
    end

    local previousPickUp = ISMoveableSpriteProps.pickUpMoveable
    ISMoveableSpriteProps.pickUpMoveable = function(self, character, square, createItem, forceAllow)
        local runtime = getRuntime(self)
        if runtime == nil then
            return previousPickUp(self, character, square, createItem, forceAllow)
        end

        local selected = square and self:findOnSquare(square, self.spriteName) or nil
        local segment = getSegmentForObject(runtime, selected)
        if segment == nil then
            return false
        end

        if not forceAllow
            and not character:isMovablesCheat()
            and not ISMoveableDefinitions.cheat
            and not self:canPickUpMoveable(character, square, selected)
        then
            return false
        end

        local members = getLeafMembers(runtime, selected, segment)
        if members == nil then
            return false
        end

        local items = {}
        for partIndex = 1, 2 do
            local part = runtime.geometry[segment.facing][segment.leaf][partIndex]
            local moveProps = ISMoveableSpriteProps.new(part.closed)
            local object = members[partIndex]

            moveProps.isMultiSprite = true
            items[partIndex] = moveProps:pickUpMoveableInternal(
                character,
                object:getSquare(),
                object,
                nil,
                part.closed,
                createItem,
                forceAllow
            )
        end

        if ISMoveableCursor ~= nil
            and ISMoveableCursor.clearCacheForAllPlayers ~= nil
        then
            ISMoveableCursor.clearCacheForAllPlayers()
        end

        return items
    end
end


function LargeGatePickup.install()
    if installed then
        return
    end

    LargeGatePickup.refresh()
    installHooks()

    Events.OnLoadedTileDefinitions.Add(LargeGatePickup.refresh)
    Events.OnGameBoot.Add(function()
        local stats = LargeGatePickup.refresh()
        print(
            "[LMION:Pickup] large-gate pickup ready: "
                .. tostring(stats.definitions)
                .. " definitions, "
                .. tostring(stats.sprites)
                .. " sprites"
        )
    end)

    installed = true
end


return LargeGatePickup
