require "LMION/Debug/Inspect/Entity/Common"

local Entity = LMION.Debug.Inspect.Entity
local Common = Entity.Common
local Reflection = LMION.Debug.Util.Reflection

local UiConfig = Entity.UiConfig or {}
Entity.UiConfig = UiConfig

function UiConfig.dump(script, report)
    if ComponentType == nil or ComponentType.UiConfig == nil then return end
    local ui = Common.getComponent(script, ComponentType.UiConfig)
    if ui == nil then return end

    report:section("Entity UiConfig")
    report:field("class", LMION.Debug.Util.Safe.className(ui))

    local fields = {
        { "displayNameDebug", "getDisplayNameDebug" },
        { "uiEnabled", "isUiEnabled" },
        { "entityStyle", "getEntityStyle" },
        { "xuiSkinName", "getXuiSkinName" },
        { "isoMasterOnly", "isoMasterOnly" },
    }
    for _, field in ipairs(fields) do
        if Reflection.hasMethod(ui, field[2], 0) then
            report:field(field[1], ui[field[2]](ui))
        end
    end

    Common.dumpScriptSource(ui, report, "source")
end

return UiConfig
