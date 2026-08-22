require "LMION/Debug/Registry"
require "LMION/Doors/Models"
require "LMION/Debug/TestZone/Spawner"

LMION.Debug.TestZone = LMION.Debug.TestZone or {}

local TestZone = LMION.Debug.TestZone
local Spawner = TestZone.Spawner

local FIXED_ORIGIN_X = 15660
local FIXED_ORIGIN_Y = 600
local FIXED_Z = 0
local FIXED_WIDTH = 34
local FIXED_HEIGHT = 28
local FIXED_TELEPORT_X = FIXED_ORIGIN_X - 2
local FIXED_TELEPORT_Y = FIXED_ORIGIN_Y - 2
local FIXED_LOAD_TIMEOUT_TICKS = 600
local EXPECTED_ENTITY_COUNT = 77

local FIXED_FLOOR_CANDIDATES = {
    "blends_street_01_0",
    "blends_street_01_1",
    "blends_natural_01_64",
}

local EXTRA_VANILLA_ENTITIES = {
    "Base.DoubleWireGate",
    "Base.DoubleFenceGate",
    "Base.DoubleDoor",
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
    return getCell():getGridSquare(FIXED_ORIGIN_X, FIXED_ORIGIN_Y, FIXED_Z)
end

local function addScript(scripts, seen, script)
    if script == nil or script.getFullName == nil then
        return false
    end

    local id = tostring(script:getFullName())
    if id == "" or seen[id] then
        return false
    end

    seen[id] = true
    scripts[#scripts + 1] = script
    return true
end

function TestZone.collectEntityScripts()
    local scripts = {}
    local seen = {}
    local unresolved = {}

    if ScriptManager == nil or ScriptManager.instance == nil then
        return scripts, { "ScriptManager" }
    end

    local models = LMION.Doors ~= nil and LMION.Doors.getAll ~= nil
        and LMION.Doors.getAll() or {}

    for doorId, model in pairs(models) do
        local entityId = model ~= nil and model.sourceEntity or doorId
        local script = ScriptManager.instance:getGameEntityScript(entityId)

        if not addScript(scripts, seen, script) then
            if script == nil then
                unresolved[#unresolved + 1] = tostring(entityId)
            end
        end
    end

    for _, id in ipairs(EXTRA_VANILLA_ENTITIES) do
        local script = ScriptManager.instance:getGameEntityScript(id)
        if not addScript(scripts, seen, script) and script == nil then
            unresolved[#unresolved + 1] = tostring(id)
        end
    end

    table.sort(scripts, function(a, b)
        return tostring(a:getFullName()) < tostring(b:getFullName())
    end)
    table.sort(unresolved)

    return scripts, unresolved
end

local function formatSkipReasons(reasons)
    local parts = {}

    for name, count in pairs(reasons or {}) do
        parts[#parts + 1] = tostring(name) .. "=" .. tostring(count)
    end

    table.sort(parts)
    return #parts > 0 and table.concat(parts, ", ") or "none"
end

local function logSpawnResult(result, unresolved)
    if result.error ~= nil then
        if LMION.error ~= nil then
            LMION.error("Debug", "test zone: " .. tostring(result.error))
        end
        return
    end

    if LMION.log ~= nil then
        LMION.log(
            "Debug",
            "test zone spawned "
                .. tostring(result.entitiesSpawned)
                .. "/"
                .. tostring(result.entitiesFound)
                .. " entities in "
                .. tostring(result.familiesSpawned)
                .. "/"
                .. tostring(result.familiesFound)
                .. " groups; objects="
                .. tostring(result.objectsSpawned)
                .. ", frames="
                .. tostring(result.framesSpawned)
                .. ", skipped="
                .. tostring(result.skipped)
                .. " ["
                .. formatSkipReasons(result.skipReasons)
                .. "]"
        )
    end

    if result.entitiesFound ~= EXPECTED_ENTITY_COUNT and LMION.warn ~= nil then
        LMION.warn(
            "Debug",
            "test zone expected "
                .. tostring(EXPECTED_ENTITY_COUNT)
                .. " entities but found "
                .. tostring(result.entitiesFound)
        )
    end

    if unresolved ~= nil and #unresolved > 0 and LMION.warn ~= nil then
        LMION.warn(
            "Debug",
            "test zone unresolved entities: " .. table.concat(unresolved, ", ")
        )
    end

    if #result.rejected > 0 and LMION.warn ~= nil then
        for _, entry in ipairs(result.rejected) do
            LMION.warn(
                "Debug",
                "test zone rejected "
                    .. tostring(entry.id)
                    .. ": "
                    .. tostring(entry.reason)
            )
        end
    end
end

local function finishFixedRebuild()
    local floorSprite = chooseFixedFloorSprite()

    if floorSprite == nil then
        TestZone._fixedRebuild = nil
        if LMION.error ~= nil then
            LMION.error("Debug", "test zone: no usable floor sprite found")
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

        TestZone._fixedRebuild = nil
        if LMION.error ~= nil then
            LMION.error("Debug", "test zone prepare failed: " .. tostring(reason))
        end
        return
    end

    local scripts, unresolved = TestZone.collectEntityScripts()
    local result = Spawner.spawn(scripts, fixedOriginSquare())
    TestZone._fixedRebuild = nil

    if LMION.log ~= nil then
        LMION.log(
            "Debug",
            "test zone prepared "
                .. tostring(prep.squares)
                .. " squares at "
                .. tostring(FIXED_ORIGIN_X)
                .. ","
                .. tostring(FIXED_ORIGIN_Y)
                .. ","
                .. tostring(FIXED_Z)
                .. "; removed="
                .. tostring(prep.removedObjects)
        )
    end

    logSpawnResult(result, unresolved)
end

function TestZone.onFixedRebuildTick()
    local state = TestZone._fixedRebuild

    if state == nil then
        Events.OnTick.Remove(TestZone.onFixedRebuildTick)
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

    player:teleportTo(FIXED_TELEPORT_X, FIXED_TELEPORT_Y, FIXED_Z)
    TestZone._fixedRebuild = { ticks = 0 }

    Events.OnTick.Remove(TestZone.onFixedRebuildTick)
    Events.OnTick.Add(TestZone.onFixedRebuildTick)

    if LMION.log ~= nil then
        LMION.log(
            "Debug",
            "test zone requested near "
                .. tostring(FIXED_ORIGIN_X)
                .. ","
                .. tostring(FIXED_ORIGIN_Y)
        )
    end

    return true
end

TestZone.fixed = {
    x = FIXED_ORIGIN_X,
    y = FIXED_ORIGIN_Y,
    z = FIXED_Z,
    width = FIXED_WIDTH,
    height = FIXED_HEIGHT,
}

return TestZone
