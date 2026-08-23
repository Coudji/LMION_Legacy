require "Moveables/ISMoveableSpriteProps"
require "LMION/Core"

local Pickup = LMION.Pickup
local Doors = LMION.Doors

local function getProfileForMoveProps(moveProps, sprite)
    if moveProps == nil then
        return nil
    end

    local resolvedSprite = sprite or moveProps.sprite
    if type(resolvedSprite) == "string" then
        resolvedSprite = getSprite(resolvedSprite)
    end

    local profile = resolvedSprite and Doors.getProfileForSprite(resolvedSprite) or nil
    if profile == nil or profile.pickup == nil or profile.pickup.allowed ~= true then
        return nil
    end

    return profile
end

local function applyProfileToMoveProps(moveProps, sprite)
    local profile = getProfileForMoveProps(moveProps, sprite)
    if profile == nil then
        return nil
    end

    local pickup = profile.pickup

    moveProps.name = profile.name or moveProps.name
    moveProps.type = pickup.moveType or "Object"
    moveProps.pickUpTool = pickup.pickUpTool
    moveProps.placeTool = pickup.placeTool
    moveProps.pickUpLevel = pickup.pickUpLevel or 0
    moveProps.rawWeight = pickup.pickUpWeight or moveProps.rawWeight
    moveProps.weight = moveProps.rawWeight and (moveProps.rawWeight / 10) or moveProps.weight
    moveProps.canBreak = pickup.pickUpTool ~= nil and pickup.canBreak == true

    if profile.materials ~= nil then
        moveProps.material = profile.materials.primary or moveProps.material
        moveProps.material2 = profile.materials.secondary or moveProps.material2
        moveProps.materialType = profile.materials.materialType or moveProps.materialType
    end

    moveProps.lmionDoorProfile = profile
    return profile
end

local function markDoorSpriteMoveable(sprite, profile)
    if sprite == nil or profile == nil or profile.pickup == nil or profile.pickup.allowed ~= true then
        return false
    end

    local properties = sprite:getProperties()
    if properties == nil then
        return false
    end

    properties:set("IsMoveAble")
    return true
end

local function configureKnownDoorSprites()
    local scripts = ScriptManager.instance:getAllGameEntities()
    local configured = 0

    for i = 0, scripts:size() - 1 do
        local script = scripts:get(i)
        local profile = Doors.getProfile(script:getName())

        if profile ~= nil then
            local spriteConfig = script:getComponentScriptFor(ComponentType.SpriteConfig)
            if spriteConfig ~= nil then
                local tileNames = spriteConfig:getAllTileNames()
                for j = 0, tileNames:size() - 1 do
                    local sprite = getSprite(tileNames:get(j))
                    if markDoorSpriteMoveable(sprite, profile) then
                        configured = configured + 1
                    end
                end
            end
        end
    end

    LMION.log("Pickup", "configured " .. tostring(configured) .. " LMION door sprites for Moveables")
end

Events.OnLoadedTileDefinitions.Add(configureKnownDoorSprites)

if Pickup._originalMoveableSpritePropsNew == nil then
    Pickup._originalMoveableSpritePropsNew = ISMoveableSpriteProps.new
end

ISMoveableSpriteProps.new = function(sprite)
    local moveProps = Pickup._originalMoveableSpritePropsNew(sprite)

    local resolvedSprite = sprite
    if type(resolvedSprite) == "string" then
        resolvedSprite = getSprite(resolvedSprite)
    end

    applyProfileToMoveProps(moveProps, resolvedSprite)
    return moveProps
end

if Pickup._originalMoveableInstanceItem == nil then
    Pickup._originalMoveableInstanceItem = ISMoveableSpriteProps.instanceItem
end

ISMoveableSpriteProps.instanceItem = function(self, spriteNameOverride)
    local item = Pickup._originalMoveableInstanceItem(self, spriteNameOverride)
    local profile = self and (self.lmionDoorProfile or getProfileForMoveProps(self)) or nil

    if item ~= nil and profile ~= nil and profile.name ~= nil and item.setName ~= nil then
        item:setName(profile.name)
    end

    return item
end

if Pickup._originalCanPlaceMoveableInternal == nil then
    Pickup._originalCanPlaceMoveableInternal = ISMoveableSpriteProps.canPlaceMoveableInternal
end

ISMoveableSpriteProps.canPlaceMoveableInternal = function(self, character, square, item, forceTypeObject)
    local profile = self and (self.lmionDoorProfile or getProfileForMoveProps(self)) or nil
    if profile == nil then
        return Pickup._originalCanPlaceMoveableInternal(self, character, square, item, forceTypeObject)
    end

    if square == nil or square:isVehicleIntersecting() then
        return false
    end

    local north = Doors.getNorthFromSprite(self.sprite)
    if not Doors.canPlaceDoorAt(square, north, profile.requiresFrame) then
        return false
    end

    if character ~= nil and instanceof(character, "IsoPlayer") then
        if not ISMoveableDefinitions.cheat and not character:isMovablesCheat() then
            local hasSkill = self:hasRequiredSkill(character, "place")
            local hasTool = not self.placeTool or self:hasTool(character, "place")
            if not hasSkill or not hasTool then
                return false
            end
        end
    end

    return true
end

return Pickup
