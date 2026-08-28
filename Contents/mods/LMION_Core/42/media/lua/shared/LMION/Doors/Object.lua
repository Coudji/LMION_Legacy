local Doors = LMION.Doors

--[[
Project Zomboid has two valid physical representations for doors:
- IsoDoor for map-authored doors and other specialized door objects;
- IsoThumpable configured as a door for construction-driven objects.

Gameplay modules should ask Core whether an object is a door instead of depending
on one concrete Java class.
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
