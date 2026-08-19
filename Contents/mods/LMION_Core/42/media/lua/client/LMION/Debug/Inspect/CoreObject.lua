require "LMION/Debug/Registry"
require "LMION/Debug/Util/Safe"
require "LMION/Debug/Inspect/Options"
require "LMION/Debug/Inspect/PropertyReaders"

local Debug = LMION.Debug
local Safe = Debug.Util.Safe
local Options = Debug.Inspect.Options
local PropertyReaders = Debug.Inspect.PropertyReaders

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

local function collectionToStrings(collection)
    local result = {}
    local count = Safe.collectionSize(collection)

    for i = 0, count - 1 do
        local value = Safe.collectionGet(collection, i)
        result[#result + 1] = tostring(value)
    end

    return result
end

local function joinOrEmpty(values)
    if #values == 0 then
        return "<none>"
    end

    return table.concat(values, ", ")
end

local function getProperties(object)
    return Safe.value("getProperties", function()
        return object:getProperties()
    end, nil)
end

local function dumpPropertiesClean(properties, report)
    if properties == nil then
        report:field("flags", "<nil>")
        report:field("properties", "<nil>")
        return
    end

    local flags = Safe.value("getFlagsList", function()
        return properties:getFlagsList()
    end, nil)

    local names = Safe.value("getPropertyNames", function()
        return properties:getPropertyNames()
    end, nil)

    report:field("flags", joinOrEmpty(collectionToStrings(flags)))
    report:field("properties", joinOrEmpty(collectionToStrings(names)))
end

local function dumpPropertiesFull(properties, report)
    if properties == nil then
        report:field("properties", "<nil>")
        return
    end

    local flags = Safe.value("getFlagsList", function()
        return properties:getFlagsList()
    end, nil)

    local flagValues = collectionToStrings(flags)
    report:field("flags.count", #flagValues)

    for i, flag in ipairs(flagValues) do
        report:field("flag[" .. tostring(i - 1) .. "]", flag)
    end

    local names = Safe.value("getPropertyNames", function()
        return properties:getPropertyNames()
    end, nil)

    local propertyNames = collectionToStrings(names)
    report:field("properties.count", #propertyNames)

    for i, name in ipairs(propertyNames) do
        local hasReader, value = PropertyReaders.read(properties, name)
        local suffix = hasReader and "" or " [no reader]"
        report:field("property[" .. tostring(i - 1) .. "]." .. name .. suffix, value)
    end
end

Debug.registerInspector("core.object", 10, function(object, report)
    report:section("Object")
    report:field("class", Safe.className(object))
    report:field("square", Safe.squareString(object:getSquare()))
    report:field("type", object:getType())
    report:field("sprite", Safe.spriteName(object))

    local properties = getProperties(object)
    dumpPropertiesClean(properties, report)

    if not Options.isFullDetails() then
        return
    end

    report:section("Object details")
    report:field("tostring", tostring(object))
    report:field("objectName", object:getObjectName())
    report:field("name", object:getName())
    report:field("scriptName", object:getScriptName())
    report:field("objectIndex", object:getObjectIndex())
    report:field("specialObjectIndex", object:getSpecialObjectIndex())
    report:field("worldObjectIndex", object:getWorldObjectIndex())

    local sprite = object:getSprite()
    report:field("sprite.getName", sprite ~= nil and sprite:getName() or nil)
    report:field("textureName", object:getTextureName())
    report:field("dir", object:getDir())

    dumpModData(object, report)
    dumpPropertiesFull(properties, report)
end)
