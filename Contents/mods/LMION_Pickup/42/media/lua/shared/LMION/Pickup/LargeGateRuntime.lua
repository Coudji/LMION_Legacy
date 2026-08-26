require "LMION/Pickup/LargeGateSpecs"

local Pickup = LMION.Pickup
local LargeGate = Pickup.LargeGate
local leafSpecs = LargeGate.Leaves
local gridFacingSpecs = LargeGate.GridFacingSpecs

Pickup._largeGateOriginalSpriteGrids = Pickup._largeGateOriginalSpriteGrids or {}
Pickup.LargeGateRuntimeSpriteGrids = {}

local function installRuntimeSpriteGrid(leafId, facing)
    local leaf = leafSpecs[leafId]
    local gridSpec = gridFacingSpecs[facing]
    if leaf == nil or gridSpec == nil or IsoSpriteGrid == nil or IsoSpriteGrid.new == nil then
        return false
    end

    local grid = IsoSpriteGrid.new(gridSpec.width, gridSpec.height)
    if grid == nil then
        return false
    end

    local members = {}
    for position, partIndex in ipairs(gridSpec.partOrder) do
        local part = leaf.parts[partIndex]
        local spriteName = part and part.faces[facing] or nil
        local sprite = spriteName and getSprite(spriteName) or nil
        if sprite == nil then
            return false
        end

        local x = gridSpec.width > 1 and position - 1 or 0
        local y = gridSpec.height > 1 and position - 1 or 0
        grid:setSprite(x, y, sprite)
        members[position] = {spriteName = spriteName, sprite = sprite}
    end

    if not grid:validate() then
        return false
    end

    for _, member in ipairs(members) do
        if Pickup._largeGateOriginalSpriteGrids[member.spriteName] == nil then
            Pickup._largeGateOriginalSpriteGrids[member.spriteName] = member.sprite:getSpriteGrid() or false
        end
        member.sprite:setSpriteGrid(grid)
    end

    Pickup.LargeGateRuntimeSpriteGrids[leafId .. ":" .. facing] = grid
    return true
end

local function installAllRuntimeSpriteGrids(reason)
    Pickup.LargeGateRuntimeSpriteGrids = {}

    local installedGridCount = 0
    local expectedGridCount = 0
    for leafId, _ in pairs(leafSpecs) do
        expectedGridCount = expectedGridCount + 2
        if installRuntimeSpriteGrid(leafId, "N") then
            installedGridCount = installedGridCount + 1
        end
        if installRuntimeSpriteGrid(leafId, "W") then
            installedGridCount = installedGridCount + 1
        end
    end

    local suffix = reason and (" (" .. tostring(reason) .. ")") or ""
    if installedGridCount == expectedGridCount then
        LMION.log("Pickup", "installed large-gate runtime sprite grids" .. suffix)
        return true
    end

    LMION.error("Pickup", "failed to install all large-gate runtime sprite grids: " .. tostring(installedGridCount) .. "/" .. tostring(expectedGridCount) .. suffix)
    return false
end

Pickup.installLargeGateRuntimeSpriteGrids = installAllRuntimeSpriteGrids

if Events ~= nil and Events.OnLoadedTileDefinitions ~= nil then
    if not Pickup._largeGateRuntimeSpriteGridHookInstalled then
        Events.OnLoadedTileDefinitions.Add(function()
            if Pickup.installLargeGateRuntimeSpriteGrids ~= nil then
                Pickup.installLargeGateRuntimeSpriteGrids("OnLoadedTileDefinitions")
            end
        end)
        Pickup._largeGateRuntimeSpriteGridHookInstalled = true
    end
end

installAllRuntimeSpriteGrids("lua-load")

return LargeGate
