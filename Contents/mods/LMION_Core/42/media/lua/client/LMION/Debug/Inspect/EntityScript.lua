require "LMION/Debug/Registry"
require "LMION/Debug/Util/Safe"
require "LMION/Debug/Util/Reflection"
require "LMION/Debug/Inspect/Options"

local Debug = LMION.Debug
local Safe = Debug.Util.Safe
local Reflection = Debug.Util.Reflection
local Options = Debug.Inspect.Options

local function getEntityScriptName(object)
    local properties = Safe.value("object.getProperties", function()
        return object:getProperties()
    end, nil)

    if properties == nil or not properties:has("EntityScriptName") then
        return nil
    end

    local value = properties:get("EntityScriptName")

    if value == nil or tostring(value) == "" then
        return nil
    end

    return tostring(value)
end

local function dumpComponentList(script, report)
    if not Reflection.hasMethod(script, "getComponentScripts", 0) then
        return
    end

    local components = script:getComponentScripts()
    local count = Safe.collectionSize(components)
    report:field("components.count", count)

    for i = 0, count - 1 do
        local component = Safe.collectionGet(components, i)
        report:field(
            "component[" .. tostring(i) .. "]",
            component ~= nil and Safe.className(component) or nil
        )
    end
end

local function dumpTileList(spriteConfig, report)
    if not Reflection.hasMethod(spriteConfig, "getAllTileNames", 0) then
        return
    end

    local names = spriteConfig:getAllTileNames()
    local count = Safe.collectionSize(names)
    report:field("tiles.count", count)

    for i = 0, count - 1 do
        report:field(
            "tile[" .. tostring(i) .. "]",
            Safe.collectionGet(names, i)
        )
    end
end

local function dumpFaceTiles(face, faceIndex, report)
    if face == nil
        or not Reflection.hasMethod(face, "getZLayers", 0)
        or not Reflection.hasMethod(face, "getLayer", 1) then
        return
    end

    local zLayers = face:getZLayers()

    for z = 0, zLayers - 1 do
        local layer = face:getLayer(z)

        if layer ~= nil
            and Reflection.hasMethod(layer, "getHeight", 0)
            and Reflection.hasMethod(layer, "getRow", 1) then
            local height = layer:getHeight()

            for y = 0, height - 1 do
                local row = layer:getRow(y)

                if row ~= nil
                    and Reflection.hasMethod(row, "getWidth", 0)
                    and Reflection.hasMethod(row, "getTile", 1) then
                    local width = row:getWidth()

                    for x = 0, width - 1 do
                        local tile = row:getTile(x)

                        if tile ~= nil and Reflection.hasMethod(tile, "getTileName", 0) then
                            local suffix = ""

                            if Reflection.hasMethod(tile, "isEmptySpace", 0)
                                and tile:isEmptySpace() then
                                suffix = suffix .. " [empty]"
                            end

                            if Reflection.hasMethod(tile, "isBlocksSquare", 0)
                                and tile:isBlocksSquare() then
                                suffix = suffix .. " [blocks]"
                            end

                            report:field(
                                "face[" .. tostring(faceIndex)
                                    .. "].tile[" .. tostring(x)
                                    .. "," .. tostring(y)
                                    .. "," .. tostring(z) .. "]",
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
    if not Reflection.hasMethod(spriteConfig, "getFace", 1) then
        return
    end

    for i = 0, 3 do
        local face = Safe.value(
            "SpriteConfig.getFace[" .. tostring(i) .. "]",
            function()
                return spriteConfig:getFace(i)
            end,
            nil
        )

        if face ~= nil then
            local prefix = "face[" .. tostring(i) .. "]."

            if Reflection.hasMethod(face, "getFaceName", 0) then
                report:field(prefix .. "name", face:getFaceName())
            end

            if Reflection.hasMethod(face, "getTotalWidth", 0) then
                report:field(prefix .. "width", face:getTotalWidth())
            end

            if Reflection.hasMethod(face, "getTotalHeight", 0) then
                report:field(prefix .. "height", face:getTotalHeight())
            end

            if Reflection.hasMethod(face, "getZLayers", 0) then
                report:field(prefix .. "zLayers", face:getZLayers())
            end

            dumpFaceTiles(face, i, report)
        end
    end
end

local function dumpSpriteConfig(script, report)
    if ComponentType == nil
        or ComponentType.SpriteConfig == nil
        or not Reflection.hasMethod(script, "getComponentScriptFor", 1) then
        return
    end

    local spriteConfig = script:getComponentScriptFor(ComponentType.SpriteConfig)

    if spriteConfig == nil then
        return
    end

    report:section("Entity SpriteConfig")
    report:field("class", Safe.className(spriteConfig))

    if Reflection.hasMethod(spriteConfig, "isValid", 0) then
        report:field("valid", spriteConfig:isValid())
    end

    if Reflection.hasMethod(spriteConfig, "isMultiTile", 0) then
        report:field("multiTile", spriteConfig:isMultiTile())
    end

    if Reflection.hasMethod(spriteConfig, "isSingleFace", 0) then
        report:field("singleFace", spriteConfig:isSingleFace())
    end

    if Reflection.hasMethod(spriteConfig, "getIsThumpable", 0) then
        report:field("thumpable", spriteConfig:getIsThumpable())
    end

    if Reflection.hasMethod(spriteConfig, "isoMasterOnly", 0) then
        report:field("isoMasterOnly", spriteConfig:isoMasterOnly())
    end

    if Reflection.hasMethod(spriteConfig, "isPole", 0) then
        report:field("pole", spriteConfig:isPole())
    end

    if Reflection.hasMethod(spriteConfig, "isProp", 0) then
        report:field("prop", spriteConfig:isProp())
    end

    if Reflection.hasMethod(spriteConfig, "getHealth", 0) then
        report:field("health", spriteConfig:getHealth())
    end

    if Reflection.hasMethod(spriteConfig, "getBonusHealth", 0) then
        report:field("bonusHealth", spriteConfig:getBonusHealth())
    end

    if Reflection.hasMethod(spriteConfig, "getSkillBaseHealth", 0) then
        report:field("skillBaseHealth", spriteConfig:getSkillBaseHealth())
    end

    if Reflection.hasMethod(spriteConfig, "getBreakSound", 0) then
        report:field("breakSound", spriteConfig:getBreakSound())
    end

    if Reflection.hasMethod(spriteConfig, "getCanBePadlocked", 0) then
        report:field("canBePadlocked", spriteConfig:getCanBePadlocked())
    end

    if Reflection.hasMethod(spriteConfig, "getDontNeedFrame", 0) then
        report:field("dontNeedFrame", spriteConfig:getDontNeedFrame())
    end

    if Reflection.hasMethod(spriteConfig, "getNeedToBeAgainstWall", 0) then
        report:field("needToBeAgainstWall", spriteConfig:getNeedToBeAgainstWall())
    end

    if Reflection.hasMethod(spriteConfig, "getNeedWindowFrame", 0) then
        report:field("needWindowFrame", spriteConfig:getNeedWindowFrame())
    end

    if Reflection.hasMethod(spriteConfig, "getCornerSprite", 0) then
        report:field("cornerSprite", spriteConfig:getCornerSprite())
    end

    if Reflection.hasMethod(spriteConfig, "getDebugItem", 0) then
        report:field("debugItem", spriteConfig:getDebugItem())
    end

    if Reflection.hasMethod(spriteConfig, "getOnCreate", 0) then
        report:field("onCreate", spriteConfig:getOnCreate())
    end

    if Reflection.hasMethod(spriteConfig, "getOnIsValid", 0) then
        report:field("onIsValid", spriteConfig:getOnIsValid())
    end

    if Reflection.hasMethod(spriteConfig, "getTimedActionOnIsValid", 0) then
        report:field("timedActionOnIsValid", spriteConfig:getTimedActionOnIsValid())
    end

    dumpTileList(spriteConfig, report)
    dumpFaces(spriteConfig, report)
end

Debug.registerInspector("core.entityScript", 40, function(object, report)
    if not Options.isFullDetails() then
        return
    end

    local entityScriptName = getEntityScriptName(object)

    if entityScriptName == nil then
        return
    end

    report:section("Entity script")
    report:field("propertyName", entityScriptName)

    if ScriptManager == nil
        or ScriptManager.instance == nil
        or not Reflection.hasMethod(ScriptManager.instance, "getGameEntityScript", 1) then
        report:field("resolved", false)
        return
    end

    local script = ScriptManager.instance:getGameEntityScript(entityScriptName)

    if script == nil then
        report:field("resolved", false)
        return
    end

    report:field("resolved", true)
    report:field("class", Safe.className(script))

    if Reflection.hasMethod(script, "getName", 0) then
        report:field("name", script:getName())
    end

    if Reflection.hasMethod(script, "getFullName", 0) then
        report:field("fullName", script:getFullName())
    end

    if Reflection.hasMethod(script, "getModuleName", 0) then
        report:field("module", script:getModuleName())
    end

    if Reflection.hasMethod(script, "getModID", 0) then
        report:field("modID", script:getModID())
    end

    if Reflection.hasMethod(script, "getFileAbsPath", 0) then
        report:field("file", script:getFileAbsPath())
    end

    if Reflection.hasMethod(script, "getExistsAsVanilla", 0) then
        report:field("existsAsVanilla", script:getExistsAsVanilla())
    end

    if Reflection.hasMethod(script, "getRegistry_id", 0) then
        report:field("registryId", script:getRegistry_id())
    end

    dumpComponentList(script, report)
    dumpSpriteConfig(script, report)
end)

return true
