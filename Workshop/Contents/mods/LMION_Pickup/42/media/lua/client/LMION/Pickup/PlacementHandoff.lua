local MoveableAdapter = require "LMION/Pickup/MoveableAdapter"


-- Legacy garages already established the safe cross-tree pattern:
-- inventory UI is client Lua, BuildingObjects cursors are gameplay/server Lua.
-- Do not require the server cursor during early client loading. Wait until
-- OnGameStart, when both globals/module mutations are available in-game.
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
