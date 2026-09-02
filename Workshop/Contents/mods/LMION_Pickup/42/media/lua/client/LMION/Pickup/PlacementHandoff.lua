local MoveableAdapter = require "LMION/Pickup/Simple/MoveableAdapter"
local LargeGatePickup = require "LMION/Pickup/LargeGatePickup"
local LargeGatePlacement = require "LMION/Pickup/LargeGatePlacement"
local GaragePickup = require "LMION/Pickup/GaragePickup"
local GaragePlacement = require "LMION/Pickup/GaragePlacement"


-- Inventory UI is client Lua while BuildingObjects cursors live in gameplay /
-- server Lua. Do not require cursor files here. Wait until OnGameStart, when
-- their public handoff functions have been attached to the shared modules.
local function installPlacementHandoff()
    if type(ISMoveableContextMenu) ~= "table"
        or type(ISMoveableContextMenu.openMovableCursor) ~= "function"
        or type(MoveableAdapter.openPlacementCursor) ~= "function"
    then
        return
    end

    if MoveableAdapter._originalOpenMovableCursor == nil then
        MoveableAdapter._originalOpenMovableCursor =
            ISMoveableContextMenu.openMovableCursor
    end

    if ISMoveableContextMenu.openMovableCursor
        == MoveableAdapter._lmionOpenMovableCursor
    then
        return
    end

    MoveableAdapter._lmionOpenMovableCursor = function(item, playerObj)
        if LargeGatePickup.getParcelIdentity(item) ~= nil then
            if type(LargeGatePlacement.openPlacementCursor) == "function"
                and LargeGatePlacement.openPlacementCursor(item, playerObj)
            then
                return
            end

            return MoveableAdapter._originalOpenMovableCursor(
                item,
                playerObj
            )
        end

        if GaragePickup.getParcelIdentity(item) ~= nil then
            if type(GaragePlacement.openPlacementCursor) == "function"
                and GaragePlacement.openPlacementCursor(item, playerObj)
            then
                return
            end

            return MoveableAdapter._originalOpenMovableCursor(
                item,
                playerObj
            )
        end

        local identity = MoveableAdapter.getParcelIdentity(item)

        if identity ~= nil
            and MoveableAdapter.openPlacementCursor(item, playerObj)
        then
            return
        end

        return MoveableAdapter._originalOpenMovableCursor(
            item,
            playerObj
        )
    end

    ISMoveableContextMenu.openMovableCursor =
        MoveableAdapter._lmionOpenMovableCursor

    print("[LMION:Pickup] door Place handoff installed")
end


installPlacementHandoff()
Events.OnGameStart.Add(installPlacementHandoff)
