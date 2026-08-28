require "LMION/Core"

LMION.Pickup = LMION.Pickup or {}
local Pickup = LMION.Pickup

Pickup.ID = "LMION_Pickup"
Pickup.VERSION = "0.0.9-dev"
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
require "LMION/Pickup/ToolDefinitions"
require "LMION/Pickup/DoorMoveables"
require "LMION/Pickup/GarageDoorSpecs"
require "LMION/Pickup/GarageDoorRuntime"
require "LMION/Pickup/GarageDoorMoveables"
require "LMION/Pickup/GarageDoorPickup"
require "LMION/Pickup/GarageDoorPlacement"
require "LMION/Pickup/LargeGateProfiles"
require "LMION/Pickup/LargeGateSpecs"
require "LMION/Pickup/LargeGateRuntime"
require "LMION/Pickup/LargeGateMoveables"
require "LMION/Pickup/LargeGatePlacement"
require "LMION/Pickup/LargeGateOpenState"
require "LMION/Pickup/LargeGateOpenPickup"

--[[
Vanilla Moveables calls ReadFromWorldSprite() while creating the inventory item.
That can overwrite InventoryItem.weight from world-sprite data; vanilla restores
only actualWeight afterward. LMION already owns an explicit gameplay weight for
all supported doors and multi-part parcels, so keep both InventoryItem weight
fields synchronized with the resolved MoveProps value after the complete
specialized instanceItem chain has finished.
]]
local function isLmionTransportMoveProps(moveProps)
    return moveProps ~= nil
        and (moveProps.lmionDoorProfile ~= nil
            or moveProps.lmionGarageFamily ~= nil
            or moveProps.lmionLargeGateLeaf ~= nil)
end

if Pickup._weightNormalizedPreviousInstanceItem == nil then
    Pickup._weightNormalizedPreviousInstanceItem = ISMoveableSpriteProps.instanceItem
end

ISMoveableSpriteProps.instanceItem = function(self, spriteNameOverride)
    local item = Pickup._weightNormalizedPreviousInstanceItem(self, spriteNameOverride)

    if item ~= nil and isLmionTransportMoveProps(self) then
        local weight = tonumber(self.weight)
        if weight ~= nil and weight > 0 then
            item:setActualWeight(weight)
            item:setWeight(weight)
        end
    end

    return item
end

LMION.registerModule(Pickup.ID, Pickup)
LMION.log("Pickup", "loaded " .. Pickup.VERSION)

return Pickup
