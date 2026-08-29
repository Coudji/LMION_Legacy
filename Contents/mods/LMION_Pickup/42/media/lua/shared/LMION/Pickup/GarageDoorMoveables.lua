require "Moveables/ISMoveableSpriteProps"
require "LMION/Pickup/GarageDoorRuntime"

local Pickup = LMION.Pickup
local Doors = LMION.Doors
local GarageDoor = Pickup.GarageDoor
local segmentsBySprite = GarageDoor.SegmentsBySprite

local function getSegment(sprite)
    if sprite == nil then
        return nil
    end

    local spriteName = sprite
    if type(sprite) ~= "string" then
        spriteName = sprite:getName()
    end

    return spriteName and segmentsBySprite[spriteName] or nil
end

local function setMovePropsIdentity(moveProps, segment)
    if moveProps == nil or segment == nil then
        return
    end

    local family = segment.family
    moveProps.name = family.id
    moveProps.customItem = segment.itemType
    moveProps.type = "Object"
    moveProps.pickUpTool = family.pickUpTool
    moveProps.placeTool = family.placeTool
    moveProps.pickUpLevel = family.pickUpLevel or 0
    moveProps.rawWeight = family.partWeight * 10
    moveProps.weight = family.partWeight
    moveProps.canBreak = false
    moveProps.lmionGarageFamily = segment.familyId
    moveProps.lmionGaragePart = segment.partIndex
    moveProps.lmionGarageFaces = segment.rotationFaces or segment.faces
    moveProps.lmionGarageFacing = segment.facing
    moveProps.lmionGarageIsOpen = segment.isOpen == true
    moveProps.lmionGarageClosedSprite = segment.closedSpriteName
    moveProps.facing = segment.facing

    local scriptItem = ScriptManager.instance:FindItem(segment.itemType)
    if scriptItem ~= nil then
        moveProps.name = scriptItem:getDisplayName()
    end
end

-- Vanilla rebuilds ISMoveableSpriteProps several times while entering Place mode
-- (inventory sprite -> SpriteGrid anchor -> rotated face). Normally our new()
-- wrapper below re-applies LMION identity every time, but cursor/gameplay code must
-- not depend on that load-order detail. A known garage sprite is sufficient to
-- restore its semantic family/role/facing on demand.
function GarageDoor.ensureMovePropsIdentity(moveProps)
    if moveProps == nil then
        return nil
    end

    local segment = getSegment(moveProps.sprite or moveProps.spriteName)
    if segment ~= nil then
        setMovePropsIdentity(moveProps, segment)
    end
    return segment
end

local function markKnownSpritesMoveable()
    local configured = 0
    local rejectedFamilies = 0

    for _, family in pairs(GarageDoor.Families) do
        local valid = true
        local reason = nil
        if GarageDoor.validateFamily ~= nil then
            valid, reason = GarageDoor.validateFamily(family)
        end

        if valid then
            for partIndex = 1, 3 do
                local part = family.parts[partIndex]
                for _, facing in ipairs({"N", "W"}) do
                    for _, spriteName in ipairs({part.faces[facing], part.openFaces[facing]}) do
                        local sprite = spriteName and getSprite(spriteName) or nil
                        local properties = sprite and sprite:getProperties() or nil
                        if properties ~= nil then
                            properties:set("IsMoveAble")
                            configured = configured + 1
                        end
                    end
                end
            end
        else
            rejectedFamilies = rejectedFamilies + 1
            LMION.error(
                "Pickup",
                "garage door family " .. tostring(family.id) .. " is not Moveables-safe: " .. tostring(reason)
            )
        end
    end

    LMION.log("Pickup", "configured " .. tostring(configured) .. " garage door sprites for Moveables")
    if rejectedFamilies > 0 then
        LMION.error("Pickup", tostring(rejectedFamilies) .. " garage door families rejected by sprite-index validation")
    end
end

if Pickup._garageDoorPreviousNew == nil then
    Pickup._garageDoorPreviousNew = ISMoveableSpriteProps.new
end

ISMoveableSpriteProps.new = function(sprite)
    local moveProps = Pickup._garageDoorPreviousNew(sprite)
    local resolved = sprite
    if type(resolved) == "string" then
        resolved = getSprite(resolved)
    end

    local segment = getSegment(resolved)
    if segment ~= nil then
        setMovePropsIdentity(moveProps, segment)
    end

    return moveProps
end

if Pickup._garageDoorPreviousHasFaces == nil then
    Pickup._garageDoorPreviousHasFaces = ISMoveableSpriteProps.hasFaces
end

ISMoveableSpriteProps.hasFaces = function(self)
    GarageDoor.ensureMovePropsIdentity(self)
    if self ~= nil and self.lmionGarageFaces ~= nil then
        return self.lmionGarageFaces.N ~= nil
            and self.lmionGarageFaces.W ~= nil
            and self.lmionGarageFaces.N ~= self.lmionGarageFaces.W
    end

    return Pickup._garageDoorPreviousHasFaces(self)
end

if Pickup._garageDoorPreviousGetFaces == nil then
    Pickup._garageDoorPreviousGetFaces = ISMoveableSpriteProps.getFaces
end

ISMoveableSpriteProps.getFaces = function(self)
    GarageDoor.ensureMovePropsIdentity(self)
    if self ~= nil and self.lmionGarageFaces ~= nil then
        return {
            N = self.lmionGarageFaces.N,
            W = self.lmionGarageFaces.W,
        }
    end

    return Pickup._garageDoorPreviousGetFaces(self)
end

if Pickup._garageDoorPreviousGetIndexedFaces == nil then
    Pickup._garageDoorPreviousGetIndexedFaces = ISMoveableSpriteProps.getIndexedFaces
end

ISMoveableSpriteProps.getIndexedFaces = function(self)
    GarageDoor.ensureMovePropsIdentity(self)
    if self ~= nil and self.lmionGarageFaces ~= nil then
        local faces = self:getFaces()
        return {faces.N, faces.W, faces.N, faces.W}
    end

    return Pickup._garageDoorPreviousGetIndexedFaces(self)
end

if Pickup._garageDoorPreviousInstanceItem == nil then
    Pickup._garageDoorPreviousInstanceItem = ISMoveableSpriteProps.instanceItem
end

ISMoveableSpriteProps.instanceItem = function(self, spriteNameOverride)
    GarageDoor.ensureMovePropsIdentity(self)
    if self == nil or self.lmionGarageFamily == nil then
        return Pickup._garageDoorPreviousInstanceItem(self, spriteNameOverride)
    end

    local segment = getSegment(spriteNameOverride or self.sprite)
    if segment == nil or segment.familyId ~= self.lmionGarageFamily then
        return Pickup._garageDoorPreviousInstanceItem(self, spriteNameOverride)
    end

    local canonicalSpriteName = segment.closedSpriteName or spriteNameOverride or self.spriteName
    local previousCustomItem = self.customItem
    self.customItem = segment.itemType
    local item = Pickup._garageDoorPreviousInstanceItem(self, canonicalSpriteName)
    self.customItem = previousCustomItem

    if item ~= nil then
        local modData = item:getModData()
        modData.lmionGarageFamily = segment.familyId
        modData.lmionGaragePart = segment.partIndex

        if self.lmionGaragePendingHealth ~= nil then
            modData.lmionDoorHealth = self.lmionGaragePendingHealth
        end
        if self.lmionGaragePendingMaxHealth ~= nil then
            modData.lmionDoorMaxHealth = self.lmionGaragePendingMaxHealth
        end
    end

    return item
end

if Pickup._garageDoorPreviousFindInInventoryMultiSprite == nil then
    Pickup._garageDoorPreviousFindInInventoryMultiSprite = ISMoveableSpriteProps.findInInventoryMultiSprite
end

ISMoveableSpriteProps.findInInventoryMultiSprite = function(self, character, requestedName)
    GarageDoor.ensureMovePropsIdentity(self)
    if self == nil or self.lmionGarageFamily == nil then
        return Pickup._garageDoorPreviousFindInInventoryMultiSprite(self, character, requestedName)
    end

    local gridIndex = tonumber(string.match(requestedName or "", "%((%d+)/3%)$"))
    local family = GarageDoor.Families[self.lmionGarageFamily]

    local partIndex = gridIndex
    if self.facing == "W" and gridIndex ~= nil then
        partIndex = 4 - gridIndex
    end

    local part = family and partIndex and family.parts[partIndex] or nil
    if part == nil or character == nil then
        return nil
    end

    local inventory = character:getInventory()
    local items = inventory and inventory:getItems() or nil
    if items == nil then
        return nil
    end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item ~= nil and item:getFullType() == part.itemType then
            return item, inventory
        end
    end

    return nil
end

if Pickup._garageDoorPreviousCanPickUpMoveable == nil then
    Pickup._garageDoorPreviousCanPickUpMoveable = ISMoveableSpriteProps.canPickUpMoveable
end

ISMoveableSpriteProps.canPickUpMoveable = function(self, character, square, object)
    GarageDoor.ensureMovePropsIdentity(self)
    if self == nil or self.lmionGarageFamily == nil then
        return Pickup._garageDoorPreviousCanPickUpMoveable(self, character, square, object)
    end

    local selected = object
    if selected == nil and square ~= nil then
        selected = self:findOnSquare(square, self.spriteName)
    end

    if selected == nil or not instanceof(selected, "IsoDoor") then
        return false
    end

    local first = IsoDoor.getGarageDoorFirst(selected)
    if first == nil or IsoDoor.getGarageDoorIndex(first) ~= 1 then
        return false
    end

    local expectedOpen = selected:IsOpen()
    local current = first
    for expectedIndex = 1, 3 do
        if current == nil
            or not instanceof(current, "IsoDoor")
            or current:IsOpen() ~= expectedOpen
            or IsoDoor.getGarageDoorIndex(current) ~= expectedIndex then
            return false
        end

        local sprite = current:getSprite()
        local segment = getSegment(sprite)
        if segment == nil
            or segment.familyId ~= self.lmionGarageFamily
            or segment.partIndex ~= expectedIndex
            or segment.isOpen ~= expectedOpen then
            return false
        end

        if expectedIndex < 3 then
            current = IsoDoor.getGarageDoorNext(current)
        end
    end

    return Pickup._garageDoorPreviousCanPickUpMoveable(self, character, square, selected)
end

if Pickup._garageDoorPreviousPickUpMoveableInternal == nil then
    Pickup._garageDoorPreviousPickUpMoveableInternal = ISMoveableSpriteProps.pickUpMoveableInternal
end

ISMoveableSpriteProps.pickUpMoveableInternal = function(self, character, square, object, sprInstance, spriteName, createItem, rotating)
    GarageDoor.ensureMovePropsIdentity(self)
    local segment = self and self.lmionGarageFamily and getSegment(spriteName) or nil

    self.lmionGaragePendingHealth = nil
    self.lmionGaragePendingMaxHealth = nil

    if segment ~= nil and object ~= nil and instanceof(object, "IsoDoor") then
        self.lmionGaragePendingHealth = object:getHealth()
        local modData = object:getModData()
        if modData ~= nil then
            self.lmionGaragePendingMaxHealth = tonumber(modData[Doors.MaxHealthModDataKey])
        end
    end

    local canonicalSpriteName = segment and segment.closedSpriteName or spriteName
    local item = Pickup._garageDoorPreviousPickUpMoveableInternal(
        self,
        character,
        square,
        object,
        sprInstance,
        canonicalSpriteName,
        createItem,
        rotating
    )

    self.lmionGaragePendingHealth = nil
    self.lmionGaragePendingMaxHealth = nil
    return item
end

if Pickup._garageDoorPreviousPlaceMoveableInternal == nil then
    Pickup._garageDoorPreviousPlaceMoveableInternal = ISMoveableSpriteProps.placeMoveableInternal
end

ISMoveableSpriteProps.placeMoveableInternal = function(self, square, item, spriteName)
    GarageDoor.ensureMovePropsIdentity(self)
    local segment = self and self.lmionGarageFamily and getSegment(spriteName) or nil
    if segment == nil then
        return Pickup._garageDoorPreviousPlaceMoveableInternal(self, square, item, spriteName)
    end

    local savedHealth = nil
    local savedMaxHealth = nil
    if item ~= nil and item:hasModData() then
        local modData = item:getModData()
        savedHealth = tonumber(modData.lmionDoorHealth)
        savedMaxHealth = tonumber(modData.lmionDoorMaxHealth)
    end

    local result = Pickup._garageDoorPreviousPlaceMoveableInternal(self, square, item, segment.closedSpriteName or spriteName)
    local door = result

    if door ~= nil and instanceof(door, "IsoDoor") then
        if savedMaxHealth ~= nil then
            Doors.setEffectiveMaxHealth(door, savedMaxHealth)
        end
        if savedHealth ~= nil then
            door:setHealth(math.max(0, savedHealth))
        end
        if isServer() then
            door:transmitCompleteItemToClients()
        end
    end

    return result
end

if Pickup._garageDoorConfigureHandler ~= nil then
    Events.OnLoadedTileDefinitions.Remove(Pickup._garageDoorConfigureHandler)
end

Pickup._garageDoorConfigureHandler = function()
    markKnownSpritesMoveable()
    GarageDoor.installRuntimeSpriteGrids()
end
Events.OnLoadedTileDefinitions.Add(Pickup._garageDoorConfigureHandler)

markKnownSpritesMoveable()

return GarageDoor
