LMION.Doors = LMION.Doors or {}
local Doors = LMION.Doors

Doors.Profiles = require "LMION/DoorProfiles"
Doors.MaxHealthModDataKey = "lmionDoorMaxHealth"
Doors.BuildContext = nil

--[[
Doors.lua is the public Core door bootstrap. Focused modules below extend the same
LMION.Doors table so existing callers keep one stable API while responsibilities
remain separated for humans reading the implementation.
]]
require "LMION/Doors/Registry"
require "LMION/Doors/EngineProperties"
require "LMION/Doors/Durability"
require "LMION/Doors/Placement"
require "LMION/Doors/Construction"

if Events ~= nil and Events.OnLoadedTileDefinitions ~= nil then
    Events.OnLoadedTileDefinitions.Add(Doors.applyEngineProfiles)
end

if Events ~= nil and Events.LoadGridsquare ~= nil then
    Events.LoadGridsquare.Add(Doors.adoptWorldDoorsOnSquare)
end

if Events ~= nil and Events.OnObjectAdded ~= nil then
    Events.OnObjectAdded.Add(Doors.adoptWorldDoor)
end

Doors.applyEngineProfiles()

return Doors
