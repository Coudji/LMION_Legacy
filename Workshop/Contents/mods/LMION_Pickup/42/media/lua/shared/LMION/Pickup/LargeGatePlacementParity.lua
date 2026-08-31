local LMION = require "LMION/API"
local LargeGatePickup = require "LMION/Pickup/LargeGatePickup"
local LargeGatePlacement = require "LMION/Pickup/LargeGatePlacement"

local LargeGatePlacementParity = {}

local installed = false


local function otherLeaf(leaf)
    return leaf == "A" and "B" or "A"
end


local function keyForSquare(square)
    if square == nil then
        return nil
    end

    return tostring(square:getX())
        .. ":"
        .. tostring(square:getY())
        .. ":"
        .. tostring(square:getZ())
end


local function sameFootprint(left, right)
    if type(left) ~= "table" or type(right) ~= "table" then
        return false
    end

    local leftKeys = {}
    local rightKeys = {}

    for partIndex = 1, 2 do
        local leftKey = keyForSquare(left[partIndex])
        local rightKey = keyForSquare(right[partIndex])
        if leftKey == nil or rightKey == nil then
            return false
        end
        leftKeys[leftKey] = true
        rightKeys[rightKey] = true
    end

    for key in pairs(leftKeys) do
        if not rightKeys[key] then
            return false
        end
    end

    for key in pairs(rightKeys) do
        if not leftKeys[key] then
            return false
        end
    end

    return true
end


local function getClosedSquares(runtime, anchor, facing, leaf)
    local topology = runtime and runtime.topology or nil
    local layout = topology
        and topology.layout
        and topology.layout[facing]
        and topology.layout[facing].closed
        or nil
    local indices = topology
        and topology.leaves
        and topology.leaves[leaf]
        and topology.leaves[leaf].indices
        and topology.leaves[leaf].indices[facing]
        or nil

    if layout == nil or indices == nil or anchor == nil then
        return nil
    end

    local squares = {}

    for partIndex = 1, 2 do
        local logicalIndex = tonumber(indices[partIndex])
        local offset = logicalIndex and layout[logicalIndex] or nil
        if offset == nil then
            return nil
        end

        local square = getCell():getGridSquare(
            anchor.x + tonumber(offset[1]),
            anchor.y + tonumber(offset[2]),
            anchor.z
        )
        if square == nil then
            return nil
        end

        squares[partIndex] = square
    end

    return squares
end


local function getAnchorForSegment(runtime, object, segment)
    local square = object and object:getSquare() or nil
    local state = segment and segment.isOpen and "open" or "closed"
    local layout = runtime
        and runtime.topology
        and runtime.topology.layout
        and runtime.topology.layout[segment.facing]
        and runtime.topology.layout[segment.facing][state]
        or nil
    local offset = layout and layout[segment.logicalIndex] or nil

    if square == nil or offset == nil then
        return nil
    end

    return {
        x = square:getX() - tonumber(offset[1]),
        y = square:getY() - tonumber(offset[2]),
        z = square:getZ(),
    }
end


local function hasFacingConflict(plan)
    if plan == nil
        or plan.runtime == nil
        or plan.preview == nil
        or plan.leaf == nil
        or plan.facing == nil
    then
        return false
    end

    local wantedPartner = otherLeaf(plan.leaf)
    local previewSquares = {
        plan.preview[1] and plan.preview[1].square,
        plan.preview[2] and plan.preview[2].square,
    }

    if previewSquares[1] == nil or previewSquares[2] == nil then
        return false
    end

    local minX = math.min(
        previewSquares[1]:getX(),
        previewSquares[2]:getX()
    ) - 4
    local maxX = math.max(
        previewSquares[1]:getX(),
        previewSquares[2]:getX()
    ) + 4
    local minY = math.min(
        previewSquares[1]:getY(),
        previewSquares[2]:getY()
    ) - 4
    local maxY = math.max(
        previewSquares[1]:getY(),
        previewSquares[2]:getY()
    ) + 4
    local z = previewSquares[1]:getZ()

    for x = minX, maxX do
        for y = minY, maxY do
            local square = getCell():getGridSquare(x, y, z)
            local specialObjects = square and square:getSpecialObjects() or nil

            if specialObjects ~= nil then
                for index = 0, specialObjects:size() - 1 do
                    local object = specialObjects:get(index)
                    if LMION.isDoorObject(object) then
                        local sprite = object:getSprite()
                        local spriteName = sprite and sprite:getName() or nil
                        local segment = spriteName
                            and LargeGatePickup.getSegment(spriteName)
                            or nil

                        if segment ~= nil
                            and segment.definitionId == plan.runtime.definitionId
                            and segment.leaf == wantedPartner
                        then
                            local anchor = getAnchorForSegment(
                                plan.runtime,
                                object,
                                segment
                            )
                            local missingClosed = getClosedSquares(
                                plan.runtime,
                                anchor,
                                segment.facing,
                                plan.leaf
                            )

                            if sameFootprint(previewSquares, missingClosed) then
                                return segment.facing ~= plan.facing
                            end
                        end
                    end
                end
            end
        end
    end

    return false
end


local function addClosedPreview(plan)
    if plan == nil or plan.runtime == nil then
        return plan
    end

    local squares = getClosedSquares(
        plan.runtime,
        plan.anchor,
        plan.facing,
        plan.leaf
    )
    if squares == nil then
        plan.valid = false
        return plan
    end

    plan.preview = {}

    for partIndex = 1, 2 do
        plan.preview[partIndex] = {
            square = squares[partIndex],
            sprite = LargeGatePickup.getPartSprite(
                plan.runtime.definitionId,
                plan.facing,
                plan.leaf,
                partIndex,
                false
            ),
            valid = plan[partIndex] and plan[partIndex].valid == true,
        }
    end

    if hasFacingConflict(plan) then
        plan.valid = false
        plan.orientationConflict = true
    end

    return plan
end


function LargeGatePlacementParity.install()
    if installed then
        return
    end

    local previousGetPreview = LargeGatePlacement.getPreview
    LargeGatePlacement.getPreview = function(character, square, item, facing)
        return addClosedPreview(
            previousGetPreview(character, square, item, facing)
        )
    end

    require "Moveables/ISMoveableSpriteProps"

    local previousCanPlace = ISMoveableSpriteProps.canPlaceMoveable
    ISMoveableSpriteProps.canPlaceMoveable = function(
        self,
        character,
        square,
        item
    )
        if self ~= nil and self.lmionLargeGateDefinitionId ~= nil then
            local plan = LargeGatePlacement.getPreview(
                character,
                square,
                item,
                self.lmionLargeGateFacing
            )
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
        if self ~= nil and self.lmionLargeGateDefinitionId ~= nil then
            local plan = LargeGatePlacement.getPreview(
                character,
                square,
                nil,
                self.lmionLargeGateFacing
            )
            if plan == nil or not plan.valid then
                return false
            end
        end

        return previousPlace(
            self,
            character,
            square,
            origSpriteName,
            forceAllow
        )
    end

    installed = true
end


return LargeGatePlacementParity
