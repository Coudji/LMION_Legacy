require "LMION/Debug/Registry"
require "LMION/Debug/Showroom/Catalog"
require "LMION/Debug/Showroom/Spawner"

LMION.Debug.Showroom = LMION.Debug.Showroom or {}

local Showroom = LMION.Debug.Showroom
local Catalog = Showroom.Catalog
local Spawner = Showroom.Spawner

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

        local doorSounds = reportData.doorSounds or {}
        local soundParts = {}
        for sound, count in pairs(doorSounds) do
            soundParts[#soundParts + 1] = tostring(sound) .. "=" .. tostring(count)
        end
        table.sort(soundParts)
        LMION.log("Debug", "DoorSound distribution: " .. (#soundParts > 0 and table.concat(soundParts, ", ") or "<none>"))
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

    if result.error ~= nil then
        if LMION.error ~= nil then
            LMION.error("Debug", "door showroom: " .. tostring(result.error))
        end
        return result
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

    return result
end

return Showroom
