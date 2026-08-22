require "LMION/Debug/Registry"

LMION.Debug.TestZone = LMION.Debug.TestZone or {}

local Spawner = LMION.Debug.TestZone.Spawner or {}
LMION.Debug.TestZone.Spawner = Spawner

local STANDARD_FRAME_N = "fixtures_doors_frames_01_1"
local PAIRED_FRAME_LEFT_N = "fixtures_doors_frames_01_26"
local PAIRED_FRAME_RIGHT_N = "fixtures_doors_frames_01_27"
local SECTION_GAP_Y = 3

local SECTION_ORDER = {
    "garage",
    "portal",
    "paired",
    "single",
}

local SECTION_LAYOUT = {
    garage = { columns = 7, gapX = 1, gapY = 2 },
    portal = { columns = 6, gapX = 1, gapY = 2 },
    paired = { columns = 5, gapX = 1, gapY = 2 },
    single = { columns = 18, gapX = 0, gapY = 2 },
}

local function isMultiplayer()
    return (isClient ~= nil and isClient())
        or (isServer ~= nil and isServer())
end

local function getSquare(x, y, z)
    return getCell():getGridSquare(x, y, z)
end

function Spawner.isAreaLoaded(originX, originY, z, width, height)
    for y = originY, originY + height - 1 do
        for x = originX, originX + width - 1 do
            if getSquare(x, y, z) == nil then
                return false, x, y
            end
        end
    end
    return true, nil, nil
end

local function clearSquare(square)
    local removed = 0
    local objects = square:getObjects()

    for i = objects:size() - 1, 0, -1 do
        local object = objects:get(i)
        if object ~= nil then
            square:transmitRemoveItemFromSquare(object)
            if object:getObjectIndex() ~= -1 then
                square:RemoveTileObject(object)
            end
            removed = removed + 1
        end
    end

    return removed
end

function Spawner.prepareArea(originX, originY, z, width, height, floorSprite)
    if isMultiplayer() then
        return false, "test zone is single-player debug only for now"
    end
    if floorSprite == nil or tostring(floorSprite) == "" then
        return false, "missing floor sprite"
    end
    if getSprite ~= nil and getSprite(floorSprite) == nil then
        return false, "unknown floor sprite: " .. tostring(floorSprite)
    end

    local loaded, missingX, missingY = Spawner.isAreaLoaded(originX, originY, z, width, height)
    if not loaded then
        return false, "unloaded:" .. tostring(missingX) .. "," .. tostring(missingY)
    end

    local result = {
        squares = 0,
        removedObjects = 0,
        floorSprite = floorSprite,
    }

    for y = originY, originY + height - 1 do
        for x = originX, originX + width - 1 do
            local square = getSquare(x, y, z)
            result.removedObjects = result.removedObjects + clearSquare(square)
            square:addFloor(floorSprite)
            square:disableErosion()
            result.squares = result.squares + 1
        end
    end

    return true, nil, result
end

local function getOpenFace(entry)
    if entry == nil or entry.objectInfo == nil then
        return nil
    end
    return entry.objectInfo:getFace("n_open")
end

local function buildFamily(entry)
    if entry == nil or entry.objectInfo == nil then
        return nil, "missing ObjectInfo"
    end

    local closedFace = entry.objectInfo:getFace("n")
    if closedFace == nil then
        return nil, "missing north ObjectInfo face"
    end

    local openFace = getOpenFace(entry)
    if openFace ~= nil
        and (openFace:getWidth() ~= closedFace:getWidth()
        or openFace:getHeight() ~= closedFace:getHeight()) then
        openFace = nil
    end

    local parts = {}

    for z = 0, closedFace:getzLayers() - 1 do
        for x = 0, closedFace:getWidth() - 1 do
            for y = 0, closedFace:getHeight() - 1 do
                local tileInfo = closedFace:getTileInfo(x, y, z)
                if tileInfo ~= nil and tileInfo:getSpriteName() ~= nil then
                    local openSprite = nil
                    if openFace ~= nil then
                        local openTileInfo = openFace:getTileInfo(x, y, z)
                        if openTileInfo ~= nil then
                            openSprite = openTileInfo:getSpriteName()
                        end
                    end

                    parts[#parts + 1] = {
                        gameScript = entry.gameScript,
                        spriteScript = entry.spriteScript,
                        sprite = tostring(tileInfo:getSpriteName()),
                        openSprite = openSprite ~= nil and tostring(openSprite) or nil,
                        x = x,
                        y = y,
                        z = z,
                    }
                end
            end
        end
    end

    if #parts == 0 then
        return nil, "empty north ObjectInfo face"
    end

    local width = closedFace:getWidth()
    local height = closedFace:getHeight()
    local onCreate = entry.spriteScript ~= nil and entry.spriteScript:getOnCreate() or nil
    local kind = "single"

    if onCreate == "LMION.Doors.onCreateGarage" then
        kind = "garage"
    elseif width > 1 or height > 1 then
        kind = "portal"
    end

    return {
        id = entry.id,
        name = entry.gameScript ~= nil and tostring(entry.gameScript:getName()) or entry.id,
        kind = kind,
        width = width,
        height = height,
        parts = parts,
        entityCount = 1,
    }, nil
end

local function shiftParts(parts, offsetX, offsetY)
    local shifted = {}

    for _, part in ipairs(parts) do
        shifted[#shifted + 1] = {
            gameScript = part.gameScript,
            spriteScript = part.spriteScript,
            sprite = part.sprite,
            openSprite = part.openSprite,
            x = part.x + offsetX,
            y = part.y + offsetY,
            z = part.z,
        }
    end

    return shifted
end

local function mergePaired(left, right)
    local parts = shiftParts(left.parts, 0, 0)
    local rightParts = shiftParts(right.parts, left.width, 0)

    for _, part in ipairs(rightParts) do
        parts[#parts + 1] = part
    end

    return {
        id = left.id .. "+" .. right.id,
        name = left.name .. "+" .. right.name,
        kind = "paired",
        width = left.width + right.width,
        height = math.max(left.height, right.height),
        parts = parts,
        entityCount = 2,
    }
end

local function prepareFamilies(entries)
    local raw = {}
    local byId = {}
    local rejected = {}

    for _, entry in ipairs(entries or {}) do
        local family, reason = buildFamily(entry)
        if family ~= nil then
            raw[#raw + 1] = family
            byId[family.id] = family
        else
            rejected[#rejected + 1] = {
                id = entry ~= nil and tostring(entry.id) or "<nil>",
                reason = reason or "unknown",
            }
        end
    end

    table.sort(raw, function(a, b)
        return a.id < b.id
    end)

    local consumed = {}
    local sections = {
        garage = {},
        portal = {},
        paired = {},
        single = {},
    }

    for _, family in ipairs(raw) do
        if not consumed[family.id] then
            if family.kind == "single" and string.sub(family.id, -4) == "Left" then
                local rightId = string.sub(family.id, 1, #family.id - 4) .. "Right"
                local right = byId[rightId]
                if right ~= nil and right.kind == "single" then
                    sections.paired[#sections.paired + 1] = mergePaired(family, right)
                    consumed[family.id] = true
                    consumed[right.id] = true
                else
                    sections.single[#sections.single + 1] = family
                    consumed[family.id] = true
                end
            elseif family.kind == "single" and string.sub(family.id, -5) == "Right" then
                local leftId = string.sub(family.id, 1, #family.id - 5) .. "Left"
                if byId[leftId] == nil then
                    sections.single[#sections.single + 1] = family
                end
                consumed[family.id] = true
            else
                sections[family.kind][#sections[family.kind] + 1] = family
                consumed[family.id] = true
            end
        end
    end

    for _, key in ipairs(SECTION_ORDER) do
        table.sort(sections[key], function(a, b)
            return a.id < b.id
        end)
    end

    return sections, rejected
end

local function squareIsUsable(square)
    if square == nil then
        return false, "unloaded"
    end

    local objects = square:getObjects()
    local floor = square:getFloor()
    local expected = floor ~= nil and 1 or 0
    if objects ~= nil and objects:size() > expected then
        return false, "occupied"
    end

    local specialObjects = square:getSpecialObjects()
    if specialObjects ~= nil and specialObjects:size() > 0 then
        return false, "occupied"
    end

    return true, nil
end

local function familySquaresAvailable(family, baseX, baseY, baseZ)
    for _, part in ipairs(family.parts) do
        local square = getSquare(baseX + part.x, baseY + part.y, baseZ + part.z)
        local usable, reason = squareIsUsable(square)
        if not usable then
            return false, reason
        end
    end

    return true, nil
end

local function frameSpriteFor(family, partIndex, part)
    if family.kind == "garage" or family.kind == "portal" then
        return nil
    end

    if family.kind == "paired" then
        if partIndex == 1 then
            return PAIRED_FRAME_LEFT_N
        end
        return PAIRED_FRAME_RIGHT_N
    end

    if part.spriteScript ~= nil and not part.spriteScript:getDontNeedFrame() then
        return STANDARD_FRAME_N
    end

    return nil
end

local function spawnFrame(square, spriteName)
    if spriteName == nil then
        return nil
    end
    if getSprite ~= nil and getSprite(spriteName) == nil then
        return nil
    end

    local frame = IsoObject.new(getCell(), square, spriteName)
    if frame == nil then
        return nil
    end

    if frame.getModData ~= nil then
        frame:getModData().lmionTestZoneFrame = true
    end

    square:AddTileObject(frame)
    return frame
end

local function isNativeGroupedDoor(spriteName)
    if getSprite == nil then
        return false
    end

    local sprite = getSprite(spriteName)
    if sprite == nil then
        return false
    end

    local properties = sprite:getProperties()
    if properties == nil then
        return false
    end

    return properties:has("DoubleDoor") or properties:has("GarageDoor")
end

local function tagObject(object, family, part, partIndex)
    if object == nil or object.getModData == nil then
        return
    end

    local data = object:getModData()
    data.lmionTestZone = true
    data.lmionTestZoneKind = family.kind
    data.lmionTestZoneFamily = family.id
    data.lmionTestZoneEntity = part.gameScript ~= nil and tostring(part.gameScript:getFullName()) or nil
    data.lmionTestZonePart = partIndex
end

local function addSpecialObject(square, object)
    local insertIndex = square:getObjects():size()
    square:AddSpecialObject(object, insertIndex)

    if triggerEvent ~= nil then
        triggerEvent("OnObjectAdded", object)
    end
end

local function spawnPart(family, part, square, partIndex, result)
    local frameSprite = frameSpriteFor(family, partIndex, part)

    if frameSprite ~= nil then
        local frame = spawnFrame(square, frameSprite)
        if frame == nil then
            return false, "frame-spawn-failed:" .. tostring(frameSprite)
        end
        result.framesSpawned = result.framesSpawned + 1
        result.objectsSpawned = result.objectsSpawned + 1
    end

    local object
    local grouped = isNativeGroupedDoor(part.sprite)

    if grouped then
        object = IsoDoor.new(getCell(), square, part.sprite, true)
    elseif part.openSprite ~= nil then
        object = IsoThumpable.new(getCell(), square, part.sprite, part.openSprite, true, {})
    else
        object = IsoThumpable.new(getCell(), square, part.sprite, true, {})
    end

    if object == nil then
        return false, "door-spawn-failed:" .. tostring(part.sprite)
    end

    if not grouped and object.setIsDoor ~= nil then
        object:setIsDoor(true)
    end

    tagObject(object, family, part, partIndex)
    addSpecialObject(square, object)

    if not grouped and GameEntityFactory ~= nil
        and GameEntityFactory.CreateIsoObjectEntity ~= nil
        and part.gameScript ~= nil then
        GameEntityFactory.CreateIsoObjectEntity(object, part.gameScript, true)
    end

    result.objectsSpawned = result.objectsSpawned + 1
    return true, nil
end

local function spawnFamily(family, baseX, baseY, baseZ, result)
    local available, reason = familySquaresAvailable(family, baseX, baseY, baseZ)
    if not available then
        return false, reason
    end

    for index, part in ipairs(family.parts) do
        local square = getSquare(baseX + part.x, baseY + part.y, baseZ + part.z)
        local ok, partReason = spawnPart(family, part, square, index, result)
        if not ok then
            return false, partReason
        end
    end

    return true, nil
end

local function sectionMetrics(families, layout)
    local maxWidth = 1
    local maxHeight = 1

    for _, family in ipairs(families) do
        maxWidth = math.max(maxWidth, family.width)
        maxHeight = math.max(maxHeight, family.height)
    end

    return maxWidth + layout.gapX, maxHeight + layout.gapY
end

local function spawnSection(families, layout, originX, originY, z, result)
    if #families == 0 then
        return 0
    end

    local cellX, cellY = sectionMetrics(families, layout)
    local rows = math.floor((#families - 1) / layout.columns) + 1

    for index, family in ipairs(families) do
        local zero = index - 1
        local column = zero % layout.columns
        local row = math.floor(zero / layout.columns)
        local x = originX + column * cellX
        local y = originY + row * cellY
        local ok, reason = spawnFamily(family, x, y, z, result)

        if ok then
            result.familiesSpawned = result.familiesSpawned + 1
            result.entitiesSpawned = result.entitiesSpawned + family.entityCount
        else
            result.skipped = result.skipped + 1
            result.skipReasons[reason or "unknown"] =
                (result.skipReasons[reason or "unknown"] or 0) + 1
        end
    end

    return rows * cellY - layout.gapY
end

function Spawner.spawn(entries, originSquare)
    local sections, rejected = prepareFamilies(entries)
    local result = {
        entitiesFound = #(entries or {}),
        entitiesSpawned = 0,
        familiesFound = 0,
        familiesSpawned = 0,
        objectsSpawned = 0,
        framesSpawned = 0,
        skipped = 0,
        rejected = rejected,
        skipReasons = {},
        sectionCounts = {},
    }

    if originSquare == nil then
        result.error = "missing origin square"
        return result
    end
    if isMultiplayer() then
        result.error = "test zone spawning is single-player debug only for now"
        return result
    end

    for _, key in ipairs(SECTION_ORDER) do
        result.sectionCounts[key] = #sections[key]
        result.familiesFound = result.familiesFound + #sections[key]
    end

    local originX = originSquare:getX()
    local currentY = originSquare:getY()
    local z = originSquare:getZ()

    for _, key in ipairs(SECTION_ORDER) do
        local families = sections[key]
        if #families > 0 then
            local usedHeight = spawnSection(
                families,
                SECTION_LAYOUT[key],
                originX,
                currentY,
                z,
                result
            )
            currentY = currentY + usedHeight + SECTION_GAP_Y
        end
    end

    Spawner.lastResult = result
    Spawner.lastSections = sections
    return result
end

return Spawner
