require "LMION/Pickup"

local Pickup = LMION.Pickup
local GarageDoor = Pickup.GarageDoor

local options = PZAPI.ModOptions:create(
    "LMION_GaragePlacement",
    getText("UI_LMION_GarageWidthOptions")
)

local decreaseKey = options:addKeyBind(
    "GarageWidthDecrease",
    getText("UI_LMION_GarageWidthDecrease"),
    Keyboard.KEY_SUBTRACT
)

local increaseKey = options:addKeyBind(
    "GarageWidthIncrease",
    getText("UI_LMION_GarageWidthIncrease"),
    Keyboard.KEY_ADD
)

local function getActiveGaragePlacement()
    if getCell() == nil then
        return nil, nil
    end

    local cursor = getCell():getDrag(0)
    if cursor == nil
        or cursor.Type ~= "ISMoveableCursor"
        or ISMoveableCursor.mode[cursor.player] ~= "place" then
        return nil, nil
    end

    local moveProps = cursor.currentMoveProps or cursor.origMoveProps
    if moveProps == nil or moveProps.lmionGarageFamily == nil then
        return nil, nil
    end

    return cursor, moveProps.lmionGarageFamily
end

local function onKeyPressed(key)
    local cursor, familyId = getActiveGaragePlacement()
    if cursor == nil or familyId == nil then
        return
    end

    local delta = nil
    if key == decreaseKey:getValue() then
        delta = -1
    elseif key == increaseKey:getValue() then
        delta = 1
    end

    if delta == nil then
        return
    end

    local newLength = GarageDoor.adjustPlacementLength(cursor.character, familyId, delta)
    if newLength ~= nil then
        cursor.objectListCache = nil
        cursor.cacheObject = nil
        getSoundManager():playUISound("UIObjectMenuObjectRotateOutline")
    end
end

Events.OnKeyPressed.Add(onKeyPressed)

return GarageDoor
