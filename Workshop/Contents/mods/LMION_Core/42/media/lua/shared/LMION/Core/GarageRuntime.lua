local DoorRuntime = require "LMION/Core/DoorRuntime"
local GarageTopology = require "LMION/Core/GarageTopology"
local Registry = require "LMION/Core/Registry"
local Resolver = require "LMION/Core/Resolver"

local GarageRuntime = {}

local FACINGS = { "N", "W" }
local ROLE_NAMES = { "START", "MIDDLE", "END" }

local dirty = true
local segmentsBySprite = {}
local definitionsById = {}


local function isGarageDefinition(definition)
    local topology = definition and definition.topology or nil
    return type(definition) == "table"
        and type(definition.definitionId) == "string"
        and definition.definitionId ~= ""
        and type(topology) == "table"
        and topology.type == "garage"
end


local function isGeometryPart(part)
    return type(part) == "table"
        and type(part.closed) == "string"
        and part.closed ~= ""
        and type(part.open) == "string"
        and part.open ~= ""
end


local function validateGeometry(definition)
    local geometry = definition.geometry
    if type(geometry) ~= "table" then
        return false
    end

    for _, facing in ipairs(FACINGS) do
        local face = geometry[facing]
        if type(face) ~= "table" then
            return false
        end

        for _, roleName in ipairs(ROLE_NAMES) do
            if not isGeometryPart(face[roleName]) then
                return false
            end
        end
    end

    return true
end


local function addSprite(index, definitionId, facing, roleName, isOpen, spriteName, part)
    if index[spriteName] ~= nil then
        error("LMION: duplicate garage sprite " .. tostring(spriteName), 3)
    end

    local topology = GarageTopology.get()

    index[spriteName] = {
        definitionId = definitionId,
        facing = facing,
        role = roleName,
        roleIndex = topology.roles[roleName],
        isOpen = isOpen,
        spriteName = spriteName,
        closedSprite = part.closed,
        openSprite = part.open,
    }
end


function GarageRuntime.invalidate()
    dirty = true
end


function GarageRuntime.rebuild()
    local nextSegments = {}
    local nextDefinitions = {}
    local definitionIds = Registry.getDefinitionIds()

    for index = 1, #definitionIds do
        local definitionId = definitionIds[index]
        local definition = Resolver.resolveDefinition(definitionId)

        if isGarageDefinition(definition) then
            if not validateGeometry(definition) then
                error(
                    "LMION: garage definition "
                        .. definitionId
                        .. " has invalid geometry",
                    2
                )
            end

            nextDefinitions[definitionId] = definition

            for _, facing in ipairs(FACINGS) do
                local face = definition.geometry[facing]

                for _, roleName in ipairs(ROLE_NAMES) do
                    local part = face[roleName]
                    addSprite(
                        nextSegments,
                        definitionId,
                        facing,
                        roleName,
                        false,
                        part.closed,
                        part
                    )
                    addSprite(
                        nextSegments,
                        definitionId,
                        facing,
                        roleName,
                        true,
                        part.open,
                        part
                    )
                end
            end
        end
    end

    segmentsBySprite = nextSegments
    definitionsById = nextDefinitions
    dirty = false
end


local function ensureBuilt()
    if dirty then
        GarageRuntime.rebuild()
    end
end


function GarageRuntime.getSegmentBySprite(spriteName)
    if type(spriteName) ~= "string" or spriteName == "" then
        return nil
    end

    ensureBuilt()
    return segmentsBySprite[spriteName]
end


local function getFacing(object)
    if object == nil or object.getNorth == nil then
        return nil
    end

    return object:getNorth() and "N" or "W"
end


local function getEngineRoleIndex(object)
    if object == nil
        or IsoDoor == nil
        or IsoDoor.getGarageDoorIndex == nil
    then
        return nil
    end

    local ok, roleIndex = pcall(IsoDoor.getGarageDoorIndex, object)
    roleIndex = ok and tonumber(roleIndex) or nil

    local topology = GarageTopology.get()
    return topology.roleNames[roleIndex] ~= nil and roleIndex or nil
end


function GarageRuntime.getSegmentForObject(object)
    if not DoorRuntime.isIsoDoor(object) then
        return nil
    end

    local sprite = object:getSprite()
    local spriteName = sprite and sprite:getName() or nil
    local segment = GarageRuntime.getSegmentBySprite(spriteName)

    if segment == nil
        or segment.facing ~= getFacing(object)
        or segment.roleIndex ~= getEngineRoleIndex(object)
        or segment.isOpen ~= object:IsOpen()
    then
        return nil
    end

    return segment
end


local function matchesChainMember(object, expected)
    local segment = GarageRuntime.getSegmentForObject(object)

    return segment ~= nil
        and segment.definitionId == expected.definitionId
        and segment.facing == expected.facing
        and segment.isOpen == expected.isOpen,
        segment
end


function GarageRuntime.getChain(source)
    local sourceSegment = GarageRuntime.getSegmentForObject(source)
    if sourceSegment == nil
        or IsoDoor == nil
        or IsoDoor.getGarageDoorFirst == nil
        or IsoDoor.getGarageDoorNext == nil
    then
        return nil
    end

    local first = IsoDoor.getGarageDoorFirst(source)
    if first == nil then
        return nil
    end

    local expected = {
        definitionId = sourceSegment.definitionId,
        facing = sourceSegment.facing,
        isOpen = sourceSegment.isOpen,
    }

    local members = {}
    local segments = {}
    local seen = {}
    local current = first

    while current ~= nil do
        if seen[current] then
            return nil
        end
        seen[current] = true

        local matches, segment = matchesChainMember(current, expected)
        if not matches then
            return nil
        end

        local position = #members + 1
        if position == 1 then
            if segment.role ~= "START" then
                return nil
            end
        elseif segment.role == "START" then
            return nil
        end

        members[position] = current
        segments[position] = segment

        if segment.role == "END" then
            if position < GarageTopology.get().minLength then
                return nil
            end

            ensureBuilt()
            return {
                definitionId = expected.definitionId,
                definition = definitionsById[expected.definitionId],
                facing = expected.facing,
                isOpen = expected.isOpen,
                members = members,
                segments = segments,
                length = position,
            }
        end

        if segment.role ~= "MIDDLE" and position > 1 then
            return nil
        end

        current = IsoDoor.getGarageDoorNext(current)
    end

    return nil
end


function GarageRuntime.finalizeSegment(object, definition, facing, role)
    if not DoorRuntime.isDoorObject(object)
        or not isGarageDefinition(definition)
        or (facing ~= "N" and facing ~= "W")
        or GarageTopology.get().roles[role] == nil
        or not validateGeometry(definition)
    then
        return nil
    end

    local part = definition.geometry[facing][role]
    local closedSprite = getSprite(part.closed)
    local openSprite = getSprite(part.open)

    if closedSprite == nil or openSprite == nil then
        return nil
    end

    local door = DoorRuntime.ensureCanonicalDoor(object)
    if door == nil or door:getNorth() ~= (facing == "N") then
        return nil
    end

    door:setSprite(closedSprite)

    if door.setOpenSprite ~= nil then
        door:setOpenSprite(openSprite)
    end

    if door.setOpen ~= nil then
        door:setOpen(false)
    end

    return door
end


return GarageRuntime
