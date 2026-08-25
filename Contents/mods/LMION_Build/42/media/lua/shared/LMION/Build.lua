require "LMION/Core"

LMION.Build = LMION.Build or {}
local Build = LMION.Build

Build.ID = "LMION_Build"
Build.VERSION = "0.0.4-dev"

local splitDoubleWireGateTiles = {
    ["fixtures_doors_fences_01_64"] = true,
    ["fixtures_doors_fences_01_65"] = true,
    ["fixtures_doors_fences_01_66"] = true,
    ["fixtures_doors_fences_01_67"] = true,
    ["fixtures_doors_fences_01_72"] = true,
    ["fixtures_doors_fences_01_73"] = true,
    ["fixtures_doors_fences_01_74"] = true,
    ["fixtures_doors_fences_01_75"] = true,
}

if LMION.Doors ~= nil and LMION.Doors.Profiles ~= nil then
    LMION.Doors.Profiles.DoubleWireGateLeft = LMION.Doors.Profiles.DoubleWireGate
    LMION.Doors.Profiles.DoubleWireGateRight = LMION.Doors.Profiles.DoubleWireGate
end

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
                local matched = 0

                for j = 0, tileNames:size() - 1 do
                    if splitDoubleWireGateTiles[tostring(tileNames:get(j))] then
                        matched = matched + 1
                    end
                end

                if matched ~= 8 then
                    LMION.error(
                        "Build",
                        "refusing to modify vanilla DoubleWireGate sprite ownership: expected 8 known tiles, found "
                            .. tostring(matched)
                            .. " of "
                            .. tostring(tileNames:size())
                    )
                    return false
                end

                for j = tileNames:size() - 1, 0, -1 do
                    if splitDoubleWireGateTiles[tostring(tileNames:get(j))] then
                        tileNames:remove(j)
                    end
                end

                LMION.log(
                    "Build",
                    "released 8 known vanilla DoubleWireGate tiles; preserved " .. tostring(tileNames:size()) .. " other tile names"
                )
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
