LMION.Doors = LMION.Doors or {}
local Doors = LMION.Doors

Doors.Profiles = Doors.Profiles or {}
Doors.MaxHealthModDataKey = "lmionDoorMaxHealth"
Doors.Profiles.MahoganyPanelDoor = {
    id = "MahoganyPanelDoor",
    nameKey = "EC_LMION_MahoganyPanelDoor",
    fallbackName = "Mahogany Panel Door",
    requiresFrame = true,

    materials = {
        primary = "Door",
        secondary = "MetalPlates",
        materialType = "Wood_Solid",
    },

    pickup = {
        allowed = true,
        itemType = "Base.LMION_MahoganyPanelDoor",
        moveType = "Object",
        pickUpTool = "Hammer",
        placeTool = "Hammer",
        pickUpLevel = 2,
        pickUpWeight = 200,
        canBreak = false,
    },
}

Doors.Profiles.BlueServiceDoor = {
    id = "BlueServiceDoor",
    durability = {
        worldMaxHealth = 600,
    },
}

local spriteProfiles = nil

local function buildSpriteProfiles()
    if spriteProfiles ~= nil then
        return
    end

    spriteProfiles = {}

    local scripts = ScriptManager.instance:getAllGameEntities()
    for i = 0, scripts:size() - 1 do
        local script = scripts:get(i)
        local profile = Doors.Profiles[script:getName()]

        if profile ~= nil then
            local spriteConfig = script:getComponentScriptFor(ComponentType.SpriteConfig)
            if spriteConfig ~= nil then
                local tileNames = spriteConfig:getAllTileNames()
                for j = 0, tileNames:size() - 1 do
                    spriteProfiles[tileNames:get(j)] = profile
                end
            end
        end
    end
end

local function setAliasedProperty(properties, name, value)
    if properties == nil or value == nil then
        return true
    end

    local expected = tostring(value)
    local hadValue = properties:has(name)
    local previous = hadValue and properties:get(name) or nil

    properties:set(name, expected)

    if properties:has(name) and properties:get(name) == expected then
        return true
    end

    if hadValue and previous ~= nil then
        properties:set(name, previous)
    else
        properties:unset(name)
    end

    return false
end

local function applyEngineProfileToSprite(sprite, profile)
    if sprite == nil or profile == nil or profile.materials == nil then
        return false
    end

    local properties = sprite:getProperties()
    if properties == nil then
        return false
    end

    local materials = profile.materials
    local ok = true

    if materials.primary ~= nil then
        ok = setAliasedProperty(properties, "Material", materials.primary) and ok
    end

    if materials.secondary ~= nil then
        ok = setAliasedProperty(properties, "Material2", materials.secondary) and ok
    end

    if materials.tertiary ~= nil then
        ok = setAliasedProperty(properties, "Material3", materials.tertiary) and ok
    end

    if materials.materialType ~= nil then
        ok = setAliasedProperty(properties, "MaterialType", materials.materialType) and ok
    end

    return ok
end

function Doors.applyEngineProfiles()
    if ScriptManager == nil or ScriptManager.instance == nil or getSprite == nil then
        return 0, 0
    end

    local scripts = ScriptManager.instance:getAllGameEntities()
    local applied = 0
    local rejected = 0

    for i = 0, scripts:size() - 1 do
        local script = scripts:get(i)
        local profile = Doors.Profiles[script:getName()]

        if profile ~= nil and profile.materials ~= nil then
            local spriteConfig = script:getComponentScriptFor(ComponentType.SpriteConfig)
            if spriteConfig ~= nil then
                local tileNames = spriteConfig:getAllTileNames()
                for j = 0, tileNames:size() - 1 do
                    local sprite = getSprite(tileNames:get(j))
                    if sprite ~= nil then
                        if applyEngineProfileToSprite(sprite, profile) then
                            applied = applied + 1
                        else
                            rejected = rejected + 1
                        end
                    end
                end
            end
        end
    end

    if LMION.log ~= nil then
        LMION.log("Core", "engine profiles applied=" .. tostring(applied) .. ", rejected=" .. tostring(rejected))
    end

    return applied, rejected
end

function Doors.getProfile(entityName)
    return entityName and Doors.Profiles[entityName] or nil
end

function Doors.getDisplayName(profile)
    if profile == nil then
        return nil
    end

    if profile.nameKey ~= nil then
        local translated = getText(profile.nameKey)
        if translated ~= nil and translated ~= profile.nameKey then
            return translated
        end
    end

    return profile.fallbackName or profile.id
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

function Doors.getProfileForSprite(sprite)
    if sprite == nil then
        return nil
    end

    if type(sprite) == "string" then
        sprite = getSprite(sprite)
    end

    if sprite == nil or sprite:getName() == nil then
        return nil
    end

    buildSpriteProfiles()
    return spriteProfiles[sprite:getName()]
end

function Doors.adoptWorldDoor(object)
    if object == nil or instanceof(object, "IsoDoor") == false then
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

    local currentHealth = object:getHealth()
    local engineMaxHealth = object:getMaxHealth()

    Doors.setEffectiveMaxHealth(object, worldMaxHealth)

    if currentHealth == engineMaxHealth then
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

function Doors.getNorthFromSprite(sprite)
    if sprite == nil then
        return nil
    end

    if type(sprite) == "string" then
        sprite = getSprite(sprite)
    end

    local properties = sprite and sprite:getProperties() or nil
    if properties == nil then
        return nil
    end

    if properties:has(IsoFlagType.doorN) then
        return true
    end

    if properties:has(IsoFlagType.doorW) then
        return false
    end

    return nil
end

function Doors.canPlaceDoorAt(square, north, requiresFrame)
    if square == nil or north == nil then
        return false
    end

    local hasFrame = false
    local hasDoor = false

    local specialObjects = square:getSpecialObjects()
    for i = 0, specialObjects:size() - 1 do
        local object = specialObjects:get(i)

        if instanceof(object, "IsoThumpable") then
            if object:isDoorFrame() and object:getNorth() == north then
                hasFrame = true
            end
            if object:isDoor() and object:getNorth() == north then
                hasDoor = true
            end
        end
    end

    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)

        if instanceof(object, "IsoObject") then
            if north and object:getType() == IsoObjectType.doorFrN then
                hasFrame = true
            elseif not north and object:getType() == IsoObjectType.doorFrW then
                hasFrame = true
            end

            local sprite = object:getSprite()
            local properties = sprite and sprite:getProperties() or nil
            if properties ~= nil then
                if north and properties:has("DoorWallN") then
                    hasFrame = true
                elseif not north and properties:has("DoorWallW") then
                    hasFrame = true
                end
            end
        end

        if instanceof(object, "IsoDoor") and object:getNorth() == north then
            hasDoor = true
        end
    end

    if requiresFrame == false then
        return not hasDoor
    end

    return hasFrame and not hasDoor
end

function Doors.onCreateDoor(params)
    local thumpable = params and params.thumpable or nil
    if thumpable == nil then
        return nil
    end

    local square = thumpable:getSquare()
    local profile = Doors.getProfileForSprite(thumpable:getSprite())
    local maxHealth = thumpable:getMaxHealth()
    local door = IsoDoor.new(
        getCell(),
        square,
        thumpable:getSprite(),
        thumpable:getNorth()
    )

    door:setName(profile and (profile.fallbackName or profile.id) or thumpable:getName())
    door:setModData(copyTable(thumpable:getModData()))
    Doors.setEffectiveMaxHealth(door, maxHealth)
    door:setKeyId(thumpable:getKeyId())
    door:setIsLocked(false)
    door:setLockedByKey(false)
    door:setHealth(thumpable:getHealth())

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

if Events ~= nil and Events.OnLoadedTileDefinitions ~= nil then
    Events.OnLoadedTileDefinitions.Add(Doors.applyEngineProfiles)
end

if Events ~= nil and Events.LoadGridsquare ~= nil then
    Events.LoadGridsquare.Add(Doors.adoptWorldDoorsOnSquare)
end

Doors.applyEngineProfiles()

return Doors
