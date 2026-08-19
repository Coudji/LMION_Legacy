require "ISUI/ISContextMenu"
require "LMION/Debug/Registry"
require "LMION/Debug/Inspect/Options"
require "LMION/Debug/Inspect/PropertyReaders"
require "LMION/Debug/Inspect/DefaultPropertyReaders"
require "LMION/Debug/Inspect/PropertyContainer"
require "LMION/Debug/Inspect/ObjectInspector"
require "LMION/Debug/Inspect/CoreObject"
require "LMION/Debug/Inspect/IsoSprite"
require "LMION/Debug/Inspect/IsoDoor"
require "LMION/Debug/Inspect/IsoThumpable"
require "LMION/Debug/World/SquareScanner"
require "LMION/Debug/World/Selection"
require "LMION/Debug/UI/InspectorWindow"
require "LMION/Debug/Showroom"

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

function Inspector.openAtSquare(square)
    Debug.Window.openAtSquare(square)
end

function Inspector.spawnDoorShowroom(square)
    if Debug.Showroom ~= nil then
        Debug.Showroom.spawnAt(square)
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

    context:addOption(
        "LMION Spawn Door Showroom here",
        square,
        Inspector.spawnDoorShowroom
    )
end

if Inspector._contextHandler ~= nil then
    Events.OnFillWorldObjectContextMenu.Remove(Inspector._contextHandler)
end

Inspector._contextHandler = Inspector.onFillWorldObjectContextMenu
Events.OnFillWorldObjectContextMenu.Add(Inspector._contextHandler)

if LMION.log ~= nil then
    LMION.log("Debug", "modular inspector ready")
end
