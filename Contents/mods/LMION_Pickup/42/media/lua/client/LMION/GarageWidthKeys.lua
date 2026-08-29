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
-- all UI handoffs only once those globals coexist. In particular, do NOT require
-- GarageDoorCursor.lua from this early client file: runtime testing proved that
-- doing so can leave the inventory Place command on vanilla ISMoveableCursor.
local function getSelectedVanillaPlaceItem(cursor)
    if cursor == nil
        or cursor.isMoveableCursor ~= true
        or cursor.getMoveableMode == nil
        or cursor:getMoveableMode() ~= "place"
        or cursor.getInventoryObjectList == nil then
        return nil
    end

    local objects = cursor.objectListCache
    if objects == nil or #objects == 0 then
        objects = cursor:getInventoryObjectList()
    end

    if objects == nil or #objects == 0 then
        return nil
    end

    local index = cursor.objectIndex or 1
    if index < 1 or index > #objects then
        index = 1
    end

    local selected = objects[index]
    return selected and selected.object or nil
end

local function installGaragePlacementHandoff()
    if LMION == nil
        or LMION.Pickup == nil
        or LMION.Pickup.GarageDoor == nil then
        return
    end

    local GarageDoor = LMION.Pickup.GarageDoor
    if type(GarageDoor.getParcelIdentity) ~= "function"
        or type(GarageDoor.openPlacementCursor) ~= "function" then
        return
    end

    -- Inventory context-menu Place: this is the already runtime-validated path.
    -- It receives the exact clicked item and must bypass vanilla Place mode for
    -- garage parcels before fixed SpriteGrid semantics take ownership.
    if type(ISMoveableContextMenu) == "table"
        and type(ISMoveableContextMenu.openMovableCursor) == "function" then
        if PickupGaragePlacementOriginalOpenMovableCursor == nil then
            PickupGaragePlacementOriginalOpenMovableCursor = ISMoveableContextMenu.openMovableCursor
        end

        if ISMoveableContextMenu.openMovableCursor ~= LMIONGarageOpenMovableCursor then
            LMIONGarageOpenMovableCursor = function(item, playerObj)
                local identity = GarageDoor.getParcelIdentity(item)

                if identity ~= nil
                    and GarageDoor.openPlacementCursor(item, playerObj) then
                    return
                end

                return PickupGaragePlacementOriginalOpenMovableCursor(item, playerObj)
            end

            ISMoveableContextMenu.openMovableCursor = LMIONGarageOpenMovableCursor
            LMION.log("Pickup", "garage inventory Place handoff installed")
        end
    end

    -- Sidebar Moveables -> Place has no explicit item parameter. Let vanilla do
    -- only what that button is designed to do: create/reuse ISMoveableCursor and
    -- select its current inventory entry. Immediately after that, if the selected
    -- entry is a garage parcel, replace the generic drag cursor with LMION's
    -- variable-width garage cursor. Ordinary Moveables remain entirely vanilla.
    if type(ISMoveablesIconPopup) == "table"
        and type(ISMoveablesIconPopup.onMouseUp) == "function" then
        if PickupGaragePlacementOriginalMoveablesPopupMouseUp == nil then
            PickupGaragePlacementOriginalMoveablesPopupMouseUp = ISMoveablesIconPopup.onMouseUp
        end

        if ISMoveablesIconPopup.onMouseUp ~= LMIONGarageMoveablesPopupMouseUp then
            LMIONGarageMoveablesPopupMouseUp = function(self, x, y)
                local result = PickupGaragePlacementOriginalMoveablesPopupMouseUp(self, x, y)

                local character = self and self.owner and self.owner.chr or nil
                local playerNum = character and character:getPlayerNum() or nil
                local cursor = playerNum ~= nil and getCell():getDrag(playerNum) or nil
                local item = getSelectedVanillaPlaceItem(cursor)
                local identity = item and GarageDoor.getParcelIdentity(item) or nil

                if identity ~= nil
                    and GarageDoor.openPlacementCursor(item, character) then
                    LMION.log(
                        "Pickup",
                        "garage sidebar Place handoff family=" .. tostring(identity.familyId)
                    )
                end

                return result
            end

            ISMoveablesIconPopup.onMouseUp = LMIONGarageMoveablesPopupMouseUp
            LMION.log("Pickup", "garage Moveables sidebar Place handoff installed")
        end
    end
end

installGaragePlacementHandoff()
Events.OnGameStart.Add(installGaragePlacementHandoff)
