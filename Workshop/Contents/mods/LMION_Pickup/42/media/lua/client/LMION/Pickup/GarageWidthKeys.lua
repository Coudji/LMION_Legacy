require "PZAPI/ModOptions"

local options = PZAPI.ModOptions:getOptions("LMION_GaragePlacement")

if options == nil then
    options = PZAPI.ModOptions:create(
        "LMION_GaragePlacement",
        getText("UI_LMION_GarageWidthOptions")
    )
end

if options:getOption("GarageWidthDecrease") == nil then
    options:addKeyBind(
        "GarageWidthDecrease",
        getText("UI_LMION_GarageWidthDecrease"),
        Keyboard.KEY_SUBTRACT
    )
end

if options:getOption("GarageWidthIncrease") == nil then
    options:addKeyBind(
        "GarageWidthIncrease",
        getText("UI_LMION_GarageWidthIncrease"),
        Keyboard.KEY_ADD
    )
end
