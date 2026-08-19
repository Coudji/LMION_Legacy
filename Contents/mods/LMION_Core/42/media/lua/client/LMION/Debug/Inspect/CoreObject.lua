require "LMION/Debug/Registry"
require "LMION/Debug/Util/Safe"

local Debug = LMION.Debug
local Safe = Debug.Util.Safe

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

local function dumpProperties(object, report)
    local properties = Safe.value("getProperties", function()
        return object:getProperties()
    end, nil)

    if properties == nil then
        report:field("properties", "<nil>")
        return
    end

    -- IMPORTANT: do not call PropertyContainer:Val(key) here.
    -- Some property names exposed by getPropertyNames() can throw a Java
    -- RuntimeException in debug mode and force-open the Lua debugger.
    local flags = Safe.value("getFlagsList", function()
        return properties:getFlagsList()
    end, nil)

    local flagCount = Safe.collectionSize(flags)
    report:field("flags.count", flagCount)

    for i = 0, flagCount - 1 do
        report:field("flag[" .. tostring(i) .. "]", Safe.collectionGet(flags, i))
    end

    local names = Safe.value("getPropertyNames", function()
        return properties:getPropertyNames()
    end, nil)

    local propertyCount = Safe.collectionSize(names)
    report:field("properties.count", propertyCount)

    for i = 0, propertyCount - 1 do
        report:field("property[" .. tostring(i) .. "]", Safe.collectionGet(names, i))
    end
end

Debug.registerInspector("core.object", 10, function(object, report)
    report:section("Core object")
    report:field("tostring", tostring(object))
    report:field("class", Safe.className(object))
    report:field("objectName", object:getObjectName())
    report:field("name", object:getName())
    report:field("type", object:getType())
    report:field("scriptName", object:getScriptName())
    report:field("square", Safe.squareString(object:getSquare()))
    report:field("objectIndex", object:getObjectIndex())
    report:field("specialObjectIndex", object:getSpecialObjectIndex())
    report:field("worldObjectIndex", object:getWorldObjectIndex())
    report:field("spriteName", Safe.spriteName(object))

    local sprite = object:getSprite()

    if sprite ~= nil then
        report:field("sprite.getName", sprite:getName())
    else
        report:field("sprite.getName", nil)
    end

    report:field("textureName", object:getTextureName())
    report:field("dir", object:getDir())

    dumpModData(object, report)
    dumpProperties(object, report)
end)
