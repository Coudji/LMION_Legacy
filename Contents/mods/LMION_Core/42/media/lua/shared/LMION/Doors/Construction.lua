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

local function describeGarageObject(object)
    if object == nil then
        return "<nil>"
    end

    local representation = Doors.getDoorRepresentation(object) or tostring(object:getObjectName())
    local sprite = object.getSprite ~= nil and object:getSprite() or nil
    local spriteName = sprite ~= nil and sprite:getName() or "<nil>"
    local square = object.getSquare ~= nil and object:getSquare() or nil
    local squareText = "<nil>"
    if square ~= nil then
        squareText = tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ())
    end

    return "class=" .. tostring(representation)
        .. " sprite=" .. tostring(spriteName)
        .. " square=" .. squareText
        .. " garageIndex=" .. tostring(getGarageDoorIndex(object))
end

--[[
Garage construction is the deliberate representation exception.

The pre-refactor implementation had two safeguards:
1. SpriteConfig.OnCreate replaced the temporary IsoThumpable with an IsoDoor.
2. BuildHook rescanned the completed construction and normalized it again if the
   temporary IsoThumpable was still present.

B42.20.4 runtime testing proved that keeping only the first safeguard is not
sufficient: a completed garage can still remain an IsoThumpable. Keep the
replacement primitive in Core and let Build call initializeConstructedDoor after
construction as the second, authoritative finalization pass.

Do not generalize this conversion to 1x1 doors or DoubleDoor large gates.
]]
local function replaceGarageThumpable(thumpable)
    if not Doors.isThumpableDoor(thumpable) or getGarageDoorIndex(thumpable) == nil then
        return thumpable
    end

    local square = thumpable:getSquare()
    local sprite = thumpable:getSprite()
    if square == nil or sprite == nil then
        LMION.error("Core", "replaceGarageThumpable(): incomplete temporary garage object")
        return nil
    end

    local state = Doors.captureDoorState(thumpable)
    local garageDoor = IsoDoor.new(getCell(), square, sprite, thumpable:getNorth())

    if thumpable.getName ~= nil and garageDoor.setName ~= nil then
        garageDoor:setName(thumpable:getName())
    end

    if state ~= nil then
        Doors.restoreDoorState(garageDoor, state)
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
Construction normally owns gameplay values, not the Java representation chosen by
the engine. Vanilla GameEntity construction may produce an IsoThumpable door; keep
it as-is and initialize only the state LMION_Build explicitly decided.

Garage doors are the exception above: if the completed object is still an
IsoThumpable garage member, finalize it as IsoDoor before applying Build-owned
state. The returned value is always the final world object so callers do not keep
a stale reference after replacement.
]]
function Doors.initializeConstructedDoor(params)
    local object = params and params.object or nil
    if not Doors.isDoorObject(object) then
        return nil
    end

    if Doors.isThumpableDoor(object) and getGarageDoorIndex(object) ~= nil then
        object = replaceGarageThumpable(object)
        if not Doors.isDoorObject(object) then
            return nil
        end
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
First-chance garage replacement used by the seven SpriteConfig OnCreate hooks.
BuildHook still performs the historical post-build finalization pass because the
callback alone is not yet proven reliable enough to guarantee the final
representation. Temporary instrumentation below will tell us whether this callback
actually survives into the completed world object on B42.20.4.
]]
function Doors.onCreateGarage(params)
    local thumpable = params and params.thumpable or nil
    LMION.log("Core", "GARAGE TRACE OnCreate enter: " .. describeGarageObject(thumpable))

    if thumpable == nil or not Doors.isThumpableDoor(thumpable) then
        LMION.error("Core", "onCreateGarage(): missing temporary IsoThumpable door")
        return nil
    end

    local garageDoor = replaceGarageThumpable(thumpable)
    LMION.log("Core", "GARAGE TRACE OnCreate replacement: " .. describeGarageObject(garageDoor))

    if not Doors.isIsoDoor(garageDoor) then
        return nil
    end

    garageDoor = Doors.initializeConstructedDoor({
        object = garageDoor,
        effectiveMaxHealth = params and params.effectiveMaxHealth or nil,
    })

    LMION.log("Core", "GARAGE TRACE OnCreate return: " .. describeGarageObject(garageDoor))

    return {
        replaceObject = true,
        object = garageDoor,
    }
end

return Doors
