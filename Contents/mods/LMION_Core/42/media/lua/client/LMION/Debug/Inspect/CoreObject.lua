require "LMION/Debug/Registry"
require "LMION/Debug/Util/Safe"
require "LMION/Debug/Util/Reflection"
require "LMION/Debug/Inspect/Options"
require "LMION/Debug/Inspect/PropertyContainer"

local Debug = LMION.Debug
local Safe = Debug.Util.Safe
local Reflection = Debug.Util.Reflection
local Options = Debug.Inspect.Options
local PropertyContainer = Debug.Inspect.PropertyContainer

local function dumpModData(object, report)
    local modData = Safe.value("getModData", function()
        return object:getModData()
    end, nil)

    if modData == nil then
        report:field("modData", "<nil>")
        return
    end

    local found = false

    for key, value in pairs(modData) do
        found = true
        report:field("modData." .. tostring(key), value)
    end

    if not found then
        report:field("modData", "<empty>")
    end
end

local function spriteName(sprite)
    if sprite == nil then
        return nil
    end

    return Safe.value("sprite.getName", function()
        return sprite:getName()
    end, tostring(sprite))
end

Debug.registerInspector("core.object", 10, function(object, report)
    report:section("Object")
    report:field("class", Safe.className(object))
    report:field("square", Safe.squareString(object:getSquare()))
    report:field("type", object:getType())
    report:field("sprite", Safe.spriteName(object))

    local properties = PropertyContainer.fromObject(object)
    PropertyContainer.dumpCompact(properties, report)

    if not Options.isFullDetails() then
        return
    end

    -- Full details deepen the existing Object section instead of creating a
    -- second artificial level such as "Object details".
    report:field("tostring", tostring(object))
    report:field("objectName", object:getObjectName())
    report:field("name", object:getName())
    report:field("scriptName", object:getScriptName())
    report:field("objectIndex", object:getObjectIndex())
    report:field("specialObjectIndex", object:getSpecialObjectIndex())
    report:field("worldObjectIndex", object:getWorldObjectIndex())
    report:field("textureName", object:getTextureName())
    report:field("dir", object:getDir())

    if Reflection.hasMethod(object, "getTileName", 0) then
        report:field("tileName", object:getTileName())
    end

    if Reflection.hasMethod(object, "getFacing", 0) then
        report:field("facing", object:getFacing())
    end

    if Reflection.hasMethod(object, "getEntityNetID", 0) then
        report:field("entityNetID", object:getEntityNetID())
    end

    if Reflection.hasMethod(object, "getMasterObject", 0) then
        local master = object:getMasterObject()
        report:field("masterObject", master ~= nil and Safe.objectLabel(master) or nil)
    end

    if Reflection.hasMethod(object, "getOverlaySprite", 0) then
        report:field("overlaySprite", spriteName(object:getOverlaySprite()))
    end

    if Reflection.hasMethod(object, "getCustomColor", 0) then
        report:field("customColor", object:getCustomColor())
    end

    dumpModData(object, report)
    PropertyContainer.dumpFull(properties, report, "Object")
end)
