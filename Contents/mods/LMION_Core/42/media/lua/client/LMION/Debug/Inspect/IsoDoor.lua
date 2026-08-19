require "LMION/Debug/Registry"
require "LMION/Debug/Util/Safe"
require "LMION/Debug/Util/Reflection"
require "LMION/Debug/Inspect/Options"

local Debug = LMION.Debug
local Safe = Debug.Util.Safe
local Reflection = Debug.Util.Reflection
local Options = Debug.Inspect.Options

local function isIsoDoor(object)
    return object ~= nil
        and instanceof ~= nil
        and instanceof(object, "IsoDoor") == true
end

local function spriteLabel(object)
    if object == nil then
        return nil
    end

    return Safe.squareString(object:getSquare())
        .. " / "
        .. tostring(Safe.spriteName(object) or "<no sprite>")
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

local function dumpDoubleDoorGroup(object, report, doubleDoorIndex)
    if type(doubleDoorIndex) ~= "number" or doubleDoorIndex < 0 then
        return
    end

    for i = 1, 4 do
        local member = Safe.value("IsoDoor.getDoubleDoorObject", function()
            return IsoDoor.getDoubleDoorObject(object, i)
        end, nil)

        if member ~= nil then
            report:field("doubleDoorObject[" .. tostring(i) .. "]", spriteLabel(member))
        end
    end
end

local function dumpGarageGroup(object, report, garageDoorIndex)
    if type(garageDoorIndex) ~= "number" or garageDoorIndex < 0 then
        return
    end

    local first = Safe.value("IsoDoor.getGarageDoorFirst", function()
        return IsoDoor.getGarageDoorFirst(object)
    end, nil)

    local prev = Safe.value("IsoDoor.getGarageDoorPrev", function()
        return IsoDoor.getGarageDoorPrev(object)
    end, nil)

    local next = Safe.value("IsoDoor.getGarageDoorNext", function()
        return IsoDoor.getGarageDoorNext(object)
    end, nil)

    report:field("garage.first", first ~= nil and spriteLabel(first) or nil)
    report:field("garage.prev", prev ~= nil and spriteLabel(prev) or nil)
    report:field("garage.next", next ~= nil and spriteLabel(next) or nil)
end

Debug.registerInspector("vanilla.isoDoor", 50, function(object, report)
    if not isIsoDoor(object) then
        return
    end

    local doubleDoorIndex = getDoubleDoorIndex(object)
    local garageDoorIndex = getGarageDoorIndex(object)

    report:section("IsoDoor")
    report:field("north", object:getNorth())
    report:field("open", object:IsOpen())
    report:field("locked", object:isLocked())
    report:field("lockedByKey", object:isLockedByKey())
    report:field("keyId", object:getKeyId())
    report:field("health", tostring(object:getHealth()) .. " / " .. tostring(object:getMaxHealth()))
    report:field("barricaded", object:isBarricaded())
    report:field("closedSprite", Reflection.getSpriteFieldName(object, "closedSprite"))
    report:field("openSprite", Reflection.getSpriteFieldName(object, "openSprite"))
    report:field("oppositeSquare", Safe.squareString(object:getOppositeSquare()))
    report:field("doubleDoorIndex", doubleDoorIndex)
    report:field("garageDoorIndex", garageDoorIndex)

    -- Group linkage is valuable even in the clean report when the object is
    -- actually part of a grouped opening.
    dumpDoubleDoorGroup(object, report, doubleDoorIndex)
    dumpGarageGroup(object, report, garageDoorIndex)

    if not Options.isFullDetails() then
        return
    end

    report:section("IsoDoor details")
    report:field("maxHealth", object:getMaxHealth())
    report:field("exterior", object:isExterior())
    report:field("hoppable", object:isHoppable())
    report:field("closedSprite.source", "reflection: closedSprite")
    report:field("openSprite.source", "reflection: openSprite")
end)
