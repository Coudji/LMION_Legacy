require "LMION/Pickup/GarageDoorSpecs"

local Pickup = LMION.Pickup
local GarageDoor = Pickup.GarageDoor

Pickup._garageDoorOriginalSpriteGrids = Pickup._garageDoorOriginalSpriteGrids or {}
Pickup.GarageDoorRuntimeSpriteGrids = Pickup.GarageDoorRuntimeSpriteGrids or {}

--[[
Moveables only treats a sprite as multi-tile when IsoSprite:getSpriteGrid() is set.
Garage linkage itself does not need this grid; the grid exists only to give the
Moveables cursor a stable three-tile footprint and rotation model.
]]
local function installGrid(family, facing)
    local runtimeKey = family.id .. ":" .. facing
    local oldGrid = Pickup.GarageDoorRuntimeSpriteGrids[runtimeKey]

    if oldGrid ~= nil then
        for partIndex = 1, 3 do
            local sprite = getSprite(family.parts[partIndex].faces[facing])
            if sprite ~= nil and sprite:getSpriteGrid() == oldGrid then
                sprite:setSpriteGrid(nil)
            end
        end
    end

    local grid
    if facing == "N" then
        grid = IsoSpriteGrid.new(3, 1)
        for partIndex = 1, 3 do
            local sprite = getSprite(family.parts[partIndex].faces.N)
            if sprite == nil then
                return false
            end
            grid:setSprite(partIndex - 1, 0, sprite)
        end
    elseif facing == "W" then
        grid = IsoSpriteGrid.new(1, 3)
        for partIndex = 1, 3 do
            local sprite = getSprite(family.parts[partIndex].faces.W)
            if sprite == nil then
                return false
            end

            -- Vanilla garage indices advance toward decreasing Y when west-facing.
            grid:setSprite(0, 3 - partIndex, sprite)
        end
    else
        return false
    end

    if not grid:validate() then
        return false
    end

    for partIndex = 1, 3 do
        local sprite = getSprite(family.parts[partIndex].faces[facing])
        if Pickup._garageDoorOriginalSpriteGrids[sprite:getName()] == nil then
            Pickup._garageDoorOriginalSpriteGrids[sprite:getName()] = sprite:getSpriteGrid()
        end
        sprite:setSpriteGrid(grid)
    end

    Pickup.GarageDoorRuntimeSpriteGrids[runtimeKey] = grid
    return true
end

local function installAllRuntimeSpriteGrids()
    local installed = 0
    local expected = 0

    for _, family in pairs(GarageDoor.Families) do
        for _, facing in ipairs({"N", "W"}) do
            expected = expected + 1
            if installGrid(family, facing) then
                installed = installed + 1
            end
        end
    end

    if installed == expected then
        LMION.log("Pickup", "installed " .. tostring(installed) .. " garage door runtime sprite grids")
    else
        LMION.error("Pickup", "garage door runtime sprite grids: " .. tostring(installed) .. "/" .. tostring(expected) .. " installed")
    end

    return installed == expected
end

GarageDoor.installRuntimeSpriteGrids = installAllRuntimeSpriteGrids
Pickup.installGarageDoorRuntimeSpriteGrids = installAllRuntimeSpriteGrids

if Pickup._garageDoorRuntimeGridHandler ~= nil then
    Events.OnLoadedTileDefinitions.Remove(Pickup._garageDoorRuntimeGridHandler)
end

Pickup._garageDoorRuntimeGridHandler = installAllRuntimeSpriteGrids
Events.OnLoadedTileDefinitions.Add(Pickup._garageDoorRuntimeGridHandler)

installAllRuntimeSpriteGrids()

return GarageDoor
