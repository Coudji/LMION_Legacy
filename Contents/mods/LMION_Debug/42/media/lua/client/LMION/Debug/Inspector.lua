require "ISUI/ISContextMenu"
require "LMION/Debug/Registry"
require "LMION/Debug/Inspect/Door"
require "LMION/Debug/Inspect/Opening"
require "LMION/Debug/Inspect/Frame"
require "LMION/Debug/Inspect/ObjectInspector"
require "LMION/Debug/World/SquareScanner"
require "LMION/Debug/World/Selection"
require "LMION/Debug/UI/InspectorWindow"
require "LMION/Debug/TestZone"

local Debug = LMION.Debug

if not Debug.isEnabled() then
    return
end

Debug.Inspector = Debug.Inspector or {}
local Inspector = Debug.Inspector

local function getClickedSquare(playerNum, worldObjects)
    if worldObjects ~= nil then
        for _, object in ipairs(worldObjects) do
            if object ~= nil then
                local square = object:getSquare()

                if square ~= nil then
                    return square
                end
            end
        end
    end

    if getSpecificPlayer ~= nil then
        local player = getSpecificPlayer(playerNum)

        if player ~= nil then
            return player:getSquare()
        end
    end

    return nil
end

local function getDoorOnSquare(square)
    if square == nil then
        return nil
    end

    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if object ~= nil and instanceof(object, "IsoDoor") then
            return object
        end
    end

    return nil
end

function Inspector.openAtSquare(square)
    Debug.Window.openAtSquare(square)
end

function Inspector.repairDoor(door)
    if door == nil or LMION.Doors == nil or LMION.Doors.repairHealth == nil then
        return
    end

    local newHealth, restored = LMION.Doors.repairHealth(door, 50)

    if LMION.log ~= nil then
        LMION.log(
            "Debug",
            "repair +50 restored=" .. tostring(restored)
                .. ", health=" .. tostring(newHealth)
                .. ", lmionMax=" .. tostring(LMION.Doors.getEffectiveMaxHealth(door))
                .. ", engineMax=" .. tostring(door:getMaxHealth())
        )
    end
end

function Inspector.onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    if test then
        return
    end

    local square = getClickedSquare(playerNum, worldObjects)

    context:addOption(
        "LMION Inspector",
        square,
        Inspector.openAtSquare
    )

    local door = getDoorOnSquare(square)
    if door ~= nil and LMION.Doors ~= nil and LMION.Doors.getEffectiveMaxHealth ~= nil then
        local maxHealth = LMION.Doors.getEffectiveMaxHealth(door)
        if maxHealth ~= nil and door:getHealth() < maxHealth then
            context:addOption(
                "LMION Repair +50 HP",
                door,
                Inspector.repairDoor
            )
        end
    end
end

if Inspector._contextHandler ~= nil then
    Events.OnFillWorldObjectContextMenu.Remove(Inspector._contextHandler)
end

Inspector._contextHandler = Inspector.onFillWorldObjectContextMenu
Events.OnFillWorldObjectContextMenu.Add(Inspector._contextHandler)

if LMION.log ~= nil then
    LMION.log("Debug", "door inspector ready")
end
