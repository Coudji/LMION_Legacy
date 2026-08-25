require "LMION/Core"

LMION.Build = LMION.Build or {}
local Build = LMION.Build

Build.ID = "LMION_Build"
Build.VERSION = "0.0.4-dev"

local expectedClosedTiles = {
    ["fixtures_doors_fences_01_64"] = true,
    ["fixtures_doors_fences_01_65"] = true,
    ["fixtures_doors_fences_01_66"] = true,
    ["fixtures_doors_fences_01_67"] = true,
    ["fixtures_doors_fences_01_72"] = true,
    ["fixtures_doors_fences_01_73"] = true,
    ["fixtures_doors_fences_01_74"] = true,
    ["fixtures_doors_fences_01_75"] = true,
}

local expectedLeftTiles = {
    ["fixtures_doors_fences_01_64"] = true,
    ["fixtures_doors_fences_01_65"] = true,
    ["fixtures_doors_fences_01_66"] = true,
    ["fixtures_doors_fences_01_67"] = true,
}

local leftSpriteConfigBody = [[
entity DoubleWireGate
{
    component SpriteConfig
    {
        skillBaseHealth = 300,
        dontNeedFrame = true,
        BreakSound = BreakDoor,

        face W
        {
            layer
            {
                row = fixtures_doors_fences_01_65,
                row = fixtures_doors_fences_01_64,
            }
        }

        face N
        {
            layer
            {
                row = fixtures_doors_fences_01_66 fixtures_doors_fences_01_67,
            }
        }
    }
}
]]

local function countKnown(tileNames, known)
    local count = 0
    for i = 0, tileNames:size() - 1 do
        if known[tostring(tileNames:get(i))] then
            count = count + 1
        end
    end
    return count
end

local function dumpSpriteConfig(label, spriteConfig)
    if spriteConfig == nil then
        LMION.error("Build", label .. " SpriteConfig=nil")
        return
    end

    local tileNames = spriteConfig:getAllTileNames()
    LMION.log("Build", label .. " allTileNames count=" .. tostring(tileNames:size()))
    for i = 0, tileNames:size() - 1 do
        LMION.log("Build", label .. " allTileNames[" .. tostring(i) .. "]=" .. tostring(tileNames:get(i)))
    end

    for faceId = 0, 5 do
        local face = spriteConfig:getFace(faceId)
        if face ~= nil then
            LMION.log(
                "Build",
                label
                    .. " face["
                    .. tostring(faceId)
                    .. "]="
                    .. tostring(face:getFaceName())
                    .. " width="
                    .. tostring(face:getTotalWidth())
                    .. " height="
                    .. tostring(face:getTotalHeight())
                    .. " layers="
                    .. tostring(face:getZLayers())
            )

            for layerIndex = 0, face:getZLayers() - 1 do
                local layer = face:getLayer(layerIndex)
                if layer ~= nil then
                    for rowIndex = 0, layer:getHeight() - 1 do
                        local row = layer:getRow(rowIndex)
                        if row ~= nil then
                            for tileIndex = 0, row:getWidth() - 1 do
                                local tile = row:getTile(tileIndex)
                                if tile ~= nil then
                                    LMION.log(
                                        "Build",
                                        label
                                            .. " face["
                                            .. tostring(faceId)
                                            .. "] layer["
                                            .. tostring(layerIndex)
                                            .. "] row["
                                            .. tostring(rowIndex)
                                            .. "] tile["
                                            .. tostring(tileIndex)
                                            .. "]="
                                            .. tostring(tile:getTileName())
                                    )
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function Build.prepareSplitDoubleWireGate()
    if ScriptManager == nil or ScriptManager.instance == nil then
        return false
    end

    local script = ScriptManager.instance:getGameEntityScript("Base.DoubleWireGate")
    if script == nil then
        script = ScriptManager.instance:getGameEntityScript("DoubleWireGate")
    end
    if script == nil then
        LMION.error("Build", "DoubleWireGate GameEntityScript not found")
        return false
    end

    local spriteConfig = script:getComponentScriptFor(ComponentType.SpriteConfig)
    if spriteConfig == nil then
        LMION.error("Build", "DoubleWireGate SpriteConfig not found")
        return false
    end

    dumpSpriteConfig("DoubleWireGate before reload", spriteConfig)

    local tileNames = spriteConfig:getAllTileNames()
    local closedCount = countKnown(tileNames, expectedClosedTiles)
    if closedCount ~= 8 then
        LMION.error(
            "Build",
            "refusing DoubleWireGate reload: expected all 8 vanilla closed tiles, found " .. tostring(closedCount)
        )
        return false
    end

    spriteConfig:PreReload()

    local ok, err = pcall(function()
        script:Load("DoubleWireGate", leftSpriteConfigBody)
    end)

    if not ok then
        LMION.error("Build", "DoubleWireGate reload failed: " .. tostring(err))
        return false
    end

    local reloaded = script:getComponentScriptFor(ComponentType.SpriteConfig)
    dumpSpriteConfig("DoubleWireGate after reload", reloaded)

    if reloaded == nil then
        LMION.error("Build", "DoubleWireGate reload produced no SpriteConfig")
        return false
    end

    local reloadedNames = reloaded:getAllTileNames()
    if reloadedNames:size() ~= 4 or countKnown(reloadedNames, expectedLeftTiles) ~= 4 then
        LMION.error("Build", "DoubleWireGate reload verification failed")
        return false
    end

    if LMION.Doors ~= nil and LMION.Doors.Profiles ~= nil then
        LMION.Doors.Profiles.DoubleWireGateRight = LMION.Doors.Profiles.DoubleWireGate
    end

    LMION.log("Build", "DoubleWireGate vanilla SpriteConfig reloaded as left half")
    return true
end

if Events ~= nil and Events.OnGameBoot ~= nil then
    Events.OnGameBoot.Add(Build.prepareSplitDoubleWireGate)
end

LMION.registerModule(Build.ID, Build)
LMION.log("Build", "loaded " .. Build.VERSION)

return Build
