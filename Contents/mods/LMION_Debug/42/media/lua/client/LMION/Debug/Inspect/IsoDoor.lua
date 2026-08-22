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

local function objectLabel(object)
    if object == nil then
        return nil
    end

    return Safe.squareString(object:getSquare())
        .. " / "
        .. Safe.objectLabel(object)
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

local function getOpenSpriteInfo(object)
    if Reflection.hasMethod(object, "getOpenSprite", 0) then
        return spriteName(object:getOpenSprite()), "public:getOpenSprite"
    end

    return Reflection.getSpriteFieldName(object, "openSprite"), "reflection:openSprite"
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

    if Reflection.hasMethod(object, "HasCurtains", 0) and object:HasCurtains() then
        parts[#parts + 1] = "curtains"
    end

    return table.concat(parts, ", ")
end

Debug.registerInspector("vanilla.isoDoor", 50, function(object, report)
    if not isIsoDoor(object) then
        return
    end

    local doubleDoorIndex = getDoubleDoorIndex(object)
    local garageDoorIndex = getGarageDoorIndex(object)
    local openSprite, openSpriteSource = getOpenSpriteInfo(object)
    local closedSprite = Reflection.getSpriteFieldName(object, "closedSprite")
    local hasCurtains = Reflection.hasMethod(object, "HasCurtains", 0)
        and object:HasCurtains()
        or false

    report:section("Door")

    if not Options.isFullDetails() then
        report:field("state", (object:getNorth() and "N" or "W") .. ", " .. (object:IsOpen() and "open" or "closed"))
        report:field("health", tostring(object:getHealth()) .. " / " .. tostring(object:getMaxHealth()))
        report:field("security", securitySummary(object))
        report:field("closedSprite", closedSprite)
        report:field("openSprite", openSprite)
        report:field("group", groupSummary(doubleDoorIndex, garageDoorIndex))
        return
    end

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

    if Reflection.hasMethod(object, "isObstructed", 0) then
        report:field("obstructed", object:isObstructed())
    end

    report:field("curtains", hasCurtains)

    if hasCurtains and Reflection.hasMethod(object, "isCurtainOpen", 0) then
        report:field("curtainOpen", object:isCurtainOpen())
    end

    report:field("closedSprite", closedSprite)
    report:field("openSprite", openSprite)
    report:field("oppositeSquare", Safe.squareString(object:getOppositeSquare()))
    report:field("doubleDoorIndex", doubleDoorIndex)
    report:field("garageDoorIndex", garageDoorIndex)

    dumpDoubleDoorGroup(object, report, doubleDoorIndex)
    dumpGarageGroup(object, report, garageDoorIndex)

    report:field("exterior", object:isExterior())
    report:field("hoppable", object:isHoppable())

    if Reflection.hasMethod(object, "haveKey", 0) then
        report:field("haveKey", object:haveKey())
    end

    if Reflection.hasMethod(object, "isBarricadeAllowed", 0) then
        report:field("barricadeAllowed", object:isBarricadeAllowed())
    end

    if Reflection.hasMethod(object, "getBarricadeOnSameSquare", 0) then
        report:field("barricade.sameSquare", objectLabel(object:getBarricadeOnSameSquare()))
    end

    if Reflection.hasMethod(object, "getBarricadeOnOppositeSquare", 0) then
        report:field("barricade.oppositeSquare", objectLabel(object:getBarricadeOnOppositeSquare()))
    end

    if Reflection.hasMethod(object, "canAddCurtain", 0) then
        report:field("canAddCurtain", object:canAddCurtain())
    end

    if hasCurtains and Reflection.hasMethod(object, "getSheetSquare", 0) then
        report:field("sheetSquare", Safe.squareString(object:getSheetSquare()))
    end

    if Reflection.hasMethod(object, "getThumpCondition", 0) then
        report:field("thumpCondition", object:getThumpCondition())
    end

    if Reflection.hasMethod(object, "IsStrengthenedByPushedItems", 0) then
        report:field("strengthenedByPushedItems", object:IsStrengthenedByPushedItems())
    end

    report:field("closedSprite.source", "reflection:closedSprite")
    report:field("openSprite.source", openSpriteSource)
end)
