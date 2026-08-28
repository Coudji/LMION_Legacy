local Doors = LMION.Doors

function Doors.getHealth(object)
    if not Doors.isDoorObject(object) or object.getHealth == nil then
        return nil
    end

    return tonumber(object:getHealth())
end

function Doors.setHealth(object, value)
    if not Doors.isDoorObject(object) or object.setHealth == nil then
        return nil
    end

    local health = tonumber(value)
    if health == nil then
        return nil
    end

    health = math.max(0, math.floor(health))
    object:setHealth(health)
    return health
end

function Doors.getConstructionMaxHealth(profile, craftRecipe, character)
    local durability = profile and profile.durability or nil
    if durability == nil then
        return nil
    end

    local baseHealth = tonumber(durability.health)
    local skillBaseHealth = tonumber(durability.skillBaseHealth) or 0
    if baseHealth == nil then
        return nil
    end

    local skillLevel = 0
    if skillBaseHealth ~= 0
        and craftRecipe ~= nil
        and character ~= nil
        and craftRecipe.getHighestRelevantSkillLevel ~= nil then
        skillLevel = tonumber(craftRecipe:getHighestRelevantSkillLevel(character)) or 0
    end

    return math.max(0, math.floor(baseHealth + skillBaseHealth * skillLevel))
end

function Doors.clearEffectiveMaxHealthOverride(object)
    if object == nil or object.getModData == nil then
        return false
    end

    local modData = object:getModData()
    if modData == nil then
        return false
    end

    modData[Doors.MaxHealthModDataKey] = nil
    return true
end

function Doors.setEffectiveMaxHealth(object, value)
    if not Doors.isDoorObject(object) then
        return nil
    end

    local maxHealth = tonumber(value)
    if maxHealth == nil then
        return nil
    end

    maxHealth = math.max(0, math.floor(maxHealth))

    if Doors.isThumpableDoor(object) and object.setMaxHealth ~= nil then
        object:setMaxHealth(maxHealth)
        Doors.clearEffectiveMaxHealthOverride(object)
        return maxHealth
    end

    if object.getModData ~= nil then
        object:getModData()[Doors.MaxHealthModDataKey] = maxHealth
        return maxHealth
    end

    return nil
end

function Doors.getEffectiveMaxHealth(object)
    if not Doors.isDoorObject(object) then
        return nil
    end

    if object.getModData ~= nil then
        local modData = object:getModData()
        local logicalMax = modData and tonumber(modData[Doors.MaxHealthModDataKey]) or nil
        if logicalMax ~= nil then
            return logicalMax
        end
    end

    if object.getMaxHealth ~= nil then
        return tonumber(object:getMaxHealth())
    end

    return nil
end

function Doors.repairHealth(object, amount)
    local currentHealth = Doors.getHealth(object)
    local maxHealth = Doors.getEffectiveMaxHealth(object)
    local repairAmount = tonumber(amount)

    if currentHealth == nil or maxHealth == nil or repairAmount == nil or repairAmount <= 0 then
        return currentHealth, 0
    end

    repairAmount = math.floor(repairAmount)
    if currentHealth >= maxHealth then
        return currentHealth, 0
    end

    local newHealth = math.min(maxHealth, currentHealth + repairAmount)
    Doors.setHealth(object, newHealth)
    return newHealth, newHealth - currentHealth
end

return Doors
