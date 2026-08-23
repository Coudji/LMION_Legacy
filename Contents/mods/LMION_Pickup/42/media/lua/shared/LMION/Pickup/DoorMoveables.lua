require "Moveables/ISMoveableSpriteProps"
require "LMION/Pickup/DoorProfiles"

local Pickup = LMION.Pickup
local Profiles = Pickup.DoorProfiles

local knownSprites = {}
local knownSpritesReady = false

local function buildKnownSprites()
    if knownSpritesReady then
        return
    end

    knownSpritesReady = true

    local scripts = ScriptManager.instance:getAllGameEntities()
    for i = 0, scripts:size() - 1 do
        local script = scripts:get(i)
        if script:getModID() == "LMION_Core" then
            local spriteConfig = script:getComponentScriptFor(ComponentType.SpriteConfig)
            if spriteConfig ~= nil then
                local tileNames = spriteConfig:getAllTileNames()
                for j = 0, tileNames:size() - 1 do
                    knownSprites[tileNames:get(j)] = script:getName()
                end
            end
        end
    end
end

local function getKnownProfile(entityName)
    local profile = {}

    for key, value in pairs(Profiles.knownDefault) do
        profile[key] = value
    end

    local entityProfile = Profiles.entities[entityName]
    if entityProfile ~= nil then
        for key, value in pairs(entityProfile) do
            profile[key] = value
        end
    end

    return profile
end

local function setProperty(properties, name, value)
    if value ~= nil then
        properties:set(name, tostring(value))
    end
end

local function applyProfile(properties, profile, overwrite)
    if overwrite or not properties:has("IsMoveAble") then
        properties:set("IsMoveAble")
    end

    local function apply(name, value)
        if value ~= nil and (overwrite or not properties:has(name)) then
            setProperty(properties, name, value)
        end
    end

    apply("PickUpTool", profile.pickUpTool)
    apply("PlaceTool", profile.placeTool)
    apply("PickUpLevel", profile.pickUpLevel)
    apply("PickUpWeight", profile.pickUpWeight)

    if overwrite then
        if profile.canBreak then
            properties:set("CanBreak")
        else
            properties:unset("CanBreak")
        end
    elseif profile.canBreak and not properties:has("CanBreak") then
        properties:set("CanBreak")
    end
end

local function configureDoorSprite(sprite)
    if sprite == nil then
        return
    end

    local properties = sprite:getProperties()
    if properties == nil then
        return
    end

    if not properties:has(IsoFlagType.doorN) and not properties:has(IsoFlagType.doorW) then
        return
    end

    buildKnownSprites()

    local entityName = knownSprites[sprite:getName()]
    if entityName ~= nil then
        applyProfile(properties, getKnownProfile(entityName), true)
    elseif not properties:has("IsMoveAble") then
        applyProfile(properties, Profiles.unknownDefault, false)
    end
end

if Pickup._originalMoveableSpritePropsNew == nil then
    Pickup._originalMoveableSpritePropsNew = ISMoveableSpriteProps.new
end

ISMoveableSpriteProps.new = function(sprite)
    local resolvedSprite = sprite
    if type(resolvedSprite) == "string" then
        resolvedSprite = getSprite(resolvedSprite)
    end

    configureDoorSprite(resolvedSprite)

    return Pickup._originalMoveableSpritePropsNew(sprite)
end

return Pickup
