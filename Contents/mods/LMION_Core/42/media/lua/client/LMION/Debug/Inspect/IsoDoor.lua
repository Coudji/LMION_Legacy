require "LMION/Debug/Registry"
require "LMION/Debug/Util/Safe"
require "LMION/Debug/Util/Reflection"

local Debug = LMION.Debug
local Safe = Debug.Util.Safe
local Reflection = Debug.Util.Reflection

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

Debug.registerInspector("vanilla.isoDoor", 50, function(object, report)
    if not isIsoDoor(object) then
        return
    end

    report:section("Vanilla IsoDoor")
    report:field("isIsoDoor", true)
    report:field("north", object:getNorth())
    report:field("open", object:IsOpen())
    report:field("locked", object:isLocked())
    report:field("lockedByKey", object:isLockedByKey())
    report:field("keyId", object:getKeyId())
    report:field("health", object:getHealth())
    report:field("maxHealth", object:getMaxHealth())
    report:field("barricaded", object:isBarricaded())
    report:field("exterior", object:isExterior())
    report:field("hoppable", object:isHoppable())
    report:field("closedSprite(reflect)", Reflection.getSpriteFieldName(object, "closedSprite"))
    report:field("openSprite(reflect)", Reflection.getSpriteFieldName(object, "openSprite"))
    report:field("oppositeSquare", Safe.squareString(object:getOppositeSquare()))

    local doubleDoorIndex = Safe.value("IsoDoor.getDoubleDoorIndex", function()
        return IsoDoor.getDoubleDoorIndex(object)
    end, -1)

    report:field("doubleDoorIndex", doubleDoorIndex)

    if type(doubleDoorIndex) == "number" and doubleDoorIndex >= 0 then
        for i = 1, 4 do
            local member = Safe.value("IsoDoor.getDoubleDoorObject", function()
                return IsoDoor.getDoubleDoorObject(object, i)
            end, nil)

            if member ~= nil then
                report:field("doubleDoorObject[" .. tostring(i) .. "]", spriteLabel(member))
            end
        end
    end

    local garageDoorIndex = Safe.value("IsoDoor.getGarageDoorIndex", function()
        return IsoDoor.getGarageDoorIndex(object)
    end, -1)

    report:field("garageDoorIndex", garageDoorIndex)

    if type(garageDoorIndex) == "number" and garageDoorIndex >= 0 then
        local first = Safe.value("IsoDoor.getGarageDoorFirst", function()
            return IsoDoor.getGarageDoorFirst(object)
        end, nil)

        local prev = Safe.value("IsoDoor.getGarageDoorPrev", function()
            return IsoDoor.getGarageDoorPrev(object)
        end, nil)

        local next = Safe.value("IsoDoor.getGarageDoorNext", function()
            return IsoDoor.getGarageDoorNext(object)
        end, nil)

        if first ~= nil then
            report:field("garage.first", spriteLabel(first))
        end

        if prev ~= nil then
            report:field("garage.prev", spriteLabel(prev))
        end

        if next ~= nil then
            report:field("garage.next", spriteLabel(next))
        end
    end
end)
