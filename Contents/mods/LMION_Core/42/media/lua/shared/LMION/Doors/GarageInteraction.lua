require "TimedActions/ISOpenCloseDoor"

local Doors = LMION.Doors

--[[
B42.20.3 implements garage topology helpers for both IsoDoor and IsoThumpable,
but only IsoDoor.ToggleDoorActual() contains the collective GARAGE_DOOR toggle
branch. A constructed IsoThumpable garage therefore opens only the selected panel
unless Core bridges that missing semantic behavior.

Keep the engine-selected IsoThumpable representation. The selected panel still
runs through vanilla ISOpenCloseDoor/ToggleDoor first so normal lock, barricade,
obstruction and sound behavior remains authoritative. Only after that operation
actually changes state do we silently align the two other garage members.
]]

local function getGarageIndex(object)
    if not Doors.isThumpableDoor(object) or object:getSprite() == nil then
        return nil
    end

    local index = IsoDoor.getGarageDoorIndex(object)
    if index == nil or index < 1 or index > 3 then
        return nil
    end

    return index
end

local function getGarageMembers(source)
    local sourceIndex = getGarageIndex(source)
    if sourceIndex == nil then
        return nil
    end

    local north = source:getNorth()
    local first = IsoDoor.getGarageDoorFirst(source)
    if getGarageIndex(first) ~= 1 or first:getNorth() ~= north then
        return nil
    end

    local members = {}
    local current = first

    for expectedIndex = 1, 3 do
        if getGarageIndex(current) ~= expectedIndex or current:getNorth() ~= north then
            return nil
        end

        members[expectedIndex] = current
        if expectedIndex < 3 then
            current = IsoDoor.getGarageDoorNext(current)
        end
    end

    return members
end

local function synchronizeMembers(source, members, shouldBeOpen)
    local changed = false

    for _, member in ipairs(members) do
        if member ~= source and member:IsOpen() ~= shouldBeOpen then
            member:ToggleDoorSilent()

            if member:IsOpen() ~= shouldBeOpen then
                LMION.error("Core", "garage IsoThumpable member refused synchronized toggle")
            else
                changed = true

                local square = member:getSquare()
                if square ~= nil then
                    square:RecalcAllWithNeighbours(true)
                end

                -- ToggleDoorSilent() intentionally has no network send. Use the
                -- public full-thumpable sync API instead of IsoObject.sync(int),
                -- which is not part of the Lua-facing IsoThumpable API.
                if member.syncIsoThumpable ~= nil then
                    member:syncIsoThumpable()
                end
            end
        end
    end

    if changed then
        triggerEvent("OnContainerUpdate")
    end
end

if Doors._originalOpenCloseDoorComplete == nil then
    Doors._originalOpenCloseDoorComplete = ISOpenCloseDoor.complete
end

ISOpenCloseDoor.complete = function(self)
    local source = self and self.item or nil
    local members = getGarageMembers(source)

    if members == nil then
        return Doors._originalOpenCloseDoorComplete(self)
    end

    local wasOpen = source:IsOpen()
    local result = Doors._originalOpenCloseDoorComplete(self)
    local isOpen = source:IsOpen()

    -- Vanilla may refuse the selected panel because it is locked, barricaded or
    -- obstructed. In that case do not mutate any sibling panel.
    if isOpen ~= wasOpen then
        synchronizeMembers(source, members, isOpen)
    end

    return result
end

return Doors
