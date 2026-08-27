require "LMION/Debug/Registry"
require "LMION/Debug/Util/Safe"

LMION.Debug.Inspect = LMION.Debug.Inspect or {}

local Debug = LMION.Debug
local Safe = Debug.Util.Safe
local Frame = Debug.Inspect.Frame or {}
Debug.Inspect.Frame = Frame

local function spriteProperties(object)
    local sprite = object and object:getSprite() or nil
    return sprite and sprite:getProperties() or nil
end

local function hasProperty(properties, name)
    return properties ~= nil and properties:has(name)
end

local function propertyValue(properties, name)
    if properties == nil or not properties:has(name) then
        return nil
    end
    return properties:get(name)
end

local function hasFlag(properties, flag)
    return properties ~= nil and flag ~= nil and properties:has(flag)
end

local function frameOrientation(object, properties)
    local objectType = object and object:getType() or nil

    if objectType == IsoObjectType.doorFrN
        or hasFlag(properties, IsoFlagType.doorFrN)
        or hasProperty(properties, "DoorWallN") then
        return "N"
    end

    if objectType == IsoObjectType.doorFrW
        or hasFlag(properties, IsoFlagType.doorFrW)
        or hasProperty(properties, "DoorWallW") then
        return "W"
    end

    return nil
end

local function isRelevantFrameSprite(object, properties)
    if object == nil or properties == nil then
        return false
    end

    local objectType = object:getType()
    if objectType == IsoObjectType.doorFrN or objectType == IsoObjectType.doorFrW then
        return true
    end

    return hasFlag(properties, IsoFlagType.doorFrN)
        or hasFlag(properties, IsoFlagType.doorFrW)
        or hasProperty(properties, "DoorWallN")
        or hasProperty(properties, "DoorWallW")
        or hasFlag(properties, IsoFlagType.DoubleDoor1)
        or hasFlag(properties, IsoFlagType.DoubleDoor2)
        or hasProperty(properties, "DoubleDoor")
        or hasProperty(properties, "CutawayHint")
        or hasProperty(properties, "WallStyle")
        or hasProperty(properties, "WallObjectAllowDoorframe")
end

Debug.registerInspector("frame.runtime", 15, function(object, report)
    local properties = spriteProperties(object)
    if not isRelevantFrameSprite(object, properties) then
        return
    end

    report:section("Frame / wall properties")
    report:field("objectType", Safe.value("object.getType", function()
        return object:getType()
    end, nil))
    report:field("orientationHint", frameOrientation(object, properties) or "<unset>")

    -- TileZed exposes human-facing double-doorframe choices. B42.20.3 runtime
    -- registers the concrete DoubleDoor1 / DoubleDoor2 flags, so report both
    -- directly and keep CutawayHint visible until the editor mapping is proven.
    report:field("DoubleDoor", hasProperty(properties, "DoubleDoor"))
    report:field("DoubleDoor1", hasFlag(properties, IsoFlagType.DoubleDoor1) or hasProperty(properties, "DoubleDoor1"))
    report:field("DoubleDoor2", hasFlag(properties, IsoFlagType.DoubleDoor2) or hasProperty(properties, "DoubleDoor2"))
    report:field("CutawayHint", propertyValue(properties, "CutawayHint") or "<unset>")

    -- WallStyle is visible in TileZed but is not a B42.20.3 TilePropertyKey in
    -- the inspected game JAR. Reporting it here lets runtime evidence decide
    -- whether tile definitions still carry it as editor-authored metadata.
    report:field("WallStyle", propertyValue(properties, "WallStyle") or "<unset>")

    report:field("WallObjectAllowDoorframe", hasProperty(properties, "WallObjectAllowDoorframe"))
    report:field("DoorWallN", hasProperty(properties, "DoorWallN"))
    report:field("DoorWallW", hasProperty(properties, "DoorWallW"))
    report:field("doorFrN", hasFlag(properties, IsoFlagType.doorFrN))
    report:field("doorFrW", hasFlag(properties, IsoFlagType.doorFrW))
end)

return Frame
