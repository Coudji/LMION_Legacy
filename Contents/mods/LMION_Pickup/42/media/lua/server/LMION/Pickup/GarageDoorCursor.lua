require "BuildingObjects/ISMoveableCursor"
require "LMION/Pickup/GarageDoorPlacement"

local Pickup = LMION.Pickup
local GarageDoor = Pickup.GarageDoor

local function ensureGarageMoveProps(moveProps)
    if moveProps ~= nil and GarageDoor.ensureMovePropsIdentity ~= nil then
        GarageDoor.ensureMovePropsIdentity(moveProps)
    end
    return moveProps
end

local function isGarageMoveProps(moveProps)
    moveProps = ensureGarageMoveProps(moveProps)
    return moveProps ~= nil
        and moveProps.lmionGarageFamily ~= nil
        and moveProps.lmionGaragePart ~= nil
end

local function clearLegacyOutline(cursor)
    local objects = cursor and cursor.lmionGarageOutlinedObjects or nil
    if objects == nil then
        return
    end

    for _, object in ipairs(objects) do
        if object ~= nil then
            object:setOutlineHighlight(cursor.player, false)
        end
    end

    cursor.lmionGarageOutlinedObjects = nil
end

local function renderFloorSquare(square)
    local floor = square and square:getFloor() or nil
    local floorSprite = floor and floor:getSprite() or nil
    if floorSprite ~= nil then
        floorSprite:RenderGhostTileColor(
            square:getX(),
            square:getY(),
            square:getZ(),
            0.75,
            1,
            0.75,
            0.25
        )
    end
end

local function renderFloorFootprint(members)
    for _, member in ipairs(members) do
        renderFloorSquare(member.square)
    end
end

local function renderOpenPickupFootprint(self, x, y, z)
    local moveProps = ensureGarageMoveProps(self.currentMoveProps)
    local mode = ISMoveableCursor.mode and ISMoveableCursor.mode[self.player] or nil
    if mode ~= "pickup"
        or not isGarageMoveProps(moveProps)
        or moveProps.lmionGarageIsOpen ~= true then
        return
    end

    local square = self.currentSquare or getCell():getGridSquare(x, y, z)
    local selected = square and moveProps:findOnSquare(square, moveProps.spriteName) or nil
    local members = selected and GarageDoor.getMembers(selected, moveProps.lmionGarageFamily) or nil

    if members ~= nil then
        renderFloorFootprint(members)
    end
end

if Pickup._garageDoorOriginalRender == nil then
    Pickup._garageDoorOriginalRender = ISMoveableCursor.render
end

ISMoveableCursor.render = function(self, x, y, z, square)
    local result = Pickup._garageDoorOriginalRender(self, x, y, z, square)
    renderOpenPickupFootprint(self, x, y, z)
    return result
end

if Pickup._garageDoorOriginalRenderSpriteGrid == nil then
    Pickup._garageDoorOriginalRenderSpriteGrid = ISMoveableCursor.renderSpriteGrid
end

ISMoveableCursor.renderSpriteGrid = function(self, x, y, z, color)
    clearLegacyOutline(self)

    local mode = ISMoveableCursor.mode and ISMoveableCursor.mode[self.player] or nil
    local origMoveProps = ensureGarageMoveProps(self.origMoveProps)
    local currentMoveProps = ensureGarageMoveProps(self.currentMoveProps)

    if mode == "pickup"
        and isGarageMoveProps(origMoveProps)
        and isGarageMoveProps(currentMoveProps) then
        local square = self.currentSquare or getCell():getGridSquare(x, y, z)
        local selected = square and currentMoveProps:findOnSquare(square, currentMoveProps.spriteName) or nil
        local members = selected and GarageDoor.getMembers(selected, currentMoveProps.lmionGarageFamily) or nil

        if members ~= nil then
            renderFloorFootprint(members)
        end
        return
    end

    if mode == "place" and isGarageMoveProps(currentMoveProps) then
        local square = self.currentSquare or getCell():getGridSquare(x, y, z)
        local plan = GarageDoor.buildPlacementPlan(currentMoveProps, self.character, square)
        if plan ~= nil then
            for position = 1, plan.length do
                local entry = plan[position]
                local targetSquare = entry.square
                renderFloorSquare(targetSquare)

                local sprite = getSprite(entry.spriteName)
                if sprite ~= nil then
                    sprite:RenderGhostTileColor(
                        targetSquare:getX(),
                        targetSquare:getY(),
                        targetSquare:getZ(),
                        0,
                        (self.yOffset or 0) * Core.getTileScale(),
                        color.r,
                        color.g,
                        color.b,
                        0.8
                    )
                end
            end
            return
        end
    end

    return Pickup._garageDoorOriginalRenderSpriteGrid(self, x, y, z, color)
end

if Pickup._garageDoorOriginalSetInfoPanel == nil then
    Pickup._garageDoorOriginalSetInfoPanel = ISMoveableCursor.setInfoPanel
end

ISMoveableCursor.setInfoPanel = function(self, square, object, moveProps, customTexture)
    local infoPanel = Pickup._garageDoorOriginalSetInfoPanel(self, square, object, moveProps, customTexture)
    moveProps = ensureGarageMoveProps(moveProps)
    local mode = ISMoveableCursor.mode and ISMoveableCursor.mode[self.player] or nil

    if infoPanel ~= nil
        and mode == "place"
        and square ~= nil
        and isGarageMoveProps(moveProps) then
        local plan = GarageDoor.buildPlacementPlan(moveProps, self.character, square)
        local maximum = GarageDoor.getMaximumAvailableLength(self.character, moveProps.lmionGarageFamily)

        if plan ~= nil and maximum ~= nil then
            infoPanel:setFooterText(
                getText("UI_LMION_GarageWidthCurrent") .. " L" .. tostring(plan.length)
                    .. "  |  " .. getText("UI_LMION_GarageWidthMaximum") .. " L" .. tostring(maximum)
                    .. "[br/]" .. getText("UI_LMION_GarageWidthAdjust"),
                UIFont.Small
            )

            local diagnosticKey = tostring(moveProps.lmionGarageFamily)
                .. ":" .. tostring(plan.length)
                .. ":" .. tostring(maximum)
            if Pickup._garageDoorCursorDiagnosticKey ~= diagnosticKey then
                Pickup._garageDoorCursorDiagnosticKey = diagnosticKey
                LMION.log(
                    "Pickup",
                    "garage placement cursor family=" .. tostring(moveProps.lmionGarageFamily)
                        .. " selected=L" .. tostring(plan.length)
                        .. " max=L" .. tostring(maximum)
                )
            end
        end
    end

    return infoPanel
end

local function getWidthKey(optionId, fallback)
    if PZAPI ~= nil and PZAPI.ModOptions ~= nil then
        local options = PZAPI.ModOptions:getOptions("LMION_GaragePlacement")
        local option = options and options:getOption(optionId) or nil
        if option ~= nil then
            return option:getValue()
        end
    end
    return fallback
end

local function onGarageWidthKey(key)
    local player = getPlayer()
    if player == nil or getCell() == nil then
        return
    end

    local playerNum = player:getPlayerNum()
    local cursor = getCell():getDrag(playerNum)
    if cursor == nil
        or cursor.Type ~= "ISMoveableCursor"
        or ISMoveableCursor.mode[playerNum] ~= "place" then
        return
    end

    local moveProps = ensureGarageMoveProps(cursor.currentMoveProps or cursor.origMoveProps)
    if not isGarageMoveProps(moveProps) then
        return
    end

    local delta = nil
    if key == getWidthKey("GarageWidthDecrease", Keyboard.KEY_SUBTRACT) then
        delta = -1
    elseif key == getWidthKey("GarageWidthIncrease", Keyboard.KEY_ADD) then
        delta = 1
    end

    if delta == nil then
        return
    end

    local currentPlan = cursor.currentSquare
        and GarageDoor.buildPlacementPlan(moveProps, cursor.character, cursor.currentSquare)
        or nil
    local oldLength = currentPlan and currentPlan.length or nil
    local newLength = GarageDoor.adjustPlacementLength(cursor.character, moveProps.lmionGarageFamily, delta)

    LMION.log(
        "Pickup",
        "garage width key family=" .. tostring(moveProps.lmionGarageFamily)
            .. " delta=" .. tostring(delta)
            .. " old=" .. tostring(oldLength)
            .. " new=" .. tostring(newLength)
    )

    if newLength ~= nil and newLength ~= oldLength then
        cursor:clearCache()
        getSoundManager():playUISound("UIObjectMenuObjectRotateOutline")
    end
end

Events.OnKeyPressed.Add(onGarageWidthKey)
LMION.log("Pickup", "garage variable-width cursor hooks installed")

if Pickup._garageDoorOriginalCursorClearCache ~= nil then
    ISMoveableCursor.clearCache = Pickup._garageDoorOriginalCursorClearCache
end

return GarageDoor
