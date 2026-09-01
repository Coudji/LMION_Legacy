local LMION = require "LMION/API"
local ToolAdapter = require "LMION/Pickup/ToolAdapter"
local TransportState = require "LMION/Pickup/TransportState"

local GaragePickup = {}

local PARCEL_ITEM = "Base.LMION_OpeningParcel"
local FACINGS = { "N", "W" }
local ROLES = { "START", "MIDDLE", "END" }

local installed = false
local runtimeByDefinitionId = {}

local function isEmptyTable(value)
    if type(value) ~= "table" then return false end
    for _ in pairs(value) do return false end
    return true
end

local function isPart(part)
    return type(part) == "table"
        and type(part.closed) == "string" and part.closed ~= ""
        and type(part.open) == "string" and part.open ~= ""
end

local function buildRuntime(definition)
    local topology = definition and definition.topology or nil
    local geometry = definition and definition.geometry or nil
    local pickup = definition and definition.pickup or nil
    local packages = type(pickup) == "table" and pickup.packages or nil
    local replacement = definition and definition.replacement or nil
    local weight = type(packages) == "table" and tonumber(packages.weight) or nil

    if type(definition) ~= "table"
        or type(definition.definitionId) ~= "string" or definition.definitionId == ""
        or type(definition.displayName) ~= "string" or definition.displayName == ""
        or type(definition.entity) ~= "string" or definition.entity == ""
        or type(topology) ~= "table" or topology.type ~= "garage"
        or definition.frame ~= false
        or type(geometry) ~= "table"
        or type(packages) ~= "table"
        or weight == nil or weight <= 0
        or tonumber(pickup.breakChance or 0) ~= 0
        or type(replacement) ~= "table"
        or not isEmptyTable(replacement.materials or {})
    then return nil end

    for _, facing in ipairs(FACINGS) do
        local face = geometry[facing]
        if type(face) ~= "table" then return nil end
        for _, role in ipairs(ROLES) do
            if not isPart(face[role]) then return nil end
        end
    end

    local tools, toolError = ToolAdapter.resolve(definition)
    if tools == nil then
        print("[LMION:Pickup] skipped " .. definition.definitionId .. ": " .. tostring(toolError))
        return nil
    end

    return {
        definitionId = definition.definitionId,
        displayName = definition.displayName,
        entityId = definition.entity,
        definition = definition,
        geometry = geometry,
        weight = weight,
        skillLevel = tools.level,
        pickUpTool = tools.pickUpTool,
        placeTool = tools.placeTool,
    }
end

local function getSpriteName(value)
    if type(value) == "string" then return value end
    return value ~= nil and value:getName() or nil
end

local function markMoveable(spriteName)
    local sprite = getSprite(spriteName)
    local properties = sprite and sprite:getProperties() or nil
    if properties ~= nil then properties:set("IsMoveAble") end
end

function GaragePickup.refresh()
    local nextRuntime = {}
    local definitionIds = LMION.getRegisteredDefinitionIds()
    local definitions = 0
    local sprites = 0

    for index = 1, #definitionIds do
        local definition = LMION.getEffectiveDefinition(definitionIds[index])
        local runtime = buildRuntime(definition)
        if runtime ~= nil then
            nextRuntime[runtime.definitionId] = runtime
            definitions = definitions + 1
            for _, facing in ipairs(FACINGS) do
                for _, role in ipairs(ROLES) do
                    local part = runtime.geometry[facing][role]
                    markMoveable(part.closed)
                    markMoveable(part.open)
                    sprites = sprites + 2
                end
            end
        end
    end

    runtimeByDefinitionId = nextRuntime
    return { definitions = definitions, sprites = sprites }
end

function GaragePickup.getRuntime(definitionId)
    return runtimeByDefinitionId[definitionId]
end

function GaragePickup.getParcelIdentity(item)
    local state = item and TransportState.read(item) or nil
    local segment = state and LMION.getGarageSegmentBySprite(state.spriteName) or nil
    local runtime = segment and runtimeByDefinitionId[segment.definitionId] or nil
    if state == nil or segment == nil or runtime == nil then return nil end
    return { definitionId = segment.definitionId, role = segment.role, state = state }
end

local function getRuntime(moveProps)
    local definitionId = moveProps and moveProps.lmionGarageDefinitionId or nil
    return definitionId and runtimeByDefinitionId[definitionId] or nil
end

local function applyMoveProps(moveProps, sprite)
    if moveProps == nil then return moveProps end
    local spriteName = getSpriteName(sprite) or getSpriteName(moveProps.sprite)
    local segment = spriteName and LMION.getGarageSegmentBySprite(spriteName) or nil
    local runtime = segment and runtimeByDefinitionId[segment.definitionId] or nil
    if runtime == nil then return moveProps end

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
    moveProps.lmionGarageDefinitionId = runtime.definitionId
    moveProps.lmionGarageFacing = segment.facing
    moveProps.lmionGarageRole = segment.role
    moveProps.lmionGarageIsOpen = segment.isOpen
    return moveProps
end

local function applyFlatpackPresentation(item)
    if item == nil then return nil end
    local texture = Texture ~= nil and Texture.getSharedTexture ~= nil
        and Texture.getSharedTexture("Item_Flatpack") or nil
    if texture ~= nil and item.setTexture ~= nil then item:setTexture(texture) end
    local modData = item:getModData()
    if modData ~= nil then modData.Flatpack = "true" end
    return item
end

local function getParcelName(runtime, role)
    return runtime.displayName .. " " .. tostring(role)
end

local function finalizeParcel(item, runtime, role)
    if item == nil or runtime == nil then return item end
    item:setActualWeight(runtime.weight)
    item:setWeight(runtime.weight)
    item:setName(getParcelName(runtime, role))
    item:setCustomName(true)
    if isClient() and sendItemStats ~= nil then sendItemStats(item) end
    return item
end

local function getSelectedObject(moveProps, square, object)
    if object ~= nil then return object end
    if moveProps == nil or square == nil then return nil end
    return moveProps:findOnSquare(square, moveProps.spriteName)
end

local function buildPickupPlan(source, runtime)
    if source == nil or runtime == nil then return nil end
    local chain = LMION.getGarageChain(source)
    if chain == nil or chain.definitionId ~= runtime.definitionId then return nil end

    local entries = {}
    for position = 1, chain.length do
        local object = chain.members[position]
        local segment = chain.segments[position]
        local square = object and object:getSquare() or nil
        if object == nil or square == nil or segment == nil
            or segment.definitionId ~= runtime.definitionId
        then return nil end
        entries[position] = { object = object, square = square, segment = segment }
    end

    return { runtime = runtime, chain = chain, entries = entries, length = chain.length }
end

function GaragePickup.getPickupPlan(source)
    local segment = LMION.getGarageSegmentForObject(source)
    local runtime = segment and runtimeByDefinitionId[segment.definitionId] or nil
    return buildPickupPlan(source, runtime)
end

local function canPickUpMember(character, entry)
    local moveProps = ISMoveableSpriteProps.new(entry.segment.spriteName)
    if moveProps == nil then return false end

    -- Garage members are part of one multi-object pickup. Vanilla deliberately
    -- skips inventory-capacity checks for _isMulti=true while still validating
    -- object state, skills, tools and other per-member requirements.
    return moveProps:canPickUpMoveableInternal(
        character,
        entry.square,
        entry.object,
        true
    ) == true
end

local function canPickUpPlan(character, plan)
    if character == nil or plan == nil then return false end
    for position = 1, plan.length do
        local entry = plan.entries[position]
        if not entry.object:isObjectNoContainerOrEmpty()
            or not canPickUpMember(character, entry)
        then return false end
    end
    return true
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
        if runtime == nil then return previousCanPickUp(self, character, square, object) end

        local selected = getSelectedObject(self, square, object)
        local segment = LMION.getGarageSegmentForObject(selected)
        if segment == nil
            or segment.definitionId ~= runtime.definitionId
            or segment.role ~= self.lmionGarageRole
        then return false end

        return canPickUpPlan(character, buildPickupPlan(selected, runtime))
    end

    local previousInstanceItem = ISMoveableSpriteProps.instanceItem
    ISMoveableSpriteProps.instanceItem = function(self, spriteNameOverride)
        local runtime = getRuntime(self)
        if runtime == nil then return previousInstanceItem(self, spriteNameOverride) end

        local item = applyFlatpackPresentation(instanceItem(PARCEL_ITEM))
        if item ~= nil then
            TransportState.write(item, self.lmionGaragePendingState or {})
            finalizeParcel(item, runtime, self.lmionGarageRole)
        end
        return item
    end

    local previousInternal = ISMoveableSpriteProps.pickUpMoveableInternal
    ISMoveableSpriteProps.pickUpMoveableInternal = function(
        self, character, square, object, sprInstance, spriteName, createItem, rotating
    )
        local runtime = getRuntime(self)
        self.lmionGaragePendingState = nil

        if runtime ~= nil and object ~= nil then
            local segment = LMION.getGarageSegmentForObject(object)
            local captured = LMION.captureDoorState(object) or {}
            if segment ~= nil and segment.definitionId == runtime.definitionId then
                self.lmionGaragePendingState = {
                    entityId = runtime.entityId,
                    spriteName = segment.closedSprite,
                    health = captured.health,
                    maxHealth = captured.maxHealth,
                }
            end
        end

        local item = previousInternal(
            self, character, square, object, sprInstance, spriteName, createItem, rotating
        )
        self.lmionGaragePendingState = nil
        if runtime ~= nil then return finalizeParcel(item, runtime, self.lmionGarageRole) end
        return item
    end

    local previousPickUp = ISMoveableSpriteProps.pickUpMoveable
    ISMoveableSpriteProps.pickUpMoveable = function(
        self, character, square, createItem, forceAllow
    )
        local runtime = getRuntime(self)
        if runtime == nil then
            return previousPickUp(self, character, square, createItem, forceAllow)
        end

        local selected = getSelectedObject(self, square, nil)
        local plan = buildPickupPlan(selected, runtime)
        if plan == nil then return false end

        if not forceAllow
            and not character:isMovablesCheat()
            and not ISMoveableDefinitions.cheat
            and not canPickUpPlan(character, plan)
        then return false end

        local items = {}
        for position = 1, plan.length do
            local entry = plan.entries[position]
            local moveProps = ISMoveableSpriteProps.new(entry.segment.closedSprite)
            if moveProps == nil then return false end

            -- This makes vanilla deposit the parcel on the member's square.
            moveProps.isMultiSprite = true
            items[position] = moveProps:pickUpMoveableInternal(
                character,
                entry.square,
                entry.object,
                nil,
                entry.segment.closedSprite,
                createItem,
                forceAllow
            )
        end

        if ISMoveableCursor ~= nil and ISMoveableCursor.clearCacheForAllPlayers ~= nil then
            ISMoveableCursor.clearCacheForAllPlayers()
        end
        return items
    end
end

function GaragePickup.install()
    if installed then return end
    ToolAdapter.install()
    GaragePickup.refresh()
    installHooks()
    Events.OnLoadedTileDefinitions.Add(GaragePickup.refresh)
    Events.OnGameBoot.Add(function()
        local stats = GaragePickup.refresh()
        print("[LMION:Pickup] garage pickup ready: "
            .. tostring(stats.definitions) .. " definitions, "
            .. tostring(stats.sprites) .. " sprites")
    end)
    installed = true
end

return GaragePickup
