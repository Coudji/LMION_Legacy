require "LMION/Debug/Registry"
require "LMION/Debug/Util/Safe"
require "LMION/Debug/Util/Reflection"
require "LMION/Debug/Inspect/Options"
require "LMION/Debug/Inspect/PropertyContainer"

local Debug = LMION.Debug
local Safe = Debug.Util.Safe
local Reflection = Debug.Util.Reflection
local Options = Debug.Inspect.Options
local PropertyContainer = Debug.Inspect.PropertyContainer

local function spriteName(sprite)
    if sprite == nil then
        return nil
    end

    return Safe.value("IsoSprite.getName", function()
        return sprite:getName()
    end, tostring(sprite))
end

local function dumpSpriteGrid(sprite, report)
    if sprite == nil or not Reflection.hasMethod(sprite, "getSpriteGrid", 0) then
        return
    end

    local grid = sprite:getSpriteGrid()

    if grid == nil then
        report:field("grid", "<none>")
        return
    end

    local width = Reflection.hasMethod(grid, "getWidth", 0) and grid:getWidth() or "?"
    local height = Reflection.hasMethod(grid, "getHeight", 0) and grid:getHeight() or "?"
    local levels = Reflection.hasMethod(grid, "getLevels", 0) and grid:getLevels() or "?"

    report:field("grid", tostring(width) .. " x " .. tostring(height) .. " x " .. tostring(levels))

    if Reflection.hasMethod(grid, "getSpriteCount", 0) then
        report:field("grid.spriteCount", grid:getSpriteCount())
    end

    if Reflection.hasMethod(grid, "getSpriteGridPosX", 1) then
        report:field("grid.positionX", grid:getSpriteGridPosX(sprite))
    end

    if Reflection.hasMethod(grid, "getSpriteGridPosY", 1) then
        report:field("grid.positionY", grid:getSpriteGridPosY(sprite))
    end

    if Reflection.hasMethod(grid, "getSpriteGridPosZ", 1) then
        report:field("grid.positionZ", grid:getSpriteGridPosZ(sprite))
    end

    if Reflection.hasMethod(grid, "getAnchorSprite", 0) then
        report:field("grid.anchorSprite", spriteName(grid:getAnchorSprite()))
    end
end

Debug.registerInspector("core.sprite", 20, function(object, report)
    if not Options.isFullDetails() then
        return
    end

    local sprite = Safe.value("IsoObject.getSprite", function()
        return object:getSprite()
    end, nil)

    if sprite == nil then
        return
    end

    report:section("Sprite")
    report:field("name", spriteName(sprite))

    if Reflection.hasMethod(sprite, "getID", 0) then
        report:field("id", sprite:getID())
    end

    if Reflection.hasMethod(sprite, "getType", 0) then
        report:field("type", sprite:getType())
    end

    if Reflection.hasMethod(sprite, "getTileType", 0) then
        report:field("tileType", sprite:getTileType())
    end

    if Reflection.hasMethod(sprite, "getParentObjectName", 0) then
        report:field("parentObjectName", sprite:getParentObjectName())
    end

    dumpSpriteGrid(sprite, report)

    if not Reflection.hasMethod(sprite, "getProperties", 0) then
        return
    end

    local objectProperties = PropertyContainer.fromObject(object)
    local spriteProperties = sprite:getProperties()

    if spriteProperties == objectProperties then
        report:section("Sprite properties")
        report:field("same as", "Object properties")
        return
    end

    PropertyContainer.dumpFull(spriteProperties, report, "Sprite")
end)
