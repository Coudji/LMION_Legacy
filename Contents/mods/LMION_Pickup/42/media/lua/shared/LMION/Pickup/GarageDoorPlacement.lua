require "Moveables/ISMoveableSpriteProps"
require "LMION/Pickup/GarageDoorPickup"

local Pickup = LMION.Pickup
local GarageDoor = Pickup.GarageDoor

local TRACE_PREFIX = "[LMION][GarageTrace][Placement] "

local function trace(message)
    print(TRACE_PREFIX .. tostring(message))
end

local function squareText(square)
    if square == nil then
        return "nil"
    end

    return tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ())
end

local function spriteName(sprite)
    return sprite and sprite:getName() or "nil"
end

local function itemText(item)
    if item == nil then
        return "nil"
    end

    local modData = item:hasModData() and item:getModData() or nil
    return table.concat({
        "fullType=" .. tostring(item:getFullType()),
        "name=" .. tostring(item:getName()),
        "worldSprite=" .. tostring(item:getWorldSprite()),
        "family=" .. tostring(modData and modData.lmionGarageFamily),
        "part=" .. tostring(modData and modData.lmionGaragePart),
        "health=" .. tostring(modData and modData.lmionDoorHealth),
        "maxHealth=" .. tostring(modData and modData.lmionDoorMaxHealth),
    }, " ")
end

local function objectText(object)
    if object == nil then
        return "nil"
    end

    local sprite = object:getSprite()
    local properties = sprite and sprite:getProperties() or nil
    local rawGarageIndex = properties and properties:get("GarageDoor") or nil
    local normalizedIndex = instanceof(object, "IsoDoor") and IsoDoor.getGarageDoorIndex(object) or nil
    local square = object:getSquare()

    return table.concat({
        "object=" .. tostring(object),
        "sprite=" .. tostring(spriteName(sprite)),
        "square=" .. squareText(square),
        "north=" .. tostring(instanceof(object, "IsoDoor") and object:getNorth() or nil),
        "open=" .. tostring(instanceof(object, "IsoDoor") and object:IsOpen() or nil),
        "garageRaw=" .. tostring(rawGarageIndex),
        "garageIndex=" .. tostring(normalizedIndex),
    }, " ")
end

local function isGarageMoveProps(moveProps)
    return moveProps ~= nil
        and moveProps.lmionGarageFamily ~= nil
        and moveProps.lmionGaragePart ~= nil
end

local function findInventoryItem(character, fullType)
    if character == nil or fullType == nil then
        return nil, nil
    end

    local inventory = character:getInventory()
    if inventory == nil then
        return nil, nil
    end

    local items = inventory:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item ~= nil and item:getFullType() == fullType then
            return item, inventory
        end
    end

    return nil, nil
end

local function getCurrentFacing(moveProps)
    if moveProps == nil then
        return nil
    end

    if moveProps.facing == "N" or moveProps.facing == "W" then
        return moveProps.facing
    end

    if moveProps.lmionGarageFacing == "N" or moveProps.lmionGarageFacing == "W" then
        return moveProps.lmionGarageFacing
    end

    return nil
end

local function traceMoveProps(label, moveProps, square, origSpriteName)
    if moveProps == nil then
        trace(label .. " moveProps=nil")
        return
    end

    local sprite = moveProps.sprite
    local grid = sprite and sprite:getSpriteGrid() or nil
    local gridX = grid and grid:getSpriteGridPosX(sprite) or nil
    local gridY = grid and grid:getSpriteGridPosY(sprite) or nil
    local anchor = grid and grid:getAnchorSprite() or nil

    trace(table.concat({
        label,
        "square=" .. squareText(square),
        "origSpriteName=" .. tostring(origSpriteName),
        "spriteName=" .. tostring(moveProps.spriteName),
        "sprite=" .. tostring(spriteName(sprite)),
        "facing=" .. tostring(moveProps.facing),
        "cursorFacing=" .. tostring(moveProps.cursorFacing),
        "lmionFacing=" .. tostring(moveProps.lmionGarageFacing),
        "family=" .. tostring(moveProps.lmionGarageFamily),
        "part=" .. tostring(moveProps.lmionGaragePart),
        "isMultiSprite=" .. tostring(moveProps.isMultiSprite),
        "gridPos=" .. tostring(gridX) .. "," .. tostring(gridY),
        "gridAnchor=" .. tostring(spriteName(anchor)),
        "gridSize=" .. tostring(grid and grid:getWidth()) .. "x" .. tostring(grid and grid:getHeight()),
    }, " "))
end

local function traceLiveGrid(moveProps, square)
    local sprite = moveProps and moveProps.sprite or nil
    local grid = sprite and sprite:getSpriteGrid() or nil
    if grid == nil then
        trace("LIVE_GRID nil")
        return
    end

    local selfGridX = grid:getSpriteGridPosX(sprite)
    local selfGridY = grid:getSpriteGridPosY(sprite)
    local originX = square and square:getX() - selfGridX or nil
    local originY = square and square:getY() - selfGridY or nil
    local z = square and square:getZ() or nil

    trace("LIVE_GRID selfPos=" .. tostring(selfGridX) .. "," .. tostring(selfGridY)
        .. " origin=" .. tostring(originX) .. "," .. tostring(originY) .. "," .. tostring(z)
        .. " size=" .. tostring(grid:getWidth()) .. "x" .. tostring(grid:getHeight())
        .. " count=" .. tostring(grid:getSpriteCount()))

    for y = 0, grid:getHeight() - 1 do
        for x = 0, grid:getWidth() - 1 do
            local gridSprite = grid:getSprite(x, y)
            local worldX = originX and originX + x or nil
            local worldY = originY and originY + y or nil
            local segment = gridSprite and GarageDoor.SegmentsBySprite[gridSprite:getName()] or nil
            trace("LIVE_GRID_SLOT local=" .. tostring(x) .. "," .. tostring(y)
                .. " world=" .. tostring(worldX) .. "," .. tostring(worldY) .. "," .. tostring(z)
                .. " sprite=" .. tostring(spriteName(gridSprite))
                .. " enginePart=" .. tostring(segment and segment.partIndex))
        end
    end

    local sgrid = square and moveProps:getSpriteGridInfo(square, false) or nil
    if sgrid == nil then
        trace("LIVE_GRID_INFO nil for square=" .. squareText(square))
        return
    end

    for index, member in ipairs(sgrid) do
        trace("LIVE_GRID_INFO index=" .. tostring(index)
            .. " cacheXY=" .. tostring(member.x) .. "," .. tostring(member.y)
            .. " square=" .. squareText(member.square)
            .. " sprite=" .. tostring(member.sprite and member.sprite:getName()))
    end
end

--[[
The square passed by Moveables corresponds to `self.sprite` inside the current
SpriteGrid. Derive the grid's local 0,0 square first, exactly like vanilla does,
then map visual grid slots back to GarageDoor member identities.

This avoids using lmionGaragePart as a spatial offset. That value is engine
identity and is deliberately reversed relative to visual grid order in W.
]]
local function getPlacementSquares(moveProps, square)
    if not isGarageMoveProps(moveProps) or square == nil then
        return nil
    end

    local family = GarageDoor.Families[moveProps.lmionGarageFamily]
    local facing = getCurrentFacing(moveProps)
    local sprite = moveProps.sprite
    local grid = sprite and sprite:getSpriteGrid() or nil
    local order = family and family.gridPartOrder and family.gridPartOrder[facing] or nil

    if family == nil or facing == nil or grid == nil or order == nil then
        return nil
    end

    local gridX = grid:getSpriteGridPosX(sprite)
    local gridY = grid:getSpriteGridPosY(sprite)
    if gridX == nil or gridY == nil or gridX < 0 or gridY < 0 then
        return nil
    end

    local originX = square:getX() - gridX
    local originY = square:getY() - gridY
    local z = square:getZ()
    local squares = {}

    for slot, partIndex in ipairs(order) do
        local x = originX + (facing == "N" and slot - 1 or 0)
        local y = originY + (facing == "W" and slot - 1 or 0)
        local targetSquare = getCell():getGridSquare(x, y, z)
        if targetSquare == nil then
            return nil
        end

        squares[partIndex] = targetSquare
    end

    return squares
end

local function buildPlacementPlan(moveProps, character, square)
    local family = moveProps and GarageDoor.Families[moveProps.lmionGarageFamily] or nil
    local facing = getCurrentFacing(moveProps)
    local squares = getPlacementSquares(moveProps, square)
    if family == nil or facing == nil or squares == nil then
        return nil
    end

    local plan = {}
    for partIndex = 1, 3 do
        local part = family.parts[partIndex]
        local item, inventory = findInventoryItem(character, part and part.itemType)
        local targetSpriteName = part and part.faces and part.faces[facing] or nil
        if item == nil or inventory == nil or targetSpriteName == nil then
            return nil
        end

        plan[partIndex] = {
            item = item,
            inventory = inventory,
            square = squares[partIndex],
            spriteName = targetSpriteName,
        }
    end

    return plan
end

local function tracePlan(moveProps, plan)
    local family = moveProps and GarageDoor.Families[moveProps.lmionGarageFamily] or nil
    local facing = getCurrentFacing(moveProps)
    local order = family and family.gridPartOrder and family.gridPartOrder[facing] or nil

    trace("PLAN family=" .. tostring(moveProps and moveProps.lmionGarageFamily)
        .. " facing=" .. tostring(facing)
        .. " gridPartOrder=" .. tostring(order and table.concat(order, ",")))

    if plan == nil then
        trace("PLAN nil")
        return
    end

    for partIndex = 1, 3 do
        local entry = plan[partIndex]
        trace("PLAN_PART part=" .. tostring(partIndex)
            .. " targetSquare=" .. squareText(entry and entry.square)
            .. " targetSprite=" .. tostring(entry and entry.spriteName)
            .. " item={" .. itemText(entry and entry.item) .. "}")
    end
end

local function traceTargetSquares(plan, label)
    if plan == nil then
        return
    end

    for partIndex = 1, 3 do
        local square = plan[partIndex] and plan[partIndex].square or nil
        if square ~= nil then
            local objects = square:getSpecialObjects()
            trace(label .. " part=" .. tostring(partIndex)
                .. " square=" .. squareText(square)
                .. " specialObjectCount=" .. tostring(objects:size()))

            for i = 0, objects:size() - 1 do
                local object = objects:get(i)
                trace(label .. " part=" .. tostring(partIndex)
                    .. " objectIndex=" .. tostring(i)
                    .. " " .. objectText(object))
            end
        end
    end
end

local function traceFinalTopology(placed, familyId)
    for partIndex = 1, 3 do
        trace("PLACED_RESULT expectedPart=" .. tostring(partIndex) .. " " .. objectText(placed[partIndex]))
    end

    local source = placed[1] or placed[2] or placed[3]
    if source == nil then
        trace("FINAL_TOPOLOGY no placed source")
        return
    end

    local first = IsoDoor.getGarageDoorFirst(source)
    trace("FINAL_TOPOLOGY first=" .. objectText(first))

    local members = GarageDoor.getMembers(source, familyId)
    if members == nil then
        trace("FINAL_TOPOLOGY GarageDoor.getMembers=nil")
    else
        for partIndex = 1, 3 do
            trace("FINAL_TOPOLOGY member=" .. tostring(partIndex) .. " " .. objectText(members[partIndex].object))
        end
    end

    for partIndex = 1, 3 do
        local object = placed[partIndex]
        if object ~= nil then
            trace("FINAL_LINK part=" .. tostring(partIndex)
                .. " prev={" .. objectText(IsoDoor.getGarageDoorPrev(object)) .. "}"
                .. " next={" .. objectText(IsoDoor.getGarageDoorNext(object)) .. "}")
        end
    end
end

GarageDoor.getPlacementSquares = getPlacementSquares
GarageDoor.buildPlacementPlan = buildPlacementPlan

if Pickup._garageDoorPlacementPreviousCanPlaceMoveable == nil then
    Pickup._garageDoorPlacementPreviousCanPlaceMoveable = ISMoveableSpriteProps.canPlaceMoveable
end

ISMoveableSpriteProps.canPlaceMoveable = function(self, character, square, item)
    if not isGarageMoveProps(self) or not self.isMultiSprite then
        return Pickup._garageDoorPlacementPreviousCanPlaceMoveable(self, character, square, item)
    end

    local plan = buildPlacementPlan(self, character, square)
    if plan == nil then
        return false
    end

    for partIndex = 1, 3 do
        local entry = plan[partIndex]
        local moveProps = ISMoveableSpriteProps.new(entry.spriteName)
        if moveProps == nil or not moveProps.isMoveable then
            return false
        end

        local wasMultiSprite = moveProps.isMultiSprite
        moveProps.isMultiSprite = false
        local canPlace = moveProps:canPlaceMoveableInternal(character, entry.square, entry.item)
        moveProps.isMultiSprite = wasMultiSprite

        if not canPlace then
            return false
        end
    end

    return true
end

if Pickup._garageDoorPlacementPreviousPlaceMoveable == nil then
    Pickup._garageDoorPlacementPreviousPlaceMoveable = ISMoveableSpriteProps.placeMoveable
end

ISMoveableSpriteProps.placeMoveable = function(self, character, square, origSpriteName, forceAllow)
    if not isGarageMoveProps(self) or not self.isMultiSprite then
        return Pickup._garageDoorPlacementPreviousPlaceMoveable(self, character, square, origSpriteName, forceAllow)
    end

    trace("================ PLACE BEGIN ================")
    traceMoveProps("PLACE_CONTEXT", self, square, origSpriteName)
    trace("PLACE_FORCE_ALLOW=" .. tostring(forceAllow))
    traceLiveGrid(self, square)

    local plan = buildPlacementPlan(self, character, square)
    tracePlan(self, plan)
    traceTargetSquares(plan, "BEFORE_PLACE")

    if plan == nil then
        LMION.error("Pickup", "garage door placement plan is unavailable")
        trace("PLACE_ABORT plan=nil")
        trace("================ PLACE END ==================")
        return false
    end

    for partIndex = 1, 3 do
        local entry = plan[partIndex]
        local probeProps = ISMoveableSpriteProps.new(entry.spriteName)
        local wasMultiSprite = probeProps and probeProps.isMultiSprite or nil
        if probeProps ~= nil then
            probeProps.isMultiSprite = false
        end
        local canPlace = probeProps ~= nil
            and probeProps.isMoveable
            and probeProps:canPlaceMoveableInternal(character, entry.square, entry.item)
        if probeProps ~= nil then
            probeProps.isMultiSprite = wasMultiSprite
        end

        trace("CAN_PLACE_PART part=" .. tostring(partIndex)
            .. " result=" .. tostring(canPlace)
            .. " square=" .. squareText(entry.square)
            .. " sprite=" .. tostring(entry.spriteName)
            .. " probeFacing=" .. tostring(probeProps and probeProps.facing)
            .. " probePart=" .. tostring(probeProps and probeProps.lmionGaragePart))
    end

    local selectedPart = tonumber(self.lmionGaragePart) or 1
    if not forceAllow
        and not character:isMovablesCheat()
        and not ISMoveableDefinitions.cheat
        and not self:canPlaceMoveable(character, square, plan[selectedPart].item) then
        trace("PLACE_ABORT self:canPlaceMoveable=false selectedPart=" .. tostring(selectedPart))
        trace("================ PLACE END ==================")
        return false
    end

    local placed = {}
    for partIndex = 1, 3 do
        local entry = plan[partIndex]
        local moveProps = ISMoveableSpriteProps.new(entry.spriteName)
        if moveProps == nil or not moveProps.isMoveable then
            LMION.error("Pickup", "garage target move props missing for " .. tostring(entry.spriteName))
            trace("PLACE_ABORT missing moveProps part=" .. tostring(partIndex))
            trace("================ PLACE END ==================")
            return false
        end

        traceMoveProps("PLACE_PART_PROPS part=" .. tostring(partIndex), moveProps, entry.square, entry.spriteName)
        trace("PLACE_PART_INPUT part=" .. tostring(partIndex)
            .. " square=" .. squareText(entry.square)
            .. " sprite=" .. tostring(entry.spriteName)
            .. " item={" .. itemText(entry.item) .. "}")

        local wasMultiSprite = moveProps.isMultiSprite
        moveProps.isMultiSprite = false
        local object = moveProps:placeMoveableInternal(entry.square, entry.item, entry.spriteName)
        moveProps.isMultiSprite = wasMultiSprite

        trace("PLACE_PART_OUTPUT part=" .. tostring(partIndex) .. " " .. objectText(object))

        if object == nil then
            LMION.error("Pickup", "garage failed placing part " .. tostring(partIndex))
            trace("PLACE_ABORT placeMoveableInternal=nil part=" .. tostring(partIndex))
            trace("================ PLACE END ==================")
            return false
        end

        placed[partIndex] = object
    end

    traceTargetSquares(plan, "AFTER_PLACE")
    traceFinalTopology(placed, self.lmionGarageFamily)

    for partIndex = 1, 3 do
        local entry = plan[partIndex]
        trace("REMOVE_ITEM part=" .. tostring(partIndex) .. " item={" .. itemText(entry.item) .. "}")
        entry.inventory:Remove(entry.item)
        sendRemoveItemFromContainer(entry.inventory, entry.item)
    end

    if ISMoveableCursor ~= nil and ISMoveableCursor.clearCacheForAllPlayers ~= nil then
        ISMoveableCursor.clearCacheForAllPlayers()
    end

    trace("================ PLACE END ==================")
    return placed
end

return GarageDoor
