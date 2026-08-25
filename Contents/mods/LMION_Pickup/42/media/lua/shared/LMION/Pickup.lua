require "LMION/Core"

LMION.Pickup = LMION.Pickup or {}
local Pickup = LMION.Pickup

Pickup.ID = "LMION_Pickup"
Pickup.VERSION = "0.0.8-dev"
Pickup.Strategies = Pickup.Strategies or {}

function Pickup.registerStrategy(id, strategy, priority)
    if type(id) ~= "string" or id == "" then
        LMION.error("Pickup", "registerStrategy(): invalid strategy id")
        return false
    end

    if type(strategy) ~= "table" then
        LMION.error("Pickup", "registerStrategy(): strategy must be a table")
        return false
    end

    if type(strategy.matches) ~= "function" then
        LMION.error("Pickup", "strategy '" .. id .. "' has no matches() function")
        return false
    end

    for i = #Pickup.Strategies, 1, -1 do
        if Pickup.Strategies[i].id == id then
            table.remove(Pickup.Strategies, i)
        end
    end

    table.insert(Pickup.Strategies, {
        id = id,
        priority = tonumber(priority) or 0,
        strategy = strategy,
    })

    table.sort(Pickup.Strategies, function(a, b)
        if a.priority == b.priority then
            return a.id < b.id
        end
        return a.priority > b.priority
    end)

    LMION.log("Pickup", "registered strategy: " .. id)
    return true
end

function Pickup.findStrategy(worldObject)
    if worldObject == nil then
        return nil, nil
    end

    for i = 1, #Pickup.Strategies do
        local entry = Pickup.Strategies[i]
        local ok, matches = pcall(entry.strategy.matches, worldObject)

        if not ok then
            LMION.error(
                "Pickup",
                "strategy '" .. entry.id .. "' failed in matches(): " .. tostring(matches)
            )
        elseif matches then
            return entry.strategy, entry.id
        end
    end

    return nil, nil
end

function Pickup.getRegisteredStrategyCount()
    return #Pickup.Strategies
end

require "LMION/Pickup/DoorProfiles"
require "LMION/Pickup/LargeGateProfiles"
require "LMION/Pickup/ToolDefinitions"
require "LMION/Pickup/DoorMoveables"
require "LMION/Pickup/LargeGateMoveables"
require "BuildingObjects/ISMoveableCursor"

local function renderLargeGateGrid(self, x, y, z, color)
    local moveProps = self and self.currentMoveProps or nil
    if moveProps == nil or moveProps.lmionLargeGateLeaf == nil then
        return false
    end

    local sprite = moveProps.sprite
    local grid = sprite and sprite:getSpriteGrid() or nil
    if grid == nil then
        return false
    end

    local offsetX = grid:getSpriteGridPosX(sprite)
    local offsetY = grid:getSpriteGridPosY(sprite)
    local baseX = x - offsetX
    local baseY = y - offsetY
    local yOffset = (self.yOffset or 0) * Core.getTileScale()

    for gridX = 0, grid:getWidth() - 1 do
        for gridY = 0, grid:getHeight() - 1 do
            local worldX = baseX + gridX
            local worldY = baseY + gridY
            local square = getCell():getGridSquare(worldX, worldY, z)
            if square ~= nil and square:getFloor() ~= nil and square:getFloor():getSprite() ~= nil then
                square:getFloor():getSprite():RenderGhostTileColor(
                    worldX,
                    worldY,
                    z,
                    0.75,
                    1,
                    0.75,
                    0.25
                )
            end

            local ghostSprite = grid:getSprite(gridX, gridY)
            if ghostSprite ~= nil then
                ghostSprite:RenderGhostTileColor(
                    worldX,
                    worldY,
                    z,
                    0,
                    yOffset,
                    color.r,
                    color.g,
                    color.b,
                    0.8
                )
            end
        end
    end

    return true
end

if Pickup._largeGateOriginalRenderSpriteGrid == nil then
    Pickup._largeGateOriginalRenderSpriteGrid = ISMoveableCursor.renderSpriteGrid
end

ISMoveableCursor.renderSpriteGrid = function(self, x, y, z, color)
    if renderLargeGateGrid(self, x, y, z, color) then
        return
    end

    return Pickup._largeGateOriginalRenderSpriteGrid(self, x, y, z, color)
end

LMION.registerModule(Pickup.ID, Pickup)
LMION.log("Pickup", "loaded " .. Pickup.VERSION)

return Pickup
