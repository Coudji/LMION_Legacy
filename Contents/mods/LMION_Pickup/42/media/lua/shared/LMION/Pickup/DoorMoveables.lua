require "Moveables/ISMoveableSpriteProps"
require "LMION/Core"

local Pickup = LMION.Pickup
local Doors = LMION.Doors

local function setProperty(properties, name, value)
    if value ~= nil then
        properties:set(name, tostring(value))
    end
end

local function applyBoolean(properties, name, value)
    if value == true then
        properties:set(name)
    elseif value == false then
        properties:unset(name)
    end
end

local function configureDoorSprite(sprite)
    if sprite == nil then
        return nil
    end

    local properties = sprite:getProperties()
    if properties == nil then
        return nil
    end

    if not properties:has(IsoFlagType.doorN) and not properties:has(IsoFlagType.doorW) then
        return nil
    end

    local profile = Doors.getProfileForSprite(sprite)
    if profile == nil or profile.pickup == nil or profile.pickup.allowed ~= true then
        return nil
    end

    local pickup = profile.pickup

    properties:set("IsMoveAble")
    setProperty(properties, "MoveType", pickup.moveType or "Object")
    setProperty(properties, "CustomName", profile.name)
    setProperty(properties, "PickUpTool", pickup.pickUpTool)
    setProperty(properties, "PlaceTool", pickup.placeTool)
    setProperty(properties, "PickUpLevel", pickup.pickUpLevel)
    setProperty(properties, "PickUpWeight", pickup.pickUpWeight)
    applyBoolean(properties, "CanBreak", pickup.canBreak)

    if profile.materials ~= nil then
        setProperty(properties, "Material", profile.materials.primary)
        setProperty(properties, "Material2", profile.materials.secondary)
        setProperty(properties, "MaterialType", profile.materials.materialType)
    end

    return profile
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

    local props = Pickup._originalMoveableSpritePropsNew(sprite)
    if props ~= nil and resolvedSprite ~= nil then
        props.lmionDoorProfile = Doors.getProfileForSprite(resolvedSprite)
    end

    return props
end

if Pickup._originalCanPlaceMoveableInternal == nil then
    Pickup._originalCanPlaceMoveableInternal = ISMoveableSpriteProps.canPlaceMoveableInternal
end

ISMoveableSpriteProps.canPlaceMoveableInternal = function(self, character, square, item, forceTypeObject)
    local profile = self and self.lmionDoorProfile or nil
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
