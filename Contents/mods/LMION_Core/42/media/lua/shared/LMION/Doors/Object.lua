local Doors = LMION.Doors

--[[
Project Zomboid may present a semantic door through either Java class:
- IsoDoor for map/world doors and specialized native door mechanics;
- IsoThumpable(isDoor) for construction-driven engine objects.

Core recognizes both because LMION must be able to adopt, inspect, capture and
transport either source representation. This does not make both classes canonical:
LMION-created/finalized/reinstalled doors converge to IsoDoor through Core.
]]
function Doors.isIsoDoor(object)
    return object ~= nil and instanceof(object, "IsoDoor")
end

function Doors.isThumpableDoor(object)
    return object ~= nil
        and instanceof(object, "IsoThumpable")
        and object.isDoor ~= nil
        and object:isDoor()
end

function Doors.isDoorObject(object)
    return Doors.isIsoDoor(object) or Doors.isThumpableDoor(object)
end

-- Informational/source representation only. Gameplay modules must not use this
-- value to choose the representation of an LMION-created or reinstalled door.
function Doors.getDoorRepresentation(object)
    if Doors.isIsoDoor(object) then
        return "IsoDoor"
    end

    if Doors.isThumpableDoor(object) then
        return "IsoThumpable"
    end

    return nil
end

return Doors
