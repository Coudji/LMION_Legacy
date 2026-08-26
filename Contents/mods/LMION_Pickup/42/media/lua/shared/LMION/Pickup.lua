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
require "LMION/Pickup/ToolDefinitions"
require "LMION/Pickup/DoorMoveables"
require "LMION/Pickup/GarageDoorSpecs"
require "LMION/Pickup/GarageDoorRuntime"
require "LMION/Pickup/GarageDoorMoveables"
require "LMION/Pickup/LargeGateProfiles"
require "LMION/Pickup/LargeGateSpecs"
require "LMION/Pickup/LargeGateRuntime"
require "LMION/Pickup/LargeGateMoveables"
require "LMION/Pickup/LargeGatePlacement"

LMION.registerModule(Pickup.ID, Pickup)
LMION.log("Pickup", "loaded " .. Pickup.VERSION)

return Pickup
