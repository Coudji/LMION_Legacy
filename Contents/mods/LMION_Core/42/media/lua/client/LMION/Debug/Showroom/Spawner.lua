require "LMION/Debug/Registry"
require "LMION/Debug/Showroom/Catalog"
require "LMION/Debug/Showroom/Layout"

LMION.Debug.Showroom = LMION.Debug.Showroom or {}

local Catalog = LMION.Debug.Showroom.Catalog
local Layout = LMION.Debug.Showroom.Layout
local Spawner = LMION.Debug.Showroom.Spawner or {}
LMION.Debug.Showroom.Spawner = Spawner

local SECTION_GAP = 2
local REJECTED_COLUMNS = 10
local REJECTED_CELL_X = 4
local REJECTED_CELL_Y = 4
local REJECTED_SECTION_GAP = 4

local STANDARD_FRAME_N = "fixtures_doors_frames_01_1"
local PAIRED_FRAME_LEFT_N = "fixtures_doors_frames_01_26"
local PAIRED_FRAME_RIGHT_N = "fixtures_doors_frames_01_27"

local SECTION_SPECS = {
    { key = "garage", columns = 7, cellX = 5, cellY = 4 },
    { key = "double", columns = 6, cellX = 5, cellY = 4 },
    { key = "paired", columns = 5, cellX = 4, cellY = 4 },
    { key = "special", columns = 16, cellX = 3, cellY = 3 },
    { key = "standard", columns = 16, cellX = 3, cellY = 3 },
}

local SPECIAL_KIND_ORDER = {
    "sliding",
    "fence-high",
    "fence-low",
    "small",
}

local SPECIAL_KINDS = {
    sliding = true,
    ["fence-high"] = true,
    ["fence-low"] = true,
    small = true,
}

local function isMultiplayer()
    return (isClient ~= nil and isClient())
        or (isServer ~= nil and isServer())
end

local function getSquare(x, y, z)
    return getCell():getGridSquare(x, y, z)
end

function Spawner.isAreaLoaded(originX, originY, z, width, height)
    for y = originY, originY + height - 1 do
        for x = originX, originX + width - 1 do
            if getSquare(x, y, z) == nil then
                return false, x, y
            end
        end
    end
    return true, nil, nil
end

local function clearSquare(square)
    local removed = 0
    local objects = square:getObjects()

    for i = objects:size() - 1, 0, -1 do
        local object = objects:get(i)
        if object ~= nil then
            square:transmitRemoveItemFromSquare(object)
            if object:getObjectIndex() ~= -1 then
                square:RemoveTileObject(object)
            end
            removed = removed + 1
        end
    end

    return removed
end

function Spawner.prepareArea(originX, originY, z, width, height, floorSprite)
    if isMultiplayer() then
        return false, "showroom workspace is single-player debug only for now"
    end
    if floorSprite == nil or tostring(floorSprite) == "" then
        return false, "missing floor sprite"
    end
    if getSprite ~= nil and getSprite(floorSprite) == nil then
        return false, "unknown floor sprite: " .. tostring(floorSprite)
    end

    local loaded, missingX, missingY = Spawner.isAreaLoaded(originX, originY, z, width, height)
    if not loaded then
        return false, "unloaded:" .. tostring(missingX) .. "," .. tostring(missingY)
    end

    local result = {
        squares = 0,
        removedObjects = 0,
        floorSprite = floorSprite,
    }

    for y = originY, originY + height - 1 do
        for x = originX, originX + width - 1 do
            local square = getSquare(x, y, z)
            result.removedObjects = result.removedObjects + clearSquare(square)
            square:addFloor(floorSprite)
            square:disableErosion()
            result.squares = result.squares + 1
        end
    end

    return true, nil, result
end

local function squareIsUsable(square)
    if square == nil then
        return false, "unloaded"
    end

    local objects = square:getObjects()
    local floor = square:getFloor()
    local expected = floor ~= nil and 1 or 0
    if objects ~= nil and objects:size() > expected then
        return false, "occupied"
    end

    local specialObjects = square:getSpecialObjects()
    if specialObjects ~= nil and specialObjects:size() > 0 then
        return false, "occupied"
    end

    return true, nil
end

local function partPosition(family, baseX, baseY, partIndex)
    if #family.parts <= 1 then
        return baseX, baseY
    end

    local offset = partIndex - 1
    if family.anchor.north then
        return baseX + offset, baseY
    end
    return baseX, baseY + offset
end

local function familySquaresAvailable(family, baseX, baseY, z)
    for i = 1, #family.parts do
        local x, y = partPosition(family, baseX, baseY, i)
        local usable, reason = squareIsUsable(getSquare(x, y, z))
        if not usable then
            return false, reason
        end
    end
    return true, nil
end

local function addSpecialObject(square, object)
    if object == nil then
        return false
    end

    if GameEntityFactory ~= nil then
        local properties = object:getProperties()
        if properties ~= nil and properties:has(IsoFlagType.EntityScript) then
            GameEntityFactory.CreateIsoEntityFromCellLoading(object)
        end
    end

    local insertIndex = square:getObjects():size()
    square:AddSpecialObject(object, insertIndex)

    if triggerEvent ~= nil then
        triggerEvent("OnObjectAdded", object)
    end

    return true
end

local function createIsoDoor(record, square)
    return IsoDoor.new(getCell(), square, record.name, record.north == true)
end

local function createEntityDoor(scan, record, square)
    local openRecord = Catalog.getStateMate(scan, record)
    local object

    if openRecord ~= nil then
        object = IsoThumpable.new(
            getCell(), square, record.name, openRecord.name, record.north == true, {}
        )
    else
        object = IsoThumpable.new(getCell(), square, record.name, record.north == true, {})
    end

    object:setIsDoor(true)
    return object
end

local function frameSpriteFor(family, partIndex)
    local mode = Layout.getFrameMode(family)

    if mode == "none" or family.kind == "garage" or family.kind == "double" then
        return nil
    end

    if mode == "paired" or family.kind == "paired" then
        if partIndex == 1 then
            return PAIRED_FRAME_LEFT_N
        end
        return PAIRED_FRAME_RIGHT_N
    end

    return STANDARD_FRAME_N
end

local function spawnFrame(square, spriteName, family, familyIndex, partIndex)
    if spriteName == nil then
        return nil
    end

    if getSprite ~= nil and getSprite(spriteName) == nil then
        return nil
    end

    local frame = IsoObject.new(getCell(), square, spriteName)
    if frame == nil then
        return nil
    end

    if frame.getModData ~= nil then
        local data = frame:getModData()
        data.lmionShowroomFrame = true
        data.lmionShowroomFrameSprite = spriteName
        data.lmionShowroomIndex = familyIndex
        data.lmionShowroomPart = partIndex
        data.lmionShowroomKind = family.kind
        data.lmionShowroomAnchor = family.anchor ~= nil and family.anchor.name or nil
    end

    square:AddTileObject(frame)
    return frame
end

local function tagShowroomObject(object, family, familyIndex, partIndex, frameSprite)
    if object == nil or object.getModData == nil then
        return
    end

    local data = object:getModData()
    data.lmionShowroomIndex = familyIndex
    data.lmionShowroomKind = family.kind
    data.lmionShowroomPart = partIndex
    data.lmionShowroomAnchor = family.anchor ~= nil and family.anchor.name or nil
    data.lmionShowroomName = Layout.getDisplayName(family)
    data.lmionShowroomFrame = Layout.getFrameMode(family)
    data.lmionShowroomFrameSprite = frameSprite

    if family.profile ~= nil then
        data.lmionShowroomSide = family.profile.side
        data.lmionShowroomPair = family.profile.pair
    end
end

local function spawnPart(scan, family, record, square, familyIndex, partIndex, result)
    local frameSprite = frameSpriteFor(family, partIndex)

    if frameSprite ~= nil then
        result.framesFound = result.framesFound + 1
        if spawnFrame(square, frameSprite, family, familyIndex, partIndex) == nil then
            return nil, "frame-spawn-failed:" .. tostring(frameSprite)
        end
        result.framesSpawned = result.framesSpawned + 1
        result.objectsSpawned = result.objectsSpawned + 1
    end

    local object
    if record.entityScriptName ~= nil then
        object = createEntityDoor(scan, record, square)
    else
        object = createIsoDoor(record, square)
    end
    if object == nil then
        return nil, "door-spawn-failed"
    end

    tagShowroomObject(object, family, familyIndex, partIndex, frameSprite)

    if not addSpecialObject(square, object) then
        return nil, "door-add-failed"
    end

    return object, nil
end

local function spawnFamily(scan, family, baseX, baseY, z, familyIndex, result)
    local available, reason = familySquaresAvailable(family, baseX, baseY, z)
    if not available then
        return false, reason, 0
    end

    local spawned = 0
    for i, record in ipairs(family.parts) do
        local x, y = partPosition(family, baseX, baseY, i)
        local square = getSquare(x, y, z)
        local object, partReason = spawnPart(
            scan, family, record, square, familyIndex, i, result
        )
        if object == nil then
            return false, partReason or "spawn-failed", spawned
        end
        spawned = spawned + 1
    end

    return true, nil, spawned
end

local function splitSections(families)
    local sections = {
        garage = {},
        double = {},
        paired = {},
        special = {},
        standard = {},
    }
    local special = {}

    for _, kind in ipairs(SPECIAL_KIND_ORDER) do
        special[kind] = {}
    end

    for _, family in ipairs(families) do
        if family.kind == "garage" or family.kind == "double" or family.kind == "paired" then
            sections[family.kind][#sections[family.kind] + 1] = family
        elseif SPECIAL_KINDS[family.kind] then
            special[family.kind][#special[family.kind] + 1] = family
        else
            sections.standard[#sections.standard + 1] = family
        end
    end

    for _, kind in ipairs(SPECIAL_KIND_ORDER) do
        for _, family in ipairs(special[kind]) do
            sections.special[#sections.special + 1] = family
        end
    end

    return sections
end

local function spawnGrid(
    scan,
    families,
    originX,
    originY,
    z,
    columns,
    cellX,
    cellY,
    result,
    indexOffset
)
    indexOffset = indexOffset or 0

    for index, family in ipairs(families) do
        local zero = index - 1
        local column = zero % columns
        local row = math.floor(zero / columns)
        local x = originX + column * cellX
        local y = originY + row * cellY
        local familyIndex = indexOffset + index
        local ok, reason, objectCount = spawnFamily(
            scan, family, x, y, z, familyIndex, result
        )

        if ok then
            result.familiesSpawned = result.familiesSpawned + 1
            result.objectsSpawned = result.objectsSpawned + objectCount
        else
            result.skipped = result.skipped + 1
            result.skipReasons[reason or "unknown"] =
                (result.skipReasons[reason or "unknown"] or 0) + 1
        end
    end

    if #families == 0 then
        return 0
    end
    return math.floor((#families - 1) / columns) + 1
end

local function spawnRejected(scan, originX, originY, z, result)
    local rejected = (scan.excluded and scan.excluded.incomplete) or {}
    result.rejectedFound = #rejected

    for index, entry in ipairs(rejected) do
        local zero = index - 1
        local column = zero % REJECTED_COLUMNS
        local row = math.floor(zero / REJECTED_COLUMNS)
        local x = originX + column * REJECTED_CELL_X
        local y = originY + row * REJECTED_CELL_Y
        local record = entry.record
        local family = {
            kind = "rejected",
            anchor = record,
            parts = { record },
        }
        local ok, reason, objectCount = spawnFamily(
            scan, family, x, y, z, 9000 + index, result
        )

        if ok then
            result.rejectedSpawned = result.rejectedSpawned + 1
            result.objectsSpawned = result.objectsSpawned + objectCount
        else
            result.rejectedSkipped = result.rejectedSkipped + 1
            local key = "rejected:" .. tostring(reason or "unknown")
            result.skipReasons[key] = (result.skipReasons[key] or 0) + 1
        end
    end

    if #rejected == 0 then
        return 0
    end
    return math.floor((#rejected - 1) / REJECTED_COLUMNS) + 1
end

function Spawner.spawn(scan, families, originSquare)
    local prepared = Layout.prepare(families)
    local sections = splitSections(prepared)
    local result = {
        familiesFound = #prepared,
        familiesSpawned = 0,
        objectsSpawned = 0,
        skipped = 0,
        skipReasons = {},
        rejectedFound = 0,
        rejectedSpawned = 0,
        rejectedSkipped = 0,
        framesFound = 0,
        framesSpawned = 0,
        sectionCounts = {},
    }

    if originSquare == nil then
        result.error = "missing origin square"
        return result
    end
    if isMultiplayer() then
        result.error = "showroom spawning is single-player debug only for now"
        return result
    end

    local originX = originSquare:getX()
    local currentY = originSquare:getY()
    local z = originSquare:getZ()
    local familyIndexOffset = 0

    for _, spec in ipairs(SECTION_SPECS) do
        local sectionFamilies = sections[spec.key]
        result.sectionCounts[spec.key] = #sectionFamilies

        if #sectionFamilies > 0 then
            local rows = spawnGrid(
                scan,
                sectionFamilies,
                originX,
                currentY,
                z,
                spec.columns,
                spec.cellX,
                spec.cellY,
                result,
                familyIndexOffset
            )
            familyIndexOffset = familyIndexOffset + #sectionFamilies
            currentY = currentY + rows * spec.cellY + SECTION_GAP
        end
    end

    currentY = currentY + REJECTED_SECTION_GAP
    spawnRejected(scan, originX, currentY, z, result)

    Spawner.lastResult = result
    Spawner.lastPreparedFamilies = prepared
    Spawner.lastSections = sections
    return result
end

return Spawner
