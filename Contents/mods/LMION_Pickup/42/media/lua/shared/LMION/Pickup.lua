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

local function renderLargeGateLeaf(self, x, y, z)
    if self == nil or ISMoveableCursor.mode[self.player] ~= "place" then
        return false
    end

    local moveProps = self.currentMoveProps
    if moveProps == nil or moveProps.lmionLargeGateLeaf == nil then
        return false
    end

    local leaf = Pickup.LargeGateLeafSpecs and Pickup.LargeGateLeafSpecs[moveProps.lmionLargeGateLeaf] or nil
    local facing = moveProps.lmionDoorFacing
    local partIndex = tonumber(moveProps.lmionLargeGatePart)
    if leaf == nil or facing == nil or partIndex == nil then
        return false
    end

    local dx = 0
    local dy = 0
    if facing == "N" then
        dx = 1
    elseif facing == "W" then
        dy = -1
    else
        return false
    end

    local anchorX = x
    local anchorY = y
    if partIndex == 2 then
        anchorX = anchorX - dx
        anchorY = anchorY - dy
    elseif partIndex ~= 1 then
        return false
    end

    local color = self.colorMod or ISMoveableSpriteProps.invalidColor or {r=1, g=0, b=0}
    local yOffset = (self.yOffset or 0) * Core.getTileScale()

    for index = 1, 2 do
        local spriteName = leaf.parts[index].faces[facing]
        local sprite = spriteName and getSprite(spriteName) or nil
        if sprite == nil then
            return false
        end

        local worldX = anchorX + ((index - 1) * dx)
        local worldY = anchorY + ((index - 1) * dy)
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

        sprite:RenderGhostTileColor(
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

    return true
end

if Pickup._largeGateOriginalCursorRender == nil then
    Pickup._largeGateOriginalCursorRender = ISMoveableCursor.render
end

ISMoveableCursor.render = function(self, x, y, z, square)
    if renderLargeGateLeaf(self, x, y, z) then
        return
    end

    return Pickup._largeGateOriginalCursorRender(self, x, y, z, square)
end

LMION.registerModule(Pickup.ID, Pickup)
LMION.log("Pickup", "loaded " .. Pickup.VERSION)

return Pickup
