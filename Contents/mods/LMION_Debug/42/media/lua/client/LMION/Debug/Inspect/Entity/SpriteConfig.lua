require "LMION/Debug/Inspect/Entity/Common"

local Entity = LMION.Debug.Inspect.Entity
local Common = Entity.Common
local Safe = LMION.Debug.Util.Safe
local Reflection = LMION.Debug.Util.Reflection

local SpriteConfig = Entity.SpriteConfig or {}
Entity.SpriteConfig = SpriteConfig

local function dumpTileList(spriteConfig, report)
    if Reflection.hasMethod(spriteConfig, "getAllTileNames", 0) then
        Common.dumpCollection(report, "tiles", spriteConfig:getAllTileNames())
    end
end

local function dumpFaceTiles(face, faceIndex, report)
    if face == nil or not Reflection.hasMethod(face, "getZLayers", 0)
        or not Reflection.hasMethod(face, "getLayer", 1) then return end

    for z = 0, face:getZLayers() - 1 do
        local layer = face:getLayer(z)
        if layer ~= nil and Reflection.hasMethod(layer, "getHeight", 0)
            and Reflection.hasMethod(layer, "getRow", 1) then
            for y = 0, layer:getHeight() - 1 do
                local row = layer:getRow(y)
                if row ~= nil and Reflection.hasMethod(row, "getWidth", 0)
                    and Reflection.hasMethod(row, "getTile", 1) then
                    for x = 0, row:getWidth() - 1 do
                        local tile = row:getTile(x)
                        if tile ~= nil and Reflection.hasMethod(tile, "getTileName", 0) then
                            local suffix = ""
                            if Reflection.hasMethod(tile, "isEmptySpace", 0) and tile:isEmptySpace() then suffix = suffix .. " [empty]" end
                            if Reflection.hasMethod(tile, "isBlocksSquare", 0) and tile:isBlocksSquare() then suffix = suffix .. " [blocks]" end
                            report:field(
                                "face[" .. tostring(faceIndex) .. "].tile["
                                    .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z) .. "]",
                                tostring(tile:getTileName()) .. suffix
                            )
                        end
                    end
                end
            end
        end
    end
end

local function dumpFaces(spriteConfig, report)
    if not Reflection.hasMethod(spriteConfig, "getFace", 1) then return end

    for i = 0, 3 do
        local face = Safe.value("SpriteConfig.getFace[" .. tostring(i) .. "]", function()
            return spriteConfig:getFace(i)
        end, nil)
        if face ~= nil then
            local prefix = "face[" .. tostring(i) .. "]."
            local fields = {
                { "name", "getFaceName" },
                { "width", "getTotalWidth" },
                { "height", "getTotalHeight" },
                { "zLayers", "getZLayers" },
                { "lightOffsetX", "getLightsourceOffsetX" },
                { "lightOffsetY", "getLightsourceOffsetY" },
                { "lightOffsetZ", "getLightsourceOffsetZ" },
            }
            for _, field in ipairs(fields) do
                if Reflection.hasMethod(face, field[2], 0) then
                    report:field(prefix .. field[1], face[field[2]](face))
                end
            end
            dumpFaceTiles(face, i, report)
        end
    end
end

function SpriteConfig.dump(script, report)
    if ComponentType == nil or ComponentType.SpriteConfig == nil then return end
    local spriteConfig = Common.getComponent(script, ComponentType.SpriteConfig)
    if spriteConfig == nil then return end

    report:section("Entity SpriteConfig")
    report:field("class", Safe.className(spriteConfig))

    local fields = {
        { "valid", "isValid" },
        { "multiTile", "isMultiTile" },
        { "singleFace", "isSingleFace" },
        { "thumpable", "getIsThumpable" },
        { "isoMasterOnly", "isoMasterOnly" },
        { "pole", "isPole" },
        { "prop", "isProp" },
        { "health", "getHealth" },
        { "bonusHealth", "getBonusHealth" },
        { "skillBaseHealth", "getSkillBaseHealth" },
        { "breakSound", "getBreakSound" },
        { "canBePadlocked", "getCanBePadlocked" },
        { "dontNeedFrame", "getDontNeedFrame" },
        { "needToBeAgainstWall", "getNeedToBeAgainstWall" },
        { "needWindowFrame", "getNeedWindowFrame" },
        { "cornerSprite", "getCornerSprite" },
        { "debugItem", "getDebugItem" },
        { "onCreate", "getOnCreate" },
        { "onIsValid", "getOnIsValid" },
        { "timedActionOnIsValid", "getTimedActionOnIsValid" },
    }
    for _, field in ipairs(fields) do
        if Reflection.hasMethod(spriteConfig, field[2], 0) then
            report:field(field[1], spriteConfig[field[2]](spriteConfig))
        end
    end

    if Reflection.hasMethod(spriteConfig, "getLightsourceFuel", 0) then report:field("lightsourceFuel", spriteConfig:getLightsourceFuel()) end
    if Reflection.hasMethod(spriteConfig, "getLightsourceItem", 0) then report:field("lightsourceItem", spriteConfig:getLightsourceItem()) end
    if Reflection.hasMethod(spriteConfig, "getLightsourceTagItem", 0) then
        Common.dumpCollection(report, "lightsourceTagItem", spriteConfig:getLightsourceTagItem())
    end
    if Reflection.hasMethod(spriteConfig, "getPreviousStages", 0) then
        Common.dumpCollection(report, "previousStages", spriteConfig:getPreviousStages())
    end

    dumpTileList(spriteConfig, report)
    dumpFaces(spriteConfig, report)
    Common.dumpScriptSource(spriteConfig, report, "source")
end

return SpriteConfig
