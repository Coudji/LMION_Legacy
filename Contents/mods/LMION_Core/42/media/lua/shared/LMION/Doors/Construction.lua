local Doors = LMION.Doors

local function getGarageDoorIndex(object)
    if not Doors.isDoorObject(object) or object:getSprite() == nil then
        return nil
    end

    local index = IsoDoor.getGarageDoorIndex(object)
    if index == nil or index < 1 or index > 3 then
        return nil
    end

    return index
end

--[[
Garage construction is the deliberate representation exception.

The seven garage SpriteConfigs call Doors.onCreateGarage while ISBuildIsoEntity is
still constructing each temporary IsoThumpable member. B42.20.4 runtime tracing
confirmed that the returned IsoDoor replacement survives into the completed world
object for all three members of the tested garage.

Therefore OnCreate is the only garage representation-conversion path. The generic
post-build BuildHook may still initialize Build-owned stats on the final object,
but it must not perform a second representation conversion.

Do not generalize this conversion to 1x1 doors or DoubleDoor large gates.
]]
local function replaceGarageThumpable(thumpable)
    if not Doors.isThumpableDoor(thumpable) or getGarageDoorIndex(thumpable) == nil then
        return nil
    end

    local square = thumpable:getSquare()
    local sprite = thumpable:getSprite()
    if square == nil or sprite == nil then
        LMION.error("Core", "replaceGarageThumpable(): incomplete temporary garage object")
        return nil
    end

    local garageDoor = IsoDoor.new(getCell(), square, sprite, thumpable:getNorth())

    -- Preserve only the state the old validated garage path intentionally kept.
    -- In particular, do NOT inherit the temporary IsoThumpable lock flags: the
    -- pre-refactor implementation explicitly created constructed garages unlocked.
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
    -- old working garage construction path.
    if GameEntityFactory ~= nil and GameEntityFactory.CreateIsoEntityFromCellLoading ~= nil then
        local properties = garageDoor:getProperties()
        if properties ~= nil and properties:has(IsoFlagType.EntityScript) then
            GameEntityFactory.CreateIsoEntityFromCellLoading(garageDoor)
        end
    end

    square:AddSpecialObject(garageDoor)
    square:transmitRemoveItemFromSquare(thumpable)

    return garageDoor
end

--[[
Generic Build-owned state initialization. This function never changes Java
representation. Ordinary doors/large gates keep their engine-created class, while
garages have already been converted by their SpriteConfig OnCreate callback.
]]
function Doors.initializeConstructedDoor(params)
    local object = params and params.object or nil
    if not Doors.isDoorObject(object) then
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
Garage-specific SpriteConfig OnCreate callback.

Runtime tracing on B42.20.4 confirmed this callback receives each temporary garage
IsoThumpable, replaces it with IsoDoor, returns that replacement to vanilla, and
the same IsoDoor is still present when Build performs its normal post-build scan.
]]
function Doors.onCreateGarage(params)
    local thumpable = params and params.thumpable or nil
    if thumpable == nil or not Doors.isThumpableDoor(thumpable) then
        LMION.error("Core", "onCreateGarage(): missing temporary IsoThumpable door")
        return nil
    end

    local garageDoor = replaceGarageThumpable(thumpable)
    if not Doors.isIsoDoor(garageDoor) then
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
