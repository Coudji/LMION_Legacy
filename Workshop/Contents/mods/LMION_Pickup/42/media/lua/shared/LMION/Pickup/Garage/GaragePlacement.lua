local LMION = require "LMION/API"
local ParcelUtils = require "LMION/Pickup/Common/ParcelUtils"
local GaragePickup = require "LMION/Pickup/Garage/GaragePickup"
local TransportState = require "LMION/Pickup/TransportState"

local GaragePlacement = {}

local ROLES = { "START", "MIDDLE", "END" }


local function itemMatches(item, definitionId, role)
    local identity = GaragePickup.getParcelIdentity(item)

    return identity ~= nil
        and identity.definitionId == definitionId
        and identity.role == role
end


local function appendParcel(target, item, source, definitionId, role, seen)
    if item == nil
        or source == nil
        or seen[item]
        or not itemMatches(item, definitionId, role)
    then
        return
    end

    seen[item] = true
    target[#target + 1] = {
        item = item,
        source = source,
    }
end


local function collectRoleParcels(character, definitionId, role, preferred)
    local found = {}
    local seen = {}

    if preferred ~= nil and itemMatches(preferred, definitionId, role) then
        local container = preferred:getContainer()
        if container ~= nil then
            appendParcel(found, preferred, container, definitionId, role, seen)
        else
            local worldItem = preferred.getWorldItem ~= nil
                and preferred:getWorldItem()
                or nil
            if worldItem ~= nil and worldItem:getSquare() ~= nil then
                appendParcel(found, preferred, "floor", definitionId, role, seen)
            end
        end
    end

    local inventory = character and character:getInventory() or nil
    local items = inventory and inventory:getItems() or nil

    if items ~= nil then
        for index = 0, items:size() - 1 do
            appendParcel(
                found,
                items:get(index),
                inventory,
                definitionId,
                role,
                seen
            )
        end
    end

    local playerSquare = character and character:getSquare() or nil
    if playerSquare == nil then
        return found
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
                        appendParcel(
                            found,
                            worldObject:getItem(),
                            "floor",
                            definitionId,
                            role,
                            seen
                        )
                    end
                end
            end
        end
    end

    return found
end


local function collectParcels(character, definitionId, preferred)
    local preferredIdentity = preferred
        and GaragePickup.getParcelIdentity(preferred)
        or nil

    local result = {}
    for _, role in ipairs(ROLES) do
        result[role] = collectRoleParcels(
            character,
            definitionId,
            role,
            preferredIdentity ~= nil
                and preferredIdentity.definitionId == definitionId
                and preferredIdentity.role == role
                and preferred
                or nil
        )
    end

    return result
end


local function maximumLength(parts)
    if parts == nil
        or #parts.START < 1
        or #parts.END < 1
    then
        return nil
    end

    local maximum = 2 + #parts.MIDDLE
    local policyMaximum = LMION.getGarageMaxLength()

    if policyMaximum ~= nil then
        maximum = math.min(maximum, policyMaximum)
    end

    return maximum
end


function GaragePlacement.findAvailableParcel(
    character,
    definitionId,
    role,
    preferred
)
    if GaragePickup.getRuntime(definitionId) == nil then
        return nil, nil
    end

    local found = collectRoleParcels(
        character,
        definitionId,
        role,
        preferred
    )
    local parcel = found[1]

    if parcel == nil then
        return nil, nil
    end

    return parcel.item, parcel.source
end


function GaragePlacement.getMaximumAvailableLength(character, definitionId, preferred)
    if GaragePickup.getRuntime(definitionId) == nil then
        return nil
    end

    return maximumLength(collectParcels(character, definitionId, preferred))
end


function GaragePlacement.clampLength(character, definitionId, requested, preferred)
    local maximum = GaragePlacement.getMaximumAvailableLength(
        character,
        definitionId,
        preferred
    )
    if maximum == nil then
        return nil
    end

    requested = math.floor(tonumber(requested) or maximum)
    return math.max(2, math.min(requested, maximum))
end


local function getRoleForPosition(position, length)
    if position == 1 then
        return "START"
    end

    if position == length then
        return "END"
    end

    return "MIDDLE"
end


local function getTargetSquare(startSquare, facing, position)
    local topology = LMION.getGarageTopology()
    local step = topology
        and topology.step
        and topology.step[facing]
        or nil

    if startSquare == nil or type(step) ~= "table" then
        return nil
    end

    local offset = position - 1
    return getCell():getGridSquare(
        startSquare:getX() + (tonumber(step.x) or 0) * offset,
        startSquare:getY() + (tonumber(step.y) or 0) * offset,
        startSquare:getZ()
    )
end


function GaragePlacement.buildPlan(character, item, length, facing, startSquare)
    local identity = GaragePickup.getParcelIdentity(item)
    local runtime = identity and GaragePickup.getRuntime(identity.definitionId) or nil

    if runtime == nil
        or startSquare == nil
        or (facing ~= "N" and facing ~= "W")
    then
        return nil
    end

    local parts = collectParcels(character, runtime.definitionId, item)
    local maximum = maximumLength(parts)
    length = tonumber(length)

    if maximum == nil
        or length == nil
        or length ~= math.floor(length)
        or length < 2
        or length > maximum
        or not LMION.isGarageLengthAllowed(length)
    then
        return nil
    end

    local plan = {
        runtime = runtime,
        definitionId = runtime.definitionId,
        facing = facing,
        length = length,
        valid = true,
    }
    local middleIndex = 1

    for position = 1, length do
        local role = getRoleForPosition(position, length)
        local parcel = nil

        if role == "START" then
            parcel = parts.START[1]
        elseif role == "END" then
            parcel = parts.END[1]
        else
            parcel = parts.MIDDLE[middleIndex]
            middleIndex = middleIndex + 1
        end

        local geometry = runtime.geometry[facing][role]
        local square = getTargetSquare(startSquare, facing, position)

        if parcel == nil or square == nil or geometry == nil then
            return nil
        end

        plan[position] = {
            role = role,
            item = parcel.item,
            source = parcel.source,
            square = square,
            spriteName = geometry.closed,
            valid = false,
        }
    end

    return plan
end


local function getSingleSegmentMoveProps(entry)
    local moveProps = entry
        and entry.spriteName
        and ISMoveableSpriteProps.new(entry.spriteName)
        or nil

    if moveProps == nil or not moveProps.isMoveable then
        return nil
    end

    moveProps.isMultiSprite = false
    return moveProps
end


function GaragePlacement.validatePlan(character, plan)
    if character == nil
        or plan == nil
        or not LMION.isGarageLengthAllowed(plan.length)
    then
        return false
    end

    local allValid = true

    for position = 1, plan.length do
        local entry = plan[position]
        local moveProps = getSingleSegmentMoveProps(entry)
        local valid = moveProps ~= nil
            and entry.item ~= nil
            and entry.square ~= nil
            and moveProps:canPlaceMoveableInternal(
                character,
                entry.square,
                entry.item
            )
            and LMION.canPlaceDoorAt(
                entry.square,
                plan.facing,
                false,
                nil
            )

        entry.valid = valid == true
        if not valid then
            allValid = false
        end
    end

    plan.valid = allValid
    return allValid
end


function GaragePlacement.getMoveProps(item, facing)
    local identity = GaragePickup.getParcelIdentity(item)
    local runtime = identity and GaragePickup.getRuntime(identity.definitionId) or nil
    local part = runtime
        and runtime.geometry
        and runtime.geometry[facing]
        and runtime.geometry[facing].START
        or nil

    if part == nil then
        return nil
    end

    return getSingleSegmentMoveProps({ spriteName = part.closed })
end


local function removeWorldObject(object)
    local square = object and object:getSquare() or nil
    if object == nil or square == nil then
        return
    end

    square:transmitRemoveItemFromSquare(object)
    square:RecalcAllWithNeighbours(true)
end


local function rollbackPlaced(objects)
    for index = #objects, 1, -1 do
        removeWorldObject(objects[index])
    end
end


function GaragePlacement.placePlan(character, plan)
    if not GaragePlacement.validatePlan(character, plan) then
        return false
    end

    local placed = {}

    for position = 1, plan.length do
        local entry = plan[position]
        local moveProps = getSingleSegmentMoveProps(entry)

        if moveProps == nil then
            rollbackPlaced(placed)
            return false
        end

        local object = moveProps:placeMoveableInternal(
            entry.square,
            entry.item,
            entry.spriteName
        )

        if object == nil then
            rollbackPlaced(placed)
            return false
        end

        local door = LMION.finalizePlacedGarageSegment(
            object,
            plan.runtime.definition,
            plan.facing,
            entry.role
        )

        if door == nil then
            removeWorldObject(object)
            rollbackPlaced(placed)
            return false
        end

        TransportState.clearFromObject(door)
        LMION.restoreDoorState(door, TransportState.read(entry.item))
        placed[position] = door

        if isServer() then
            door:transmitCompleteItemToClients()
        end
    end

    for position = 1, plan.length do
        local entry = plan[position]
        ParcelUtils.consume(entry.item, entry.source)
        buildUtil.setHaveConstruction(entry.square, true)
    end

    if ISMoveableCursor ~= nil
        and ISMoveableCursor.clearCacheForAllPlayers ~= nil
    then
        ISMoveableCursor.clearCacheForAllPlayers()
    end

    return true
end


return GaragePlacement
