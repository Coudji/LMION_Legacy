local Doors = LMION.Doors

--[[
LMION construction has one representation invariant: the completed door is an
IsoDoor. ISBuildIsoEntity may create a temporary IsoThumpable, but that is an
engine construction detail rather than a persistent LMION representation.

Ordinary doors and DoubleDoor gate members are canonicalized during the generic
post-build finalization performed by BuildHook. Garage members are canonicalized
earlier by SpriteConfig.OnCreate because their native garage mechanics require an
IsoDoor before normal interaction can safely occur.
]]
function Doors.initializeConstructedDoor(params)
    local object = params and params.object or nil
    if not Doors.isDoorObject(object) then
        return nil
    end

    object = Doors.ensureCanonicalDoor(object, {
        preserveLockState = false,
    })
    if not Doors.isCanonicalDoor(object) then
        return nil
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

    return object
end

--[[
Garage-specific early canonicalization.

B42.20.4 runtime tracing confirmed that SpriteConfig.OnCreate receives each
temporary garage IsoThumpable, the returned IsoDoor survives into the completed
world object, and BuildHook later finds that same IsoDoor. Keep this early timing
because IsoThumpable does not implement complete native GarageDoor mechanics.

The conversion primitive itself is shared with every other LMION door through
Doors.ensureCanonicalDoor(); garage doors are special only in WHEN conversion
happens, not in the representation policy.
]]
function Doors.onCreateGarage(params)
    local thumpable = params and params.thumpable or nil
    if thumpable == nil or not Doors.isThumpableDoor(thumpable) then
        LMION.error("Core", "onCreateGarage(): missing temporary IsoThumpable door")
        return nil
    end

    local garageDoor = Doors.ensureCanonicalDoor(thumpable, {
        preserveLockState = false,
    })
    if not Doors.isCanonicalDoor(garageDoor) then
        return nil
    end

    garageDoor = Doors.initializeConstructedDoor({
        object = garageDoor,
        effectiveMaxHealth = params and params.effectiveMaxHealth or nil,
    })

    return {
        replaceObject = true,
        object = garageDoor,
    }
end

return Doors
