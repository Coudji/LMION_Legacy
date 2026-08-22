require "LMION/Debug/Registry"

LMION.Debug.Util = LMION.Debug.Util or {}
LMION.Debug.Util.Safe = LMION.Debug.Util.Safe or {}

local Safe = LMION.Debug.Util.Safe

function Safe.try(label, callback)
    local ok, value = pcall(callback)

    if ok then
        return true, value
    end

    local message = tostring(value)

    if LMION ~= nil and LMION.warn ~= nil then
        LMION.warn("Debug", tostring(label) .. ": " .. message)
    end

    return false, message
end

function Safe.value(label, callback, fallback)
    local ok, value = Safe.try(label, callback)

    if ok then
        return value
    end

    return fallback
end

function Safe.className(object)
    if object == nil then
        return nil
    end

    return Safe.value("className", function()
        local javaClass = object:getClass()
        return javaClass ~= nil and javaClass:getName() or nil
    end, nil)
end

function Safe.shortClassName(object)
    local fullName = Safe.className(object)

    if fullName == nil then
        return "<unknown>"
    end

    fullName = tostring(fullName)
    return fullName:match("([^%.]+)$") or fullName
end

function Safe.squareString(square)
    if square == nil then
        return "<nil>"
    end

    return tostring(square:getX())
        .. ","
        .. tostring(square:getY())
        .. ","
        .. tostring(square:getZ())
end

function Safe.squareKey(square)
    if square == nil then
        return nil
    end

    return tostring(square:getX())
        .. ":"
        .. tostring(square:getY())
        .. ":"
        .. tostring(square:getZ())
end

function Safe.spriteName(object)
    if object == nil then
        return nil
    end

    local sprite = Safe.value("getSprite", function()
        return object:getSprite()
    end, nil)

    if sprite ~= nil then
        local name = Safe.value("sprite.getName", function()
            return sprite:getName()
        end, nil)

        if name ~= nil and tostring(name) ~= "" then
            return name
        end
    end

    local name = Safe.value("getSpriteName", function()
        return object:getSpriteName()
    end, nil)

    if name ~= nil and tostring(name) ~= "" then
        return name
    end

    name = Safe.value("getTile", function()
        return object:getTile()
    end, nil)

    if name ~= nil and tostring(name) ~= "" then
        return name
    end

    local raw = tostring(object)
    local parsed = raw:match("^[^:]*:([^:]+):")

    if parsed ~= nil and parsed ~= "null" and parsed ~= "" then
        return parsed
    end

    return nil
end

function Safe.objectLabel(object)
    if object == nil then
        return "<nil>"
    end

    local class = Safe.shortClassName(object)
    local sprite = Safe.spriteName(object) or "<no sprite>"
    return tostring(class) .. " | " .. tostring(sprite)
end

function Safe.collectionSize(collection)
    if collection == nil then
        return 0
    end

    return Safe.value("collection.size", function()
        return collection:size()
    end, 0)
end

function Safe.collectionGet(collection, index)
    if collection == nil then
        return nil
    end

    return Safe.value("collection.get", function()
        return collection:get(index)
    end, nil)
end

function Safe.objectKey(object)
    if object == nil then
        return nil
    end

    return tostring(object)
end

return Safe
