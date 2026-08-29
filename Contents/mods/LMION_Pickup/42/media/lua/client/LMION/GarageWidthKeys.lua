require "PZAPI/ModOptions"

-- Persistent/user-configurable garage placement keys.
local options = PZAPI.ModOptions:getOptions("LMION_GaragePlacement")
if options == nil then
    options = PZAPI.ModOptions:create(
        "LMION_GaragePlacement",
        getText("UI_LMION_GarageWidthOptions")
    )
end

if options:getOption("GarageWidthDecrease") == nil then
    options:addKeyBind(
        "GarageWidthDecrease",
        getText("UI_LMION_GarageWidthDecrease"),
        Keyboard.KEY_SUBTRACT
    )
end

if options:getOption("GarageWidthIncrease") == nil then
    options:addKeyBind(
        "GarageWidthIncrease",
        getText("UI_LMION_GarageWidthIncrease"),
        Keyboard.KEY_ADD
    )
end

-- Inventory UI belongs to the client Lua tree, while the dedicated garage
-- placement cursor belongs to the gameplay/server BuildingObjects tree. Install
-- the handoff at OnGameStart, when both globals are available, rather than using
-- a cross-tree require during early menu loading.
local function installGaragePlacementHandoff()
    if type(ISMoveableContextMenu) ~= "table"
        or type(ISMoveableContextMenu.openMovableCursor) ~= "function" then
        return
    end

    if LMION == nil
        or LMION.Pickup == nil
        or LMION.Pickup.GarageDoor == nil then
        return
    end

    local GarageDoor = LMION.Pickup.GarageDoor
    if PickupGaragePlacementOriginalOpenMovableCursor == nil then
        PickupGaragePlacementOriginalOpenMovableCursor = ISMoveableContextMenu.openMovableCursor
    end

    if ISMoveableContextMenu.openMovableCursor == LMIONGarageOpenMovableCursor then
        return
    end

    LMIONGarageOpenMovableCursor = function(item, playerObj)
        local identity = GarageDoor.getParcelIdentity
            and GarageDoor.getParcelIdentity(item)
            or nil

        if identity ~= nil
            and GarageDoor.openPlacementCursor ~= nil
            and GarageDoor.openPlacementCursor(item, playerObj) then
            return
        end

        return PickupGaragePlacementOriginalOpenMovableCursor(item, playerObj)
    end

    ISMoveableContextMenu.openMovableCursor = LMIONGarageOpenMovableCursor
    LMION.log("Pickup", "garage inventory Place handoff installed")
end

installGaragePlacementHandoff()
Events.OnGameStart.Add(installGaragePlacementHandoff)
