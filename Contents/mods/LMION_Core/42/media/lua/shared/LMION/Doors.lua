--[[
    Let Me In... Or Not - Core door-model registry.

    Core owns only the shared identity and placement-facing representation
    of a door model. Feature modules may attach their own data by owner id.
]]

require "LMION/Core"

LMION.Doors = LMION.Doors or {}
local Doors = LMION.Doors

Doors.Models = Doors.Models or {}
Doors.Extensions = Doors.Extensions or {}

local function isValidId(doorId)
    return type(doorId) == "string" and doorId ~= ""
end

local function cloneShallow(source)
    local copy = {}
    if type(source) ~= "table" then
        return copy
    end

    for key, value in pairs(source) do
        copy[key] = value
    end

    return copy
end

function Doors.register(doorId, model)
    if not isValidId(doorId) then
        LMION.error("Doors", "register(): invalid doorId")
        return false
    end

    if type(model) ~= "table" then
        LMION.error("Doors", "register(): model must be a table")
        return false
    end

    local stored = cloneShallow(model)
    stored.doorId = doorId

    Doors.Models[doorId] = stored
    LMION.emit("doors.modelRegistered", doorId, stored)
    return true
end

function Doors.extend(doorId, ownerId, data)
    if not isValidId(doorId) then
        LMION.error("Doors", "extend(): invalid doorId")
        return false
    end

    if not isValidId(ownerId) then
        LMION.error("Doors", "extend(): invalid ownerId")
        return false
    end

    if type(data) ~= "table" then
        LMION.error("Doors", "extend(): data must be a table")
        return false
    end

    Doors.Extensions[doorId] = Doors.Extensions[doorId] or {}
    Doors.Extensions[doorId][ownerId] = data
    LMION.emit("doors.modelExtended", doorId, ownerId, data)
    return true
end

function Doors.get(doorId)
    return Doors.Models[doorId]
end

function Doors.getExtension(doorId, ownerId)
    local byOwner = Doors.Extensions[doorId]
    if byOwner == nil then
        return nil
    end
    return byOwner[ownerId]
end

function Doors.getExtensions(doorId)
    return Doors.Extensions[doorId]
end

function Doors.getAll()
    return Doors.Models
end

function Doors.getCount()
    local count = 0
    for _ in pairs(Doors.Models) do
        count = count + 1
    end
    return count
end

function Doors.onCreateGarage(params)
    local thumpable = params and params.thumpable or nil
    if thumpable == nil then
        return nil
    end

    local square = thumpable:getSquare()
    local garageDoor = IsoDoor.new(
        getCell(),
        square,
        thumpable:getSprite(),
        thumpable:getNorth()
    )

    garageDoor:setName(thumpable:getName())
    garageDoor:setModData(copyTable(thumpable:getModData()))
    garageDoor:setKeyId(thumpable:getKeyId())
    garageDoor:setIsLocked(false)
    garageDoor:setLockedByKey(false)
    garageDoor:setHealth(thumpable:getHealth())

    if GameEntityFactory ~= nil then
        local properties = garageDoor:getProperties()
        if properties ~= nil and properties:has(IsoFlagType.EntityScript) then
            GameEntityFactory.CreateIsoEntityFromCellLoading(garageDoor)
        end
    end

    square:AddSpecialObject(garageDoor)
    square:transmitRemoveItemFromSquare(thumpable)

    return {
        replaceObject = true,
        object = garageDoor,
    }
end

return Doors
