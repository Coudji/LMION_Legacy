require "LMION/Debug/Registry"
require "LMION/Debug/Util/Safe"
require "LMION/Debug/Util/Reflection"
require "LMION/Debug/Inspect/Options"

local Debug = LMION.Debug
local Safe = Debug.Util.Safe
local Reflection = Debug.Util.Reflection
local Options = Debug.Inspect.Options

local function isDoorLikeThumpable(object)
    if object == nil
        or instanceof == nil
        or instanceof(object, "IsoThumpable") ~= true then
        return false
    end

    if Reflection.hasMethod(object, "isDoor", 0) and object:isDoor() then
        return true
    end

    local properties = object:getProperties()

    if properties == nil then
        return false
    end

    return properties:has(IsoFlagType.doorN)
        or properties:has(IsoFlagType.doorW)
        or properties:has("DoubleDoor")
        or properties:has("GarageDoor")
end

local function spriteName(sprite)
    if sprite == nil then
        return nil
    end

    return Safe.value("sprite.getName", function()
        return sprite:getName()
    end, tostring(sprite))
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

local function groupSummary(doubleDoorIndex, garageDoorIndex)
    if type(garageDoorIndex) == "number" and garageDoorIndex >= 0 then
        return "garage[" .. tostring(garageDoorIndex) .. "]"
    end
    if type(doubleDoorIndex) == "number" and doubleDoorIndex >= 0 then
        return "double[" .. tostring(doubleDoorIndex) .. "]"
    end
    return "single"
end

local function securitySummary(object)
    local parts = {}

    if object:isLocked() then
        parts[#parts + 1] = "locked"
    else
        parts[#parts + 1] = "unlocked"
    end

    if object:isLockedByKey() then
        parts[#parts + 1] = "key=" .. tostring(object:getKeyId())
    end

    if object:isBarricaded() then
        parts[#parts + 1] = "barricaded"
    end

    return table.concat(parts, ", ")
end

Debug.registerInspector("vanilla.isoThumpableDoor", 55, function(object, report)
    if not isDoorLikeThumpable(object) then
        return
    end

    local doubleDoorIndex = getDoubleDoorIndex(object)
    local garageDoorIndex = getGarageDoorIndex(object)
    local openSprite = Reflection.hasMethod(object, "getOpenSprite", 0)
        and spriteName(object:getOpenSprite())
        or Reflection.getSpriteFieldName(object, "openSprite")
    local closedSprite = Reflection.getSpriteFieldName(object, "closedSprite")

    report:section("Door")

    if not Options.isFullDetails() then
        if Reflection.hasMethod(object, "getEntityFullTypeDebug", 0) then
            local entityType = object:getEntityFullTypeDebug()
            if entityType ~= nil and tostring(entityType) ~= "" then
                report:field("entityType", entityType)
            end
        end

        report:field("state", (object:getNorth() and "N" or "W") .. ", " .. (object:IsOpen() and "open" or "closed"))
        report:field("health", tostring(object:getHealth()) .. " / " .. tostring(object:getMaxHealth()))
        report:field("security", securitySummary(object))
        report:field("closedSprite", closedSprite)
        report:field("openSprite", openSprite)
        report:field("group", groupSummary(doubleDoorIndex, garageDoorIndex))
        return
    end

    if Reflection.hasMethod(object, "getEntityFullTypeDebug", 0) then
        report:field("entityType", object:getEntityFullTypeDebug())
    end

    report:field("isDoor", Reflection.hasMethod(object, "isDoor", 0) and object:isDoor() or false)
    report:field("north", object:getNorth())
    report:field("open", object:IsOpen())
    report:field("locked", object:isLocked())
    report:field("lockedByKey", object:isLockedByKey())
    report:field("keyId", object:getKeyId())
    report:field("health", tostring(object:getHealth()) .. " / " .. tostring(object:getMaxHealth()))
    report:field("barricaded", object:isBarricaded())

    if Reflection.hasMethod(object, "isDestroyed", 0) then
        report:field("destroyed", object:isDestroyed())
    end

    report:field("closedSprite", closedSprite)
    report:field("openSprite", openSprite)
    report:field("oppositeSquare", Safe.squareString(object:getOppositeSquare()))
    report:field("doubleDoorIndex", doubleDoorIndex)
    report:field("garageDoorIndex", garageDoorIndex)

    dumpDoubleDoorGroup(object, report, doubleDoorIndex)
    dumpGarageGroup(object, report, garageDoorIndex)

    report:field("hoppable", object:isHoppable())

    if Reflection.hasMethod(object, "isDismantable", 0) then
        report:field("dismantable", object:isDismantable())
    end

    if Reflection.hasMethod(object, "getCanBarricade", 0) then
        report:field("canBarricade", object:getCanBarricade())
    end

    if Reflection.hasMethod(object, "isCanPassThrough", 0) then
        report:field("canPassThrough", object:isCanPassThrough())
    end

    if Reflection.hasMethod(object, "getThumpSound", 0) then
        report:field("thumpSound", object:getThumpSound())
    end

    if Reflection.hasMethod(object, "isDoorFrame", 0) then
        report:field("doorFrame", object:isDoorFrame())
    end

    report:field("closedSprite.source", "reflection:closedSprite")
    report:field(
        "openSprite.source",
        Reflection.hasMethod(object, "getOpenSprite", 0)
            and "public:getOpenSprite"
            or "reflection:openSprite"
    )
end)
