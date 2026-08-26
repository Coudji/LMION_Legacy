require "Moveables/ISMoveableSpriteProps"
require "LMION/Pickup/LargeGateRuntime"

local Pickup = LMION.Pickup
local LargeGate = Pickup.LargeGate
local leafSpecs = LargeGate.Leaves
local segmentBySprite = LargeGate.SegmentsBySprite

--[[ Resolve the exact two physical IsoDoor members that belong to one LMION leaf. ]]
local function getDoubleDoorIndex(object)
    if object == nil or IsoDoor == nil or IsoDoor.getDoubleDoorIndex == nil then
        return nil
    end

    local ok, value = pcall(IsoDoor.getDoubleDoorIndex, object)
    if not ok then
        return nil
    end

    value = tonumber(value)
    if value == nil or value < 1 or value > 4 then
        return nil
    end

    return value
end

local function getDoubleDoorObject(source, index)
    if source == nil or IsoDoor == nil or IsoDoor.getDoubleDoorObject == nil then
        return nil
    end

    local ok, value = pcall(IsoDoor.getDoubleDoorObject, source, index)
    if not ok then
        return nil
    end

    return value
end

local function getLeafMembers(source, leafId)
    local leaf = leafSpecs[leafId]
    if leaf == nil or source == nil then
        return nil
    end

    local sourceSprite = source:getSprite()
    local sourceSpriteName = sourceSprite and sourceSprite:getName() or nil
    local sourceSegment = sourceSpriteName and segmentBySprite[sourceSpriteName] or nil
    if sourceSegment == nil or sourceSegment.leafId ~= leafId then
        return nil
    end

    local facing = sourceSegment.facing
    local logicalIndices = leaf.indices[facing]
    if logicalIndices == nil then
        return nil
    end

    local sourceIndex = getDoubleDoorIndex(source)
    if sourceIndex == nil then
        return nil
    end

    local members = {}
    for partIndex, logicalIndex in ipairs(logicalIndices) do
        local object = sourceIndex == logicalIndex and source or getDoubleDoorObject(source, logicalIndex)
        if object == nil or not instanceof(object, "IsoDoor") then
            return nil
        end

        local sprite = object:getSprite()
        local spriteName = sprite and sprite:getName() or nil
        local segment = spriteName and segmentBySprite[spriteName] or nil
        if segment == nil or segment.leafId ~= leafId or segment.partIndex ~= partIndex or segment.facing ~= facing then
            return nil
        end

        members[partIndex] = {object = object, square = object:getSquare(), spriteName = spriteName}
    end

    return members
end

local function setParcelIdentity(moveProps, segment)
    if moveProps == nil or segment == nil then
        return
    end

    moveProps.customItem = segment.itemType
    moveProps.lmionLargeGateLeaf = segment.leafId
    moveProps.lmionLargeGatePart = segment.partIndex
    moveProps.lmionDoorFaces = segment.faces
    moveProps.lmionDoorFacing = segment.facing
    moveProps.facing = segment.facing
    moveProps.rawWeight = 120
    moveProps.weight = 12

    if ScriptManager ~= nil and ScriptManager.instance ~= nil then
        local scriptItem = ScriptManager.instance:FindItem(segment.itemType)
        if scriptItem ~= nil then
            moveProps.name = scriptItem:getDisplayName()
        end
    end
end

local function findInventoryItem(character, fullType)
    if character == nil or fullType == nil then
        return nil
    end

    local inventory = character:getInventory()
    if inventory == nil then
        return nil
    end

    local items = inventory:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item ~= nil and item:getFullType() == fullType then
            return item, inventory
        end
    end

    return nil
end

local function isLargeGateMoveProps(moveProps)
    return moveProps ~= nil
        and moveProps.lmionLargeGateLeaf ~= nil
        and moveProps.lmionLargeGatePart ~= nil
        and moveProps.lmionDoorFaces ~= nil
end

--[[
Decorate vanilla Moveables props with LMION leaf/parcel identity while preserving
the original constructor for every unrelated moveable object.
]]
if Pickup._largeGateOriginalMoveableSpritePropsNew == nil then
    Pickup._largeGateOriginalMoveableSpritePropsNew = ISMoveableSpriteProps.new
end

ISMoveableSpriteProps.new = function(sprite)
    local moveProps = Pickup._largeGateOriginalMoveableSpritePropsNew(sprite)

    local resolved = sprite
    if type(resolved) == "string" then
        resolved = getSprite(resolved)
    end

    local spriteName = resolved and resolved:getName() or nil
    local segment = spriteName and segmentBySprite[spriteName] or nil
    if segment ~= nil then
        setParcelIdentity(moveProps, segment)
    end

    return moveProps
end

if Pickup._largeGateOriginalGetFaces == nil then
    Pickup._largeGateOriginalGetFaces = ISMoveableSpriteProps.getFaces
end

ISMoveableSpriteProps.getFaces = function(self)
    if isLargeGateMoveProps(self) then
        return {N = self.lmionDoorFaces.N, W = self.lmionDoorFaces.W}
    end

    return Pickup._largeGateOriginalGetFaces(self)
end

if Pickup._largeGateOriginalHasFaces == nil then
    Pickup._largeGateOriginalHasFaces = ISMoveableSpriteProps.hasFaces
end

ISMoveableSpriteProps.hasFaces = function(self)
    if isLargeGateMoveProps(self) then
        local faces = self:getFaces()
        return faces.N ~= nil and faces.W ~= nil
    end

    return Pickup._largeGateOriginalHasFaces(self)
end

if Pickup._largeGateOriginalGetIndexedFaces == nil then
    Pickup._largeGateOriginalGetIndexedFaces = ISMoveableSpriteProps.getIndexedFaces
end

ISMoveableSpriteProps.getIndexedFaces = function(self)
    if isLargeGateMoveProps(self) then
        local faces = self:getFaces()
        local n = faces.N
        local w = faces.W
        return {n, w, n, w}
    end

    return Pickup._largeGateOriginalGetIndexedFaces(self)
end

if Pickup._largeGateOriginalGetFaceIndex == nil then
    Pickup._largeGateOriginalGetFaceIndex = ISMoveableSpriteProps.getFaceIndex
end

ISMoveableSpriteProps.getFaceIndex = function(self)
    if isLargeGateMoveProps(self) then
        if self.lmionDoorFacing == "N" then
            return 1
        end
        if self.lmionDoorFacing == "W" then
            return 2
        end
        return -1
    end

    return Pickup._largeGateOriginalGetFaceIndex(self)
end

if Pickup._largeGateOriginalFindInInventoryMultiSprite == nil then
    Pickup._largeGateOriginalFindInInventoryMultiSprite = ISMoveableSpriteProps.findInInventoryMultiSprite
end

ISMoveableSpriteProps.findInInventoryMultiSprite = function(self, character, requestedName)
    if isLargeGateMoveProps(self) then
        local gridIndex = tonumber(string.match(requestedName or "", "%((%d+)/2%)$"))
        local leaf = leafSpecs[self.lmionLargeGateLeaf]
        local part = leaf and gridIndex and leaf.parts[gridIndex] or nil
        if part ~= nil then
            return findInventoryItem(character, part.itemType)
        end
        return nil
    end

    return Pickup._largeGateOriginalFindInInventoryMultiSprite(self, character, requestedName)
end

--[[
Pickup validates the complete two-member leaf, then temporarily treats each member
as a one-sprite object so vanilla creates one inventory parcel per physical door.
]]
if Pickup._largeGateOriginalCanPickUpMoveable == nil then
    Pickup._largeGateOriginalCanPickUpMoveable = ISMoveableSpriteProps.canPickUpMoveable
end

ISMoveableSpriteProps.canPickUpMoveable = function(self, character, square, object)
    if self == nil or self.lmionLargeGateLeaf == nil then
        return Pickup._largeGateOriginalCanPickUpMoveable(self, character, square, object)
    end

    local selected = object
    if selected == nil and square ~= nil then
        selected = self:findOnSquare(square, self.spriteName)
    end

    if selected == nil then
        return false
    end

    local wasMultiSprite = self.isMultiSprite
    self.isMultiSprite = false
    local canPickUp = Pickup._largeGateOriginalCanPickUpMoveable(self, character, square, selected)
    self.isMultiSprite = wasMultiSprite
    if not canPickUp then
        return false
    end

    local members = getLeafMembers(selected, self.lmionLargeGateLeaf)
    if members == nil then
        return false
    end

    for _, member in ipairs(members) do
        if member.object == nil or not member.object:isObjectNoContainerOrEmpty() then
            return false
        end
    end

    if character ~= nil and not ISMoveableDefinitions.cheat and not character:isMovablesCheat() and not character:getInventory():hasRoomFor(character, 24) then
        return false
    end

    return true
end

if Pickup._largeGateOriginalPickUpMoveable == nil then
    Pickup._largeGateOriginalPickUpMoveable = ISMoveableSpriteProps.pickUpMoveable
end

ISMoveableSpriteProps.pickUpMoveable = function(self, character, square, createItem, forceAllow)
    if self == nil or self.lmionLargeGateLeaf == nil then
        return Pickup._largeGateOriginalPickUpMoveable(self, character, square, createItem, forceAllow)
    end

    local selected = self:findOnSquare(square, self.spriteName)
    if selected == nil then
        return false
    end

    if not forceAllow and not character:isMovablesCheat() and not ISMoveableDefinitions.cheat and not self:canPickUpMoveable(character, square, selected) then
        return false
    end

    local members = getLeafMembers(selected, self.lmionLargeGateLeaf)
    if members == nil then
        return false
    end

    local items = {}
    for partIndex, member in ipairs(members) do
        local moveProps = ISMoveableSpriteProps.new(member.spriteName)
        moveProps.isMultiSprite = false
        local item = moveProps:pickUpMoveableInternal(character, member.square, member.object, nil, member.spriteName, createItem, forceAllow)
        items[partIndex] = item
    end

    if ISMoveableCursor ~= nil and ISMoveableCursor.clearCacheForAllPlayers ~= nil then
        ISMoveableCursor.clearCacheForAllPlayers()
    end

    return items
end

return Pickup
