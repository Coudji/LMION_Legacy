local Doors = LMION.Doors

--[[
Construction recipes create IsoThumpable objects first. LMION normalizes completed
door recipes into IsoDoor while preserving modData, key identity and logical max.
]]
function Doors.onCreateDoor(params)
    local thumpable = params and params.thumpable or nil
    if thumpable == nil then
        return nil
    end

    local square = thumpable:getSquare()
    local profile = Doors.getProfileForSprite(thumpable:getSprite())
    local effectiveMaxHealth = params and tonumber(params.effectiveMaxHealth) or nil

    if effectiveMaxHealth == nil
        and Doors.BuildContext ~= nil
        and Doors.BuildContext.profile == profile then
        effectiveMaxHealth = tonumber(Doors.BuildContext.effectiveMaxHealth)
    end

    if effectiveMaxHealth == nil then
        effectiveMaxHealth = thumpable:getMaxHealth()
    end

    local door = IsoDoor.new(
        getCell(),
        square,
        thumpable:getSprite(),
        thumpable:getNorth()
    )

    door:setName(profile and Doors.getDisplayName(profile) or thumpable:getName())
    door:setModData(copyTable(thumpable:getModData()))
    Doors.setEffectiveMaxHealth(door, effectiveMaxHealth)
    door:setKeyId(thumpable:getKeyId())
    door:setIsLocked(false)
    door:setLockedByKey(false)

    if effectiveMaxHealth ~= nil then
        door:setHealth(effectiveMaxHealth)
    else
        door:setHealth(thumpable:getHealth())
    end

    if GameEntityFactory ~= nil then
        local properties = door:getProperties()
        if properties ~= nil and properties:has(IsoFlagType.EntityScript) then
            GameEntityFactory.CreateIsoEntityFromCellLoading(door)
        end
    end

    square:AddSpecialObject(door)
    square:transmitRemoveItemFromSquare(thumpable)

    return {
        replaceObject = true,
        object = door,
    }
end

Doors.onCreateGarage = Doors.onCreateDoor

return Doors
