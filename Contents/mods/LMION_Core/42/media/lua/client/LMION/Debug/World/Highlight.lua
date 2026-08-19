require "LMION/Debug/Util/Safe"
require "LMION/Debug/World/Selection"

LMION.Debug.World = LMION.Debug.World or {}

-- Reload-friendly cleanup of markers created by a previous version of this file.
if LMION.Debug.World.Highlight ~= nil and LMION.Debug.World.Highlight.clearAll ~= nil then
    LMION.Debug.World.Highlight.clearAll()
end

local Safe = LMION.Debug.Util.Safe
local Selection = LMION.Debug.World.Selection
local Highlight = {
    markers = {},
    hoverMarker = nil,
    hoverKey = nil,
}

LMION.Debug.World.Highlight = Highlight

local function getManager()
    if getWorldMarkers == nil then
        return nil
    end

    return getWorldMarkers()
end

local function removeMarker(marker)
    if marker == nil then
        return
    end

    local manager = getManager()

    if manager ~= nil then
        manager:removeGridSquareMarker(marker)
    else
        marker:remove()
    end
end

local function addMarker(square, r, g, b, alpha, size)
    if square == nil then
        return nil
    end

    local manager = getManager()

    if manager == nil then
        return nil
    end

    local marker = manager:addGridSquareMarker(
        square,
        r,
        g,
        b,
        false,
        size
    )

    if marker ~= nil then
        marker:setA(alpha)
        marker:setDoAlpha(false)
        marker:setDoBlink(false)
    end

    return marker
end

function Highlight.clearPersistent()
    for _, marker in pairs(Highlight.markers) do
        removeMarker(marker)
    end

    Highlight.markers = {}
end

function Highlight.clearHover()
    if Highlight.hoverMarker ~= nil then
        removeMarker(Highlight.hoverMarker)
    end

    Highlight.hoverMarker = nil
    Highlight.hoverKey = nil
end

function Highlight.clearAll()
    Highlight.clearHover()
    Highlight.clearPersistent()
end

function Highlight.sync()
    Highlight.clearPersistent()

    for _, entry in ipairs(Selection.getEntries()) do
        local active = entry.key == Selection.activeKey

        local marker

        if active then
            -- Active square: stronger warm marker.
            marker = addMarker(entry.square, 1.0, 0.72, 0.15, 0.90, 1.02)
        else
            -- Other selected squares: clearly visible but less dominant.
            marker = addMarker(entry.square, 0.20, 0.80, 1.0, 0.62, 0.96)
        end

        if marker ~= nil then
            Highlight.markers[entry.key] = marker
        end
    end
end

function Highlight.setHover(square)
    local key = square ~= nil and Safe.squareKey(square) or nil

    if key == Highlight.hoverKey then
        return
    end

    Highlight.clearHover()

    if square == nil then
        return
    end

    Highlight.hoverKey = key
    Highlight.hoverMarker = addMarker(square, 1.0, 1.0, 1.0, 0.95, 1.08)
end

return Highlight
