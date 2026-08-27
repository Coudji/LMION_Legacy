require "Moveables/ISMoveablesAction"

local Pickup = LMION.Pickup

local function isLmionScrewdriverPickup(action)
    local moveProps = action and action.moveProps or nil
    if action == nil or action.mode ~= "pickup" or moveProps == nil then
        return false
    end

    if moveProps.pickUpTool ~= "Screwdriver" then
        return false
    end

    return moveProps.lmionDoorProfile ~= nil
        or moveProps.lmionGarageFamily ~= nil
        or moveProps.lmionLargeGateLeaf ~= nil
end

--[[
Vanilla Moveables gives ordinary Pickup no dedicated action animation. Its Scrap
fallback uses CharacterActionAnims.Disassemble with a screwdriver hand model.
LMION reuses that vanilla animation only for Pickup actions whose configured tool
is the vanilla Screwdriver definition. walkToAndEquip() has already equipped the
real screwdriver before ISMoveablesAction starts, so keep the actual hand model
and only set the action animation here.
]]
if Pickup._screwdriverPickupOriginalActionStart == nil then
    Pickup._screwdriverPickupOriginalActionStart = ISMoveablesAction.start
end

ISMoveablesAction.start = function(self)
    Pickup._screwdriverPickupOriginalActionStart(self)

    if isLmionScrewdriverPickup(self) then
        self:setActionAnim(CharacterActionAnims.Disassemble)
    end
end

return Pickup
