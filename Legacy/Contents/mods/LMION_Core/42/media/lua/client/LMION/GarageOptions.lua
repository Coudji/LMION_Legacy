require "LMION/Core"

local options = PZAPI.ModOptions:create(
    "LMION_Core",
    getText("UI_LMION_CoreOptions")
)

options:addTickBox(
    "UnlimitedGarageWidth",
    getText("UI_LMION_UnlimitedGarageWidth"),
    false,
    getText("UI_LMION_UnlimitedGarageWidth_Tooltip")
)

return options
