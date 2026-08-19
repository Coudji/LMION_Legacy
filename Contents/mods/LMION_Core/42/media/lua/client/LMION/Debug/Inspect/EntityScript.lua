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

Debug.registerInspector("core.entityScript", 40, function(object, report)
    if not Options.isFullDetails() then return end

    local entityScriptName = Common.getEntityScriptName(object)
    if entityScriptName == nil then return end

    report:section("Entity script")
    report:field("propertyName", entityScriptName)

    local script = Common.resolveEntityScript(entityScriptName)
    if script == nil then
        report:field("resolved", false)
        return
    end

    report:field("resolved", true)
    dumpEntityIdentity(script, report)
    Entity.UiConfig.dump(script, report)
    Entity.SpriteConfig.dump(script, report)
    Entity.CraftRecipe.dump(script, report)
end)

return true
