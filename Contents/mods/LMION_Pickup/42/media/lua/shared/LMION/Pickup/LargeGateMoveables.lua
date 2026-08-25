require "Moveables/ISMoveableSpriteProps"
require "LMION/Pickup/LargeGateProfiles"

local Pickup = LMION.Pickup

local leafSpecs = {
    left = {
        indices = {1, 2},
        parts = {
            [1] = {
                itemType = "Base.LMION_DoubleWireGateLeft_Part1",
                faces = {
                    N = "fixtures_doors_fences_01_66",
                    W = "fixtures_doors_fences_01_65",
                },
            },
            [2] = {
                itemType = "Base.LMION_DoubleWireGateLeft_Part2",
                faces = {
                    N = "fixtures_doors_fences_01_67",
                    W = "fixtures_doors_fences_01_64",
                },
            },
        },
    },
    right = {
        indices = {3, 4},
        parts = {
            [1] = {
                itemType = "Base.LMION_DoubleWireGateRight_Part1",
                faces = {
                    N = "fixtures_doors_fences_01_74",
                    W = "fixtures_doors_fences_01_73",
                },
            },
            [2] = {
                itemType = "Base.LMION_DoubleWireGateRight_Part2",
                faces = {
                    N = "fixtures_doors_fences_01_75",
                    W = "fixtures_doors_fences_01_72",
                },
            },
        },
    },
}

local segmentBySprite = {}
for leafId, leaf in pairs(leafSpecs) do
    for partIndex, part in pairs(leaf.parts) do
        for facing, spriteName in pairs(part.faces) do
            segmentBySprite[spriteName] = {
                leafId = leafId,
                partIndex = partIndex,
                facing = facing,
                itemType = part.itemType,
                faces = part.faces,
            }
        end
    end
end

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

    local sourceIndex = getDoubleDoorIndex(source)
    if sourceIndex == nil then
        return nil
    end

    local members = {}
    for partIndex, logicalIndex in ipairs(leaf.indices) do
        local object = nil
        if sourceIndex == logicalIndex then
            object = source
        else
            object = getDoubleDoorObject(source, logicalIndex)
        end

        if object == nil or not instanceof(object, "IsoDoor") then
            return nil
        end

        local sprite = object:getSprite()
        local spriteName = sprite and sprite:getName() or nil
        local segment = spriteName and segmentBySprite[spriteName] or nil
        if segment == nil or segment.leafId ~= leafId or segment.partIndex ~= partIndex then
            return nil
        end

        members[partIndex] = {
            object = object,
            square = object:getSquare(),
            spriteName = spriteName,
        }
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
            return item
        end
    end

    return nil
end

local function getPlacementSquares(self, square)
    if self == nil or square == nil then
        return nil
    end

    local facing = self.lmionDoorFacing
    local partIndex = tonumber(self.lmionLargeGatePart)
    if facing == nil or partIndex == nil then
        return nil
    end

    local dx = 0
    local dy = 0
    if facing == "N" then
        dx = 1
    elseif facing == "W" then
        dy = -1
    else
        return nil
    end

    local anchorX = square:getX()
    local anchorY = square:getY()
    if partIndex == 2 then
        anchorX = anchorX - dx
        anchorY = anchorY - dy
    elseif partIndex ~= 1 then
        return nil
    end

    local z = square:getZ()
    local part1Square = getCell():getGridSquare(anchorX, anchorY, z)
    local part2Square = getCell():getGridSquare(anchorX + dx, anchorY + dy, z)
    if part1Square == nil or part2Square == nil then
        return nil
    end

    return {
        [1] = part1Square,
        [2] = part2Square,
    }
end

local function buildPlacementPlan(self, character, square)
    local leaf = self and leafSpecs[self.lmionLargeGateLeaf] or nil
    local squares = getPlacementSquares(self, square)
    if leaf == nil or squares == nil then
        return nil
    end

    local facing = self.lmionDoorFacing
    local plan = {}
    for partIndex = 1, 2 do
        local part = leaf.parts[partIndex]
        local item = findInventoryItem(character, part.itemType)
        local spriteName = part.faces[facing]
        if item == nil or spriteName == nil then
            return nil
        end

        plan[partIndex] = {
            item = item,
            square = squares[partIndex],
            spriteName = spriteName,
        }
    end

    return plan
end

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

    if not Pickup._largeGateOriginalCanPickUpMoveable(self, character, square, selected) then
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

    if character ~= nil
        and not ISMoveableDefinitions.cheat
        and not character:isMovablesCheat()
        and not character:getInventory():hasRoomFor(character, 24) then
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

    if not forceAllow
        and not character:isMovablesCheat()
        and not ISMoveableDefinitions.cheat
        and not self:canPickUpMoveable(character, square, selected) then
        return false
    end

    local members = getLeafMembers(selected, self.lmionLargeGateLeaf)
    if members == nil then
        return false
    end

    local items = {}
    for partIndex, member in ipairs(members) do
        local moveProps = ISMoveableSpriteProps.new(member.spriteName)
        local item = moveProps:pickUpMoveableInternal(
            character,
            member.square,
            member.object,
            nil,
            member.spriteName,
            createItem,
            forceAllow
        )
        items[partIndex] = item
    end

    if ISMoveableCursor ~= nil and ISMoveableCursor.clearCacheForAllPlayers ~= nil then
        ISMoveableCursor.clearCacheForAllPlayers()
    end

    return items
end

if Pickup._largeGateOriginalCanPlaceMoveable == nil then
    Pickup._largeGateOriginalCanPlaceMoveable = ISMoveableSpriteProps.canPlaceMoveable
end

ISMoveableSpriteProps.canPlaceMoveable = function(self, character, square, item)
    if self == nil or self.lmionLargeGateLeaf == nil then
        return Pickup._largeGateOriginalCanPlaceMoveable(self, character, square, item)
    end

    local plan = buildPlacementPlan(self, character, square)
    if plan == nil then
        return false
    end

    for partIndex = 1, 2 do
        local entry = plan[partIndex]
        local moveProps = ISMoveableSpriteProps.new(entry.spriteName)
        if not moveProps:canPlaceMoveableInternal(character, entry.square, entry.item) then
            return false
        end
    end

    return true
end

if Pickup._largeGateOriginalPlaceMoveable == nil then
    Pickup._largeGateOriginalPlaceMoveable = ISMoveableSpriteProps.placeMoveable
end

ISMoveableSpriteProps.placeMoveable = function(self, character, square, origSpriteName, forceAllow)
    if self == nil or self.lmionLargeGateLeaf == nil then
        return Pickup._largeGateOriginalPlaceMoveable(self, character, square, origSpriteName, forceAllow)
    end

    local plan = buildPlacementPlan(self, character, square)
    if plan == nil then
        return false
    end

    if not forceAllow
        and not character:isMovablesCheat()
        and not ISMoveableDefinitions.cheat
        and not self:canPlaceMoveable(character, square, plan[self.lmionLargeGatePart].item) then
        return false
    end

    local placed = {}
    for partIndex = 1, 2 do
        local entry = plan[partIndex]
        local moveProps = ISMoveableSpriteProps.new(entry.spriteName)
        local object = moveProps:placeMoveableInternal(entry.square, entry.item, entry.spriteName)
        if object == nil then
            return false
        end
        placed[partIndex] = object
    end

    local inventory = character:getInventory()
    for partIndex = 1, 2 do
        local item = plan[partIndex].item
        inventory:Remove(item)
        sendRemoveItemFromContainer(inventory, item)
    end

    if ISMoveableCursor ~= nil and ISMoveableCursor.clearCacheForAllPlayers ~= nil then
        ISMoveableCursor.clearCacheForAllPlayers()
    end

    return placed
end

return Pickup
