require "LMION/Build/GarageConstruction"

local GarageBuild = LMION.Build.GarageBuild

local BAR_TYPES = {
    "Base.MetalBar",
    "Base.IronBar",
}

local BAR_TYPE_SET = {
    ["Base.MetalBar"] = true,
    ["Base.IronBar"] = true,
}

local LAST_CONSUMED_MATERIALS = setmetatable({}, {__mode = "k"})

GarageBuild.BarTypes = BAR_TYPES

if GarageBuild._originalAlternativeGetAvailable == nil then
    GarageBuild._originalAlternativeGetAvailable = GarageBuild.getAvailable
end

if GarageBuild._originalAlternativeHasRequirements == nil then
    GarageBuild._originalAlternativeHasRequirements = GarageBuild.hasRequirements
end

if GarageBuild._originalAlternativeConsumeExtras == nil then
    GarageBuild._originalAlternativeConsumeExtras = GarageBuild.consumeExtras
end

if GarageBuild._originalAlternativeRecordExtras == nil then
    GarageBuild._originalAlternativeRecordExtras = GarageBuild.recordExtrasOnBuildObject
end

local function addItem(entry, item, seen)
    if item == nil or seen[item] then
        return
    end
    seen[item] = true
    entry.items[#entry.items + 1] = item
    entry.count = entry.count + 1
end

local function addContainerItems(entry, container, fullType, seen)
    if container == nil or ISBuildIsoEntity == nil then
        return
    end

    local items = container:getAllTypeEvalRecurse(fullType, ISBuildIsoEntity.predicateMaterial)
    if items == nil then
        return
    end

    for i = 0, items:size() - 1 do
        addItem(entry, items:get(i), seen)
    end
end

local function collectBarStock(character, containers)
    local entry = {count = 0, items = {}}
    if character == nil or ISBuildIsoEntity == nil then
        return entry
    end

    local seen = {}
    local inventory = character:getInventory()
    local ground = ISBuildIsoEntity.GetAllGroundItemsForPlayer(character)

    for _, fullType in ipairs(BAR_TYPES) do
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
    end

    return entry
end

local function stockAvailable(stock, fullType, uses)
    local entry = stock and stock[fullType] or nil
    if entry == nil then
        return 0
    end
    return uses and entry.uses or entry.count
end

-- B42 CraftRecipe alternative inputs share one quantity. Mirror that contract
-- for the variable-width layer: MetalBar and IronBar contribute to one common
-- bar quota, and may be mixed in any proportion.
GarageBuild.getAvailable = function(character, fullType, uses, containers, fresh)
    if BAR_TYPE_SET[fullType] then
        return collectBarStock(character, containers).count
    end

    return GarageBuild._originalAlternativeGetAvailable(
        character,
        fullType,
        uses,
        containers,
        fresh
    )
end

GarageBuild.hasRequirements = function(character, id, length, containers, fresh)
    local requirements = GarageBuild.getRequirements(id, length)
    if requirements == nil then
        return true
    end

    local stock = GarageBuild.getStock(character, containers, fresh)
    local bars = nil

    for fullType, requirement in pairs(requirements) do
        local available
        if BAR_TYPE_SET[fullType] then
            bars = bars or collectBarStock(character, containers)
            available = bars.count
        else
            available = stockAvailable(stock, fullType, requirement.uses)
        end

        if available < requirement.amount then
            return false
        end
    end

    return true
end

local function consumeItems(character, uses, amount, items, consumedMaterials)
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
            local fullType = item and item:getFullType() or nil
            character:removeFromHands(item)
            local worldObject = item and item:getWorldItem() or nil
            local square = worldObject and worldObject:getSquare() or nil
            local removed = false

            if square ~= nil then
                square:transmitRemoveItemFromSquare(worldObject)
                item:setWorldItem(nil)
                remaining = remaining - 1
                removed = true
            else
                local container = item and item:getContainer() or nil
                if container ~= nil then
                    container:Remove(item)
                    remaining = remaining - 1
                    removed = true
                end
            end

            if removed and fullType ~= nil then
                consumedMaterials[fullType] = (consumedMaterials[fullType] or 0) + 1
            end
        end
    end

    return remaining
end

GarageBuild.consumeExtras = function(character, id, length, containers)
    LAST_CONSUMED_MATERIALS[character] = nil

    local extras = GarageBuild.getExtraRequirements(id, length)
    if extras == nil then
        return true
    end

    local stock = GarageBuild.getStock(character, containers, true)
    local bars = nil

    -- Fresh all-or-nothing preflight before removing anything.
    for fullType, requirement in pairs(extras) do
        local available
        if BAR_TYPE_SET[fullType] then
            bars = bars or collectBarStock(character, containers)
            available = bars.count
        else
            available = stockAvailable(stock, fullType, requirement.uses)
        end

        if available < requirement.amount then
            return false
        end
    end

    local consumedMaterials = {}

    for fullType, requirement in pairs(extras) do
        local items
        if BAR_TYPE_SET[fullType] then
            bars = bars or collectBarStock(character, containers)
            items = bars.items
        else
            local entry = stock[fullType]
            items = entry and entry.items or nil
        end

        if consumeItems(
            character,
            requirement.uses,
            requirement.amount,
            items,
            consumedMaterials
        ) > 0 then
            GarageBuild.invalidateStock(character)
            return false
        end
    end

    LAST_CONSUMED_MATERIALS[character] = consumedMaterials
    GarageBuild.invalidateStock(character)
    return true
end

-- Vanilla records the actual L2 alternative items. Do the same for the variable
-- delta so a mixed MetalBar/IronBar garage keeps truthful build-material data.
GarageBuild.recordExtrasOnBuildObject = function(buildObject, id, length)
    local character = buildObject and buildObject.character or nil
    local consumedMaterials = character and LAST_CONSUMED_MATERIALS[character] or nil

    if consumedMaterials == nil then
        return GarageBuild._originalAlternativeRecordExtras(buildObject, id, length)
    end

    LAST_CONSUMED_MATERIALS[character] = nil

    if buildObject == nil or buildObject.modData == nil then
        return
    end

    for fullType, amount in pairs(consumedMaterials) do
        if amount > 0 then
            local key = "need:" .. fullType
            buildObject.modData[key] = (tonumber(buildObject.modData[key]) or 0) + amount
        end
    end
end

return GarageBuild
