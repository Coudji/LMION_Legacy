require "LMION/Debug/Registry"
require "LMION/Debug/TestZone/Manifest"
require "LMION/Debug/TestZone/Spawner"

LMION.Debug.TestZone = LMION.Debug.TestZone or {}

local TestZone = LMION.Debug.TestZone
local Manifest = TestZone.Manifest
local Spawner = TestZone.Spawner

local FIXED_LOAD_TIMEOUT_TICKS = 600

local FIXED_FLOOR_CANDIDATES = {
    "blends_street_01_0",
    "blends_street_01_1",
    "blends_natural_01_64",
}

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
    local origin = Manifest.origin
    return getCell():getGridSquare(origin.x, origin.y, origin.z)
end

local function formatFailures(failures)
    if failures == nil or #failures == 0 then
        return "none"
    end

    local parts = {}
    for _, failure in ipairs(failures) do
        parts[#parts + 1] = tostring(failure.id) .. "=" .. tostring(failure.reason)
    end
    return table.concat(parts, ", ")
end

local function finishFixedRebuild()
    local floorSprite = chooseFixedFloorSprite()
    local origin = Manifest.origin

    if floorSprite == nil then
        TestZone._fixedRebuild = nil
        if LMION.error ~= nil then
            LMION.error("Debug", "test zone: no usable floor sprite found")
        end
        return
    end

    local ok, reason, prep = Spawner.prepareArea(
        origin.x,
        origin.y,
        origin.z,
        origin.width,
        origin.height,
        floorSprite
    )

    if not ok then
        if reason ~= nil and string.sub(reason, 1, 9) == "unloaded:" then
            return
        end

        TestZone._fixedRebuild = nil
        if LMION.error ~= nil then
            LMION.error("Debug", "test zone prepare failed: " .. tostring(reason))
        end
        return
    end

    local result = Spawner.spawn(Manifest.entries, fixedOriginSquare())
    TestZone._fixedRebuild = nil

    if LMION.log ~= nil then
        LMION.log(
            "Debug",
            "test zone prepared "
                .. tostring(prep.squares)
                .. " squares at "
                .. tostring(origin.x)
                .. ","
                .. tostring(origin.y)
                .. ","
                .. tostring(origin.z)
                .. "; removed="
                .. tostring(prep.removedObjects)
        )

        LMION.log(
            "Debug",
            "test zone spawned "
                .. tostring(result.spawned)
                .. "/"
                .. tostring(#Manifest.entries)
                .. " manifest entries; objects="
                .. tostring(result.objectsSpawned)
                .. ", frames="
                .. tostring(result.framesSpawned)
                .. ", failures="
                .. tostring(#result.failures)
                .. " ["
                .. formatFailures(result.failures)
                .. "]"
        )
    end

    if #result.failures > 0 and LMION.warn ~= nil then
        for _, failure in ipairs(result.failures) do
            LMION.warn(
                "Debug",
                "test zone failed " .. tostring(failure.id) .. ": " .. tostring(failure.reason)
            )
        end
    end
end

function TestZone.onFixedRebuildTick()
    local state = TestZone._fixedRebuild
    local origin = Manifest.origin

    if state == nil then
        Events.OnTick.Remove(TestZone.onFixedRebuildTick)
        return
    end

    state.ticks = state.ticks + 1

    local loaded = Spawner.isAreaLoaded(
        origin.x,
        origin.y,
        origin.z,
        origin.width,
        origin.height
    )

    if loaded then
        Events.OnTick.Remove(TestZone.onFixedRebuildTick)
        finishFixedRebuild()
        return
    end

    if state.ticks >= FIXED_LOAD_TIMEOUT_TICKS then
        TestZone._fixedRebuild = nil
        Events.OnTick.Remove(TestZone.onFixedRebuildTick)
        if LMION.error ~= nil then
            LMION.error("Debug", "test zone timed out waiting for area to load")
        end
    end
end

function TestZone.rebuildFixed()
    if (isClient ~= nil and isClient()) or (isServer ~= nil and isServer()) then
        if LMION.error ~= nil then
            LMION.error("Debug", "test zone is single-player debug only for now")
        end
        return false
    end

    local player = getPlayer ~= nil and getPlayer() or nil
    if player == nil then
        if LMION.error ~= nil then
            LMION.error("Debug", "test zone: player unavailable")
        end
        return false
    end

    local origin = Manifest.origin
    player:teleportTo(origin.teleportX, origin.teleportY, origin.z)
    TestZone._fixedRebuild = { ticks = 0 }

    Events.OnTick.Remove(TestZone.onFixedRebuildTick)
    Events.OnTick.Add(TestZone.onFixedRebuildTick)

    if LMION.log ~= nil then
        LMION.log(
            "Debug",
            "test zone requested near " .. tostring(origin.x) .. "," .. tostring(origin.y)
        )
    end

    return true
end

TestZone.fixed = Manifest.origin

return TestZone
