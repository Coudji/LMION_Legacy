local Doors = LMION.Doors

Doors.GarageRole = Doors.GarageRole or {
    START = 1,
    MIDDLE = 2,
    END_ = 3,
}

-- LMION safety policy, not an engine limit. Runtime has validated at least L12.
Doors.DefaultGarageMaxLength = 12

local function isGarageWidthLimitDisabled()
    if LMION.GarageWidthLimitDisabled == true then
        return true
    end

    if PZAPI ~= nil and PZAPI.ModOptions ~= nil and PZAPI.ModOptions.getOptions ~= nil then
        local options = PZAPI.ModOptions:getOptions("LMION_Core")
        local option = options and options:getOption("UnlimitedGarageWidth") or nil
        if option ~= nil and option.getValue ~= nil then
            return option:getValue() == true
        end
    end

    return false
end

--[[
Return the LMION gameplay maximum for a garage.

`nil` means that LMION's artificial safety limit is lifted. The actual PZ maximum
is unknown and must not be guessed here. The current local ModOptions checkbox is
only the first settings source; multiplayer/server authority remains deliberately
open and can later feed the same policy query without changing Build/Pickup.
]]
function Doors.getGarageMaxLength()
    if isGarageWidthLimitDisabled() then
        return nil
    end

    return Doors.DefaultGarageMaxLength
end

function Doors.isGarageLengthAllowed(length)
    length = tonumber(length)
    if length == nil or length < 2 then
        return false
    end

    local maximum = Doors.getGarageMaxLength()
    return maximum == nil or length <= maximum
end

function Doors.getGarageRole(object)
    if object == nil or IsoDoor == nil or IsoDoor.getGarageDoorIndex == nil then
        return nil
    end

    local role = tonumber(IsoDoor.getGarageDoorIndex(object))
    if role == Doors.GarageRole.START
        or role == Doors.GarageRole.MIDDLE
        or role == Doors.GarageRole.END_ then
        return role
    end

    return nil
end

--[[
Resolve one complete native garage chain in engine traversal order.

A valid chain is:
    START + zero-or-more MIDDLE + END

The helpers deliberately do not impose LMION's L12 gameplay limit. Core topology
must still be able to inspect/pick up a larger vanilla/world garage even when
normal LMION placement is capped. The caller decides gameplay policy separately.
]]
function Doors.getGarageChain(source)
    if source == nil or not Doors.isIsoDoor(source) then
        return nil
    end

    local first = IsoDoor.getGarageDoorFirst(source)
    if first == nil or Doors.getGarageRole(first) ~= Doors.GarageRole.START then
        return nil
    end

    local north = first:getNorth()
    local expectedOpen = first:IsOpen()
    local members = {}
    local current = first
    local previous = nil

    while current ~= nil do
        if not Doors.isIsoDoor(current)
            or current:getNorth() ~= north
            or current:IsOpen() ~= expectedOpen then
            return nil
        end

        local role = Doors.getGarageRole(current)
        if role == nil then
            return nil
        end

        if #members == 0 then
            if role ~= Doors.GarageRole.START then
                return nil
            end
        elseif role == Doors.GarageRole.START then
            return nil
        end

        members[#members + 1] = current

        if role == Doors.GarageRole.END_ then
            return members
        end

        previous = current
        current = IsoDoor.getGarageDoorNext(current)
        if current == previous then
            return nil
        end
    end

    -- A chain without an END member is malformed/incomplete.
    return nil
end

return Doors
