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

local function applyProfileToSprite(sprite, profile)
    if sprite == nil or profile == nil or profile.pickup == nil then
        return false
    end

    local pickup = profile.pickup
    if pickup.allowed ~= true then
        return false
    end

    local properties = sprite:getProperties()
    if properties == nil then
        return false
    end

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

    return true
end

local function configureKnownDoorSprites()
    local scripts = ScriptManager.instance:getAllGameEntities()
    local configured = 0

    for i = 0, scripts:size() - 1 do
        local script = scripts:get(i)
        local profile = Doors.getProfile(script:getName())

        if script:getModID() == "LMION_Core" and profile ~= nil then
            local spriteConfig = script:getComponentScriptFor(ComponentType.SpriteConfig)
            if spriteConfig ~= nil then
                local tileNames = spriteConfig:getAllTileNames()
                for j = 0, tileNames:size() - 1 do
                    local sprite = getSprite(tileNames:get(j))
                    if applyProfileToSprite(sprite, profile) then
                        configured = configured + 1
                    end
                end
            end
        end
    end

    LMION.log("Pickup", "configured " .. tostring(configured) .. " LMION door sprites for Moveables")
end

-- Configure the known LMION doors once the game's tile definitions exist.
-- This deliberately avoids overriding ISMoveableSpriteProps.new globally.
Events.OnLoadedTileDefinitions.Add(configureKnownDoorSprites)

if Pickup._originalCanPlaceMoveableInternal == nil then
    Pickup._originalCanPlaceMoveableInternal = ISMoveableSpriteProps.canPlaceMoveableInternal
end

ISMoveableSpriteProps.canPlaceMoveableInternal = function(self, character, square, item, forceTypeObject)
    local profile = self and self.sprite and Doors.getProfileForSprite(self.sprite) or nil
    if profile == nil or profile.pickup == nil or profile.pickup.allowed ~= true then
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
