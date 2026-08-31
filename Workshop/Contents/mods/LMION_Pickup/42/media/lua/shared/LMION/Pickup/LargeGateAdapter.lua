local LMION = require "LMION/API"
local ToolAdapter = require "LMION/Pickup/ToolAdapter"
local TransportState = require "LMION/Pickup/TransportState"

local LargeGateAdapter = {}

local PARCEL_ITEM = "Base.LMION_OpeningParcel"
local FACINGS = { "N", "W" }
local LEAVES = { "A", "B" }

local installed = false
local runtimeByDefinitionId = {}
local segmentsBySprite = {}
local baseInstanceItem = nil
local basePickUpMoveableInternal = nil
local basePlaceMoveableInternal = nil


local function isEmptyTable(value)
    if type(value) ~= "table" then
        return false
    end

    for _ in pairs(value) do
        return false
    end

    return true
end


local function isOffset(value)
    return type(value) == "table"
        and tonumber(value[1]) ~= nil
        and tonumber(value[2]) ~= nil
end


local function isPartGeometry(value)
    return type(value) == "table"
        and type(value.closed) == "string"
        and value.closed ~= ""
        and type(value.open) == "string"
        and value.open ~= ""
end


local function validateTopology(definition)
    local topology = definition and definition.topology or nil
    if type(topology) ~= "table" or topology.type ~= "largeGate" then
        return nil
    end

    local leaves = topology.leaves
    local layout = topology.layout

    for _, leaf in ipairs(LEAVES) do
        local leafSpec = type(leaves) == "table" and leaves[leaf] or nil
        local indices = type(leafSpec) == "table" and leafSpec.indices or nil

        for _, facing in ipairs(FACINGS) do
            local faceIndices = type(indices) == "table" and indices[facing] or nil
            if type(faceIndices) ~= "table"
                or #faceIndices ~= 2
                or tonumber(faceIndices[1]) == nil
                or tonumber(faceIndices[2]) == nil
            then
                return nil
            end
        end
    end

    for _, facing in ipairs(FACINGS) do
        local faceLayout = type(layout) == "table" and layout[facing] or nil

        for _, state in ipairs({ "closed", "open" }) do
            local offsets = type(faceLayout) == "table" and faceLayout[state] or nil
            if type(offsets) ~= "table" or #offsets ~= 4 then
                return nil
            end

            for index = 1, 4 do
                if not isOffset(offsets[index]) then
                    return nil
                end
            end
        end
    end

    return topology
end


local function validateGeometry(definition)
    local geometry = definition and definition.geometry or nil
    if type(geometry) ~= "table" then
        return nil
    end

    for _, facing in ipairs(FACINGS) do
        local face = geometry[facing]
        if type(face) ~= "table" then
            return nil
        end

        for _, leaf in ipairs(LEAVES) do
            local parts = face[leaf]
            if type(parts) ~= "table"
                or #parts ~= 2
                or not isPartGeometry(parts[1])
                or not isPartGeometry(parts[2])
            then
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
        or type(definition.entity) ~= "string"
        or definition.entity == ""
        or definition.frame ~= false
    then
        return nil
    end

    local topology = validateTopology(definition)
    local geometry = validateGeometry(definition)
    if topology == nil or geometry == nil then
        return nil
    end

    local pickup = definition.pickup
    local replacement = definition.replacement
    local packages = type(pickup) == "table" and pickup.packages or nil
    local packageWeight = type(packages) == "table"
        and tonumber(packages.weight)
        or nil

    if type(packages) ~= "table"
        or tonumber(packages.count) ~= 2
        or packageWeight == nil
        or packageWeight <= 0
        or tonumber(pickup.breakChance or 0) ~= 0
        or type(replacement) ~= "table"
        or tonumber(replacement.packages) ~= 2
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
        entity = definition.entity,
        topology = topology,
        geometry = geometry,
        frame = false,
        weight = packageWeight,
        skillLevel = tools.level,
        pickUpTool = tools.pickUpTool,
        placeTool = tools.placeTool,
    }
end


local function addSegment(target, runtime, leaf, partIndex, facing, logicalIndex, isOpen, spriteName)
    local existing = target[spriteName]
    if existing ~= nil then
        error(
            "LMION: large-gate sprite "
                .. tostring(spriteName)
                .. " is ambiguous between "
                .. tostring(existing.definitionId)
                .. " and "
                .. tostring(runtime.definitionId),
            3
        )
    end

    target[spriteName] = {
        definitionId = runtime.definitionId,
        leaf = leaf,
        partIndex = partIndex,
        facing = facing,
        logicalIndex = logicalIndex,
        isOpen = isOpen,
        spriteName = spriteName,
    }
end


local function addRuntimeSegments(target, runtime)
    for _, facing in ipairs(FACINGS) do
        for _, leaf in ipairs(LEAVES) do
            local indices = runtime.topology.leaves[leaf].indices[facing]
            local parts = runtime.geometry[facing][leaf]

            for partIndex = 1, 2 do
                local part = parts[partIndex]
                local logicalIndex = tonumber(indices[partIndex])

                addSegment(
                    target,
                    runtime,
                    leaf,
                    partIndex,
                    facing,
                    logicalIndex,
                    false,
                    part.closed
                )
                addSegment(
                    target,
                    runtime,
                    leaf,
                    partIndex,
                    facing,
                    logicalIndex,
                    true,
                    part.open
                )
            end
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


function LargeGateAdapter.refresh()
    local nextRuntimeByDefinitionId = {}
    local nextSegmentsBySprite = {}
    local definitionIds = LMION.getRegisteredDefinitionIds()
    local definitionCount = 0

    for index = 1, #definitionIds do
        local definitionId = definitionIds[index]
        local definition = LMION.getEffectiveDefinition(definitionId)
        local runtime = buildRuntime(definition)

        if runtime ~= nil then
            nextRuntimeByDefinitionId[definitionId] = runtime
            addRuntimeSegments(nextSegmentsBySprite, runtime)
            definitionCount = definitionCount + 1
        end
    end

    runtimeByDefinitionId = nextRuntimeByDefinitionId
    segmentsBySprite = nextSegmentsBySprite

    local spriteCount = 0
    for spriteName in pairs(segmentsBySprite) do
        markSpriteMoveable(spriteName)
        spriteCount = spriteCount + 1
    end

    return {
        definitions = definitionCount,
        sprites = spriteCount,
    }
end


local function getRuntimeForEntity(entityId)
    if type(entityId) ~= "string" or entityId == "" then
        return nil
    end

    local definitionId = LMION.getDefinitionIdByEntity(entityId)
    local runtime = definitionId and runtimeByDefinitionId[definitionId] or nil

    return runtime ~= nil and runtime.entity == entityId and runtime or nil
end


local function getWorldSpriteName(item)
    if item == nil or item.getWorldSprite == nil then
        return nil
    end

    local value = item:getWorldSprite()
    return type(value) == "string" and value ~= "" and value or nil
end


function LargeGateAdapter.getParcelIdentity(item)
    local state = TransportState.read(item)
    local runtime = state and getRuntimeForEntity(state.entityId) or nil
    local spriteName = getWorldSpriteName(item)
    local segment = spriteName and segmentsBySprite[spriteName] or nil

    if runtime == nil
        or segment == nil
        or segment.definitionId ~= runtime.definitionId
    then
        return nil
    end

    return {
        kind = "largeGate",
        definitionId = runtime.definitionId,
        entityId = state.entityId,
        leaf = segment.leaf,
        partIndex = segment.partIndex,
    }
end


local function getRuntimeFromMoveProps(moveProps)
    local definitionId = moveProps and moveProps.lmionLargeGateDefinitionId or nil
    return definitionId and runtimeByDefinitionId[definitionId] or nil
end


local function getClosedSprite(runtime, facing, leaf, partIndex)
    local face = runtime and runtime.geometry[facing] or nil
    local leafGeometry = type(face) == "table" and face[leaf] or nil
    local part = type(leafGeometry) == "table" and leafGeometry[partIndex] or nil

    return type(part) == "table" and part.closed or nil
end


local function getOpenSprite(runtime, facing, leaf, partIndex)
    local face = runtime and runtime.geometry[facing] or nil
    local leafGeometry = type(face) == "table" and face[leaf] or nil
    local part = type(leafGeometry) == "table" and leafGeometry[partIndex] or nil

    return type(part) == "table" and part.open or nil
end


local function getDoubleDoorIndex(object)
    if object == nil or IsoDoor == nil or IsoDoor.getDoubleDoorIndex == nil then
        return nil
    end

    local ok, value = pcall(IsoDoor.getDoubleDoorIndex, object)
    value = ok and tonumber(value) or nil

    return value ~= nil and value >= 1 and value <= 4 and value or nil
end


local function getObjectSegment(runtime, object)
    if runtime == nil or not LMION.isDoorObject(object) then
        return nil
    end

    if LMION.getDefinitionIdForObject(object) ~= runtime.definitionId then
        return nil
    end

    local sprite = object:getSprite()
    local spriteName = sprite and sprite:getName() or nil
    local segment = spriteName and segmentsBySprite[spriteName] or nil

    if segment == nil
        or segment.definitionId ~= runtime.definitionId
        or getDoubleDoorIndex(object) ~= segment.logicalIndex
    then
        return nil
    end

    return segment
end


local function getSquareAt(anchor, offset)
    if anchor == nil or not isOffset(offset) then
        return nil
    end

    return getCell():getGridSquare(
        anchor.x + tonumber(offset[1]),
        anchor.y + tonumber(offset[2]),
        anchor.z
    )
end


local function getAnchorFromObject(runtime, object, segment)
    local square = object and object:getSquare() or nil
    local faceLayout = runtime
        and runtime.topology.layout[segment.facing]
        or nil
    local stateLayout = faceLayout
        and faceLayout[segment.isOpen and "open" or "closed"]
        or nil
    local offset = stateLayout and stateLayout[segment.logicalIndex] or nil

    if square == nil or not isOffset(offset) then
        return nil
    end

    return {
        x = square:getX() - tonumber(offset[1]),
        y = square:getY() - tonumber(offset[2]),
        z = square:getZ(),
    }
end


local function findExpectedPart(runtime, square, leaf, partIndex, facing, isOpen)
    if square == nil then
        return nil
    end

    local wantedSprite = isOpen
        and getOpenSprite(runtime, facing, leaf, partIndex)
        or getClosedSprite(runtime, facing, leaf, partIndex)
    if wantedSprite == nil then
        return nil
    end

    local specialObjects = square:getSpecialObjects()
    for index = 0, specialObjects:size() - 1 do
        local object = specialObjects:get(index)
        local segment = getObjectSegment(runtime, object)

        if segment ~= nil
            and segment.leaf == leaf
            and segment.partIndex == partIndex
            and segment.facing == facing
            and segment.isOpen == isOpen
        then
            local sprite = object:getSprite()
            if sprite ~= nil and sprite:getName() == wantedSprite then
                return object
            end
        end
    end

    return nil
end


local function getLeafMembers(runtime, source, segment)
    if runtime == nil or source == nil or segment == nil then
        return nil
    end

    local anchor = getAnchorFromObject(runtime, source, segment)
    if anchor == nil then
        return nil
    end

    local state = segment.isOpen and "open" or "closed"
    local layout = runtime.topology.layout[segment.facing][state]
    local indices = runtime.topology.leaves[segment.leaf].indices[segment.facing]
    local members = {}

    for partIndex = 1, 2 do
        local logicalIndex = tonumber(indices[partIndex])
        local square = getSquareAt(anchor, layout[logicalIndex])
        local object = findExpectedPart(
            runtime,
            square,
            segment.leaf,
            partIndex,
            segment.facing,
            segment.isOpen
        )

        if object == nil then
            return nil
        end

        members[partIndex] = {
            object = object,
            square = square,
            partIndex = partIndex,
        }
    end

    return members
end


local function otherLeaf(leaf)
    return leaf == "A" and "B" or "A"
end


local function matchesLeafState(runtime, leaf, facing, anchor, state)
    local isOpen = state == "open"
    local layout = runtime.topology.layout[facing][state]
    local indices = runtime.topology.leaves[leaf].indices[facing]

    for partIndex = 1, 2 do
        local logicalIndex = tonumber(indices[partIndex])
        local square = getSquareAt(anchor, layout[logicalIndex])
        if findExpectedPart(
            runtime,
            square,
            leaf,
            partIndex,
            facing,
            isOpen
        ) == nil then
            return false
        end
    end

    return true
end


local function hasRecognizedLeafObject(runtime, leaf, facing, anchor)
    for _, state in ipairs({ "closed", "open" }) do
        local layout = runtime.topology.layout[facing][state]
        local indices = runtime.topology.leaves[leaf].indices[facing]

        for partIndex = 1, 2 do
            local logicalIndex = tonumber(indices[partIndex])
            local square = getSquareAt(anchor, layout[logicalIndex])
            local specialObjects = square and square:getSpecialObjects() or nil

            if specialObjects ~= nil then
                for index = 0, specialObjects:size() - 1 do
                    local segment = getObjectSegment(
                        runtime,
                        specialObjects:get(index)
                    )
                    if segment ~= nil
                        and segment.leaf == leaf
                        and segment.facing == facing
                    then
                        return true
                    end
                end
            end
        end
    end

    return false
end


local function detectPartnerState(runtime, leaf, facing, anchor)
    local partner = otherLeaf(leaf)

    if matchesLeafState(runtime, partner, facing, anchor, "closed") then
        return "closed"
    end

    if matchesLeafState(runtime, partner, facing, anchor, "open") then
        return "open"
    end

    if hasRecognizedLeafObject(runtime, partner, facing, anchor) then
        return "incoherent"
    end

    return "none"
end


local function itemMatches(item, runtime, leaf, partIndex)
    local identity = LargeGateAdapter.getParcelIdentity(item)

    return identity ~= nil
        and identity.definitionId == runtime.definitionId
        and identity.leaf == leaf
        and identity.partIndex == partIndex
end


local function findParcel(character, runtime, leaf, partIndex, preferred)
    if preferred ~= nil and itemMatches(preferred, runtime, leaf, partIndex) then
        return preferred, preferred:getContainer()
    end

    local inventory = character and character:getInventory() or nil
    local items = inventory and inventory:getItems() or nil

    if items ~= nil then
        for index = 0, items:size() - 1 do
            local item = items:get(index)
            if itemMatches(item, runtime, leaf, partIndex) then
                return item, inventory
            end
        end
    end

    local playerSquare = character and character:getSquare() or nil
    if playerSquare == nil then
        return nil, nil
    end

    local radius = ISMoveableSpriteProps.multiSpriteFloorRadius or 3
    local z = playerSquare:getZ()

    for x = playerSquare:getX() - radius, playerSquare:getX() + radius do
        for y = playerSquare:getY() - radius, playerSquare:getY() + radius do
            local square = getCell():getGridSquare(x, y, z)
            local worldObjects = square and square:getWorldObjects() or nil

            if worldObjects ~= nil then
                for index = 0, worldObjects:size() - 1 do
                    local worldObject = worldObjects:get(index)
                    if instanceof(worldObject, "IsoWorldInventoryObject") then
                        local item = worldObject:getItem()
                        if itemMatches(item, runtime, leaf, partIndex) then
                            return item, "floor"
                        end
                    end
                end
            end
        end
    end

    return nil, nil
end


local function consumeParcel(item, source)
    if item == nil or source == nil then
        return
    end

    if source == "floor" then
        local worldItem = item:getWorldItem()
        local square = worldItem and worldItem:getSquare() or nil
        if worldItem ~= nil and square ~= nil then
            square:transmitRemoveItemFromSquare(worldItem)
            square:removeWorldObject(worldItem)
            item:setWorldItem(nil)
        end
        return
    end

    source:Remove(item)
    sendRemoveItemFromContainer(source, item)
end


local function hasPlacementRequirements(moveProps, character)
    if character == nil or not instanceof(character, "IsoPlayer") then
        return false
    end

    if not moveProps:hasRequiredSkill(character, "place") then
        return false
    end

    return moveProps.placeTool == nil
        or moveProps:hasTool(character, "place") ~= nil
end


local function canPlacePart(runtime, character, square, facing, leaf, partIndex, item)
    local spriteName = getClosedSprite(runtime, facing, leaf, partIndex)
    local moveProps = spriteName and ISMoveableSpriteProps.new(spriteName) or nil

    if moveProps == nil
        or square == nil
        or square:getFloor() == nil
        or square:isVehicleIntersecting()
        or not moveProps:isFreeTile(square)
        or not hasPlacementRequirements(moveProps, character)
        or not LMION.canPlaceDoorAt(square, facing, false, nil)
    then
        return false
    end

    return itemMatches(item, runtime, leaf, partIndex)
end


local function buildPlacementPlan(character, square, item, facing)
    local identity = LargeGateAdapter.getParcelIdentity(item)
    if identity == nil
        or (facing ~= "N" and facing ~= "W")
        or square == nil
    then
        return nil
    end

    local runtime = runtimeByDefinitionId[identity.definitionId]
    if runtime == nil then
        return nil
    end

    local indices = runtime.topology.leaves[identity.leaf].indices[facing]
    local selectedLogicalIndex = tonumber(indices[identity.partIndex])
    local closedLayout = runtime.topology.layout[facing].closed
    local selectedOffset = closedLayout[selectedLogicalIndex]
    if not isOffset(selectedOffset) then
        return nil
    end

    local anchor = {
        x = square:getX() - tonumber(selectedOffset[1]),
        y = square:getY() - tonumber(selectedOffset[2]),
        z = square:getZ(),
    }

    local partnerState = detectPartnerState(
        runtime,
        identity.leaf,
        facing,
        anchor
    )
    if partnerState == "incoherent" then
        return nil
    end

    local targetState = partnerState == "open" and "open" or "closed"
    local targetLayout = runtime.topology.layout[facing][targetState]
    local plan = {
        runtime = runtime,
        identity = identity,
        facing = facing,
        leaf = identity.leaf,
        anchor = anchor,
        targetState = targetState,
        isOpen = targetState == "open",
        partnerState = partnerState,
    }

    for partIndex = 1, 2 do
        local logicalIndex = tonumber(indices[partIndex])
        local targetSquare = getSquareAt(anchor, targetLayout[logicalIndex])
        local parcel, source = findParcel(
            character,
            runtime,
            identity.leaf,
            partIndex,
            partIndex == identity.partIndex and item or nil
        )

        if targetSquare == nil
            or parcel == nil
            or source == nil
            or not canPlacePart(
                runtime,
                character,
                targetSquare,
                facing,
                identity.leaf,
                partIndex,
                parcel
            )
        then
            return nil
        end

        plan[partIndex] = {
            item = parcel,
            source = source,
            square = targetSquare,
            closedSprite = getClosedSprite(
                runtime,
                facing,
                identity.leaf,
                partIndex
            ),
            targetSprite = plan.isOpen
                and getOpenSprite(runtime, facing, identity.leaf, partIndex)
                or getClosedSprite(runtime, facing, identity.leaf, partIndex),
        }
    end

    return plan
end


function LargeGateAdapter.canPlaceParcel(character, square, item, facing)
    return buildPlacementPlan(character, square, item, facing) ~= nil
end


function LargeGateAdapter.getPlacementMoveProps(item, facing)
    local identity = LargeGateAdapter.getParcelIdentity(item)
    local runtime = identity and runtimeByDefinitionId[identity.definitionId] or nil
    local spriteName = runtime
        and getClosedSprite(runtime, facing, identity.leaf, identity.partIndex)
        or nil

    return spriteName and ISMoveableSpriteProps.new(spriteName) or nil
end


function LargeGateAdapter.getPlacementPreview(item, facing, square)
    local identity = LargeGateAdapter.getParcelIdentity(item)
    local runtime = identity and runtimeByDefinitionId[identity.definitionId] or nil
    if runtime == nil or square == nil then
        return nil
    end

    local indices = runtime.topology.leaves[identity.leaf].indices[facing]
    local selectedLogicalIndex = tonumber(indices[identity.partIndex])
    local closedLayout = runtime.topology.layout[facing].closed
    local selectedOffset = closedLayout[selectedLogicalIndex]
    if not isOffset(selectedOffset) then
        return nil
    end

    local anchor = {
        x = square:getX() - tonumber(selectedOffset[1]),
        y = square:getY() - tonumber(selectedOffset[2]),
        z = square:getZ(),
    }
    local partnerState = detectPartnerState(runtime, identity.leaf, facing, anchor)
    local isOpen = partnerState == "open"
    local state = isOpen and "open" or "closed"
    local layout = runtime.topology.layout[facing][state]
    local preview = {}

    for partIndex = 1, 2 do
        local logicalIndex = tonumber(indices[partIndex])
        preview[partIndex] = {
            square = getSquareAt(anchor, layout[logicalIndex]),
            spriteName = isOpen
                and getOpenSprite(runtime, facing, identity.leaf, partIndex)
                or getClosedSprite(runtime, facing, identity.leaf, partIndex),
        }
    end

    return preview
end


function LargeGateAdapter.placeParcel(character, square, item, facing)
    local plan = buildPlacementPlan(character, square, item, facing)
    if plan == nil or basePlaceMoveableInternal == nil then
        return nil
    end

    local placed = {}

    for partIndex = 1, 2 do
        local entry = plan[partIndex]
        local moveProps = ISMoveableSpriteProps.new(entry.closedSprite)
        if moveProps == nil then
            return nil
        end

        local wasMultiSprite = moveProps.isMultiSprite
        moveProps.isMultiSprite = false
        local object = basePlaceMoveableInternal(
            moveProps,
            entry.square,
            entry.item,
            entry.closedSprite
        )
        moveProps.isMultiSprite = wasMultiSprite

        if object == nil then
            return nil
        end

        local door = LMION.finalizePlacedLargeGatePart(
            object,
            plan.runtime.definition,
            plan.facing,
            plan.leaf,
            partIndex,
            plan.isOpen
        )
        if door == nil then
            return nil
        end

        TransportState.clearFromObject(door)
        LMION.restoreDoorState(door, TransportState.read(entry.item))

        if isServer() then
            door:transmitCompleteItemToClients()
        end

        placed[partIndex] = door
    end

    for partIndex = 1, 2 do
        consumeParcel(plan[partIndex].item, plan[partIndex].source)
    end

    if ISMoveableCursor ~= nil
        and ISMoveableCursor.clearCacheForAllPlayers ~= nil
    then
        ISMoveableCursor.clearCacheForAllPlayers()
    end

    return placed
end


local function applyMoveProps(moveProps, sprite)
    if moveProps == nil then
        return moveProps
    end

    local resolved = type(sprite) == "string" and getSprite(sprite) or sprite
    local spriteName = resolved and resolved:getName() or nil
    local segment = spriteName and segmentsBySprite[spriteName] or nil
    local runtime = segment
        and runtimeByDefinitionId[segment.definitionId]
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
    moveProps.facing = segment.facing
    moveProps.lmionLargeGateDefinitionId = runtime.definitionId
    moveProps.lmionLargeGateLeaf = segment.leaf
    moveProps.lmionLargeGatePart = segment.partIndex
    moveProps.lmionLargeGateFacing = segment.facing
    moveProps.lmionLargeGateIsOpen = segment.isOpen

    return moveProps
end


local function installHooks()
    require "Moveables/ISMoveableSpriteProps"

    local previousNew = ISMoveableSpriteProps.new
    ISMoveableSpriteProps.new = function(sprite)
        return applyMoveProps(previousNew(sprite), sprite)
    end

    local previousHasFaces = ISMoveableSpriteProps.hasFaces
    ISMoveableSpriteProps.hasFaces = function(self)
        if getRuntimeFromMoveProps(self) ~= nil then
            return true
        end
        return previousHasFaces(self)
    end

    local previousGetFaces = ISMoveableSpriteProps.getFaces
    ISMoveableSpriteProps.getFaces = function(self)
        local runtime = getRuntimeFromMoveProps(self)
        if runtime ~= nil then
            return {
                N = getClosedSprite(runtime, "N", self.lmionLargeGateLeaf, self.lmionLargeGatePart),
                W = getClosedSprite(runtime, "W", self.lmionLargeGateLeaf, self.lmionLargeGatePart),
            }
        end
        return previousGetFaces(self)
    end

    local previousGetIndexedFaces = ISMoveableSpriteProps.getIndexedFaces
    ISMoveableSpriteProps.getIndexedFaces = function(self)
        local runtime = getRuntimeFromMoveProps(self)
        if runtime ~= nil then
            local north = getClosedSprite(runtime, "N", self.lmionLargeGateLeaf, self.lmionLargeGatePart)
            local west = getClosedSprite(runtime, "W", self.lmionLargeGateLeaf, self.lmionLargeGatePart)
            return { north, west, north, west }
        end
        return previousGetIndexedFaces(self)
    end

    local previousCanPickUpMoveable = ISMoveableSpriteProps.canPickUpMoveable
    ISMoveableSpriteProps.canPickUpMoveable = function(self, character, square, object)
        local runtime = getRuntimeFromMoveProps(self)
        if runtime == nil then
            return previousCanPickUpMoveable(self, character, square, object)
        end

        local selected = object
            or (square and self:findOnSquare(square, self.spriteName) or nil)
        local segment = selected and getObjectSegment(runtime, selected) or nil

        if segment == nil
            or segment.leaf ~= self.lmionLargeGateLeaf
            or segment.partIndex ~= self.lmionLargeGatePart
        then
            return false
        end

        local wasMultiSprite = self.isMultiSprite
        self.isMultiSprite = false
        local canPick = previousCanPickUpMoveable(
            self,
            character,
            square,
            selected
        )
        self.isMultiSprite = wasMultiSprite
        if not canPick then
            return false
        end

        local members = getLeafMembers(runtime, selected, segment)
        if members == nil then
            return false
        end

        for partIndex = 1, 2 do
            if not members[partIndex].object:isObjectNoContainerOrEmpty() then
                return false
            end
        end

        return true
    end

    local previousPickUpMoveable = ISMoveableSpriteProps.pickUpMoveable
    ISMoveableSpriteProps.pickUpMoveable = function(self, character, square, createItem, forceAllow)
        local runtime = getRuntimeFromMoveProps(self)
        if runtime == nil then
            return previousPickUpMoveable(
                self,
                character,
                square,
                createItem,
                forceAllow
            )
        end

        local selected = square and self:findOnSquare(square, self.spriteName) or nil
        local segment = selected and getObjectSegment(runtime, selected) or nil
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
            local member = members[partIndex]
            local closedSprite = getClosedSprite(
                runtime,
                segment.facing,
                segment.leaf,
                partIndex
            )
            local moveProps = ISMoveableSpriteProps.new(closedSprite)
            if moveProps == nil then
                return false
            end

            local wasMultiSprite = moveProps.isMultiSprite
            moveProps.isMultiSprite = true
            items[partIndex] = moveProps:pickUpMoveableInternal(
                character,
                member.square,
                member.object,
                nil,
                closedSprite,
                createItem,
                forceAllow
            )
            moveProps.isMultiSprite = wasMultiSprite
        end

        if ISMoveableCursor ~= nil
            and ISMoveableCursor.clearCacheForAllPlayers ~= nil
        then
            ISMoveableCursor.clearCacheForAllPlayers()
        end

        return items
    end

    baseInstanceItem = ISMoveableSpriteProps.instanceItem
    ISMoveableSpriteProps.instanceItem = function(self, spriteNameOverride)
        local runtime = getRuntimeFromMoveProps(self)
        if runtime == nil then
            return baseInstanceItem(self, spriteNameOverride)
        end

        local closedSprite = getClosedSprite(
            runtime,
            self.lmionLargeGateFacing,
            self.lmionLargeGateLeaf,
            self.lmionLargeGatePart
        )
        local item = baseInstanceItem(self, closedSprite or spriteNameOverride)

        if item ~= nil then
            item:setActualWeight(runtime.weight)
            item:setWeight(runtime.weight)

            TransportState.write(
                item,
                self.lmionPendingLargeGateState or {
                    entityId = runtime.entity,
                }
            )
        end

        return item
    end

    basePickUpMoveableInternal = ISMoveableSpriteProps.pickUpMoveableInternal
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
        local runtime = getRuntimeFromMoveProps(self)
        self.lmionPendingLargeGateState = nil

        if runtime ~= nil and object ~= nil then
            local segment = getObjectSegment(runtime, object)
            if segment ~= nil
                and segment.leaf == self.lmionLargeGateLeaf
                and segment.partIndex == self.lmionLargeGatePart
            then
                local captured = LMION.captureDoorState(object) or {}
                self.lmionPendingLargeGateState = {
                    entityId = runtime.entity,
                    health = captured.health,
                    maxHealth = captured.maxHealth,
                }
            end
        end

        local item = basePickUpMoveableInternal(
            self,
            character,
            square,
            object,
            sprInstance,
            spriteName,
            createItem,
            rotating
        )

        self.lmionPendingLargeGateState = nil
        return item
    end

    local previousCanPlaceMoveable = ISMoveableSpriteProps.canPlaceMoveable
    ISMoveableSpriteProps.canPlaceMoveable = function(self, character, square, item)
        if getRuntimeFromMoveProps(self) == nil then
            return previousCanPlaceMoveable(self, character, square, item)
        end

        return buildPlacementPlan(character, square, item, self.lmionLargeGateFacing) ~= nil
    end

    local previousPlaceMoveable = ISMoveableSpriteProps.placeMoveable
    basePlaceMoveableInternal = ISMoveableSpriteProps.placeMoveableInternal
    ISMoveableSpriteProps.placeMoveable = function(self, character, square, origSpriteName, forceAllow)
        local runtime = getRuntimeFromMoveProps(self)
        if runtime == nil then
            return previousPlaceMoveable(
                self,
                character,
                square,
                origSpriteName,
                forceAllow
            )
        end

        local parcel = findParcel(
            character,
            runtime,
            self.lmionLargeGateLeaf,
            self.lmionLargeGatePart,
            nil
        )
        if parcel == nil then
            return false
        end

        if not forceAllow
            and not character:isMovablesCheat()
            and not ISMoveableDefinitions.cheat
            and not LargeGateAdapter.canPlaceParcel(
                character,
                square,
                parcel,
                self.lmionLargeGateFacing
            )
        then
            return false
        end

        return LargeGateAdapter.placeParcel(
            character,
            square,
            parcel,
            self.lmionLargeGateFacing
        ) ~= nil
    end
end


function LargeGateAdapter.install()
    if installed then
        return
    end

    LargeGateAdapter.refresh()
    installHooks()

    Events.OnLoadedTileDefinitions.Add(LargeGateAdapter.refresh)
    Events.OnGameBoot.Add(function()
        local stats = LargeGateAdapter.refresh()
        print(
            "[LMION:Pickup] large-gate registry ready: "
                .. tostring(stats.definitions)
                .. " definitions, "
                .. tostring(stats.sprites)
                .. " sprites"
        )
    end)

    installed = true
end


return LargeGateAdapter
