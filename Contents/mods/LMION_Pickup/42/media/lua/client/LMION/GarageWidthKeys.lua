require "PZAPI/ModOptions"
require "Moveables/ISMoveableContextMenu"
require "ISUI/ISEquippedItem"
require "BuildingObjects/ISMoveableCursor"
require "LMION/Pickup/GarageDoorCursor"

-- This client file owns persistent/user-configurable key definitions and the
-- client-only UI handoffs that route garage parcel placement to LMION's
-- dedicated variable-width cursor.
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

local Pickup = LMION.Pickup
local GarageDoor = Pickup and Pickup.GarageDoor or nil

local function getSelectedVanillaPlaceItem(cursor)
    if cursor == nil
        or cursor.isMoveableCursor ~= true
        or cursor.getMoveableMode == nil
        or cursor:getMoveableMode() ~= "place" then
        return nil
    end

    local objects = cursor.objectListCache or cursor:getInventoryObjectList()
    if objects == nil or #objects == 0 then
        return nil
    end

    cursor.objectListCache = objects

    local index = cursor.objectIndex or 1
    if index < 1 or index > #objects then
        index = 1
        cursor.objectIndex = index
    end

    local selected = objects[index]
    return selected and selected.object or nil
end

local function handoffSelectedGarage(cursor, source)
    if GarageDoor == nil
        or GarageDoor.openPlacementCursor == nil
        or GarageDoor.getParcelIdentity == nil then
        return false
    end

    local item = getSelectedVanillaPlaceItem(cursor)
    local identity = item and GarageDoor.getParcelIdentity(item) or nil
    if identity == nil then
        return false
    end

    if not GarageDoor.openPlacementCursor(item, cursor.character) then
        return false
    end

    LMION.log(
        "Pickup",
        "garage Place handoff source=" .. tostring(source)
            .. " family=" .. tostring(identity.familyId)
    )
    return true
end

-- Inventory context-menu Place has the item explicitly, so it can bypass
-- vanilla ISMoveableCursor completely.
if GarageDoor ~= nil
    and GarageDoor.openPlacementCursor ~= nil
    and Pickup._garageDoorOriginalOpenMovableCursor == nil then
    Pickup._garageDoorOriginalOpenMovableCursor = ISMoveableContextMenu.openMovableCursor

    ISMoveableContextMenu.openMovableCursor = function(item, playerObj)
        if GarageDoor.getParcelIdentity(item) ~= nil
            and GarageDoor.openPlacementCursor(item, playerObj) then
            return
        end

        return Pickup._garageDoorOriginalOpenMovableCursor(item, playerObj)
    end

    LMION.log("Pickup", "garage inventory Place handoff installed")
end

-- The left Moveables sidebar has no item argument. Vanilla first creates or
-- reuses ISMoveableCursor, switches it to Place mode, then lets that cursor pick
-- an inventory entry by objectIndex. Let vanilla perform only that selection;
-- if the selected entry is a garage parcel, replace the drag cursor immediately
-- with LMION's dedicated variable-width cursor before the next world render.
if ISMoveablesIconPopup ~= nil
    and Pickup._garageDoorOriginalMoveablesPopupMouseUp == nil then
    Pickup._garageDoorOriginalMoveablesPopupMouseUp = ISMoveablesIconPopup.onMouseUp

    ISMoveablesIconPopup.onMouseUp = function(self, x, y)
        local result = Pickup._garageDoorOriginalMoveablesPopupMouseUp(self, x, y)

        local character = self and self.owner and self.owner.chr or nil
        local playerNum = character and character:getPlayerNum() or nil
        local cursor = playerNum ~= nil and getCell():getDrag(playerNum) or nil
        handoffSelectedGarage(cursor, "sidebar")

        return result
    end

    LMION.log("Pickup", "garage Moveables sidebar Place handoff installed")
end

-- Vanilla's Rotate-building key cycles inventory entries while in generic Place
-- mode. If that cycle lands on a garage parcel, hand it off too. The dedicated
-- garage cursor derives from ISBuildingObject, not ISMoveableCursor, so its own
-- N/W rotation and +/- width controls are unaffected by this wrapper.
if ISMoveableCursor ~= nil
    and Pickup._garageDoorOriginalMoveableCursorRotateKey == nil then
    Pickup._garageDoorOriginalMoveableCursorRotateKey = ISMoveableCursor.rotateKey

    ISMoveableCursor.rotateKey = function(self, key, joypadTriggered)
        local result = Pickup._garageDoorOriginalMoveableCursorRotateKey(self, key, joypadTriggered)

        if getCell() ~= nil and getCell():getDrag(self.player) == self then
            handoffSelectedGarage(self, "cycle")
        end

        return result
    end
end

-- The Toggle-mode key (TAB by default) is handled by vanilla before this later
-- client hook. Once it switches a generic cursor into Place mode, perform the
-- same selected-item handoff.
local function onMoveablesModeKey(key)
    if not getCore():isKey("Toggle mode", key) or getCell() == nil then
        return
    end

    local player = getPlayer()
    local playerNum = player and player:getPlayerNum() or 0
    local cursor = getCell():getDrag(playerNum)
    handoffSelectedGarage(cursor, "mode-key")
end

Events.OnKeyPressed.Add(onMoveablesModeKey)
