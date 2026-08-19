require "LMION/Debug/Registry"
require "LMION/Debug/Showroom/Catalog"
require "LMION/Debug/Showroom/Spawner"

LMION.Debug.Showroom = LMION.Debug.Showroom or {}

local Showroom = LMION.Debug.Showroom
local Catalog = Showroom.Catalog
local Spawner = Showroom.Spawner

local FIXED_ORIGIN_X = 15600
local FIXED_ORIGIN_Y = 600
local FIXED_Z = 0
local FIXED_WIDTH = 52
local FIXED_HEIGHT = 50
local FIXED_TELEPORT_X = FIXED_ORIGIN_X - 2
local FIXED_TELEPORT_Y = FIXED_ORIGIN_Y - 2
local FIXED_FLOOR_CANDIDATES = {
    "blends_street_01_0",
    "blends_street_01_1",
    "blends_natural_01_64",
}
local FIXED_LOAD_TIMEOUT_TICKS = 600

local function formatCounts(counts)
    return "garage=" .. tostring(counts.garage or 0)
        .. ", double=" .. tostring(counts.double or 0)
        .. ", entity=" .. tostring(counts.entity or 0)
        .. ", single=" .. tostring(counts.single or 0)
        .. ", incomplete=" .. tostring(counts.incomplete or 0)
        .. ", unoriented=" .. tostring(counts.unoriented or 0)
        .. ", ignoredOrientation=" .. tostring(counts.ignoredOrientation or 0)
end

local function formatSkipReasons(reasons)
    local parts = {}

    for name, count in pairs(reasons or {}) do
        parts[#parts + 1] = tostring(name) .. "=" .. tostring(count)
    end

    table.sort(parts)
    return #parts > 0 and table.concat(parts, ", ") or "none"
end

local function formatDistribution(values)
    local parts = {}

    for name, count in pairs(values or {}) do
        parts[#parts + 1] = tostring(name) .. "=" .. tostring(count)
    end

    table.sort(parts)
    return #parts > 0 and table.concat(parts, ", ") or "<none>"
end

local function logRejected(scan)
    if LMION.log == nil then
        return
    end

    local rejected = Catalog.getRejected(scan)
    LMION.log("Debug", "door showroom rejected candidates=" .. tostring(#rejected))

    for index, entry in ipairs(rejected) do
        local record = entry.record
        LMION.log(
            "Debug",
            "rejected[" .. tostring(index) .. "] "
                .. tostring(record.name)
                .. " | " .. tostring(entry.reason)
                .. " | DoorSound=" .. tostring(record.doorSound or "<none>")
                .. " | EntityScriptName=" .. tostring(record.entityScriptName or "<none>")
                .. " | DoubleDoor=" .. tostring(record.doubleDoor or "<none>")
                .. " | GarageDoor=" .. tostring(record.garageDoor or "<none>")
        )
    end
end

local function chooseFixedFloorSprite()
    if getSprite == nil then
        return nil
    end

    for _, name in ipairs(FIXED_FLOOR_CANDIDATES) do
        if getSprite(name) ~= nil then
            return name
        end
    end

    return nil
end

local function fixedOriginSquare()
    return getCell():getGridSquare(FIXED_ORIGIN_X, FIXED_ORIGIN_Y, FIXED_Z)
end

local function logSpawnResult(result)
    if result.error ~= nil then
        if LMION.error ~= nil then
            LMION.error("Debug", "door showroom: " .. tostring(result.error))
        end
        return
    end

    if LMION.log ~= nil then
        LMION.log(
            "Debug",
            "door showroom spawned "
                .. tostring(result.familiesSpawned)
                .. "/"
                .. tostring(result.familiesFound)
                .. " families + rejected "
                .. tostring(result.rejectedSpawned)
                .. "/"
                .. tostring(result.rejectedFound)
                .. " ("
                .. tostring(result.objectsSpawned)
                .. " objects); skipped="
                .. tostring(result.skipped)
                .. ", rejectedSkipped="
                .. tostring(result.rejectedSkipped)
                .. " ["
                .. formatSkipReasons(result.skipReasons)
                .. "]"
        )
    end
end

function Showroom.scan()
    local scan = Catalog.scan()
    local families, counts = Catalog.buildFamilies(scan)
    local report, reportData = Catalog.buildReport(scan, families, counts)

    Showroom.lastScan = scan
    Showroom.lastFamilies = families
    Showroom.lastCounts = counts
    Showroom.lastReport = report
    Showroom.lastReportData = reportData

    if LMION.log ~= nil then
        LMION.log(
            "Debug",
            "door catalog scanned "
                .. tostring(scan.counts.sprites)
                .. " sprites, "
                .. tostring(scan.counts.candidates)
                .. " door candidates, "
                .. tostring(#families)
                .. " families ("
                .. formatCounts(counts)
                .. ")"
        )

        LMION.log(
            "Debug",
            "DoorSound distribution: " .. formatDistribution(reportData.doorSounds)
        )
        LMION.log(
            "Debug",
            "EntityScriptName distribution: " .. formatDistribution(reportData.entityScripts)
        )
    end

    logRejected(scan)
    return scan, families, counts, report
end

function Showroom.copyReport()
    local _, _, _, report = Showroom.scan()

    if Clipboard ~= nil and Clipboard.setClipboard ~= nil then
        Clipboard.setClipboard(report or "")
        if LMION.log ~= nil then
            LMION.log("Debug", "door showroom scan report copied to clipboard")
        end
        return true
    end

    if LMION.warn ~= nil then
        LMION.warn("Debug", "Clipboard API unavailable")
    end
    return false
end

function Showroom.spawnAt(originSquare)
    local scan, families = Showroom.scan()
    local result = Spawner.spawn(scan, families, originSquare)
    logSpawnResult(result)
    return result
end

local function finishFixedRebuild()
    local floorSprite = chooseFixedFloorSprite()

    if floorSprite == nil then
        Showroom._fixedRebuild = nil
        if LMION.error ~= nil then
            LMION.error("Debug", "fixed door showroom: no usable floor sprite found")
        end
        return
    end

    local ok, reason, prep = Spawner.prepareArea(
        FIXED_ORIGIN_X,
        FIXED_ORIGIN_Y,
        FIXED_Z,
        FIXED_WIDTH,
        FIXED_HEIGHT,
        floorSprite
    )

    if not ok then
        if reason ~= nil and string.sub(reason, 1, 9) == "unloaded:" then
            return
        end

        Showroom._fixedRebuild = nil
        if LMION.error ~= nil then
            LMION.error("Debug", "fixed door showroom prepare failed: " .. tostring(reason))
        end
        return
    end

    local scan, families = Showroom.scan()
    local originSquare = fixedOriginSquare()
    local result = Spawner.spawn(scan, families, originSquare)
    Showroom._fixedRebuild = nil

    if LMION.log ~= nil then
        LMION.log(
            "Debug",
            "fixed door showroom prepared "
                .. tostring(prep.squares)
                .. " squares at "
                .. tostring(FIXED_ORIGIN_X)
                .. ","
                .. tostring(FIXED_ORIGIN_Y)
                .. ","
                .. tostring(FIXED_Z)
                .. " with "
                .. tostring(floorSprite)
                .. "; removed="
                .. tostring(prep.removedObjects)
        )
    end

    logSpawnResult(result)
end

function Showroom.onFixedRebuildTick()
    local state = Showroom._fixedRebuild

    if state == nil then
        Events.OnTick.Remove(Showroom.onFixedRebuildTick)
        return
    end

    state.ticks = state.ticks + 1

    local loaded = Spawner.isAreaLoaded(
        FIXED_ORIGIN_X,
        FIXED_ORIGIN_Y,
        FIXED_Z,
        FIXED_WIDTH,
        FIXED_HEIGHT
    )

    if loaded then
        Events.OnTick.Remove(Showroom.onFixedRebuildTick)
        finishFixedRebuild()
        return
    end

    if state.ticks >= FIXED_LOAD_TIMEOUT_TICKS then
        Showroom._fixedRebuild = nil
        Events.OnTick.Remove(Showroom.onFixedRebuildTick)
        if LMION.error ~= nil then
            LMION.error(
                "Debug",
                "fixed door showroom timed out waiting for "
                    .. tostring(FIXED_WIDTH)
                    .. "x"
                    .. tostring(FIXED_HEIGHT)
                    .. " area to load"
            )
        end
    end
end

function Showroom.rebuildFixed()
    if isClient ~= nil and isClient() then
        if LMION.error ~= nil then
            LMION.error("Debug", "fixed door showroom is single-player debug only for now")
        end
        return false
    end

    local player = getPlayer ~= nil and getPlayer() or nil

    if player == nil then
        if LMION.error ~= nil then
            LMION.error("Debug", "fixed door showroom: player unavailable")
        end
        return false
    end

    player:teleportTo(FIXED_TELEPORT_X, FIXED_TELEPORT_Y, FIXED_Z)
    Showroom._fixedRebuild = { ticks = 0 }

    Events.OnTick.Remove(Showroom.onFixedRebuildTick)
    Events.OnTick.Add(Showroom.onFixedRebuildTick)

    if LMION.log ~= nil then
        LMION.log(
            "Debug",
            "fixed door showroom requested; teleporting near "
                .. tostring(FIXED_ORIGIN_X)
                .. ","
                .. tostring(FIXED_ORIGIN_Y)
                .. " and waiting for area load"
        )
    end

    return true
end

Showroom.fixed = {
    x = FIXED_ORIGIN_X,
    y = FIXED_ORIGIN_Y,
    z = FIXED_Z,
    width = FIXED_WIDTH,
    height = FIXED_HEIGHT,
}

return Showroom
