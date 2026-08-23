LMION.Doors = LMION.Doors or {}
local Doors = LMION.Doors

Doors.Profiles = Doors.Profiles or {}
Doors.Profiles.CherryDoor = Doors.Profiles.CherryDoor or {
    id = "CherryDoor",
    name = "Cherry Door",
    requiresFrame = true,

    materials = {
        primary = "Door",
        secondary = "Wood",
        materialType = "Wood_Solid",
    },

    pickup = {
        allowed = true,
        moveType = "Object",
        pickUpTool = "Hammer",
        placeTool = "Hammer",
        pickUpLevel = 2,
        pickUpWeight = 200,
        canBreak = false,
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

function Doors.getProfile(entityName)
    return entityName and Doors.Profiles[entityName] or nil
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
    local door = IsoDoor.new(
        getCell(),
        square,
        thumpable:getSprite(),
        thumpable:getNorth()
    )

    door:setName(profile and profile.name or thumpable:getName())
    door:setModData(copyTable(thumpable:getModData()))
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

return Doors
