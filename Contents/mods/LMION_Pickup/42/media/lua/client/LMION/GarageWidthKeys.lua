require "PZAPI/ModOptions"
require "BuildingObjects/ISMoveableCursor"
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

local function isGarageMoveProps(moveProps)
    return type(moveProps) == "table"
        and moveProps.lmionGarageFamily ~= nil
        and moveProps.lmionGaragePart ~= nil
end

local function getActiveGaragePlacement()
    -- Client Lua is loaded while the main menu is active. OnKeyPressed can fire
    -- before a local player/gameplay cell is fully initialized, so the garage
    -- placement handler must be completely inert outside an active game.
    local player = getPlayer()
    if player == nil or getCell() == nil then
        return nil, nil
    end

    local playerNum = player:getPlayerNum()
    local cursor = getCell():getDrag(playerNum)
    if cursor == nil
        or cursor.Type ~= "ISMoveableCursor"
        or ISMoveableCursor.mode[playerNum] ~= "place" then
        return nil, nil
    end

    local moveProps = cursor.currentMoveProps or cursor.origMoveProps
    if not isGarageMoveProps(moveProps) then
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

    local square = cursor.currentSquare
    local moveProps = cursor.currentMoveProps or cursor.origMoveProps
    local previousPlan = square and GarageDoor.buildPlacementPlan(moveProps, cursor.character, square) or nil
    local previousLength = previousPlan and previousPlan.length or nil

    local newLength = GarageDoor.adjustPlacementLength(cursor.character, familyId, delta)
    if newLength ~= nil and newLength ~= previousLength then
        cursor:clearCache()
        getSoundManager():playUISound("UIObjectMenuObjectRotateOutline")
    end
end

Events.OnKeyPressed.Add(onKeyPressed)

-- GarageDoorPlacement.lua is shared and can load before the client-side
-- ISMoveableCursor class exists. Install the variable-length renderer here as a
-- guaranteed client-side fallback so the cursor never remains visually stuck on
-- the runtime L3 SpriteGrid while the actual placement plan is L2/L4/L5/etc.
if Pickup._garageDoorPreviousRenderSpriteGrid == nil then
    Pickup._garageDoorPreviousRenderSpriteGrid = ISMoveableCursor.renderSpriteGrid

    ISMoveableCursor.renderSpriteGrid = function(self, x, y, z, color)
        local moveProps = self and self.currentMoveProps or nil
        if not isGarageMoveProps(moveProps)
            or ISMoveableCursor.mode[self.player] ~= "place" then
            return Pickup._garageDoorPreviousRenderSpriteGrid(self, x, y, z, color)
        end

        local square = getCell():getGridSquare(x, y, z)
        local plan = GarageDoor.buildPlacementPlan(moveProps, self.character, square)
        if plan == nil then
            return Pickup._garageDoorPreviousRenderSpriteGrid(self, x, y, z, color)
        end

        for position = 1, plan.length do
            local entry = plan[position]
            local targetSquare = entry.square
            local tx = targetSquare:getX()
            local ty = targetSquare:getY()
            local tz = targetSquare:getZ()

            if targetSquare:getFloor() and targetSquare:getFloor():getSprite() then
                targetSquare:getFloor():getSprite():RenderGhostTileColor(tx, ty, tz, 0.75, 1, 0.75, 0.25)
            end

            local sprite = getSprite(entry.spriteName)
            if sprite ~= nil then
                sprite:RenderGhostTileColor(
                    tx,
                    ty,
                    tz,
                    0,
                    (self.yOffset or 0) * Core.getTileScale(),
                    color.r,
                    color.g,
                    color.b,
                    0.8
                )
            end
        end
    end
end

-- Make the selected width explicit. This also makes it obvious when +/- cannot
-- move because the player currently has no compatible Middle parcel in range.
if Pickup._garageDoorPreviousSetInfoPanel == nil then
    Pickup._garageDoorPreviousSetInfoPanel = ISMoveableCursor.setInfoPanel

    ISMoveableCursor.setInfoPanel = function(self, square, object, moveProps, customTexture)
        local infoPanel = Pickup._garageDoorPreviousSetInfoPanel(self, square, object, moveProps, customTexture)

        if infoPanel ~= nil
            and square ~= nil
            and isGarageMoveProps(moveProps)
            and ISMoveableCursor.mode[self.player] == "place" then
            local plan = GarageDoor.buildPlacementPlan(moveProps, self.character, square)
            local maximum = GarageDoor.getMaximumAvailableLength(
                self.character,
                moveProps.lmionGarageFamily
            )

            if plan ~= nil and maximum ~= nil then
                local decreaseName = Keyboard.getKeyName(decreaseKey:getValue())
                local increaseName = Keyboard.getKeyName(increaseKey:getValue())
                local footer = getText("UI_LMION_GarageWidthCurrent") .. " L" .. tostring(plan.length)
                    .. "  |  " .. getText("UI_LMION_GarageWidthMaximum") .. " L" .. tostring(maximum)
                    .. "[br/]'" .. tostring(decreaseName) .. "' / '" .. tostring(increaseName) .. "' - "
                    .. getText("UI_LMION_GarageWidthAdjust")

                infoPanel:setFooterText(footer, UIFont.Small)
            end
        end

        return infoPanel
    end
end

return GarageDoor
