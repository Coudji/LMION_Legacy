require "LMION/Debug/Registry"

LMION.Debug.Showroom = LMION.Debug.Showroom or {}

local Catalog = LMION.Debug.Showroom.Catalog or {}
LMION.Debug.Showroom.Catalog = Catalog

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

local function sameSingleIdentity(a, b)
    if a == nil or b == nil
        or a.open or b.open
        or a.doubleDoor ~= nil or b.doubleDoor ~= nil
        or a.garageDoor ~= nil or b.garageDoor ~= nil
        or a.sheet == nil or b.sheet == nil
        or a.sheet ~= b.sheet
        or not hasUsableOrientation(a)
        or not hasUsableOrientation(b)
        or a.north == b.north then
        return false
    end

    return sameValue(a.entityScriptName, b.entityScriptName)
        and sameValue(a.doorSound, b.doorSound)
        and sameValue(a.customName, b.customName)
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

local function getExpectedStateOffset(record)
    if record == nil then
        return nil
    end

    if record.garageDoor ~= nil then
        return 8
    end

    -- DoubleDoor groups do not have a reliable one-part closed/open mate.
    -- Opening the group can rotate and relocate parts onto other squares.
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

    if candidate == nil then
        return nil
    end

    if record.north ~= candidate.north or record.west ~= candidate.west then
        return nil
    end

    if record.open == candidate.open then
        return nil
    end

    return candidate
end

local function shouldKeepSingleOrientation(scan, record)
    if record.north or record.sheet == nil or record.index == nil then
        return true
    end

    for _, delta in ipairs({ -1, 1 }) do
        local mate = getBySheetIndex(scan, record.sheet, record.index + delta)

        if sameSingleIdentity(record, mate) and mate.north then
            local openA = Catalog.getStateMate(scan, record)
            local openB = Catalog.getStateMate(scan, mate)

            if openA ~= nil
                and openB ~= nil
                and openA.sheet == openB.sheet
                and openA.index ~= nil
                and openB.index ~= nil
                and math.abs(openA.index - openB.index) == 1 then
                return false
            end
        end
    end

    return true
end

local function nearestGroupPart(scan, anchor, fieldName, wantedValue, maxDistance)
    if anchor == nil or anchor.sheet == nil or anchor.index == nil then
        return nil
    end

    local sheetRecords = scan.bySheetIndex[anchor.sheet]

    if sheetRecords == nil then
        return nil
    end

    local best = nil
    local bestDistance = nil

    for index, candidate in pairs(sheetRecords) do
        if candidate ~= nil
            and candidate[fieldName] == wantedValue
            and candidate.open == false
            and candidate.north == anchor.north
            and candidate.west == anchor.west
            and sameGroupIdentity(candidate, anchor) then
            local distance = math.abs(index - anchor.index)

            if distance <= maxDistance
                and (bestDistance == nil or distance < bestDistance) then
                best = candidate
                bestDistance = distance
            end
        end
    end

    return best
end

local function collectGarageParts(scan, anchor)
    local expectedOffsets = { 0, 1, 2 }
    local parts = {}

    for wanted = 1, 3 do
        local candidate = getBySheetIndex(
            scan,
            anchor.sheet,
            anchor.index ~= nil and anchor.index + expectedOffsets[wanted] or nil
        )

        if candidate == nil or candidate.garageDoor ~= wanted or candidate.open then
            candidate = nearestGroupPart(scan, anchor, "garageDoor", wanted, 16)
        end

        if candidate == nil then
            return nil
        end

        parts[#parts + 1] = candidate
    end

    return parts
end

local function collectDoubleParts(scan, anchor)
    local expectedOffsets = { 0, 1, 8, 9 }
    local parts = {}

    for wanted = 1, 4 do
        local candidate = getBySheetIndex(
            scan,
            anchor.sheet,
            anchor.index ~= nil and anchor.index + expectedOffsets[wanted] or nil
        )

        if candidate == nil or candidate.doubleDoor ~= wanted or candidate.open then
            candidate = nearestGroupPart(scan, anchor, "doubleDoor", wanted, 16)
        end

        if candidate == nil then
            return nil
        end

        parts[#parts + 1] = candidate
    end

    return parts
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
    local values = manager:getNamedMap():values()
    local iterator = values:iterator()

    while iterator:hasNext() do
        local sprite = iterator:next()
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
    }

    for _, record in ipairs(scan.records) do
        if not record.open then
            if not hasUsableOrientation(record) then
                counts.unoriented = counts.unoriented + 1
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
            elseif record.garageDoor == nil
                and record.doubleDoor == nil
                and shouldKeepSingleOrientation(scan, record) then
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
