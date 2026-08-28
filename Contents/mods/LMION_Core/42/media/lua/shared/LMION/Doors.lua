LMION.Doors = LMION.Doors or {}
local Doors = LMION.Doors

Doors.Profiles = require "LMION/DoorProfiles"
Doors.MaxHealthModDataKey = "lmionDoorMaxHealth"
Doors.BuildContext = nil

--[[
Doors.lua is the public Core door bootstrap. Focused modules below extend the same
LMION.Doors table so callers keep one stable API. Core accepts engine door inputs
from either Java representation, but LMION-created/reinstalled doors converge to
its canonical IsoDoor representation.
]]
require "LMION/Doors/Registry"
require "LMION/Doors/EngineProperties"
require "LMION/Doors/Object"
require "LMION/Doors/Durability"
require "LMION/Doors/State"
require "LMION/Doors/Representation"
require "LMION/Doors/Placement"
require "LMION/Doors/Construction"

if Events ~= nil and Events.OnLoadedTileDefinitions ~= nil then
    Events.OnLoadedTileDefinitions.Add(Doors.applyEngineProfiles)
end

-- Recognizing a world door must not change its durability. A future sandbox
-- policy may explicitly opt into profile-based world durability, but Core's
-- default behavior is passive identification only.
Doors.applyEngineProfiles()

return Doors
