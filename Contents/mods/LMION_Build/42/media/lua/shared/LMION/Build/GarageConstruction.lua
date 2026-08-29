local Build = LMION.Build
local Doors = LMION.Doors

local GarageBuild = Build.GarageBuild or {}
Build.GarageBuild = GarageBuild

GarageBuild.LengthModDataKey = "LMIONGarageBuildLength"
GarageBuild.DefaultLength = 3
GarageBuild.MinLength = 2

local GARAGE_IDS = {
    IndustrialGarageDoor = true,
    GreenGarageDoor = true,
    WhiteGarageDoor = true,
    GreyGarageDoor = true,
    RollingGarageDoor = true,
    RedWindowGarageDoor = true,
    RollingWindowGarageDoor = true,
}

local GLAZED_IDS = {
    RedWindowGarageDoor = true,
    RollingWindowGarageDoor = true,
}

local RESOURCE_TYPES = {
    "Base.BlowTorch",
    "Base.SmallSheetMetal",
    "Base.GlassPanel",
    "Base.MetalBar",
    "Base.Hinge",
    "Base.WeldingRods",
}

local BASE_L2 = {
    solid = {
        ["Base.BlowTorch"] = {amount = 1, uses = true},
        ["Base.SmallSheetMetal"] = {amount = 6},
        ["Base.MetalBar"] = {amount = 2},
        ["Base.Hinge"] = {amount = 4},
        ["Base.WeldingRods"] = {amount = 2, uses = true},
    },
    glazed = {
        ["Base.BlowTorch"] = {amount = 1, uses = true},
        ["Base.SmallSheetMetal"] = {amount = 4},
        ["Base.GlassPanel"] = {amount = 2},
        ["Base.MetalBar"] = {amount = 2},
        ["Base.Hinge"] = {amount = 4},
        ["Base.WeldingRods"] = {amount = 2, uses = true},
    },
}

local stockCache = {}

local function normalizeLength(length)
    length = math.floor(tonumber(length) or GarageBuild.DefaultLength)
    length = math.max(GarageBuild.MinLength, length)

    local maximum = Doors.getGarageMaxLength()
    if maximum ~= nil then
        length = math.min(length, maximum)
    end

    return length
end

GarageBuild.normalizeLength = normalizeLength

local function getGameScriptName(objectInfo)
    local spriteScript = objectInfo and objectInfo.getScript and objectInfo:getScript() or nil
    local gameScript = spriteScript and spriteScript:getParent() or nil
    return gameScript and gameScript:getName() or nil
end

function GarageBuild.getGarageIdFromObjectInfo(objectInfo)
    local id = getGameScriptName(objectInfo)
    return GARAGE_IDS[id] and id or nil
end

function GarageBuild.getGarageIdFromLogic(logic)
    local objectInfo = logic and logic.getSelectedBuildObject and logic:getSelectedBuildObject() or nil
    return GarageBuild.getGarageIdFromObjectInfo(objectInfo)
end

function GarageBuild.isGarageId(id)
    return GARAGE_IDS[id] == true
end

function GarageBuild.isGlazed(id)
    return GLAZED_IDS[id] == true
end

function GarageBuild.getLengthFromLogic(logic)
    local recipeData = logic and logic.getRecipeData and logic:getRecipeData() or nil
    local modData = recipeData and recipeData.getModData and recipeData:getModData() or nil
    local length = modData and modData[GarageBuild.LengthModDataKey] or nil
    return normalizeLength(length)
end

function GarageBuild.setLengthOnLogic(logic, length)
    local id = GarageBuild.getGarageIdFromLogic(logic)
    if id == nil then
        return nil
    end

    local recipeData = logic and logic.getRecipeData and logic:getRecipeData() or nil
    local modData = recipeData and recipeData.getModData and recipeData:getModData() or nil
    if modData == nil then
        return nil
    end

    length = normalizeLength(length)
    modData[GarageBuild.LengthModDataKey] = length
    return length
end

function GarageBuild.ensureLengthOnLogic(logic)
    local id = GarageBuild.getGarageIdFromLogic(logic)
    if id == nil then
        return nil
    end

    local recipeData = logic and logic.getRecipeData and logic:getRecipeData() or nil
    local modData = recipeData and recipeData.getModData and recipeData:getModData() or nil
    if modData == nil then
        return nil
    end

    if modData[GarageBuild.LengthModDataKey] == nil then
        modData[GarageBuild.LengthModDataKey] = GarageBuild.DefaultLength
    end

    return GarageBuild.setLengthOnLogic(logic, modData[GarageBuild.LengthModDataKey])
end

function GarageBuild.getRequirements(id, length)
    if not GARAGE_IDS[id] then
        return nil
    end

    length = normalizeLength(length)
    local weldSteps = math.ceil(length / 3)
    local requirements = {
        ["Base.BlowTorch"] = {
            amount = math.min(weldSteps, 10),
            uses = true,
        },
        ["Base.MetalBar"] = {amount = length},
        ["Base.Hinge"] = {amount = length * 2},
        ["Base.WeldingRods"] = {
            amount = math.min(weldSteps * 2, 20),
            uses = true,
        },
    }

    if GLAZED_IDS[id] then
        requirements["Base.SmallSheetMetal"] = {amount = length * 2}
        requirements["Base.GlassPanel"] = {amount = length}
    else
        requirements["Base.SmallSheetMetal"] = {amount = length * 3}
    end

    return requirements
end

function GarageBuild.getRequirement(id, length, fullType)
    local requirements = GarageBuild.getRequirements(id, length)
    return requirements and requirements[fullType] or nil
end

function GarageBuild.getBaseRequirement(id, fullType)
    if not GARAGE_IDS[id] then
        return nil
    end

    local base = GLAZED_IDS[id] and BASE_L2.glazed or BASE_L2.solid
    return base[fullType]
end

function GarageBuild.getExtraRequirements(id, length)
    local requirements = GarageBuild.getRequirements(id, length)
    if requirements == nil then
        return nil
    end

    local extras = {}
    for fullType, requirement in pairs(requirements) do
        local base = GarageBuild.getBaseRequirement(id, fullType)
        local amount = requirement.amount - (base and base.amount or 0)
        if amount > 0 then
            extras[fullType] = {
                amount = amount,
                uses = requirement.uses == true,
            }
        end
    end
    return extras
end

local function getCacheKey(character)
    if character ~= nil and character.getPlayerNum ~= nil then
        return tostring(character:getPlayerNum())
    end
    return tostring(character)
end

local function addItem(entry, item, seen)
    if item == nil or seen[item] then
        return
    end
    seen[item] = true

    entry.items[#entry.items + 1] = item
    entry.count = entry.count + 1
    if instanceof(item, "DrainableComboItem") and item:getCurrentUses() > 0 then
        entry.uses = entry.uses + item:getCurrentUses()
    end
end

local function addContainerItems(entry, container, fullType, seen)
    if container == nil then
        return
    end

    local items = container:getAllTypeEvalRecurse(fullType, ISBuildIsoEntity.predicateMaterial)
    if items ~= nil then
        for i = 0, items:size() - 1 do
            addItem(entry, items:get(i), seen)
        end
    end
end

local function buildStock(character, containers)
    local stock = {}
    if character == nil or ISBuildIsoEntity == nil then
        return stock
    end

    local inventory = character:getInventory()
    local ground = ISBuildIsoEntity.GetAllGroundItemsForPlayer(character)

    for _, fullType in ipairs(RESOURCE_TYPES) do
        local entry = {count = 0, uses = 0, items = {}}
        local seen = {}

        addContainerItems(entry, inventory, fullType, seen)

        if containers ~= nil then
            for i = 0, containers:size() - 1 do
                addContainerItems(entry, containers:get(i), fullType, seen)
            end
        end

        local groundEntry = ground and ground[fullType] or nil
        if groundEntry and groundEntry.items then
            for _, item in ipairs(groundEntry.items) do
                addItem(entry, item, seen)
            end
        end

        stock[fullType] = entry
    end

    return stock
end

function GarageBuild.invalidateStock(character)
    if character == nil then
        stockCache = {}
        return
    end
    stockCache[getCacheKey(character)] = nil
end

function GarageBuild.getStock(character, containers, fresh)
    local key = getCacheKey(character)
    local now = getTimestampMs and getTimestampMs() or 0
    local cached = stockCache[key]

    if not fresh and cached ~= nil and (now == 0 or now - cached.time < 100) then
        return cached.stock
    end

    local stock = buildStock(character, containers)
    stockCache[key] = {time = now, stock = stock}
    return stock
end

function GarageBuild.getAvailable(character, fullType, uses, containers, fresh)
    local stock = GarageBuild.getStock(character, containers, fresh)
    local entry = stock and stock[fullType] or nil
    if entry == nil then
        return 0
    end
    return uses and entry.uses or entry.count
end

function GarageBuild.hasRequirements(character, id, length, containers, fresh)
    local requirements = GarageBuild.getRequirements(id, length)
    if requirements == nil then
        return true
    end

    local stock = GarageBuild.getStock(character, containers, fresh)
    for fullType, requirement in pairs(requirements) do
        local entry = stock[fullType]
        local available = entry and (requirement.uses and entry.uses or entry.count) or 0
        if available < requirement.amount then
            return false
        end
    end

    return true
end

function GarageBuild.hasLogicRequirements(logic, character, fresh)
    local id = GarageBuild.getGarageIdFromLogic(logic)
    if id == nil then
        return true
    end
    local containers = logic and logic.getContainers and logic:getContainers() or nil
    return GarageBuild.hasRequirements(character, id, GarageBuild.getLengthFromLogic(logic), containers, fresh)
end

local function consumeItems(character, uses, amount, items)
    local remaining = amount
    for _, item in ipairs(items or {}) do
        if remaining <= 0 then
            break
        end

        if uses then
            if item ~= nil and item:getCurrentUses() > 0 then
                remaining = remaining - buildUtil.useDrainable(item, remaining)
            end
        else
            character:removeFromHands(item)
            local worldObject = item and item:getWorldItem() or nil
            local square = worldObject and worldObject:getSquare() or nil
            if square ~= nil then
                square:transmitRemoveItemFromSquare(worldObject)
                item:setWorldItem(nil)
                remaining = remaining - 1
            else
                local container = item and item:getContainer() or nil
                if container ~= nil then
                    container:Remove(item)
                    remaining = remaining - 1
                end
            end
        end
    end
    return remaining
end

-- Vanilla consumes the static L2 recipe first. This function consumes only the
-- exact delta between L2 and the selected garage length. A fresh preflight is
-- performed before removing any extra item so a missing extra never creates a
-- partially paid variable garage.
function GarageBuild.consumeExtras(character, id, length, containers)
    local extras = GarageBuild.getExtraRequirements(id, length)
    if extras == nil then
        return true
    end

    local stock = GarageBuild.getStock(character, containers, true)
    for fullType, requirement in pairs(extras) do
        local entry = stock[fullType]
        local available = entry and (requirement.uses and entry.uses or entry.count) or 0
        if available < requirement.amount then
            return false
        end
    end

    for fullType, requirement in pairs(extras) do
        local entry = stock[fullType]
        local remaining = consumeItems(character, requirement.uses, requirement.amount, entry.items)
        if remaining > 0 then
            GarageBuild.invalidateStock(character)
            return false
        end
    end

    GarageBuild.invalidateStock(character)
    return true
end

-- ISBuildingObject:updateModData() has already recorded the static L2 recipe by
-- the time ISBuildIsoEntity enters setInfo(). Mirror only the non-drainable delta
-- so a variable garage keeps the same `need:Base.*` material metadata that an
-- equivalent static recipe would have produced. Torch/rods intentionally remain
-- excluded, matching their DontRecordInput flags.
function GarageBuild.recordExtrasOnBuildObject(buildObject, id, length)
    local extras = GarageBuild.getExtraRequirements(id, length)
    if buildObject == nil or buildObject.modData == nil or extras == nil then
        return
    end

    for fullType, requirement in pairs(extras) do
        if not requirement.uses then
            local key = "need:" .. fullType
            buildObject.modData[key] = (tonumber(buildObject.modData[key]) or 0) + requirement.amount
        end
    end
end

-- FaceInfo is intentionally proxied per build cursor. The source SpriteConfig
-- remains the canonical L3 START/MIDDLE/END declaration; only this construction
-- instance exposes the selected width to vanilla ISBuildIsoEntity.
function GarageBuild.createFaceProxy(face, length)
    if face == nil then
        return nil
    end

    length = normalizeLength(length)
    local originalWidth = face:getWidth()
    local originalHeight = face:getHeight()
    local horizontal = originalWidth > 1

    if not horizontal and originalHeight <= 1 then
        return face
    end

    local function mapCoordinates(x, y)
        local axis = horizontal and x or y
        local originalSize = horizontal and originalWidth or originalHeight
        local mapped

        if axis <= 0 then
            mapped = 0
        elseif axis >= length - 1 then
            mapped = originalSize - 1
        else
            mapped = math.min(1, originalSize - 1)
        end

        if horizontal then
            return mapped, y
        end
        return x, mapped
    end

    local proxy = {}

    function proxy:getFaceName() return face:getFaceName() end
    function proxy:getWidth() return horizontal and length or originalWidth end
    function proxy:getHeight() return horizontal and originalHeight or length end
    function proxy:getzLayers() return face:getzLayers() end
    function proxy:getMasterX() return face:getMasterX() end
    function proxy:getMasterY() return face:getMasterY() end
    function proxy:getMasterZ() return face:getMasterZ() end
    function proxy:isMasterSet() return face:isMasterSet() end
    function proxy:isMultiSquare() return face:isMultiSquare() end
    function proxy:getMasterTileInfo() return face:getMasterTileInfo() end
    function proxy:getTileInfoForSprite(tile) return face:getTileInfoForSprite(tile) end

    function proxy:getTileInfo(x, y, z)
        local mappedX, mappedY = mapCoordinates(x, y)
        return face:getTileInfo(mappedX, mappedY, z)
    end

    function proxy:verifyObject(x, y, z, object)
        local mappedX, mappedY = mapCoordinates(x, y)
        return face:verifyObject(mappedX, mappedY, z, object)
    end

    return proxy
end

return GarageBuild
