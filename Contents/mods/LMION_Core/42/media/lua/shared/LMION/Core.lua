LMION = LMION or {}

LMION.VERSION = "0.0.5-dev"
LMION.Modules = LMION.Modules or {}

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

require "LMION/Openings"
require "LMION/Doors"

LMION.log("Core", "loaded " .. LMION.VERSION)
