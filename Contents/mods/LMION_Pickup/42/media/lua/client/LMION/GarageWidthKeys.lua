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
-- the UI wrappers as soon as their vanilla entry points and the GarageDoor table
-- exist. Do NOT require GarageDoorCursor.lua here and do NOT require
-- openPlacementCursor() to exist during installation: that server-tree method can
-- legitimately be attached later in the load sequence.
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

local function tryOpenGaragePlacement(GarageDoor, item, character)
    if GarageDoor == nil
        or type(GarageDoor.getParcelIdentity) ~= "function"
        or type(GarageDoor.openPlacementCursor) ~= "function" then
        return false, nil
    end

    local identity = GarageDoor.getParcelIdentity(item)
    if identity == nil then
        return false, nil
    end

    return GarageDoor.openPlacementCursor(item, character) == true, identity
end

local function installGaragePlacementHandoff()
    if LMION == nil
        or LMION.Pickup == nil
        or LMION.Pickup.GarageDoor == nil then
        return
    end

    local GarageDoor = LMION.Pickup.GarageDoor

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
                local opened = tryOpenGaragePlacement(GarageDoor, item, playerObj)
                if opened then
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
                local opened, identity = tryOpenGaragePlacement(GarageDoor, item, character)

                if opened then
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
