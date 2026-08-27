require "LMION/Core"
require "LMION/Pickup/DoorProfiles"

local Pickup = LMION.Pickup
local Profiles = Pickup.DoorProfiles
local DoorMoveables = Pickup.DoorMoveables or {}
Pickup.DoorMoveables = DoorMoveables

local spriteProfiles = nil

--[[
This registry translates GameEntity SpriteConfig ownership into the Pickup profile
used by vanilla Moveables. It is rebuilt after tile definitions because runtime
sprites and SpriteConfig object info are not stable before that lifecycle point.
]]
local function findObjectInfo(spriteConfig)
    if spriteConfig == nil or SpriteConfigManager == nil or SpriteConfigManager.GetObjectInfoList == nil then
        return nil
    end

    local objectInfos = SpriteConfigManager.GetObjectInfoList()
    if objectInfos == nil then
        return nil
    end

    for i = 0, objectInfos:size() - 1 do
        local info = objectInfos:get(i)
        if info ~= nil and info:getScript() == spriteConfig then
            return info
        end
    end

    return nil
end

local function getSingleFaceSprite(objectInfo, faceName)
    if objectInfo == nil then
        return nil
    end

    local face = objectInfo:getFace(faceName)
    if face == nil
        or face:getWidth() ~= 1
        or face:getHeight() ~= 1
        or face:getzLayers() ~= 1 then
        return nil
    end

    local tileInfo = face:getTileInfo(0, 0, 0)
    if tileInfo == nil or tileInfo:getSpriteName() == nil then
        return nil
    end

    return tostring(tileInfo:getSpriteName())
end

local function buildSpriteProfiles()
    if spriteProfiles ~= nil then
        return
    end

    spriteProfiles = {}

    local scripts = ScriptManager.instance:getAllGameEntities()
    for i = 0, scripts:size() - 1 do
        local script = scripts:get(i)
        local profile = Profiles.entities[script:getName()]

        if profile ~= nil then
            local spriteConfig = script:getComponentScriptFor(ComponentType.SpriteConfig)
            if spriteConfig ~= nil then
                local objectInfo = findObjectInfo(spriteConfig)
                local northSprite = getSingleFaceSprite(objectInfo, "n")
                local westSprite = getSingleFaceSprite(objectInfo, "w")

                if northSprite ~= nil and westSprite ~= nil and northSprite ~= westSprite then
                    profile.moveFaces = {
                        N = northSprite,
                        W = westSprite,
                    }
                else
                    profile.moveFaces = nil
                end

                local tileNames = spriteConfig:getAllTileNames()
                for j = 0, tileNames:size() - 1 do
                    spriteProfiles[tileNames:get(j)] = profile
                end
            end
        end
    end
end

function DoorMoveables.getProfileForSprite(sprite)
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

function DoorMoveables.getProfileForMoveProps(moveProps, sprite)
    if moveProps == nil then
        return nil
    end

    return DoorMoveables.getProfileForSprite(sprite or moveProps.sprite)
end

local function getProfileDisplayName(profile)
    if profile == nil or profile.itemType == nil then
        return profile and profile.id or nil
    end

    local scriptItem = ScriptManager.instance:FindItem(profile.itemType)
    if scriptItem ~= nil then
        return scriptItem:getDisplayName()
    end

    return profile.id
end

function DoorMoveables.applyProfileToMoveProps(moveProps, sprite)
    local profile = DoorMoveables.getProfileForMoveProps(moveProps, sprite)
    if profile == nil then
        return nil
    end

    moveProps.name = getProfileDisplayName(profile) or moveProps.name
    moveProps.customItem = profile.itemType or moveProps.customItem
    moveProps.type = profile.moveType or "Object"
    moveProps.pickUpTool = profile.pickUpTool
    moveProps.placeTool = profile.placeTool
    moveProps.pickUpLevel = profile.pickUpLevel or 0
    moveProps.rawWeight = profile.pickUpWeight or moveProps.rawWeight
    moveProps.weight = moveProps.rawWeight and (moveProps.rawWeight / 10) or moveProps.weight
    moveProps.canBreak = profile.pickUpTool ~= nil and profile.canBreak == true
    moveProps.lmionDoorProfile = profile
    moveProps.lmionDoorFaces = profile.moveFaces
    moveProps.lmionDoorFacing = nil

    local resolvedSprite = sprite or moveProps.sprite
    if type(resolvedSprite) == "string" then
        resolvedSprite = getSprite(resolvedSprite)
    end

    local spriteName = resolvedSprite and resolvedSprite:getName() or nil
    if profile.moveFaces ~= nil and spriteName ~= nil then
        if spriteName == profile.moveFaces.N then
            moveProps.lmionDoorFacing = "N"
        elseif spriteName == profile.moveFaces.W then
            moveProps.lmionDoorFacing = "W"
        else
            -- Open SpriteConfig faces are also owned by the same profile. Their
            -- sprite name is not one of the canonical closed Moveables faces, so
            -- recover orientation from the engine door flags and canonicalize
            -- them later during inventory serialization / placement.
            local north = LMION.Doors.getNorthFromSprite(resolvedSprite)
            if north == true then
                moveProps.lmionDoorFacing = "N"
            elseif north == false then
                moveProps.lmionDoorFacing = "W"
            end
        end

        if moveProps.lmionDoorFacing ~= nil then
            moveProps.facing = moveProps.lmionDoorFacing
        end
    end

    return profile
end

local function markDoorSpriteMoveable(sprite)
    if sprite == nil then
        return false
    end

    local properties = sprite:getProperties()
    if properties == nil then
        return false
    end

    properties:set("IsMoveAble")
    return true
end

function DoorMoveables.configureKnownDoorSprites()
    spriteProfiles = nil
    buildSpriteProfiles()

    local configured = 0
    for spriteName, _ in pairs(spriteProfiles) do
        local sprite = getSprite(spriteName)
        if markDoorSpriteMoveable(sprite) then
            configured = configured + 1
        end
    end

    LMION.log("Pickup", "configured " .. tostring(configured) .. " framed 1x1 door sprites for Moveables")
end

function DoorMoveables.findPlacedDoor(square, spriteName)
    if square == nil or spriteName == nil then
        return nil
    end

    local objects = square:getSpecialObjects()
    for i = objects:size() - 1, 0, -1 do
        local object = objects:get(i)
        local sprite = object and object:getSprite() or nil
        if instanceof(object, "IsoDoor")
            and sprite ~= nil
            and sprite:getName() == spriteName then
            return object
        end
    end

    return nil
end

if Pickup._doorMoveablesConfigureHandler ~= nil then
    Events.OnLoadedTileDefinitions.Remove(Pickup._doorMoveablesConfigureHandler)
end

Pickup._doorMoveablesConfigureHandler = DoorMoveables.configureKnownDoorSprites
Events.OnLoadedTileDefinitions.Add(Pickup._doorMoveablesConfigureHandler)

return DoorMoveables
