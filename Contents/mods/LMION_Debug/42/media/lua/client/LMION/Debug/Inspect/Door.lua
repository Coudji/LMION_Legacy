require "LMION/Debug/Registry"
require "LMION/Debug/Util/Safe"

LMION.Debug.Inspect = LMION.Debug.Inspect or {}

local Debug = LMION.Debug
local Safe = Debug.Util.Safe
local Door = Debug.Inspect.Door or {}
Debug.Inspect.Door = Door

local function hasProperty(object, name)
    if object == nil then
        return false
    end

    local properties = object:getProperties()
    return properties ~= nil and properties:has(name)
end

local function propertyValue(object, name)
    if object == nil then
        return nil
    end

    local properties = object:getProperties()
    if properties == nil or not properties:has(name) then
        return nil
    end

    return properties:get(name)
end

local function isIsoDoor(object)
    return object ~= nil
        and instanceof ~= nil
        and instanceof(object, "IsoDoor") == true
end

local function isIsoThumpable(object)
    return object ~= nil
        and instanceof ~= nil
        and instanceof(object, "IsoThumpable") == true
end

function Door.isDoorLike(object)
    if isIsoDoor(object) then
        return true
    end

    if not isIsoThumpable(object) then
        return false
    end

    if hasProperty(object, "DoubleDoor") or hasProperty(object, "GarageDoor") then
        return true
    end

    local properties = object:getProperties()
    if properties ~= nil then
        if properties:has(IsoFlagType.doorN) or properties:has(IsoFlagType.doorW) then
            return true
        end
    end

    local entityName = propertyValue(object, "EntityScriptName")
    if entityName == nil then
        return false
    end

    local lower = string.lower(tostring(entityName))
    return string.find(lower, "door", 1, true) ~= nil
        or string.find(lower, "gate", 1, true) ~= nil
end

local function entityScriptName(object)
    local value = propertyValue(object, "EntityScriptName")
    if value == nil or tostring(value) == "" then
        return nil
    end
    return tostring(value)
end

local function getDoubleDoorIndex(object)
    return Safe.value("IsoDoor.getDoubleDoorIndex", function()
        return IsoDoor.getDoubleDoorIndex(object)
    end, -1)
end

local function getGarageDoorIndex(object)
    return Safe.value("IsoDoor.getGarageDoorIndex", function()
        return IsoDoor.getGarageDoorIndex(object)
    end, -1)
end

local function memberLabel(object)
    if object == nil then
        return nil
    end

    return Safe.squareString(object:getSquare())
        .. " | "
        .. tostring(Safe.spriteName(object) or "<no sprite>")
end

local function doubleMembers(object)
    local members = {}

    for i = 1, 4 do
        local member = Safe.value("IsoDoor.getDoubleDoorObject", function()
            return IsoDoor.getDoubleDoorObject(object, i)
        end, nil)

        if member ~= nil then
            members[#members + 1] = tostring(i) .. "@" .. memberLabel(member)
        end
    end

    return #members > 0 and table.concat(members, ", ") or "<none>"
end

local function garageLinks(object)
    local first = Safe.value("IsoDoor.getGarageDoorFirst", function()
        return IsoDoor.getGarageDoorFirst(object)
    end, nil)
    local prev = Safe.value("IsoDoor.getGarageDoorPrev", function()
        return IsoDoor.getGarageDoorPrev(object)
    end, nil)
    local next = Safe.value("IsoDoor.getGarageDoorNext", function()
        return IsoDoor.getGarageDoorNext(object)
    end, nil)

    return "first=" .. tostring(memberLabel(first) or "<nil>")
        .. ", prev=" .. tostring(memberLabel(prev) or "<nil>")
        .. ", next=" .. tostring(memberLabel(next) or "<nil>")
end

Debug.registerInspector("door.runtime", 10, function(object, report)
    if not Door.isDoorLike(object) then
        return
    end

    local doubleDoorIndex = getDoubleDoorIndex(object)
    local garageDoorIndex = getGarageDoorIndex(object)
    local entityName = entityScriptName(object)

    report:section("Object")
    report:field("class", Safe.shortClassName(object))
    report:field("square", Safe.squareString(object:getSquare()))
    report:field("sprite", Safe.spriteName(object))

    if entityName ~= nil then
        report:field("entity", entityName)
    end

    report:section("Door")
    report:field("orientation", object:getNorth() and "N" or "W")
    report:field("open", object:IsOpen())
    report:field("health", tostring(object:getHealth()) .. " / " .. tostring(object:getMaxHealth()))
    report:field("locked", object:isLocked())
    report:field("lockedByKey", object:isLockedByKey())
    report:field("keyId", object:getKeyId())
    report:field("barricaded", object:isBarricaded())

    if isIsoDoor(object) then
        report:field("curtains", object:HasCurtains())
    end

    if type(garageDoorIndex) == "number" and garageDoorIndex >= 0 then
        report:field("group", "garage")
        report:field("garageDoorIndex", garageDoorIndex)
        report:field("garage", garageLinks(object))
    elseif type(doubleDoorIndex) == "number" and doubleDoorIndex >= 0 then
        report:field("group", "double")
        report:field("doubleDoorIndex", doubleDoorIndex)
        report:field("members", doubleMembers(object))
    else
        report:field("group", "single")
    end
end)

return Door
