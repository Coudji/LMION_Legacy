require "LMION/Debug/Util/Safe"
require "LMION/Debug/Util/Reflection"

LMION.Debug.Inspect = LMION.Debug.Inspect or {}
LMION.Debug.Inspect.Entity = LMION.Debug.Inspect.Entity or {}

local Entity = LMION.Debug.Inspect.Entity
local Safe = LMION.Debug.Util.Safe
local Reflection = LMION.Debug.Util.Reflection

local Common = Entity.Common or {}
Entity.Common = Common

function Common.display(value)
    if value == nil then return "<nil>" end
    local text = tostring(value)
    return text ~= "" and text or "<empty>"
end

function Common.getEntityScriptName(object)
    local properties = Safe.value("entity.object.getProperties", function()
        return object:getProperties()
    end, nil)
    if properties == nil or not properties:has("EntityScriptName") then return nil end
    local value = properties:get("EntityScriptName")
    if value == nil or tostring(value) == "" then return nil end
    return tostring(value)
end

function Common.resolveEntityScript(name)
    if name == nil or ScriptManager == nil or ScriptManager.instance == nil
        or not Reflection.hasMethod(ScriptManager.instance, "getGameEntityScript", 1) then
        return nil
    end
    return ScriptManager.instance:getGameEntityScript(name)
end

function Common.getComponent(script, componentType)
    if script == nil or componentType == nil
        or not Reflection.hasMethod(script, "getComponentScriptFor", 1) then
        return nil
    end
    return script:getComponentScriptFor(componentType)
end

function Common.dumpCollection(report, prefix, collection, formatter)
    local count = Safe.collectionSize(collection)
    report:field(prefix .. ".count", count)
    for i = 0, count - 1 do
        local value = Safe.collectionGet(collection, i)
        report:field(prefix .. "[" .. tostring(i) .. "]",
            formatter ~= nil and formatter(value, i) or Common.display(value))
    end
end

function Common.dumpScriptSource(script, report, prefix)
    if script == nil then return end
    local fields = {
        { "scriptObjectFullType", "getScriptObjectFullType" },
        { "scriptObjectType", "getScriptObjectType" },
        { "scriptVersion", "getScriptVersion" },
        { "enabled", "isEnabled" },
        { "debugOnly", "isDebugOnly" },
        { "loadedBodies", "getLoadedScriptBodyCount" },
    }
    for _, field in ipairs(fields) do
        if Reflection.hasMethod(script, field[2], 0) then
            report:field(prefix .. "." .. field[1], script[field[2]](script))
        end
    end
    if Reflection.hasMethod(script, "getScriptLines", 0) then
        Common.dumpCollection(report, prefix .. ".line", script:getScriptLines())
    end
end

function Common.dumpComponentList(script, report)
    if script == nil or not Reflection.hasMethod(script, "getComponentScripts", 0) then return end
    Common.dumpCollection(report, "components", script:getComponentScripts(), function(component)
        return component ~= nil and Safe.className(component) or "<nil>"
    end)
end

return Common
