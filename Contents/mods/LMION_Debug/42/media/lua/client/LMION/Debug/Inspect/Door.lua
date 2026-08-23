require "LMION/Debug/Registry"
require "LMION/Debug/Util/Safe"
require "Moveables/ISMoveableSpriteProps"

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

local function spriteProperties(object)
    if object == nil then
        return nil
    end

    local sprite = object:getSprite()
    return sprite ~= nil and sprite:getProperties() or nil
end

local function spriteHasProperty(object, name)
    local properties = spriteProperties(object)
    return properties ~= nil and properties:has(name)
end

local function spritePropertyValue(object, name)
    local properties = spriteProperties(object)
    if properties == nil or not properties:has(name) then
        return nil
    end

    return properties:get(name)
end

local function spriteHasFlag(object, flag)
    local properties = spriteProperties(object)
    return properties ~= nil and properties:has(flag)
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

local function reportMoveables(object, report)
    local sprite = object and object:getSprite() or nil
    if sprite == nil then
        return
    end

    local moveProps = Safe.value("ISMoveableSpriteProps.new", function()
        return ISMoveableSpriteProps.new(sprite)
    end, nil)

    report:section("Moveables")
    report:field("raw.IsMoveAble", spriteHasProperty(object, "IsMoveAble"))
    report:field("raw.MoveType", spritePropertyValue(object, "MoveType"))
    report:field("raw.IsoType", spritePropertyValue(object, "IsoType"))
    report:field("raw.CustomName", spritePropertyValue(object, "CustomName"))
    report:field("raw.GroupName", spritePropertyValue(object, "GroupName"))
    report:field("raw.Facing", spritePropertyValue(object, "Facing"))
    report:field("raw.WallOverlay", spriteHasFlag(object, IsoFlagType.WallOverlay))

    if moveProps == nil then
        report:field("parsed", "<nil>")
        return
    end

    report:field("parsed.isMoveable", moveProps.isMoveable)
    report:field("parsed.name", moveProps.name)
    report:field("parsed.type", moveProps.type)
    report:field("parsed.isoType", moveProps.isoType)
    report:field("parsed.facing", moveProps.facing)
    report:field("parsed.offsets", "N=" .. tostring(moveProps.Noffset)
        .. ", W=" .. tostring(moveProps.Woffset)
        .. ", S=" .. tostring(moveProps.Soffset)
        .. ", E=" .. tostring(moveProps.Eoffset))
    report:field("parsed.pickUpTool", moveProps.pickUpTool)
    report:field("parsed.placeTool", moveProps.placeTool)
    report:field("parsed.pickUpLevel", moveProps.pickUpLevel)
    report:field("parsed.weight", moveProps.weight)

    local expectedItemType = "Moveables." .. tostring(moveProps.spriteName)
    report:field("parsed.expectedItemType", expectedItemType)

    local item = Safe.value("ISMoveableSpriteProps.instanceItem", function()
        return moveProps:instanceItem()
    end, nil)
    report:field("parsed.itemExists", item ~= nil)
    if item ~= nil then
        report:field("parsed.itemFullType", Safe.value("InventoryItem.getFullType", function()
            return item:getFullType()
        end, nil))
        report:field("parsed.itemName", Safe.value("InventoryItem.getName", function()
            return item:getName()
        end, nil))
    end

    local player = getPlayer and getPlayer() or nil
    if player ~= nil and moveProps.canPickUpMoveable ~= nil then
        local canPickUp = Safe.value("ISMoveableSpriteProps.canPickUpMoveable", function()
            return moveProps:canPickUpMoveable(player, object:getSquare(), object)
        end, false)
        report:field("parsed.canPickUp", canPickUp)
    end
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

    if spriteHasProperty(object, "IsMoveAble") then
        report:line("IsMoveAble")
    end

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

    reportMoveables(object, report)
end)

return Door
