require "LMION/Debug/Registry"
require "LMION/Debug/Inspect/Options"
require "LMION/Debug/Inspect/Entity/Common"
require "LMION/Debug/Inspect/Entity/UiConfig"
require "LMION/Debug/Inspect/Entity/SpriteConfig"
require "LMION/Debug/Inspect/Entity/CraftRecipe"

local Debug = LMION.Debug
local Options = Debug.Inspect.Options
local Entity = Debug.Inspect.Entity
local Common = Entity.Common
local Safe = Debug.Util.Safe
local Reflection = Debug.Util.Reflection

local function dumpEntityIdentity(script, report)
    report:field("class", Safe.className(script))

    local fields = {
        { "displayNameDebug", "getDisplayNameDebug" },
        { "name", "getName" },
        { "fullName", "getFullName" },
        { "module", "getModuleName" },
        { "modID", "getModID" },
        { "file", "getFileAbsPath" },
        { "existsAsVanilla", "getExistsAsVanilla" },
        { "obsolete", "getObsolete" },
        { "registryId", "getRegistry_id" },
        { "hasComponents", "hasComponents" },
    }

    for _, field in ipairs(fields) do
        if Reflection.hasMethod(script, field[2], 0) then
            report:field(field[1], script[field[2]](script))
        end
    end

    Common.dumpComponentList(script, report)
    Common.dumpScriptSource(script, report, "source")
end

local function compactComponentNames(script)
    if script == nil or not Reflection.hasMethod(script, "getComponentScripts", 0) then
        return "<unknown>"
    end

    local components = script:getComponentScripts()
    local count = Safe.collectionSize(components)
    local names = {}

    for i = 0, count - 1 do
        local component = Safe.collectionGet(components, i)
        if component ~= nil then
            local className = Safe.className(component)
            className = string.gsub(className, "^.*%.", "")
            className = string.gsub(className, "Script$", "")
            names[#names + 1] = className
        end
    end

    return #names > 0 and table.concat(names, ", ") or "<none>"
end

local function dumpCompactEntity(script, report)
    if Reflection.hasMethod(script, "getFullName", 0) then
        report:field("fullName", script:getFullName())
    elseif Reflection.hasMethod(script, "getName", 0) then
        report:field("name", script:getName())
    end

    if Reflection.hasMethod(script, "getModID", 0) then
        report:field("modID", script:getModID())
    end

    report:field("components", compactComponentNames(script))
end

Debug.registerInspector("core.entityScript", 40, function(object, report)
    local entityScriptName = Common.getEntityScriptName(object)
    if entityScriptName == nil then return end

    report:section("Entity")
    report:field("propertyName", entityScriptName)

    local script = Common.resolveEntityScript(entityScriptName)
    if script == nil then
        report:field("resolved", false)
        return
    end

    report:field("resolved", true)

    if not Options.isFullDetails() then
        dumpCompactEntity(script, report)
        return
    end

    dumpEntityIdentity(script, report)
    Entity.UiConfig.dump(script, report)
    Entity.SpriteConfig.dump(script, report)
    Entity.CraftRecipe.dump(script, report)
end)

return true
