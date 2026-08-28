local Doors = LMION.Doors

--[[
LMION's canonical physical representation is IsoDoor.

IsoThumpable(isDoor) remains a valid engine/source representation and Core must be
able to read state from it. Once LMION creates, finalizes or reinstalls a supported
door, however, the world object is canonicalized to IsoDoor so gameplay modules and
addons do not need parallel physical backends.
]]
function Doors.isCanonicalDoor(object)
    return Doors.isIsoDoor(object)
end

local function recreateGameEntity(object)
    if object == nil
        or GameEntityFactory == nil
        or GameEntityFactory.CreateIsoEntityFromCellLoading == nil then
        return
    end

    local properties = object:getProperties()
    if properties ~= nil and properties:has(IsoFlagType.EntityScript) then
        GameEntityFactory.CreateIsoEntityFromCellLoading(object)
    end
end

function Doors.ensureCanonicalDoor(object, options)
    if Doors.isIsoDoor(object) then
        return object
    end

    if not Doors.isThumpableDoor(object) then
        return nil
    end

    options = options or {}

    local square = object:getSquare()
    local sprite = object:getSprite()
    local north = object.getNorth ~= nil and object:getNorth() or nil
    if square == nil or sprite == nil or north == nil then
        LMION.error("Core", "ensureCanonicalDoor(): incomplete IsoThumpable door")
        return nil
    end

    local state = Doors.captureDoorState(object)
    if state == nil then
        LMION.error("Core", "ensureCanonicalDoor(): failed to capture source door state")
        return nil
    end

    -- Fresh LMION construction must not inherit transient lock flags created by
    -- ISBuildIsoEntity. Other callers preserve the source lock state by default.
    if options.preserveLockState == false then
        state.locked = false
        state.lockedByKey = false
    end

    local objectName = object.getName ~= nil and object:getName() or nil
    local door = IsoDoor.new(getCell(), square, sprite, north)

    if objectName ~= nil and door.setName ~= nil then
        door:setName(objectName)
    end

    Doors.restoreDoorState(door, state)
    recreateGameEntity(door)

    square:AddSpecialObject(door)
    square:transmitRemoveItemFromSquare(object)

    return door
end

return Doors
