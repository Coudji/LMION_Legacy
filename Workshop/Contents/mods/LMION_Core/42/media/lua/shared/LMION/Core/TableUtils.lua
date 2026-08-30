local TableUtils = {}

local function getTableShape(value)
    local count = 0
    local maxIndex = 0

    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
            return "map"
        end

        count = count + 1
        if key > maxIndex then
            maxIndex = key
        end
    end

    if count == 0 then
        return "empty"
    end

    if maxIndex == count then
        return "array"
    end

    return "map"
end


function TableUtils.deepCopy(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}

    if seen[value] ~= nil then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy

    for key, child in pairs(value) do
        copy[TableUtils.deepCopy(key, seen)] = TableUtils.deepCopy(child, seen)
    end

    return copy
end


function TableUtils.deepMerge(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then
        error("LMION: deepMerge expects two tables", 2)
    end

    for key, sourceValue in pairs(source) do
        local targetValue = target[key]

        if type(sourceValue) == "table"
            and type(targetValue) == "table"
            and getTableShape(sourceValue) == "map"
            and getTableShape(targetValue) == "map"
        then
            TableUtils.deepMerge(targetValue, sourceValue)
        else
            target[key] = TableUtils.deepCopy(sourceValue)
        end
    end

    return target
end


return TableUtils
