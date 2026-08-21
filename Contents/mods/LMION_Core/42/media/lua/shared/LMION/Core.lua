LMION = LMION or {}

LMION.VERSION = "0.0.3-dev"
LMION.Modules = LMION.Modules or {}
LMION.Listeners = LMION.Listeners or {}

local function prefix(scope)
    if scope and scope ~= "" then
        return "[LMION:" .. tostring(scope) .. "] "
    end
    return "[LMION] "
end

function LMION.log(scope, message)
    print(prefix(scope) .. tostring(message))
end

function LMION.warn(scope, message)
    print(prefix(scope) .. "WARNING: " .. tostring(message))
end

function LMION.error(scope, message)
    print(prefix(scope) .. "ERROR: " .. tostring(message))
end

function LMION.registerModule(id, api)
    if type(id) ~= "string" or id == "" then
        LMION.error("Core", "registerModule(): invalid module id")
        return false
    end

    LMION.Modules[id] = api or {}
    LMION.log("Core", "registered module: " .. id)
    return true
end

function LMION.getModule(id)
    return LMION.Modules[id]
end

function LMION.isModuleRegistered(id)
    return LMION.Modules[id] ~= nil
end

function LMION.on(eventName, ownerId, callback)
    if type(eventName) ~= "string" or eventName == "" then
        LMION.error("Core", "on(): invalid event name")
        return false
    end

    if type(callback) ~= "function" then
        LMION.error("Core", "on(): callback must be a function")
        return false
    end

    LMION.Listeners[eventName] = LMION.Listeners[eventName] or {}

    for i = #LMION.Listeners[eventName], 1, -1 do
        if LMION.Listeners[eventName][i].owner == ownerId then
            table.remove(LMION.Listeners[eventName], i)
        end
    end

    table.insert(LMION.Listeners[eventName], {
        owner = ownerId or "unknown",
        callback = callback,
    })

    return true
end

function LMION.emit(eventName, ...)
    local listeners = LMION.Listeners[eventName]
    if listeners == nil then
        return
    end

    for i = 1, #listeners do
        local listener = listeners[i]
        local ok, err = pcall(listener.callback, ...)
        if not ok then
            LMION.error(
                "Core",
                "listener failure for '" .. tostring(eventName) ..
                "' (" .. tostring(listener.owner) .. "): " .. tostring(err)
            )
        end
    end
end

require "LMION/Doors"
require "LMION/Doors/Models"

LMION.log("Core", "loaded " .. LMION.VERSION)
