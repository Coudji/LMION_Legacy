require "Moveables/ISMoveableSpriteProps"
require "LMION/Pickup/LargeGateProfiles"

local Pickup = LMION.Pickup

local leafSpecs = {
    doubleWireLeft = {
        visualPartIndex = 1,
        indices = {
            N = {1, 2},
            W = {4, 3},
        },
        parts = {
            [1] = {
                itemType = "Base.LMION_DoubleWireGateLeft_Part1",
                faces = {
                    N = "fixtures_doors_fences_01_66",
                    W = "fixtures_doors_fences_01_65",
                },
            },
            [2] = {
                itemType = "Base.LMION_DoubleWireGateLeft_Part2",
                faces = {
                    N = "fixtures_doors_fences_01_67",
                    W = "fixtures_doors_fences_01_64",
                },
            },
        },
    },
    doubleWireRight = {
        visualPartIndex = 2,
        indices = {
            N = {3, 4},
            W = {2, 1},
        },
        parts = {
            [1] = {
                itemType = "Base.LMION_DoubleWireGateRight_Part1",
                faces = {
                    N = "fixtures_doors_fences_01_74",
                    W = "fixtures_doors_fences_01_73",
                },
            },
            [2] = {
                itemType = "Base.LMION_DoubleWireGateRight_Part2",
                faces = {
                    N = "fixtures_doors_fences_01_75",
                    W = "fixtures_doors_fences_01_72",
                },
            },
        },
    },
    doubleFenceLeft = {
        visualPartIndex = 1,
        indices = {
            N = {1, 2},
            W = {4, 3},
        },
        parts = {
            [1] = {
                itemType = "Base.LMION_DoubleFenceGateLeft_Part1",
                faces = {
                    N = "fixtures_doors_fences_01_82",
                    W = "fixtures_doors_fences_01_81",
                },
            },
            [2] = {
                itemType = "Base.LMION_DoubleFenceGateLeft_Part2",
                faces = {
                    N = "fixtures_doors_fences_01_83",
                    W = "fixtures_doors_fences_01_80",
                },
            },
        },
    },
    doubleFenceRight = {
        visualPartIndex = 2,
        indices = {
            N = {3, 4},
            W = {2, 1},
        },
        parts = {
            [1] = {
                itemType = "Base.LMION_DoubleFenceGateRight_Part1",
                faces = {
                    N = "fixtures_doors_fences_01_90",
                    W = "fixtures_doors_fences_01_89",
                },
            },
            [2] = {
                itemType = "Base.LMION_DoubleFenceGateRight_Part2",
                faces = {
                    N = "fixtures_doors_fences_01_91",
                    W = "fixtures_doors_fences_01_88",
                },
            },
        },
    },
}

Pickup.LargeGateLeafSpecs = leafSpecs

local segmentBySprite = {}
for leafId, leaf in pairs(leafSpecs) do
    for partIndex, part in pairs(leaf.parts) do
        for facing, spriteName in pairs(part.faces) do
            segmentBySprite[spriteName] = {
                leafId = leafId,
                partIndex = partIndex,
                facing = facing,
                itemType = part.itemType,
                faces = part.faces,
            }
        end
    end
end

local gridFacingSpecs = {
    N = {
        width = 2,
        height = 1,
        partOrder = {1, 2},
    },
    W = {
        width = 1,
        height = 2,
        partOrder = {1, 2},
    },
}

Pickup._largeGateOriginalSpriteGrids = Pickup._largeGateOriginalSpriteGrids or {}
Pickup.LargeGateRuntimeSpriteGrids = {}

local function installRuntimeSpriteGrid(leafId, facing)
    local leaf = leafSpecs[leafId]
    local gridSpec = gridFacingSpecs[facing]
    if leaf == nil or gridSpec == nil or IsoSpriteGrid == nil or IsoSpriteGrid.new == nil then
        return false
    end

    local grid = IsoSpriteGrid.new(gridSpec.width, gridSpec.height)
    if grid == nil then
        return false
    end

    local members = {}
    for position, partIndex in ipairs(gridSpec.partOrder) do
        local part = leaf.parts[partIndex]
        local spriteName = part and part.faces[facing] or nil
        local sprite = spriteName and getSprite(spriteName) or nil
        if sprite == nil then
            return false
        end

        local x = gridSpec.width > 1 and position - 1 or 0
        local y = gridSpec.height > 1 and position - 1 or 0
        grid:setSprite(x, y, sprite)
        members[position] = {
            spriteName = spriteName,
            sprite = sprite,
        }
    end

    if not grid:validate() then
        return false
    end

    for _, member in ipairs(members) do
        if Pickup._largeGateOriginalSpriteGrids[member.spriteName] == nil then
            Pickup._largeGateOriginalSpriteGrids[member.spriteName] = member.sprite:getSpriteGrid() or false
        end
        member.sprite:setSpriteGrid(grid)
    end

    Pickup.LargeGateRuntimeSpriteGrids[leafId .. ":" .. facing] = grid
    return true
end

local function installAllRuntimeSpriteGrids(reason)
    Pickup.LargeGateRuntimeSpriteGrids = {}

    local installedGridCount = 0
    local expectedGridCount = 0
    for leafId, _ in pairs(leafSpecs) do
        expectedGridCount = expectedGridCount + 2
        if installRuntimeSpriteGrid(leafId, "N") then
            installedGridCount = installedGridCount + 1
        end
        if installRuntimeSpriteGrid(leafId, "W") then
            installedGridCount = installedGridCount + 1
        end
    end

    local suffix = reason and (" (" .. tostring(reason) .. ")") or ""
    if installedGridCount == expectedGridCount then
        LMION.log("Pickup", "installed large-gate runtime sprite grids" .. suffix)
        return true
    end

    LMION.error(
        "Pickup",
        "failed to install all large-gate runtime sprite grids: "
            .. tostring(installedGridCount)
            .. "/"
            .. tostring(expectedGridCount)
            .. suffix
    )
    return false
end

Pickup.installLargeGateRuntimeSpriteGrids = installAllRuntimeSpriteGrids

if Events ~= nil and Events.OnLoadedTileDefinitions ~= nil then
    if not Pickup._largeGateRuntimeSpriteGridHookInstalled then
        Events.OnLoadedTileDefinitions.Add(function()
            if Pickup.installLargeGateRuntimeSpriteGrids ~= nil then
                Pickup.installLargeGateRuntimeSpriteGrids("OnLoadedTileDefinitions")
            end
        end)
        Pickup._largeGateRuntimeSpriteGridHookInstalled = true
    end
end

installAllRuntimeSpriteGrids("lua-load")

local function getDoubleDoorIndex(object)
    if object == nil or IsoDoor == nil or IsoDoor.getDoubleDoorIndex == nil then
        return nil
    end

    local ok, value = pcall(IsoDoor.getDoubleDoorIndex, object)
    if not ok then
        return nil
    end

    value = tonumber(value)
    if value == nil or value < 1 or value > 4 then
        return nil
    end

    return value
end

local function getDoubleDoorObject(source, index)
    if source == nil or IsoDoor == nil or IsoDoor.getDoubleDoorObject == nil then
        return nil
    end

    local ok, value = pcall(IsoDoor.getDoubleDoorObject, source, index)
    if not ok then
        return nil
    end

    return value
end

local function getLeafMembers(source, leafId)
    local leaf = leafSpecs[leafId]
    if leaf == nil or source == nil then
        return nil
    end

    local sourceSprite = source:getSprite()
    local sourceSpriteName = sourceSprite and sourceSprite:getName() or nil
    local sourceSegment = sourceSpriteName and segmentBySprite[sourceSpriteName] or nil
    if sourceSegment == nil or sourceSegment.leafId ~= leafId then
        return nil
    end

    local facing = sourceSegment.facing
    local logicalIndices = leaf.indices[facing]
    if logicalIndices == nil then
        return nil
    end

    local sourceIndex = getDoubleDoorIndex(source)
    if sourceIndex == nil then
        return nil
    end

    local members = {}
    for partIndex, logicalIndex in ipairs(logicalIndices) do
        local object = sourceIndex == logicalIndex and source or getDoubleDoorObject(source, logicalIndex)
        if object == nil or not instanceof(object, "IsoDoor") then
            return nil
        end

        local sprite = object:getSprite()
        local spriteName = sprite and sprite:getName() or nil
        local segment = spriteName and segmentBySprite[spriteName] or nil
        if segment == nil
            or segment.leafId ~= leafId
            or segment.partIndex ~= partIndex
            or segment.facing ~= facing then
            return nil
        end

        members[partIndex] = {
            object = object,
            square = object:getSquare(),
            spriteName = spriteName,
        }
    end

    return members
end

local function setParcelIdentity(moveProps, segment)
    if moveProps == nil or segment == nil then
        return
    end

    moveProps.customItem = segment.itemType
    moveProps.lmionLargeGateLeaf = segment.leafId
    moveProps.lmionLargeGatePart = segment.partIndex
    moveProps.lmionDoorFaces = segment.faces
    moveProps.lmionDoorFacing = segment.facing
    moveProps.facing = segment.facing
    moveProps.rawWeight = 120
    moveProps.weight = 12

    if ScriptManager ~= nil and ScriptManager.instance ~= nil then
        local scriptItem = ScriptManager.instance:FindItem(segment.itemType)
        if scriptItem ~= nil then
            moveProps.name = scriptItem:getDisplayName()
        end
    end
end

local function findInventoryItem(character, fullType)
    if character == nil or fullType == nil then
        return nil
    end

    local inventory = character:getInventory()
    if inventory == nil then
        return nil
    end

    local items = inventory:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item ~= nil and item:getFullType() == fullType then
            return item, inventory
        end
    end

    return nil
end

local function isLargeGateMoveProps(moveProps)
    return moveProps ~= nil
        and moveProps.lmionLargeGateLeaf ~= nil
        and moveProps.lmionLargeGatePart ~= nil
        and moveProps.lmionDoorFaces ~= nil
end

if Pickup._largeGateOriginalMoveableSpritePropsNew == nil then
    Pickup._largeGateOriginalMoveableSpritePropsNew = ISMoveableSpriteProps.new
end

ISMoveableSpriteProps.new = function(sprite)
    local moveProps = Pickup._largeGateOriginalMoveableSpritePropsNew(sprite)

    local resolved = sprite
    if type(resolved) == "string" then
        resolved = getSprite(resolved)
    end

    local spriteName = resolved and resolved:getName() or nil
    local segment = spriteName and segmentBySprite[spriteName] or nil
    if segment ~= nil then
        setParcelIdentity(moveProps, segment)
    end

    return moveProps
end

if Pickup._largeGateOriginalGetFaces == nil then
    Pickup._largeGateOriginalGetFaces = ISMoveableSpriteProps.getFaces
end

ISMoveableSpriteProps.getFaces = function(self)
    if isLargeGateMoveProps(self) then
        return {
            N = self.lmionDoorFaces.N,
            W = self.lmionDoorFaces.W,
        }
    end

    return Pickup._largeGateOriginalGetFaces(self)
end

if Pickup._largeGateOriginalHasFaces == nil then
    Pickup._largeGateOriginalHasFaces = ISMoveableSpriteProps.hasFaces
end

ISMoveableSpriteProps.hasFaces = function(self)
    if isLargeGateMoveProps(self) then
        local faces = self:getFaces()
        return faces.N ~= nil and faces.W ~= nil
    end

    return Pickup._largeGateOriginalHasFaces(self)
end

if Pickup._largeGateOriginalGetIndexedFaces == nil then
    Pickup._largeGateOriginalGetIndexedFaces = ISMoveableSpriteProps.getIndexedFaces
end

ISMoveableSpriteProps.getIndexedFaces = function(self)
    if isLargeGateMoveProps(self) then
        local faces = self:getFaces()
        local n = faces.N
        local w = faces.W
        return {n, w, n, w}
    end

    return Pickup._largeGateOriginalGetIndexedFaces(self)
end

if Pickup._largeGateOriginalGetFaceIndex == nil then
    Pickup._largeGateOriginalGetFaceIndex = ISMoveableSpriteProps.getFaceIndex
end

ISMoveableSpriteProps.getFaceIndex = function(self)
    if isLargeGateMoveProps(self) then
        if self.lmionDoorFacing == "N" then
            return 1
        end
        if self.lmionDoorFacing == "W" then
            return 2
        end
        return -1
    end

    return Pickup._largeGateOriginalGetFaceIndex(self)
end

if Pickup._largeGateOriginalFindInInventoryMultiSprite == nil then
    Pickup._largeGateOriginalFindInInventoryMultiSprite = ISMoveableSpriteProps.findInInventoryMultiSprite
end

ISMoveableSpriteProps.findInInventoryMultiSprite = function(self, character, requestedName)
    if isLargeGateMoveProps(self) then
        local gridIndex = tonumber(string.match(requestedName or "", "%((%d+)/2%)$"))
        local leaf = leafSpecs[self.lmionLargeGateLeaf]
        local part = leaf and gridIndex and leaf.parts[gridIndex] or nil
        if part ~= nil then
            return findInventoryItem(character, part.itemType)
        end
        return nil
    end

    return Pickup._largeGateOriginalFindInInventoryMultiSprite(self, character, requestedName)
end

if Pickup._largeGateOriginalCanPickUpMoveable == nil then
    Pickup._largeGateOriginalCanPickUpMoveable = ISMoveableSpriteProps.canPickUpMoveable
end

ISMoveableSpriteProps.canPickUpMoveable = function(self, character, square, object)
    if self == nil or self.lmionLargeGateLeaf == nil then
        return Pickup._largeGateOriginalCanPickUpMoveable(self, character, square, object)
    end

    local selected = object
    if selected == nil and square ~= nil then
        selected = self:findOnSquare(square, self.spriteName)
    end

    if selected == nil then
        return false
    end

    local wasMultiSprite = self.isMultiSprite
    self.isMultiSprite = false
    local canPickUp = Pickup._largeGateOriginalCanPickUpMoveable(self, character, square, selected)
    self.isMultiSprite = wasMultiSprite
    if not canPickUp then
        return false
    end

    local members = getLeafMembers(selected, self.lmionLargeGateLeaf)
    if members == nil then
        return false
    end

    for _, member in ipairs(members) do
        if member.object == nil or not member.object:isObjectNoContainerOrEmpty() then
            return false
        end
    end

    if character ~= nil
        and not ISMoveableDefinitions.cheat
        and not character:isMovablesCheat()
        and not character:getInventory():hasRoomFor(character, 24) then
        return false
    end

    return true
end

if Pickup._largeGateOriginalPickUpMoveable == nil then
    Pickup._largeGateOriginalPickUpMoveable = ISMoveableSpriteProps.pickUpMoveable
end

ISMoveableSpriteProps.pickUpMoveable = function(self, character, square, createItem, forceAllow)
    if self == nil or self.lmionLargeGateLeaf == nil then
        return Pickup._largeGateOriginalPickUpMoveable(self, character, square, createItem, forceAllow)
    end

    local selected = self:findOnSquare(square, self.spriteName)
    if selected == nil then
        return false
    end

    if not forceAllow
        and not character:isMovablesCheat()
        and not ISMoveableDefinitions.cheat
        and not self:canPickUpMoveable(character, square, selected) then
        return false
    end

    local members = getLeafMembers(selected, self.lmionLargeGateLeaf)
    if members == nil then
        return false
    end

    local items = {}
    for partIndex, member in ipairs(members) do
        local moveProps = ISMoveableSpriteProps.new(member.spriteName)
        moveProps.isMultiSprite = false
        local item = moveProps:pickUpMoveableInternal(
            character,
            member.square,
            member.object,
            nil,
            member.spriteName,
            createItem,
            forceAllow
        )
        items[partIndex] = item
    end

    if ISMoveableCursor ~= nil and ISMoveableCursor.clearCacheForAllPlayers ~= nil then
        ISMoveableCursor.clearCacheForAllPlayers()
    end

    return items
end

return Pickup
