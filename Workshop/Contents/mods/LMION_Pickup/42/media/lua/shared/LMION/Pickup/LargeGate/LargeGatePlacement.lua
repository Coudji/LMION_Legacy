local LMION = require "LMION/API"
local LargeGatePickup = require "LMION/Pickup/LargeGatePickup"
local TransportState = require "LMION/Pickup/TransportState"

local LargeGatePlacement = {}

local installed = false


local function getRuntime(moveProps)
    local definitionId = moveProps and moveProps.lmionLargeGateDefinitionId or nil
    return definitionId and LargeGatePickup.getRuntime(definitionId) or nil
end


local function otherLeaf(leaf)
    return leaf == "A" and "B" or "A"
end


local function getSquare(anchor, offset)
    if anchor == nil or type(offset) ~= "table" then
        return nil
    end

    return getCell():getGridSquare(
        anchor.x + tonumber(offset[1]),
        anchor.y + tonumber(offset[2]),
        anchor.z
    )
end


local function getObjectSegment(object)
    if object == nil or not LMION.isDoorObject(object) then
        return nil
    end

    local sprite = object:getSprite()
    local segment = sprite and LargeGatePickup.getSegment(sprite:getName()) or nil
    if segment == nil or IsoDoor == nil or IsoDoor.getDoubleDoorIndex == nil then
        return nil
    end

    local ok, logicalIndex = pcall(IsoDoor.getDoubleDoorIndex, object)
    logicalIndex = ok and tonumber(logicalIndex) or nil

    return logicalIndex == segment.logicalIndex and segment or nil
end


local function findSegmentObject(runtime, square, facing, leaf, partIndex, isOpen)
    if runtime == nil or square == nil then
        return nil
    end

    local expectedSprite = LargeGatePickup.getPartSprite(
        runtime.definitionId,
        facing,
        leaf,
        partIndex,
        isOpen
    )
    local specialObjects = square:getSpecialObjects()

    for index = 0, specialObjects:size() - 1 do
        local object = specialObjects:get(index)
        local segment = getObjectSegment(object)
        local sprite = object:getSprite()

        if segment ~= nil
            and segment.definitionId == runtime.definitionId
            and segment.facing == facing
            and segment.leaf == leaf
            and segment.partIndex == partIndex
            and segment.isOpen == isOpen
            and sprite ~= nil
            and sprite:getName() == expectedSprite
        then
            return object
        end
    end

    return nil
end


local function matchesLeaf(runtime, anchor, facing, leaf, state)
    local isOpen = state == "open"
    local layout = runtime.topology.layout[facing][state]
    local indices = runtime.topology.leaves[leaf].indices[facing]

    for partIndex = 1, 2 do
        local logicalIndex = tonumber(indices[partIndex])
        if findSegmentObject(
            runtime,
            getSquare(anchor, layout[logicalIndex]),
            facing,
            leaf,
            partIndex,
            isOpen
        ) == nil then
            return false
        end
    end

    return true
end


local function hasLeafFragment(runtime, anchor, facing, leaf)
    for _, state in ipairs({ "closed", "open" }) do
        local layout = runtime.topology.layout[facing][state]
        local indices = runtime.topology.leaves[leaf].indices[facing]

        for partIndex = 1, 2 do
            local logicalIndex = tonumber(indices[partIndex])
            local square = getSquare(anchor, layout[logicalIndex])
            local specialObjects = square and square:getSpecialObjects() or nil

            if specialObjects ~= nil then
                for index = 0, specialObjects:size() - 1 do
                    local segment = getObjectSegment(specialObjects:get(index))
                    if segment ~= nil
                        and segment.definitionId == runtime.definitionId
                        and segment.facing == facing
                        and segment.leaf == leaf
                    then
                        return true
                    end
                end
            end
        end
    end

    return false
end


local function getPartnerState(runtime, anchor, facing, leaf)
    local partner = otherLeaf(leaf)

    if matchesLeaf(runtime, anchor, facing, partner, "closed") then
        return "closed"
    end

    if matchesLeaf(runtime, anchor, facing, partner, "open") then
        return "open"
    end

    return hasLeafFragment(runtime, anchor, facing, partner)
        and "incoherent"
        or "none"
end


local function itemMatches(item, definitionId, leaf, partIndex)
    local identity = LargeGatePickup.getParcelIdentity(item)

    return identity ~= nil
        and identity.definitionId == definitionId
        and identity.leaf == leaf
        and identity.partIndex == partIndex
end


local function findParcel(character, definitionId, leaf, partIndex, preferred)
    if preferred ~= nil and itemMatches(preferred, definitionId, leaf, partIndex) then
        local container = preferred:getContainer()
        if container ~= nil then
            return preferred, container
        end

        local worldItem = preferred.getWorldItem ~= nil
            and preferred:getWorldItem()
            or nil
        if worldItem ~= nil and worldItem:getSquare() ~= nil then
            return preferred, "floor"
        end
    end

    local inventory = character and character:getInventory() or nil
    local items = inventory and inventory:getItems() or nil

    if items ~= nil then
        for index = 0, items:size() - 1 do
            local item = items:get(index)
            if itemMatches(item, definitionId, leaf, partIndex) then
                return item, inventory
            end
        end
    end

    local playerSquare = character and character:getSquare() or nil
    if playerSquare == nil then
        return nil, nil
    end

    local radius = ISMoveableSpriteProps.multiSpriteFloorRadius or 3
    local z = playerSquare:getZ()

    for x = playerSquare:getX() - radius, playerSquare:getX() + radius do
        for y = playerSquare:getY() - radius, playerSquare:getY() + radius do
            local square = getCell():getGridSquare(x, y, z)
            local worldObjects = square and square:getWorldObjects() or nil

            if worldObjects ~= nil then
                for index = 0, worldObjects:size() - 1 do
                    local worldObject = worldObjects:get(index)
                    if instanceof(worldObject, "IsoWorldInventoryObject") then
                        local item = worldObject:getItem()
                        if itemMatches(item, definitionId, leaf, partIndex) then
                            return item, "floor"
                        end
                    end
                end
            end
        end
    end

    return nil, nil
end


local function buildPlan(moveProps, character, square, item)
    local runtime = getRuntime(moveProps)
    local facing = moveProps and moveProps.lmionLargeGateFacing or nil
    local leaf = moveProps and moveProps.lmionLargeGateLeaf or nil
    local selectedPart = moveProps and moveProps.lmionLargeGatePart or nil

    if runtime == nil
        or square == nil
        or (facing ~= "N" and facing ~= "W")
        or (leaf ~= "A" and leaf ~= "B")
        or (selectedPart ~= 1 and selectedPart ~= 2)
    then
        return nil
    end

    local indices = runtime.topology.leaves[leaf].indices[facing]
    local closedLayout = runtime.topology.layout[facing].closed
    local selectedLogicalIndex = tonumber(indices[selectedPart])
    local selectedOffset = closedLayout[selectedLogicalIndex]

    if type(selectedOffset) ~= "table" then
        return nil
    end

    local anchor = {
        x = square:getX() - tonumber(selectedOffset[1]),
        y = square:getY() - tonumber(selectedOffset[2]),
        z = square:getZ(),
    }
    local partnerState = getPartnerState(runtime, anchor, facing, leaf)
    local targetState = partnerState == "open" and "open" or "closed"
    local layout = runtime.topology.layout[facing][targetState]

    local plan = {
        runtime = runtime,
        facing = facing,
        leaf = leaf,
        selectedPart = selectedPart,
        anchor = anchor,
        partnerState = partnerState,
        targetState = targetState,
        isOpen = targetState == "open",
        valid = partnerState ~= "incoherent",
    }

    for partIndex = 1, 2 do
        local logicalIndex = tonumber(indices[partIndex])
        local targetSquare = getSquare(anchor, layout[logicalIndex])
        local parcel, source = findParcel(
            character,
            runtime.definitionId,
            leaf,
            partIndex,
            partIndex == selectedPart and item or nil
        )
        local closedSprite = LargeGatePickup.getPartSprite(
            runtime.definitionId,
            facing,
            leaf,
            partIndex,
            false
        )
        local displaySprite = LargeGatePickup.getPartSprite(
            runtime.definitionId,
            facing,
            leaf,
            partIndex,
            plan.isOpen
        )
        local partProps = closedSprite and ISMoveableSpriteProps.new(closedSprite) or nil

        local entryValid = targetSquare ~= nil
            and parcel ~= nil
            and source ~= nil
            and partProps ~= nil
            and partProps.isMoveable
            and partProps:canPlaceMoveableInternal(
                character,
                targetSquare,
                parcel
            )
            and (not plan.isOpen or partProps:isFreeTile(targetSquare))
            and LMION.canPlaceDoorAt(targetSquare, facing, false, nil)

        plan[partIndex] = {
            square = targetSquare,
            item = parcel,
            source = source,
            closedSprite = closedSprite,
            displaySprite = displaySprite,
            valid = entryValid == true,
        }

        if not entryValid then
            plan.valid = false
        end
    end

    return plan
end


local function getMovePropsForParcel(item, facing)
    local identity = LargeGatePickup.getParcelIdentity(item)
    if identity == nil or (facing ~= "N" and facing ~= "W") then
        return nil
    end

    local spriteName = LargeGatePickup.getPartSprite(
        identity.definitionId,
        facing,
        identity.leaf,
        identity.partIndex,
        false
    )
    local moveProps = spriteName and ISMoveableSpriteProps.new(spriteName) or nil

    if moveProps == nil or getRuntime(moveProps) == nil then
        return nil
    end

    return moveProps
end


local function consumeParcel(item, source)
    if source == "floor" then
        local worldItem = item and item:getWorldItem() or nil
        local square = worldItem and worldItem:getSquare() or nil
        if worldItem ~= nil and square ~= nil then
            square:transmitRemoveItemFromSquare(worldItem)
            square:removeWorldObject(worldItem)
            item:setWorldItem(nil)
        end
        return
    end

    if item ~= nil and source ~= nil then
        source:Remove(item)
        sendRemoveItemFromContainer(source, item)
    end
end


local function placePlan(plan)
    if plan == nil or not plan.valid then
        return false
    end

    for partIndex = 1, 2 do
        local entry = plan[partIndex]
        local moveProps = ISMoveableSpriteProps.new(entry.closedSprite)
        if moveProps == nil then
            return false
        end

        local wasMultiSprite = moveProps.isMultiSprite
        moveProps.isMultiSprite = false
        local object = moveProps:placeMoveableInternal(
            entry.square,
            entry.item,
            entry.closedSprite
        )
        moveProps.isMultiSprite = wasMultiSprite

        if object == nil then
            return false
        end

        local door = LMION.finalizePlacedLargeGatePart(
            object,
            plan.runtime.definition,
            plan.facing,
            plan.leaf,
            partIndex,
            plan.isOpen
        )
        if door == nil then
            return false
        end

        TransportState.clearFromObject(door)
        LMION.restoreDoorState(door, TransportState.read(entry.item))

        if isServer() then
            door:transmitCompleteItemToClients()
        end
    end

    for partIndex = 1, 2 do
        local entry = plan[partIndex]
        consumeParcel(entry.item, entry.source)
        buildUtil.setHaveConstruction(entry.square, true)
    end

    if ISMoveableCursor ~= nil
        and ISMoveableCursor.clearCacheForAllPlayers ~= nil
    then
        ISMoveableCursor.clearCacheForAllPlayers()
    end

    return true
end


function LargeGatePlacement.getMoveProps(item, facing)
    return getMovePropsForParcel(item, facing)
end


function LargeGatePlacement.getPreview(character, square, item, facing)
    local moveProps = getMovePropsForParcel(item, facing)
    if moveProps == nil then
        return nil
    end

    return buildPlan(moveProps, character, square, item)
end


function LargeGatePlacement.canPlaceParcel(character, square, item, facing)
    local plan = LargeGatePlacement.getPreview(
        character,
        square,
        item,
        facing
    )

    return plan ~= nil and plan.valid == true
end


function LargeGatePlacement.placeParcel(character, square, item, facing)
    local plan = LargeGatePlacement.getPreview(
        character,
        square,
        item,
        facing
    )

    return placePlan(plan)
end


local function isGridAnchor(moveProps)
    if getRuntime(moveProps) == nil or not moveProps.isMultiSprite then
        return false
    end

    local sprite = moveProps.sprite
    local grid = sprite and sprite:getSpriteGrid() or nil
    return grid ~= nil and grid:getAnchorSprite() == sprite
end


local function getLeafAnchorFaces(moveProps)
    local runtime = getRuntime(moveProps)
    local leaf = moveProps and moveProps.lmionLargeGateLeaf or nil
    if runtime == nil or (leaf ~= "A" and leaf ~= "B") then
        return nil
    end

    return {
        N = LargeGatePickup.getPartSprite(
            runtime.definitionId,
            "N",
            leaf,
            1,
            false
        ),
        W = LargeGatePickup.getPartSprite(
            runtime.definitionId,
            "W",
            leaf,
            1,
            false
        ),
    }
end


local function installHooks()
    require "Moveables/ISMoveableSpriteProps"

    local previousHasFaces = ISMoveableSpriteProps.hasFaces
    ISMoveableSpriteProps.hasFaces = function(self)
        if getRuntime(self) ~= nil then
            return true
        end
        return previousHasFaces(self)
    end

    local previousGetFaces = ISMoveableSpriteProps.getFaces
    ISMoveableSpriteProps.getFaces = function(self)
        local runtime = getRuntime(self)
        if runtime ~= nil then
            if isGridAnchor(self) then
                return getLeafAnchorFaces(self) or {}
            end

            return {
                N = LargeGatePickup.getPartSprite(
                    runtime.definitionId,
                    "N",
                    self.lmionLargeGateLeaf,
                    self.lmionLargeGatePart,
                    false
                ),
                W = LargeGatePickup.getPartSprite(
                    runtime.definitionId,
                    "W",
                    self.lmionLargeGateLeaf,
                    self.lmionLargeGatePart,
                    false
                ),
            }
        end
        return previousGetFaces(self)
    end

    local previousGetIndexedFaces = ISMoveableSpriteProps.getIndexedFaces
    ISMoveableSpriteProps.getIndexedFaces = function(self)
        local runtime = getRuntime(self)
        if runtime ~= nil then
            local faces = self:getFaces()
            return { faces.N, faces.W, faces.N, faces.W }
        end
        return previousGetIndexedFaces(self)
    end

    local previousGetFaceIndex = ISMoveableSpriteProps.getFaceIndex
    ISMoveableSpriteProps.getFaceIndex = function(self)
        if getRuntime(self) ~= nil then
            if self.lmionLargeGateFacing == "N" then
                return 1
            end
            if self.lmionLargeGateFacing == "W" then
                return 2
            end
            return -1
        end
        return previousGetFaceIndex(self)
    end

    local previousCanPlace = ISMoveableSpriteProps.canPlaceMoveable
    ISMoveableSpriteProps.canPlaceMoveable = function(
        self,
        character,
        square,
        item
    )
        if getRuntime(self) ~= nil then
            local plan = buildPlan(self, character, square, item)
            return plan ~= nil and plan.valid == true
        end
        return previousCanPlace(self, character, square, item)
    end

    local previousPlace = ISMoveableSpriteProps.placeMoveable
    ISMoveableSpriteProps.placeMoveable = function(
        self,
        character,
        square,
        origSpriteName,
        forceAllow
    )
        local runtime = getRuntime(self)
        if runtime == nil then
            return previousPlace(
                self,
                character,
                square,
                origSpriteName,
                forceAllow
            )
        end

        local selectedItem = findParcel(
            character,
            runtime.definitionId,
            self.lmionLargeGateLeaf,
            self.lmionLargeGatePart,
            nil
        )
        local plan = buildPlan(self, character, square, selectedItem)

        return placePlan(plan)
    end
end


function LargeGatePlacement.install()
    if installed then
        return
    end

    installHooks()
    installed = true
end


return LargeGatePlacement
