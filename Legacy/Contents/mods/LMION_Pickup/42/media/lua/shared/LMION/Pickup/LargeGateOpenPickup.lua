require "Moveables/ISMoveableSpriteProps"
require "LMION/Pickup/LargeGateOpenState"

local Pickup = LMION.Pickup
local LargeGate = Pickup.LargeGate
local getOpenLeafMembers = LargeGate.getOpenAwareLeafMembers

local function findSelected(moveProps, square)
    if moveProps == nil or square == nil then
        return nil
    end

    return moveProps:findOnSquare(square, moveProps.spriteName)
end

-- Direct Pickup and representation restoration both remove world objects without
-- being a door toggle. Do not let the large-gate state hook mistake those removals
-- for vanilla ToggleDoor() object recreation.
if Events and Events.OnObjectAboutToBeRemoved and Pickup._largeGateOpenStateRemoveHandler ~= nil then
    Events.OnObjectAboutToBeRemoved.Remove(Pickup._largeGateOpenStateRemoveHandler)

    local toggleRemoveHandler = Pickup._largeGateOpenStateRemoveHandler
    Pickup._largeGateOpenStateRemoveHandler = function(object)
        if Pickup._largeGateDirectPickupInProgress == true
            or Pickup._largeGateSuppressToggleRemoval == true then
            return
        end
        return toggleRemoveHandler(object)
    end

    Events.OnObjectAboutToBeRemoved.Add(Pickup._largeGateOpenStateRemoveHandler)
end

--[[
An open large gate does not need to be closed before Pickup. Vanilla Moveables can
remove the actual world object directly; the transport item may still use another
sprite identity. Keep the untouched leaf exactly as it is in the world and create
our two parcels from the canonical CLOSED sprites of the removed leaf.

Placement remains intentionally closed, matching the normal LMION transport model.
]]
if Pickup._largeGateDirectOpenOriginalPickUp == nil then
    Pickup._largeGateDirectOpenOriginalPickUp = ISMoveableSpriteProps.pickUpMoveable
end

ISMoveableSpriteProps.pickUpMoveable = function(self, character, square, createItem, forceAllow)
    if self == nil or self.lmionLargeGateIsOpen ~= true then
        return Pickup._largeGateDirectOpenOriginalPickUp(self, character, square, createItem, forceAllow)
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

    local members = getOpenLeafMembers and getOpenLeafMembers(selected, self.lmionLargeGateLeaf) or nil
    if members == nil then
        return false
    end

    local pickupParts = {}
    for partIndex, member in ipairs(members) do
        local closedSpriteName = member.segment and member.segment.closedSpriteName or nil
        if closedSpriteName == nil then
            return false
        end

        local moveProps = ISMoveableSpriteProps.new(closedSpriteName)
        if moveProps == nil then
            return false
        end

        -- Match the existing closed-leaf Pickup behavior: one parcel per member,
        -- delivered as a multisprite world item while preserving Core door state.
        moveProps.isMultiSprite = true
        pickupParts[partIndex] = {
            moveProps = moveProps,
            member = member,
            closedSpriteName = closedSpriteName,
        }
    end

    local items = {}
    Pickup._largeGateDirectPickupInProgress = true
    local ok, err = pcall(function()
        for partIndex, part in ipairs(pickupParts) do
            items[partIndex] = part.moveProps:pickUpMoveableInternal(
                character,
                part.member.square,
                part.member.object,
                nil,
                part.closedSpriteName,
                createItem,
                forceAllow
            )
        end
    end)
    Pickup._largeGateDirectPickupInProgress = false

    if not ok then
        LMION.error("Pickup", "failed to pick up open large-gate leaf: " .. tostring(err))
        return false
    end

    if ISMoveableCursor ~= nil and ISMoveableCursor.clearCacheForAllPlayers ~= nil then
        ISMoveableCursor.clearCacheForAllPlayers()
    end

    return items
end

return LargeGate
