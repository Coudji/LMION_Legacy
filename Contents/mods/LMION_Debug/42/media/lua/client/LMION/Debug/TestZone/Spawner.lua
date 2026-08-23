require "LMION/Debug/Registry"

LMION.Debug.TestZone = LMION.Debug.TestZone or {}

local Spawner = LMION.Debug.TestZone.Spawner or {}
LMION.Debug.TestZone.Spawner = Spawner

local STANDARD_FRAME_N = "fixtures_doors_frames_01_1"
local PAIRED_FRAME_LEFT_N = "fixtures_doors_frames_01_26"
local PAIRED_FRAME_RIGHT_N = "fixtures_doors_frames_01_27"

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

local function resolveEntry(entry)
    if entry == nil or entry.id == nil then
        return nil, "invalid manifest entry"
    end
    if ScriptManager == nil or ScriptManager.instance == nil then
        return nil, "ScriptManager unavailable"
    end
    if SpriteConfigManager == nil or SpriteConfigManager.GetObjectInfoList == nil then
        return nil, "SpriteConfigManager unavailable"
    end
    if ComponentType == nil or ComponentType.SpriteConfig == nil then
        return nil, "ComponentType.SpriteConfig unavailable"
    end

    local gameScript = ScriptManager.instance:getGameEntityScript(entry.id)
    if gameScript == nil then
        return nil, "missing entity"
    end

    local spriteScript = gameScript:getComponentScriptFor(ComponentType.SpriteConfig)
    if spriteScript == nil then
        return nil, "missing SpriteConfig"
    end

    local objectInfos = SpriteConfigManager.GetObjectInfoList()
    if objectInfos == nil then
        return nil, "missing ObjectInfo list"
    end

    local objectInfo = nil
    for i = 0, objectInfos:size() - 1 do
        local info = objectInfos:get(i)
        if info ~= nil and info:getScript() == spriteScript then
            objectInfo = info
            break
        end
    end

    if objectInfo == nil then
        return nil, "missing ObjectInfo"
    end

    local closedFace = objectInfo:getFace("n")
    if closedFace == nil then
        return nil, "missing north face"
    end

    local openFace = objectInfo:getFace("n_open")
    if openFace ~= nil
        and (openFace:getWidth() ~= closedFace:getWidth()
        or openFace:getHeight() ~= closedFace:getHeight()) then
        openFace = nil
    end

    return {
        gameScript = gameScript,
        spriteScript = spriteScript,
        closedFace = closedFace,
        openFace = openFace,
    }, nil
end

local function frameSprite(mode)
    if mode == "standard" then
        return STANDARD_FRAME_N
    end
    if mode == "paired-left" then
        return PAIRED_FRAME_LEFT_N
    end
    if mode == "paired-right" then
        return PAIRED_FRAME_RIGHT_N
    end
    return nil
end

local function spawnFrame(square, spriteName)
    if spriteName == nil then
        return true
    end
    if getSprite ~= nil and getSprite(spriteName) == nil then
        return false
    end

    local frame = IsoObject.new(getCell(), square, spriteName)
    if frame == nil then
        return false
    end

    if frame.getModData ~= nil then
        frame:getModData().lmionTestZoneFrame = true
    end

    square:AddTileObject(frame)
    return true
end

local function addSpecialObject(square, object)
    local insertIndex = square:getObjects():size()
    square:AddSpecialObject(object, insertIndex)

    if triggerEvent ~= nil then
        triggerEvent("OnObjectAdded", object)
    end
end

local function tagObject(object, entry, partIndex)
    if object == nil or object.getModData == nil then
        return
    end

    local data = object:getModData()
    data.lmionTestZone = true
    data.lmionTestZoneKind = entry.kind
    data.lmionTestZoneEntity = entry.id
    data.lmionTestZonePart = partIndex
end

local function spawnPart(entry, resolved, square, spriteName, partIndex, result)
    local wantedFrame = frameSprite(entry.frame)
    if wantedFrame ~= nil then
        if not spawnFrame(square, wantedFrame) then
            return false, "frame spawn failed"
        end
        result.framesSpawned = result.framesSpawned + 1
        result.objectsSpawned = result.objectsSpawned + 1
    end

    local object = IsoDoor.new(getCell(), square, spriteName, true)
    if object == nil then
        return false, "door spawn failed"
    end

    tagObject(object, entry, partIndex)

    if GameEntityFactory ~= nil and GameEntityFactory.CreateIsoObjectEntity ~= nil then
        GameEntityFactory.CreateIsoObjectEntity(object, resolved.gameScript, true)
    end

    addSpecialObject(square, object)

    result.objectsSpawned = result.objectsSpawned + 1
    return true, nil
end

local function spawnEntry(entry, originSquare, result)
    local resolved, reason = resolveEntry(entry)
    if resolved == nil then
        return false, reason
    end

    local originX = originSquare:getX()
    local originY = originSquare:getY()
    local originZ = originSquare:getZ()
    local closedFace = resolved.closedFace
    local partIndex = 0

    for z = 0, closedFace:getzLayers() - 1 do
        for x = 0, closedFace:getWidth() - 1 do
            for y = 0, closedFace:getHeight() - 1 do
                local tileInfo = closedFace:getTileInfo(x, y, z)

                if tileInfo ~= nil and tileInfo:getSpriteName() ~= nil then
                    partIndex = partIndex + 1
                    local square = getSquare(
                        originX + entry.x + x,
                        originY + entry.y + y,
                        originZ + z
                    )

                    if square == nil then
                        return false, "target square unloaded"
                    end

                    local ok, partReason = spawnPart(
                        entry,
                        resolved,
                        square,
                        tostring(tileInfo:getSpriteName()),
                        partIndex,
                        result
                    )

                    if not ok then
                        return false, partReason
                    end
                end
            end
        end
    end

    if partIndex == 0 then
        return false, "north face contains no tiles"
    end

    return true, nil
end

function Spawner.spawn(entries, originSquare)
    local result = {
        spawned = 0,
        objectsSpawned = 0,
        framesSpawned = 0,
        failures = {},
    }

    if originSquare == nil then
        result.failures[#result.failures + 1] = {
            id = "<zone>",
            reason = "origin square unavailable",
        }
        return result
    end

    for _, entry in ipairs(entries or {}) do
        local ok, reason = spawnEntry(entry, originSquare, result)
        if ok then
            result.spawned = result.spawned + 1
        else
            result.failures[#result.failures + 1] = {
                id = entry ~= nil and entry.id or "<nil>",
                reason = reason or "unknown",
            }
        end
    end

    return result
end

return Spawner
