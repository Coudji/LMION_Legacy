require "LMION/Debug/Registry"
require "LMION/Debug/Util/Safe"

local Debug = LMION.Debug
local Safe = Debug.Util.Safe
local Openings = LMION.Openings

local function propertyValue(object, name)
    local properties = object and object:getProperties() or nil
    if properties == nil or not properties:has(name) then
        return nil
    end
    return properties:get(name)
end

local function getOpeningId(object)
    local entityName = propertyValue(object, "EntityScriptName")
    if entityName ~= nil and Openings.resolveId(tostring(entityName)) ~= nil then
        return tostring(entityName)
    end

    local sprite = object and object:getSprite() or nil
    local profile = sprite and LMION.Doors and LMION.Doors.getProfileForSprite
        and LMION.Doors.getProfileForSprite(sprite)
        or nil
    if profile ~= nil and Openings.resolveId(profile.id) ~= nil then
        return profile.id
    end

    return nil
end

local function extensionLabel(extension)
    return tostring(extension.source)
        .. ":" .. tostring(extension.id)
        .. " (priority " .. tostring(extension.priority) .. ")"
end

local function containsIndex(indices, value)
    for _, index in ipairs(indices or {}) do
        if index == value then
            return true
        end
    end
    return false
end

local function getObservedLeaf(object, definition)
    if definition == nil or definition.topology ~= "twoLeaves" or definition.leaves == nil then
        return nil
    end

    local index = Safe.value("IsoDoor.getDoubleDoorIndex", function()
        return IsoDoor.getDoubleDoorIndex(object)
    end, -1)
    if type(index) ~= "number" or index < 0 then
        return nil
    end

    local facing = object:getNorth() and "N" or "W"
    for _, leafId in ipairs({"A", "B"}) do
        local leaf = definition.leaves[leafId]
        local indices = leaf and leaf.doubleDoorIndices and leaf.doubleDoorIndices[facing] or nil
        if containsIndex(indices, index) then
            return leafId
        end
    end

    return nil
end

Debug.registerInspector("opening.definition", 11, function(object, report)
    if Openings == nil or object == nil then
        return
    end

    local openingId = getOpeningId(object)
    local resolvedId = openingId and Openings.resolveId(openingId) or nil
    if resolvedId == nil then
        return
    end

    local base = Openings.getBaseDefinition(resolvedId)
    local effective = Openings.getEffectiveDefinition(resolvedId)
    local extensions = Openings.getExtensions(resolvedId)

    report:section("LMION Opening")
    report:field("observedId", openingId)
    report:field("baseId", resolvedId)
    report:field("kind", effective and effective.kind or nil)
    report:field("family", effective and effective.familyName or nil)
    report:field("baseTopology", base and base.topology or nil)
    report:field("effectiveTopology", effective and effective.topology or nil)

    if effective and effective.topology == "twoLeaves" and effective.leaves then
        report:field("leaf", getObservedLeaf(object, effective) or "<unknown>")
        report:field("leaf.A.entity", effective.leaves.A and effective.leaves.A.entity or nil)
        report:field("leaf.B.entity", effective.leaves.B and effective.leaves.B.entity or nil)
    end

    if #extensions == 0 then
        report:field("extensions", "<none>")
    else
        for index, extension in ipairs(extensions) do
            report:field("extension[" .. tostring(index) .. "]", extensionLabel(extension))
        end
    end
end)

return Debug
