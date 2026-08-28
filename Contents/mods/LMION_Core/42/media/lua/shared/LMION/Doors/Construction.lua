local Doors = LMION.Doors

--[[
Construction normally owns gameplay values, not the Java representation chosen by
the engine. Vanilla GameEntity construction may produce an IsoThumpable door; keep
it as-is and initialize only the state LMION_Build explicitly decided.

Garage-door SpriteConfigs are the deliberate exception. Their OnCreate contract
predates the generic door construction path and replaces each temporary build
IsoThumpable with an IsoDoor. Garage topology/placement is authored around those
specialized door objects, and vanilla ISBuildIsoEntity explicitly supports an
OnCreate callback returning { replaceObject = true, object = ... } for this case.
Do not generalize this conversion to ordinary doors or large DoubleDoor gates.
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

--[[
Called by the seven garage-door SpriteConfig OnCreate hooks.

ISBuildIsoEntity has already created and added the temporary IsoThumpable when
this runs. Recreate that exact panel as the specialized IsoDoor representation,
then return the replacement object so vanilla transmits the correct instance.

This restores the garage-specific construction contract that was accidentally
lost when the old monolithic Doors.lua was refactored. Without the callback the
build path leaves malformed temporary garage thumpables behind; B42.20.4 was
observed crashing later when engine lighting/toggle code encountered one with a
nil sprite.
]]
function Doors.onCreateGarage(params)
    local thumpable = params and params.thumpable or nil
    if thumpable == nil or not instanceof(thumpable, "IsoThumpable") then
        LMION.error("Core", "onCreateGarage(): missing temporary IsoThumpable")
        return nil
    end

    local square = thumpable:getSquare()
    local sprite = thumpable:getSprite()
    local north = thumpable.getNorth ~= nil and thumpable:getNorth() or nil
    if square == nil or sprite == nil or north == nil then
        LMION.error("Core", "onCreateGarage(): incomplete temporary garage object")
        return nil
    end

    local garageDoor = IsoDoor.new(getCell(), square, sprite, north)

    if thumpable.getName ~= nil and garageDoor.setName ~= nil then
        garageDoor:setName(thumpable:getName())
    end

    if thumpable.getModData ~= nil and garageDoor.setModData ~= nil then
        garageDoor:setModData(copyTable(thumpable:getModData()))
    end

    if thumpable.getKeyId ~= nil and garageDoor.setKeyId ~= nil then
        garageDoor:setKeyId(thumpable:getKeyId())
    end

    if garageDoor.setIsLocked ~= nil then
        garageDoor:setIsLocked(false)
    end
    if garageDoor.setLockedByKey ~= nil then
        garageDoor:setLockedByKey(false)
    end

    if thumpable.getHealth ~= nil and garageDoor.setHealth ~= nil then
        garageDoor:setHealth(thumpable:getHealth())
    end

    -- Multi-square GameEntity components cannot be transferred safely through
    -- TransferComponents. Recreate them from the scripted entity, matching the
    -- original validated garage construction path.
    if GameEntityFactory ~= nil and GameEntityFactory.CreateIsoEntityFromCellLoading ~= nil then
        local properties = garageDoor:getProperties()
        if properties ~= nil and properties:has(IsoFlagType.EntityScript) then
            GameEntityFactory.CreateIsoEntityFromCellLoading(garageDoor)
        end
    end

    square:AddSpecialObject(garageDoor)
    square:transmitRemoveItemFromSquare(thumpable)

    return {
        replaceObject = true,
        object = garageDoor,
    }
end

return Doors
