local Doors = LMION.Doors

--[[
Construction owns gameplay values, not the Java representation chosen by the
engine. Vanilla GameEntity construction may produce an IsoThumpable door; keep it
as-is and initialize only the state LMION_Build explicitly decided.
]]
function Doors.initializeConstructedDoor(params)
    local object = params and params.object or nil
    if not Doors.isDoorObject(object) then
        return false
    end

    local profile = Doors.getProfileForSprite(object:getSprite())
    local effectiveMaxHealth = params and tonumber(params.effectiveMaxHealth) or nil

    if effectiveMaxHealth == nil
        and Doors.BuildContext ~= nil
        and Doors.BuildContext.profile == profile then
        effectiveMaxHealth = tonumber(Doors.BuildContext.effectiveMaxHealth)
    end

    if profile ~= nil and object.setName ~= nil then
        object:setName(Doors.getDisplayName(profile))
    end

    if effectiveMaxHealth ~= nil then
        Doors.setEffectiveMaxHealth(object, effectiveMaxHealth)
        Doors.setHealth(object, effectiveMaxHealth)
    end

    return true
end

return Doors
