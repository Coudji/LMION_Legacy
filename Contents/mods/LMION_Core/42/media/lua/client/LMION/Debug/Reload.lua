require "LMION/Debug/World/Selection"
require "LMION/Debug/World/SquareScanner"

LMION.Debug = LMION.Debug or {}
LMION.Debug.Reload = LMION.Debug.Reload or {}

local Reload = LMION.Debug.Reload

local NAMESPACE_TOKEN = "/LMION/"
local SELF_SUFFIX = "/LMION/Debug/Reload.lua"

local function normalize(path)
    if path == nil then
        return nil
    end

    return tostring(path):gsub("\\", "/")
end

local function isLMIONLua(path)
    local normalized = normalize(path)

    if normalized == nil then
        return false
    end

    -- Prefixing with '/' also handles require-style paths such as
    -- "LMION/Core.lua" in addition to full media/lua/... paths.
    return ("/" .. normalized):find(NAMESPACE_TOKEN, 1, true) ~= nil
end

local function isSelf(path)
    local normalized = normalize(path)

    if normalized == nil then
        return false
    end

    return ("/" .. normalized):sub(-#SELF_SUFFIX) == SELF_SUFFIX
end

local function collectLoadedLMIONFiles()
    local files = {}
    local seen = {}
    local selfFile = nil

    if getLoadedLuaCount == nil or getLoadedLua == nil then
        return files, selfFile
    end

    local count = getLoadedLuaCount()

    for i = 0, count - 1 do
        local path = getLoadedLua(i)

        if path ~= nil and isLMIONLua(path) and not seen[path] then
            seen[path] = true

            if isSelf(path) then
                selfFile = path
            else
                files[#files + 1] = path
            end
        end
    end

    return files, selfFile
end

local function snapshotWindow()
    local window = LMION.Debug.Window ~= nil and LMION.Debug.Window.instance or nil

    if window == nil then
        return nil
    end

    return {
        x = window:getX(),
        y = window:getY(),
        width = window:getWidth(),
        height = window:getHeight(),
    }
end

local function snapshotSelection()
    local Selection = LMION.Debug.World ~= nil and LMION.Debug.World.Selection or nil

    if Selection == nil then
        return nil
    end

    local snapshot = {
        squares = {},
        activeKey = Selection.activeKey,
        selectedObjectKeys = {},
    }

    for _, entry in ipairs(Selection.getEntries()) do
        local square = entry.square

        if square ~= nil then
            snapshot.squares[#snapshot.squares + 1] = {
                x = square:getX(),
                y = square:getY(),
                z = square:getZ(),
            }
        end
    end

    for key, _ in pairs(Selection.selectedObjectByKey or {}) do
        snapshot.selectedObjectKeys[key] = true
    end

    return snapshot
end

local function closeInspectorForReload()
    local window = LMION.Debug.Window ~= nil and LMION.Debug.Window.instance or nil

    if window ~= nil then
        window:close()
    elseif LMION.Debug.World ~= nil
        and LMION.Debug.World.Highlight ~= nil
        and LMION.Debug.World.Highlight.clearAll ~= nil then
        LMION.Debug.World.Highlight.clearAll()
    end
end

local function restoreSelection(snapshot)
    if snapshot == nil or getCell == nil then
        return
    end

    local World = LMION.Debug.World
    local Selection = World ~= nil and World.Selection or nil
    local SquareScanner = World ~= nil and World.SquareScanner or nil

    if Selection == nil then
        return
    end

    Selection.clearSquares()

    local cell = getCell()

    if cell == nil then
        return
    end

    for _, coords in ipairs(snapshot.squares) do
        local square = cell:getGridSquare(coords.x, coords.y, coords.z)

        if square ~= nil then
            Selection.addSquare(square, false)
        end
    end

    if snapshot.activeKey ~= nil then
        Selection.setActive(snapshot.activeKey)
    end

    if SquareScanner ~= nil then
        local entries = SquareScanner.flattenObjects(Selection.getSquares())

        for _, entry in ipairs(entries) do
            if entry.key ~= nil and snapshot.selectedObjectKeys[entry.key] then
                Selection.selectedObjectByKey[entry.key] = entry
            end
        end
    end
end

local function reopenInspector(windowSnapshot)
    if windowSnapshot == nil
        or LMION.Debug.Window == nil
        or LMION.Debug.Window.ensure == nil then
        return
    end

    local window = LMION.Debug.Window.ensure()

    window:setX(windowSnapshot.x)
    window:setY(windowSnapshot.y)
    window:setWidth(windowSnapshot.width)
    window:setHeight(windowSnapshot.height)

    if window.layout ~= nil then
        window:layout()
    end

    if window.refreshAll ~= nil then
        window:refreshAll()
    end
end

function Reload.getLoadedFiles()
    local files, selfFile = collectLoadedLMIONFiles()

    if selfFile ~= nil then
        files[#files + 1] = selfFile
    end

    return files
end

function Reload.reloadAll()
    if reloadLuaFile == nil then
        if LMION.warn ~= nil then
            LMION.warn("Reload", "reloadLuaFile() is unavailable")
        end
        return false
    end

    local files, selfFile = collectLoadedLMIONFiles()

    if #files == 0 and selfFile == nil then
        if LMION.warn ~= nil then
            LMION.warn("Reload", "no loaded LMION Lua files were found")
        end
        return false
    end

    local windowSnapshot = snapshotWindow()
    local selectionSnapshot = snapshotSelection()

    if LMION.log ~= nil then
        LMION.log(
            "Reload",
            "reloading " .. tostring(#files + (selfFile ~= nil and 1 or 0)) .. " loaded LMION Lua files"
        )
    end

    closeInspectorForReload()

    -- Keep the engine's original load order. Core/shared code therefore reloads
    -- before the client files that already depended on it.
    for _, path in ipairs(files) do
        if LMION.log ~= nil then
            LMION.log("Reload", "-> " .. tostring(path))
        end

        reloadLuaFile(path)
    end

    -- Reload this file last so the currently executing reload loop is never
    -- replaced halfway through the operation.
    if selfFile ~= nil then
        if LMION.log ~= nil then
            LMION.log("Reload", "-> " .. tostring(selfFile))
        end

        reloadLuaFile(selfFile)
    end

    restoreSelection(selectionSnapshot)
    reopenInspector(windowSnapshot)

    if LMION.log ~= nil then
        LMION.log("Reload", "LMION Lua reload complete")
    end

    return true
end

return Reload
