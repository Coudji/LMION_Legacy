require "LMION/Debug/Util/Safe"
require "LMION/Debug/Util/Reflection"
require "LMION/Debug/Inspect/PropertyReaders"

LMION.Debug.Inspect = LMION.Debug.Inspect or {}

local Safe = LMION.Debug.Util.Safe
local Reflection = LMION.Debug.Util.Reflection
local PropertyReaders = LMION.Debug.Inspect.PropertyReaders

local PropertyContainer = LMION.Debug.Inspect.PropertyContainer or {}
LMION.Debug.Inspect.PropertyContainer = PropertyContainer

local function collectionToStrings(collection)
    local result = {}
    local count = Safe.collectionSize(collection)

    for i = 0, count - 1 do
        local value = Safe.collectionGet(collection, i)

        if value ~= nil then
            result[#result + 1] = tostring(value)
        end
    end

    return result
end

local function joinOrNone(values)
    if #values == 0 then
        return "<none>"
    end

    return table.concat(values, ", ")
end

local function displayValue(value)
    if value == nil then
        return "<nil>"
    end

    if tostring(value) == "" then
        return "<empty>"
    end

    return value
end

local function readPropertyEntries(properties)
    local entries = {}

    if properties == nil then
        return entries
    end

    local names = Safe.value("PropertyContainer.getPropertyNames", function()
        return properties:getPropertyNames()
    end, nil)

    for _, name in ipairs(collectionToStrings(names)) do
        local readable, value = PropertyReaders.read(properties, name)

        entries[#entries + 1] = {
            name = name,
            readable = readable,
            value = value,
        }
    end

    return entries
end

local function formatPropertySummary(entries)
    if #entries == 0 then
        return "<none>"
    end

    local parts = {}

    for _, entry in ipairs(entries) do
        if not entry.readable then
            parts[#parts + 1] = entry.name .. "=<unread>"
        elseif entry.value == nil or tostring(entry.value) == "" then
            -- Empty-valued properties behave like presence markers in many
            -- vanilla tiles, so the compact report only needs their name.
            parts[#parts + 1] = entry.name
        else
            parts[#parts + 1] = entry.name .. "=" .. tostring(entry.value)
        end
    end

    return table.concat(parts, ", ")
end

local function dumpOptionalMetadata(properties, report)
    if Reflection.hasMethod(properties, "getSurface", 0) then
        report:field("surface", properties:getSurface())
    end

    if Reflection.hasMethod(properties, "isSurfaceOffset", 0) then
        report:field("surfaceOffset", properties:isSurfaceOffset())
    end

    if Reflection.hasMethod(properties, "isTable", 0) then
        report:field("table", properties:isTable())
    end

    if Reflection.hasMethod(properties, "isTableTop", 0) then
        report:field("tableTop", properties:isTableTop())
    end

    if Reflection.hasMethod(properties, "getStackReplaceTileOffset", 0) then
        report:field("stackReplaceTileOffset", properties:getStackReplaceTileOffset())
    end

    if Reflection.hasMethod(properties, "getItemHeight", 0) then
        report:field("itemHeight", properties:getItemHeight())
    end

    if Reflection.hasMethod(properties, "getSlopedSurfaceDirection", 0) then
        report:field("slopedSurface.direction", properties:getSlopedSurfaceDirection())
    end

    if Reflection.hasMethod(properties, "getSlopedSurfaceHeightMin", 0) then
        report:field("slopedSurface.heightMin", properties:getSlopedSurfaceHeightMin())
    end

    if Reflection.hasMethod(properties, "getSlopedSurfaceHeightMax", 0) then
        report:field("slopedSurface.heightMax", properties:getSlopedSurfaceHeightMax())
    end
end

function PropertyContainer.fromObject(object)
    if object == nil then
        return nil
    end

    return Safe.value("IsoObject.getProperties", function()
        return object:getProperties()
    end, nil)
end

function PropertyContainer.getFlags(properties)
    if properties == nil then
        return {}
    end

    local flags = Safe.value("PropertyContainer.getFlagsList", function()
        return properties:getFlagsList()
    end, nil)

    return collectionToStrings(flags)
end

function PropertyContainer.getPropertyEntries(properties)
    return readPropertyEntries(properties)
end

function PropertyContainer.dumpCompact(properties, report)
    if properties == nil then
        report:field("flags", "<nil>")
        report:field("properties", "<nil>")
        return
    end

    report:field("flags", joinOrNone(PropertyContainer.getFlags(properties)))
    report:field("properties", formatPropertySummary(readPropertyEntries(properties)))
end

function PropertyContainer.dumpFull(properties, report, sectionName)
    report:section(sectionName or "Properties")

    if properties == nil then
        report:field("properties", "<nil>")
        return
    end

    local flags = PropertyContainer.getFlags(properties)
    local entries = readPropertyEntries(properties)

    report:field("flags.count", #flags)
    report:field("flags", joinOrNone(flags))
    report:field("properties.count", #entries)

    for _, entry in ipairs(entries) do
        local name = entry.name

        if not entry.readable then
            name = name .. " [no reader]"
        end

        report:field(name, displayValue(entry.value))
    end

    dumpOptionalMetadata(properties, report)
end

return PropertyContainer
