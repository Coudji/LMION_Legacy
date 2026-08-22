require "LMION/Debug/Util/Safe"

LMION.Debug.World = LMION.Debug.World or {}
LMION.Debug.World.Selection = LMION.Debug.World.Selection or {}

local Safe = LMION.Debug.Util.Safe
local Selection = LMION.Debug.World.Selection

Selection.squares = Selection.squares or {}
Selection.squareByKey = Selection.squareByKey or {}
Selection.activeKey = Selection.activeKey or nil
Selection.selectedObjectByKey = Selection.selectedObjectByKey or {}

local function rebuildSquareMap()
    Selection.squareByKey = {}

    for _, entry in ipairs(Selection.squares) do
        Selection.squareByKey[entry.key] = entry
    end
end

function Selection.addSquare(square, makeActive)
    if square == nil then
        return false
    end

    local key = Safe.squareKey(square)
    local existing = Selection.squareByKey[key]

    if existing == nil then
        local entry = {
            key = key,
            square = square,
            text = Safe.squareString(square),
        }

        Selection.squares[#Selection.squares + 1] = entry
        Selection.squareByKey[key] = entry
    else
        existing.square = square
        existing.text = Safe.squareString(square)
    end

    if makeActive ~= false then
        Selection.activeKey = key
    end

    return true
end

function Selection.getSquares()
    local result = {}

    for _, entry in ipairs(Selection.squares) do
        result[#result + 1] = entry.square
    end

    return result
end

function Selection.getEntries()
    return Selection.squares
end

function Selection.getActiveEntry()
    if Selection.activeKey == nil then
        return nil
    end

    return Selection.squareByKey[Selection.activeKey]
end

function Selection.getActiveSquare()
    local entry = Selection.getActiveEntry()
    return entry ~= nil and entry.square or nil
end

function Selection.setActive(key)
    if Selection.squareByKey[key] == nil then
        return false
    end

    Selection.activeKey = key
    return true
end

function Selection.removeActiveSquare()
    if Selection.activeKey == nil then
        return
    end

    local removedKey = Selection.activeKey
    local kept = {}

    for _, entry in ipairs(Selection.squares) do
        if entry.key ~= removedKey then
            kept[#kept + 1] = entry
        end
    end

    Selection.squares = kept
    rebuildSquareMap()
    Selection.activeKey = Selection.squares[1] ~= nil and Selection.squares[1].key or nil

    for key, selected in pairs(Selection.selectedObjectByKey) do
        if selected.squareKey == removedKey then
            Selection.selectedObjectByKey[key] = nil
        end
    end
end

function Selection.clearSquares()
    Selection.squares = {}
    Selection.squareByKey = {}
    Selection.activeKey = nil
    Selection.selectedObjectByKey = {}
end

function Selection.addAdjacent(dx, dy, dz)
    local active = Selection.getActiveSquare()

    if active == nil then
        return false
    end

    local cell = getCell ~= nil and getCell() or nil

    if cell == nil then
        return false
    end

    local square = cell:getGridSquare(
        active:getX() + (dx or 0),
        active:getY() + (dy or 0),
        active:getZ() + (dz or 0)
    )

    if square == nil then
        return false
    end

    return Selection.addSquare(square, true)
end

function Selection.toggleObject(entry)
    if entry == nil or entry.object == nil then
        return false
    end

    local key = entry.key or Safe.objectKey(entry.object)

    if Selection.selectedObjectByKey[key] ~= nil then
        Selection.selectedObjectByKey[key] = nil
        return false
    end

    Selection.selectedObjectByKey[key] = entry
    return true
end

function Selection.selectOnlyObject(entry)
    Selection.selectedObjectByKey = {}

    if entry == nil or entry.object == nil then
        return
    end

    local key = entry.key or Safe.objectKey(entry.object)

    if key ~= nil then
        Selection.selectedObjectByKey[key] = entry
    end
end

function Selection.isObjectSelected(entry)
    if entry == nil then
        return false
    end

    local key = entry.key or Safe.objectKey(entry.object)
    return key ~= nil and Selection.selectedObjectByKey[key] ~= nil
end

function Selection.clearObjectSelection()
    Selection.selectedObjectByKey = {}
end

function Selection.selectObjectEntries(entries)
    Selection.selectedObjectByKey = {}

    for _, entry in ipairs(entries or {}) do
        if entry ~= nil and entry.object ~= nil then
            local key = entry.key or Safe.objectKey(entry.object)

            if key ~= nil then
                Selection.selectedObjectByKey[key] = entry
            end
        end
    end
end

function Selection.getSelectedObjects()
    local entries = {}

    for _, entry in pairs(Selection.selectedObjectByKey) do
        entries[#entries + 1] = entry
    end

    table.sort(entries, function(a, b)
        if a.squareText == b.squareText then
            return (a.listIndex or 0) < (b.listIndex or 0)
        end

        return tostring(a.squareText) < tostring(b.squareText)
    end)

    local objects = {}

    for _, entry in ipairs(entries) do
        objects[#objects + 1] = entry.object
    end

    return objects
end

function Selection.reset()
    Selection.clearSquares()
end

return Selection
