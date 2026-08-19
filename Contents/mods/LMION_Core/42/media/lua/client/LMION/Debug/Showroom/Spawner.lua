require "LMION/Debug/Registry"
require "LMION/Debug/Showroom/Catalog"

LMION.Debug.Showroom = LMION.Debug.Showroom or {}

local Catalog = LMION.Debug.Showroom.Catalog
local Spawner = LMION.Debug.Showroom.Spawner or {}
LMION.Debug.Showroom.Spawner = Spawner

local GROUP_COLUMNS = 8
local GROUP_CELL = 6
local SINGLE_COLUMNS = 16
local SINGLE_CELL_X = 3
local SINGLE_CELL_Y = 3
local SECTION_GAP = 4
local REJECTED_COLUMNS = 10
local REJECTED_CELL_X = 4
local REJECTED_CELL_Y = 4
local REJECTED_SECTION_GAP = 8

local function isMultiplayer()
    return (isClient ~= nil and isClient())
        or (isServer ~= nil and isServer())
end

local function getSquare(x, y, z)
    return getCell():getGridSquare(x, y, z)
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
    return IsoDoor.new(
        getCell(),
        square,
        record.name,
        record.north == true
    )
end

local function createEntityDoor(scan, record, square)
    local openRecord = Catalog.getStateMate(scan, record)
    local object

    if openRecord ~= nil then
        object = IsoThumpable.new(
            getCell(),
            square,
            record.name,
            openRecord.name,
            record.north == true,
            {}
        )
    else
        object = IsoThumpable.new(
            getCell(),
            square,
            record.name,
            record.north == true,
            {}
        )
    end

    object:setIsDoor(true)
    return object
end

local function spawnPart(scan, family, record, square)
    local object

    if record.entityScriptName ~= nil then
        object = createEntityDoor(scan, record, square)
    else
        object = createIsoDoor(record, square)
    end

    if object == nil then
        return nil
    end

    if not addSpecialObject(square, object) then
        return nil
    end

    return object
end

local function spawnFamily(scan, family, baseX, baseY, z)
    local available, reason = familySquaresAvailable(family, baseX, baseY, z)

    if not available then
        return false, reason, 0
    end

    local spawned = 0

    for i, record in ipairs(family.parts) do
        local x, y = partPosition(family, baseX, baseY, i)
        local square = getSquare(x, y, z)
        local object = spawnPart(scan, family, record, square)

        if object == nil then
            return false, "spawn-failed", spawned
        end

        spawned = spawned + 1
    end

    return true, nil, spawned
end

local function splitFamilies(families)
    local grouped = {}
    local singles = {}

    for _, family in ipairs(families) do
        if family.kind == "garage" or family.kind == "double" then
            grouped[#grouped + 1] = family
        else
            singles[#singles + 1] = family
        end
    end

    return grouped, singles
end

local function spawnGrid(scan, families, originX, originY, z, columns, cellX, cellY, result)
    for index, family in ipairs(families) do
        local zero = index - 1
        local column = zero % columns
        local row = math.floor(zero / columns)
        local x = originX + column * cellX
        local y = originY + row * cellY
        local ok, reason, objectCount = spawnFamily(scan, family, x, y, z)

        if ok then
            result.familiesSpawned = result.familiesSpawned + 1
            result.objectsSpawned = result.objectsSpawned + objectCount
        else
            result.skipped = result.skipped + 1
            result.skipReasons[reason or "unknown"] = (result.skipReasons[reason or "unknown"] or 0) + 1
        end
    end

    if #families == 0 then
        return 0
    end

    return math.floor((#families - 1) / columns) + 1
end

local function spawnRejected(scan, originX, originY, z, result)
    local rejected = Catalog.getRejected(scan)
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
        local ok, reason, objectCount = spawnFamily(scan, family, x, y, z)

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
    local result = {
        familiesFound = #families,
        familiesSpawned = 0,
        objectsSpawned = 0,
        skipped = 0,
        skipReasons = {},
        rejectedFound = 0,
        rejectedSpawned = 0,
        rejectedSkipped = 0,
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
    local originY = originSquare:getY()
    local z = originSquare:getZ()
    local grouped, singles = splitFamilies(families)

    local groupRows = spawnGrid(
        scan,
        grouped,
        originX,
        originY,
        z,
        GROUP_COLUMNS,
        GROUP_CELL,
        GROUP_CELL,
        result
    )

    local singlesY = originY + groupRows * GROUP_CELL

    if #grouped > 0 and #singles > 0 then
        singlesY = singlesY + SECTION_GAP
    end

    local singleRows = spawnGrid(
        scan,
        singles,
        originX,
        singlesY,
        z,
        SINGLE_COLUMNS,
        SINGLE_CELL_X,
        SINGLE_CELL_Y,
        result
    )

    local rejectedY = singlesY + singleRows * SINGLE_CELL_Y + REJECTED_SECTION_GAP
    spawnRejected(scan, originX, rejectedY, z, result)

    Spawner.lastResult = result
    return result
end

return Spawner
