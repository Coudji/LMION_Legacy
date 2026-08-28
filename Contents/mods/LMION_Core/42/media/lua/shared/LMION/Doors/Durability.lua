local Doors = LMION.Doors

--[[
Project Zomboid represents passable door mechanics with more than one concrete
world class. Map-authored/opening-normalized doors are commonly IsoDoor, while
vanilla GameEntity construction can leave a valid door as IsoThumpable.

Shared Core gameplay must therefore reason about the door capability, not only
one Java class. Keep this predicate intentionally narrow: an IsoThumpable counts
only when the engine itself marks it as a door.
]]
function Doors.isDoorObject(object)
    if object == nil then
        return false
    end

    if instanceof(object, "IsoDoor") then
        return true
    end

    return instanceof(object, "IsoThumpable")
        and object.isDoor ~= nil
        and object:isDoor()
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

function Doors.setEffectiveMaxHealth(object, value)
    if object == nil or object.getModData == nil then
        return nil
    end

    local maxHealth = tonumber(value)
    if maxHealth == nil then
        return nil
    end

    maxHealth = math.max(0, math.floor(maxHealth))
    object:getModData()[Doors.MaxHealthModDataKey] = maxHealth

    -- IsoDoor has no mutable engine max-health API in B42.20.3, which is why
    -- LMION keeps modData authoritative. IsoThumpable does expose setMaxHealth;
    -- mirror the same value when available so vanilla damage/condition queries
    -- remain coherent instead of reporting e.g. 850 current / 0 engine max.
    if object.setMaxHealth ~= nil then
        object:setMaxHealth(maxHealth)
    end

    return maxHealth
end

function Doors.getEffectiveMaxHealth(object)
    if object == nil then
        return nil
    end

    if object.getModData ~= nil then
        local modData = object:getModData()
        local maxHealth = modData and tonumber(modData[Doors.MaxHealthModDataKey]) or nil
        if maxHealth ~= nil then
            return maxHealth
        end
    end

    if object.getMaxHealth ~= nil then
        return object:getMaxHealth()
    end

    return nil
end

function Doors.repairHealth(object, amount)
    if object == nil or object.getHealth == nil or object.setHealth == nil then
        return nil, 0
    end

    local maxHealth = Doors.getEffectiveMaxHealth(object)
    local repairAmount = tonumber(amount)
    if maxHealth == nil or repairAmount == nil or repairAmount <= 0 then
        return object:getHealth(), 0
    end

    repairAmount = math.floor(repairAmount)
    local currentHealth = object:getHealth()
    if currentHealth >= maxHealth then
        return currentHealth, 0
    end

    local newHealth = math.min(maxHealth, currentHealth + repairAmount)
    object:setHealth(newHealth)
    return newHealth, newHealth - currentHealth
end

function Doors.adoptWorldDoor(object)
    if not Doors.isDoorObject(object) then
        return false
    end

    local profile = Doors.getProfileForSprite(object:getSprite())
    local durability = profile and profile.durability or nil
    local worldMaxHealth = durability and tonumber(durability.worldMaxHealth) or nil
    if worldMaxHealth == nil or worldMaxHealth <= 0 then
        return false
    end

    local modData = object:getModData()
    if modData ~= nil and tonumber(modData[Doors.MaxHealthModDataKey]) ~= nil then
        return false
    end

    local currentHealth = tonumber(object:getHealth())
    local engineMaxHealth = tonumber(object:getMaxHealth())
    local wasIntact = currentHealth ~= nil
        and engineMaxHealth ~= nil
        and currentHealth == engineMaxHealth

    Doors.setEffectiveMaxHealth(object, worldMaxHealth)

    -- Preserve exact damage on already-damaged objects. Fresh vanilla multi-tile
    -- construction can produce valid edge members at 0/0; current==max still
    -- means "intact" there, so adoption initializes those members correctly.
    if wasIntact then
        object:setHealth(worldMaxHealth)
    end

    return true
end

function Doors.adoptWorldDoorsOnSquare(square)
    if square == nil then
        return 0
    end

    local adopted = 0
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        if Doors.adoptWorldDoor(objects:get(i)) then
            adopted = adopted + 1
        end
    end

    return adopted
end

return Doors
