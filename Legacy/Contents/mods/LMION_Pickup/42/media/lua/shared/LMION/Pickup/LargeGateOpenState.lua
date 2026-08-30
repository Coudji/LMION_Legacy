require "LMION/Pickup/LargeGateMoveables"

local Pickup = LMION.Pickup
local LargeGate = Pickup.LargeGate
local Doors = LMION.Doors
local leaves = LargeGate.Leaves

local OPEN_SPRITE_OFFSETS = {
    N = {[1] = 5, [2] = 3, [3] = 4, [4] = 4},
    W = {[1] = 4, [2] = 4, [3] = 5, [4] = 3},
}

local LAYOUT = {
    N = {
        closed = {[1] = {0, 0}, [2] = {1, 0}, [3] = {2, 0}, [4] = {3, 0}},
        open = {[1] = {0, 0}, [2] = {0, 1}, [3] = {3, 1}, [4] = {3, 0}},
    },
    W = {
        closed = {[1] = {0, 0}, [2] = {0, -1}, [3] = {0, -2}, [4] = {0, -3}},
        open = {[1] = {0, 0}, [2] = {1, 0}, [3] = {1, -3}, [4] = {0, -3}},
    },
}

local closedSegments = {}
local openSegments = {}

local function offsetSpriteName(spriteName, offset)
    local prefix, index = string.match(tostring(spriteName or ""), "^(.-)(%d+)$")
    index = tonumber(index)
    return prefix and index and offset and (prefix .. tostring(index + offset)) or nil
end

for leafId, leaf in pairs(leaves) do
    for partIndex, part in pairs(leaf.parts) do
        for facing, closedSpriteName in pairs(part.faces) do
            local logicalIndex = leaf.indices[facing][partIndex]
            local openSpriteName = offsetSpriteName(closedSpriteName, OPEN_SPRITE_OFFSETS[facing][logicalIndex])
            local segment = {
                leafId = leafId,
                partIndex = partIndex,
                facing = facing,
                logicalIndex = logicalIndex,
                itemType = part.itemType,
                faces = part.faces,
                closedSpriteName = closedSpriteName,
                openSpriteName = openSpriteName,
            }
            closedSegments[closedSpriteName] = segment
            openSegments[openSpriteName] = segment
        end
    end
end

LargeGate.OpenSegmentsBySprite = openSegments
LargeGate.OpenStateLayout = LAYOUT

local function getDoubleDoorIndex(object)
    if object == nil or IsoDoor == nil or IsoDoor.getDoubleDoorIndex == nil then
        return nil
    end

    local ok, index = pcall(IsoDoor.getDoubleDoorIndex, object)
    index = ok and tonumber(index) or nil
    return index and index >= 1 and index <= 4 and index or nil
end

local function getDoubleDoorObject(source, index)
    if source == nil or IsoDoor == nil or IsoDoor.getDoubleDoorObject == nil then
        return nil
    end

    local ok, object = pcall(IsoDoor.getDoubleDoorObject, source, index)
    return ok and object or nil
end

local function getSegment(object)
    local sprite = object and object:getSprite() or nil
    local spriteName = sprite and sprite:getName() or nil
    return spriteName and (closedSegments[spriteName] or openSegments[spriteName]) or nil
end

local function getGateMembers(source)
    local members = {}
    for index = 1, 4 do
        local object = getDoubleDoorObject(source, index)
        local segment = getSegment(object)
        if not Doors.isDoorObject(object) or segment == nil then
            return nil
        end
        members[index] = {object = object, segment = segment, square = object:getSquare()}
    end
    return members
end

local function getLeafMembers(source, leafId)
    local leaf = leaves[leafId]
    local sourceSegment = getSegment(source)
    if leaf == nil or sourceSegment == nil or sourceSegment.leafId ~= leafId then
        return nil
    end

    local indices = leaf.indices[sourceSegment.facing]
    if indices == nil then
        return nil
    end

    local members = {}
    for partIndex, logicalIndex in ipairs(indices) do
        local object = getDoubleDoorObject(source, logicalIndex)
        local segment = getSegment(object)
        if not Doors.isDoorObject(object)
            or segment == nil
            or segment.leafId ~= leafId
            or segment.partIndex ~= partIndex
            or segment.facing ~= sourceSegment.facing then
            return nil
        end
        members[partIndex] = {object = object, segment = segment, square = object:getSquare()}
    end

    return members
end

LargeGate.getOpenAwareLeafMembers = getLeafMembers

local function captureStates(members)
    if members == nil then
        return nil
    end

    local states = {}
    for index = 1, 4 do
        local member = members[index]
        local state = member and Doors.captureDoorState(member.object) or nil
        if state == nil then
            return nil
        end
        states[index] = state
    end
    return states
end

local function restoreStates(source, states)
    if source == nil or states == nil then
        return false
    end

    local restored = 0
    for index = 1, 4 do
        local object = getDoubleDoorObject(source, index)
        local state = states[index]
        if Doors.restoreDoorState(object, state) then
            if isServer ~= nil and isServer() and object.transmitCompleteItemToClients ~= nil then
                object:transmitCompleteItemToClients()
            end
            restored = restored + 1
        end
    end

    return restored == 4
end

local function findKnownOnSquare(square, logicalIndex, facing)
    if square == nil then
        return nil
    end

    local objects = square:getSpecialObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        local segment = getSegment(object)
        if segment ~= nil
            and segment.facing == facing
            and getDoubleDoorIndex(object) == logicalIndex then
            return object
        end
    end

    return nil
end

-- Vanilla recreates some DoubleDoor members while opening/closing them. Capture
-- the complete Core state before that transition and restore it on the new world
-- objects afterward. Pickup only owns detection/timing here; state semantics live
-- in Core and can later grow to include Locks without duplicating this mechanism.
Pickup._largeGatePendingToggleState = Pickup._largeGatePendingToggleState or {}

local function onAboutToRemove(object)
    if not Doors.isDoorObject(object) or getDoubleDoorIndex(object) ~= 2 then
        return
    end

    local segment = getSegment(object)
    if segment == nil then
        return
    end

    local targetOpen = object:IsOpen()
    local previousLayout = targetOpen and "closed" or "open"
    local offsets = LAYOUT[segment.facing][previousLayout]
    local square = object:getSquare()
    local member2Offset = offsets[2]
    if square == nil then
        return
    end

    local anchorX = square:getX() - member2Offset[1]
    local anchorY = square:getY() - member2Offset[2]
    local z = square:getZ()
    local members = {}

    for index = 1, 4 do
        local offset = offsets[index]
        local memberSquare = getCell():getGridSquare(anchorX + offset[1], anchorY + offset[2], z)
        local member = findKnownOnSquare(memberSquare, index, segment.facing)
        local memberSegment = getSegment(member)
        if member == nil or memberSegment == nil then
            return
        end
        members[index] = {object = member, segment = memberSegment, square = memberSquare}
    end

    local states = captureStates(members)
    if states ~= nil then
        local key = tostring(anchorX) .. ":" .. tostring(anchorY) .. ":" .. tostring(z) .. ":" .. segment.facing
        Pickup._largeGatePendingToggleState[key] = {
            anchorX = anchorX,
            anchorY = anchorY,
            z = z,
            facing = segment.facing,
            targetOpen = targetOpen,
            states = states,
        }
    end
end

local function onContainerUpdate()
    for key, transition in pairs(Pickup._largeGatePendingToggleState) do
        Pickup._largeGatePendingToggleState[key] = nil

        local square = getCell():getGridSquare(transition.anchorX, transition.anchorY, transition.z)
        local anchor = findKnownOnSquare(square, 1, transition.facing)
        local members = anchor and getGateMembers(anchor) or nil
        local valid = members ~= nil

        if valid then
            for index = 1, 4 do
                if members[index].object:IsOpen() ~= transition.targetOpen then
                    valid = false
                    break
                end
            end
        end

        if valid then
            restoreStates(anchor, transition.states)
        end
    end
end

if Events and Events.OnObjectAboutToBeRemoved then
    if Pickup._largeGateOpenStateRemoveHandler then
        Events.OnObjectAboutToBeRemoved.Remove(Pickup._largeGateOpenStateRemoveHandler)
    end
    Pickup._largeGateOpenStateRemoveHandler = onAboutToRemove
    Events.OnObjectAboutToBeRemoved.Add(onAboutToRemove)
end

if Events and Events.OnContainerUpdate then
    if Pickup._largeGateOpenStateUpdateHandler then
        Events.OnContainerUpdate.Remove(Pickup._largeGateOpenStateUpdateHandler)
    end
    Pickup._largeGateOpenStateUpdateHandler = onContainerUpdate
    Events.OnContainerUpdate.Add(onContainerUpdate)
end

local function configureOpenSprites()
    for spriteName, _ in pairs(openSegments) do
        local sprite = getSprite(spriteName)
        local properties = sprite and sprite:getProperties() or nil
        if properties ~= nil then
            properties:set("IsMoveAble")
        end
    end
end

if Events and Events.OnLoadedTileDefinitions then
    if Pickup._largeGateOpenConfigureHandler then
        Events.OnLoadedTileDefinitions.Remove(Pickup._largeGateOpenConfigureHandler)
    end
    Pickup._largeGateOpenConfigureHandler = configureOpenSprites
    Events.OnLoadedTileDefinitions.Add(configureOpenSprites)
end
configureOpenSprites()

local function applyOpenIdentity(moveProps, segment)
    local profile = Pickup.DoorMoveables and Pickup.DoorMoveables.getProfileForSprite
        and Pickup.DoorMoveables.getProfileForSprite(segment.closedSpriteName)
        or nil

    moveProps.isMoveable = true
    moveProps.customItem = segment.itemType
    moveProps.lmionLargeGateLeaf = segment.leafId
    moveProps.lmionLargeGatePart = segment.partIndex
    moveProps.lmionLargeGateIsOpen = true
    moveProps.lmionLargeGateClosedSprite = segment.closedSpriteName
    moveProps.lmionDoorFaces = segment.faces
    moveProps.lmionDoorFacing = segment.facing
    moveProps.facing = segment.facing
    moveProps.rawWeight = 120
    moveProps.weight = 12

    if profile ~= nil then
        moveProps.type = profile.moveType or "Object"
        moveProps.pickUpTool = profile.pickUpTool
        moveProps.placeTool = profile.placeTool
        moveProps.pickUpLevel = profile.pickUpLevel or 0
        moveProps.canBreak = profile.pickUpTool ~= nil and profile.canBreak == true
    end

    local scriptItem = ScriptManager and ScriptManager.instance and ScriptManager.instance:FindItem(segment.itemType) or nil
    if scriptItem ~= nil then
        moveProps.name = scriptItem:getDisplayName()
    end
end

if Pickup._largeGateOpenOriginalNew == nil then
    Pickup._largeGateOpenOriginalNew = ISMoveableSpriteProps.new
end

ISMoveableSpriteProps.new = function(sprite)
    local moveProps = Pickup._largeGateOpenOriginalNew(sprite)
    local resolved = type(sprite) == "string" and getSprite(sprite) or sprite
    local spriteName = resolved and resolved:getName() or nil
    local segment = spriteName and openSegments[spriteName] or nil
    if segment ~= nil then
        applyOpenIdentity(moveProps, segment)
    end
    return moveProps
end

local function findSelected(moveProps, square)
    return square and moveProps:findOnSquare(square, moveProps.spriteName) or nil
end

if Pickup._largeGateOpenOriginalCanPickUp == nil then
    Pickup._largeGateOpenOriginalCanPickUp = ISMoveableSpriteProps.canPickUpMoveable
end

ISMoveableSpriteProps.canPickUpMoveable = function(self, character, square, object)
    if self == nil or self.lmionLargeGateIsOpen ~= true then
        return Pickup._largeGateOpenOriginalCanPickUp(self, character, square, object)
    end

    local selected = object or findSelected(self, square)
    if selected == nil then
        return false
    end

    local baseCanPick = Pickup._largeGateOriginalCanPickUpMoveable
    if baseCanPick ~= nil then
        local wasMultiSprite = self.isMultiSprite
        self.isMultiSprite = false
        local canPick = baseCanPick(self, character, square, selected)
        self.isMultiSprite = wasMultiSprite
        if not canPick then
            return false
        end
    end

    local members = getLeafMembers(selected, self.lmionLargeGateLeaf)
    if members == nil then
        return false
    end

    for _, member in ipairs(members) do
        if not member.object:isObjectNoContainerOrEmpty() then
            return false
        end
    end

    if character
        and not ISMoveableDefinitions.cheat
        and not character:isMovablesCheat()
        and not character:getInventory():hasRoomFor(character, 24) then
        return false
    end

    return true
end

if Pickup._largeGateOpenOriginalPickUp == nil then
    Pickup._largeGateOpenOriginalPickUp = ISMoveableSpriteProps.pickUpMoveable
end

ISMoveableSpriteProps.pickUpMoveable = function(self, character, square, createItem, forceAllow)
    if self == nil or self.lmionLargeGateIsOpen ~= true then
        return Pickup._largeGateOpenOriginalPickUp(self, character, square, createItem, forceAllow)
    end

    local selected = findSelected(self, square)
    if selected == nil then
        return false
    end

    if not forceAllow
        and not character:isMovablesCheat()
        and not ISMoveableDefinitions.cheat
        and not self:canPickUpMoveable(character, square, selected) then
        return false
    end

    local segment = getSegment(selected)
    local states = captureStates(getGateMembers(selected))
    if segment == nil or states == nil then
        return false
    end

    local anchor = getDoubleDoorObject(selected, 1) or getDoubleDoorObject(selected, 4)
    if anchor == nil then
        return false
    end

    local ok, err = pcall(function()
        anchor:ToggleDoor(character)
    end)
    if not ok or anchor:IsOpen() then
        if not ok then
            LMION.error("Pickup", "failed to close large gate before Pickup: " .. tostring(err))
        end
        return false
    end

    if not restoreStates(anchor, states) then
        return false
    end

    local leaf = leaves[segment.leafId]
    local sourceIndex = leaf and leaf.indices[segment.facing][1] or nil
    local closedSelected = sourceIndex and getDoubleDoorObject(anchor, sourceIndex) or nil
    if closedSelected == nil then
        return false
    end

    local closedSprite = closedSelected:getSprite()
    local closedProps = closedSprite and ISMoveableSpriteProps.new(closedSprite) or nil
    if closedProps == nil then
        return false
    end

    return closedProps:pickUpMoveable(character, closedSelected:getSquare(), createItem, forceAllow)
end

return LargeGate
