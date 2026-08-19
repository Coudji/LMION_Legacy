require "LMION/Debug/Registry"

LMION.Debug.Showroom = LMION.Debug.Showroom or {}

local Catalog = LMION.Debug.Showroom.Catalog or {}
LMION.Debug.Showroom.Catalog = Catalog

local DOUBLE_CLOSED_OFFSETS = { 0, 1, 8, 9 }
local DOUBLE_NORTH_OPEN_OFFSETS = { 5, 3, 4, 4 }
local DOUBLE_WEST_OPEN_OFFSETS = { 4, 4, 5, 3 }
local GARAGE_CLOSED_OFFSETS = { 0, 1, 2 }
local GARAGE_OPEN_OFFSET = 8

local function propertyValue(properties, name)
    if properties == nil or not properties:has(name) then
        return nil
    end

    return properties:get(name)
end

local function parseSpriteName(name)
    if name == nil then
        return nil, nil
    end

    local sheet, index = tostring(name):match("^(.*_)(%d+)$")
    return sheet, index ~= nil and tonumber(index) or nil
end

local function isDoorEntityName(name)
    if name == nil then
        return false
    end

    local lower = string.lower(tostring(name))
    return string.find(lower, "door", 1, true) ~= nil
        or string.find(lower, "gate", 1, true) ~= nil
end

local function makeRecord(sprite)
    if sprite == nil then
        return nil
    end

    local name = sprite:getName()

    if name == nil or tostring(name) == "" then
        return nil
    end

    local properties = sprite:getProperties()

    if properties == nil then
        return nil
    end

    local spriteType = sprite:getType()
    local doorN = properties:has(IsoFlagType.doorN)
        or spriteType == IsoObjectType.doorN
    local doorW = properties:has(IsoFlagType.doorW)
        or spriteType == IsoObjectType.doorW
    local entityScriptName = propertyValue(properties, "EntityScriptName")
    local doubleDoor = tonumber(propertyValue(properties, "DoubleDoor"))
    local garageDoor = tonumber(propertyValue(properties, "GarageDoor"))

    if not doorN
        and not doorW
        and doubleDoor == nil
        and garageDoor == nil
        and not isDoorEntityName(entityScriptName) then
        return nil
    end

    local sheet, index = parseSpriteName(name)
    local open = properties:has(IsoFlagType.open)

    if doubleDoor ~= nil and doubleDoor >= 5 then
        open = true
    elseif garageDoor ~= nil and garageDoor >= 4 then
        open = true
    end

    return {
        sprite = sprite,
        properties = properties,
        name = tostring(name),
        sheet = sheet,
        index = index,
        north = doorN,
        west = doorW,
        open = open,
        entityScriptName = entityScriptName ~= nil and tostring(entityScriptName) or nil,
        doorSound = propertyValue(properties, "DoorSound"),
        customName = propertyValue(properties, "CustomName"),
        material = propertyValue(properties, "Material"),
        material2 = propertyValue(properties, "Material2"),
        material3 = propertyValue(properties, "Material3"),
        doubleDoor = doubleDoor,
        garageDoor = garageDoor,
    }
end

local function recordSort(a, b)
    if a.sheet == b.sheet and a.index ~= nil and b.index ~= nil then
        return a.index < b.index
    end

    return a.name < b.name
end

local function sameValue(a, b)
    if a == nil and b == nil then
        return true
    end

    return tostring(a) == tostring(b)
end

local function hasUsableOrientation(record)
    return record ~= nil and record.north ~= record.west
end

local function isCanonicalOrientation(record)
    return record ~= nil and record.north == true and record.west ~= true
end

local function sameGroupIdentity(a, b)
    if a == nil or b == nil then
        return false
    end

    return sameValue(a.entityScriptName, b.entityScriptName)
        and sameValue(a.doorSound, b.doorSound)
        and sameValue(a.material, b.material)
        and sameValue(a.material2, b.material2)
        and sameValue(a.material3, b.material3)
end

local function getBySheetIndex(scan, sheet, index)
    if scan == nil or sheet == nil or index == nil then
        return nil
    end

    local sheetRecords = scan.bySheetIndex[sheet]
    return sheetRecords ~= nil and sheetRecords[index] or nil
end

local function sameOrientation(a, b)
    return a ~= nil
        and b ~= nil
        and a.north == b.north
        and a.west == b.west
end

local function oppositeOrientation(a, b)
    return a ~= nil
        and b ~= nil
        and a.north == b.west
        and a.west == b.north
end

local function getExpectedStateOffset(record)
    if record == nil then
        return nil
    end

    if record.garageDoor ~= nil then
        return GARAGE_OPEN_OFFSET
    end

    -- DoubleDoor groups use a different sprite offset for each group member.
    if record.doubleDoor ~= nil then
        return nil
    end

    return 2
end

function Catalog.getStateMate(scan, record)
    if scan == nil or record == nil or record.sheet == nil or record.index == nil then
        return nil
    end

    local offset = getExpectedStateOffset(record)

    if offset == nil then
        return nil
    end

    if record.open then
        offset = -offset
    end

    local candidate = getBySheetIndex(scan, record.sheet, record.index + offset)

    if candidate == nil or not sameOrientation(record, candidate) then
        return nil
    end

    if record.open == candidate.open then
        return nil
    end

    if record.garageDoor ~= nil then
        local expected = record.open and record.garageDoor - 3 or record.garageDoor + 3

        if candidate.garageDoor ~= expected then
            return nil
        end
    end

    return candidate
end

local function getClosedGroupPart(scan, anchor, fieldName, wantedValue, offset)
    local candidate = getBySheetIndex(
        scan,
        anchor.sheet,
        anchor.index ~= nil and anchor.index + offset or nil
    )

    if candidate == nil
        or candidate[fieldName] ~= wantedValue
        or candidate.open
        or not sameOrientation(anchor, candidate)
        or not sameGroupIdentity(anchor, candidate) then
        return nil
    end

    return candidate
end

local function validateDoubleOpenState(scan, record, wantedValue)
    if record == nil or record.sheet == nil or record.index == nil then
        return false
    end

    local offsets = record.north and DOUBLE_NORTH_OPEN_OFFSETS or DOUBLE_WEST_OPEN_OFFSETS
    local offset = offsets[wantedValue]
    local openRecord = getBySheetIndex(scan, record.sheet, record.index + offset)

    return openRecord ~= nil
        and openRecord.open
        and oppositeOrientation(record, openRecord)
        and openRecord.doubleDoor == wantedValue + 4
end

local function collectDoubleParts(scan, anchor)
    local parts = {}

    for wanted = 1, 4 do
        local candidate = getClosedGroupPart(
            scan,
            anchor,
            "doubleDoor",
            wanted,
            DOUBLE_CLOSED_OFFSETS[wanted]
        )

        if candidate == nil or not validateDoubleOpenState(scan, candidate, wanted) then
            return nil
        end

        parts[#parts + 1] = candidate
    end

    return parts
end

local function validateGarageOpenState(scan, record, wantedValue)
    if record == nil or record.sheet == nil or record.index == nil then
        return false
    end

    local openRecord = getBySheetIndex(
        scan,
        record.sheet,
        record.index + GARAGE_OPEN_OFFSET
    )

    return openRecord ~= nil
        and openRecord.open
        and sameOrientation(record, openRecord)
        and openRecord.garageDoor == wantedValue + 3
end

local function collectGarageParts(scan, anchor)
    local parts = {}

    for wanted = 1, 3 do
        local candidate = getClosedGroupPart(
            scan,
            anchor,
            "garageDoor",
            wanted,
            GARAGE_CLOSED_OFFSETS[wanted]
        )

        if candidate == nil or not validateGarageOpenState(scan, candidate, wanted) then
            return nil
        end

        parts[wanted] = candidate
    end

    -- A garage chain is START + one or more MID + END. Spawn a four-wide
    -- representative so the showroom also exercises repeated middle segments.
    return {
        parts[1],
        parts[2],
        parts[2],
        parts[3],
    }
end

local function familySort(a, b)
    local order = {
        garage = 1,
        double = 2,
        entity = 3,
        single = 4,
    }

    local aOrder = order[a.kind] or 99
    local bOrder = order[b.kind] or 99

    if aOrder ~= bOrder then
        return aOrder < bOrder
    end

    return a.anchor.name < b.anchor.name
end

function Catalog.scan()
    local scan = {
        records = {},
        bySheetIndex = {},
        counts = {
            sprites = 0,
            candidates = 0,
        },
    }

    local manager = IsoSpriteManager.instance
    local namedSprites = transformIntoKahluaTable(manager:getNamedMap())

    for _, sprite in pairs(namedSprites) do
        scan.counts.sprites = scan.counts.sprites + 1

        local record = makeRecord(sprite)

        if record ~= nil then
            scan.records[#scan.records + 1] = record
            scan.counts.candidates = scan.counts.candidates + 1

            if record.sheet ~= nil and record.index ~= nil then
                scan.bySheetIndex[record.sheet] = scan.bySheetIndex[record.sheet] or {}
                scan.bySheetIndex[record.sheet][record.index] = record
            end
        end
    end

    table.sort(scan.records, recordSort)
    Catalog.lastScan = scan
    return scan
end

function Catalog.buildFamilies(scan)
    local families = {}
    local counts = {
        garage = 0,
        double = 0,
        entity = 0,
        single = 0,
        incomplete = 0,
        unoriented = 0,
        ignoredOrientation = 0,
    }

    for _, record in ipairs(scan.records) do
        if not record.open then
            if not hasUsableOrientation(record) then
                counts.unoriented = counts.unoriented + 1
            elseif not isCanonicalOrientation(record) then
                counts.ignoredOrientation = counts.ignoredOrientation + 1
            elseif record.garageDoor == 1 then
                local parts = collectGarageParts(scan, record)

                if parts ~= nil then
                    families[#families + 1] = {
                        kind = "garage",
                        anchor = record,
                        parts = parts,
                    }
                    counts.garage = counts.garage + 1
                else
                    counts.incomplete = counts.incomplete + 1
                end
            elseif record.doubleDoor == 1 then
                local parts = collectDoubleParts(scan, record)

                if parts ~= nil then
                    families[#families + 1] = {
                        kind = "double",
                        anchor = record,
                        parts = parts,
                    }
                    counts.double = counts.double + 1
                else
                    counts.incomplete = counts.incomplete + 1
                end
            elseif record.garageDoor == nil and record.doubleDoor == nil then
                local kind = record.entityScriptName ~= nil and "entity" or "single"

                families[#families + 1] = {
                    kind = kind,
                    anchor = record,
                    parts = { record },
                }
                counts[kind] = counts[kind] + 1
            end
        end
    end

    table.sort(families, familySort)

    scan.families = families
    scan.familyCounts = counts
    return families, counts
end

return Catalog
