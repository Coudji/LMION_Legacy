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
end

local function formatSkipReasons(reasons)
    local parts = {}

    for name, count in pairs(reasons or {}) do
        parts[#parts + 1] = tostring(name) .. "=" .. tostring(count)
    end

    table.sort(parts)
    return #parts > 0 and table.concat(parts, ", ") or "none"
end

function Showroom.scan()
    local scan = Catalog.scan()
    local families, counts = Catalog.buildFamilies(scan)

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
    end

    return scan, families, counts
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
                .. " families ("
                .. tostring(result.objectsSpawned)
                .. " objects); skipped="
                .. tostring(result.skipped)
                .. " ["
                .. formatSkipReasons(result.skipReasons)
                .. "]"
        )
    end

    return result
end

return Showroom
