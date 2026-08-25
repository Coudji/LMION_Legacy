require "LMION/Core"

LMION.Build = LMION.Build or {}
local Build = LMION.Build

Build.ID = "LMION_Build"
Build.VERSION = "0.0.4-dev"

function Build.hideSplitDoubleWireGate()
    return false
end

function Build.prepareSplitDoubleWireGate()
    if ScriptManager == nil or ScriptManager.instance == nil then
        return false
    end

    local scripts = ScriptManager.instance:getAllGameEntities()
    for i = 0, scripts:size() - 1 do
        local script = scripts:get(i)
        if script ~= nil and script:getName() == "DoubleWireGate" then
            local spriteConfig = script:getComponentScriptFor(ComponentType.SpriteConfig)
            if spriteConfig ~= nil then
                local tileNames = spriteConfig:getAllTileNames()
                local released = tileNames:size()
                tileNames:clear()
                LMION.log("Build", "released vanilla DoubleWireGate sprite ownership: " .. tostring(released))
                return true
            end
        end
    end

    LMION.error("Build", "could not release vanilla DoubleWireGate sprite ownership")
    return false
end

if Events ~= nil and Events.OnGameBoot ~= nil then
    Events.OnGameBoot.Add(Build.prepareSplitDoubleWireGate)
end

LMION.registerModule(Build.ID, Build)
LMION.log("Build", "loaded " .. Build.VERSION)

return Build
