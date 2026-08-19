require "LMION/Debug/Util/Safe"

LMION.Debug.World = LMION.Debug.World or {}
LMION.Debug.World.SquareScanner = LMION.Debug.World.SquareScanner or {}

local Safe = LMION.Debug.Util.Safe
local SquareScanner = LMION.Debug.World.SquareScanner

local function objectEntry(object, listIndex, square)
    return {
        object = object,
        key = Safe.objectKey(object),
        listIndex = listIndex,
        square = square,
        squareKey = Safe.squareKey(square),
        squareText = Safe.squareString(square),
        className = Safe.className(object),
        classShort = Safe.shortClassName(object),
        spriteName = Safe.spriteName(object),
        objectName = object ~= nil and object:getObjectName() or nil,
        objectIndex = object ~= nil and object:getObjectIndex() or -1,
        specialObjectIndex = object ~= nil and object:getSpecialObjectIndex() or -1,
        worldObjectIndex = object ~= nil and object:getWorldObjectIndex() or -1,
    }
end

function SquareScanner.scan(square)
    if square == nil then
        return nil
    end

    local model = {
        square = square,
        key = Safe.squareKey(square),
        text = Safe.squareString(square),
        x = square:getX(),
        y = square:getY(),
        z = square:getZ(),
        floor = square:getFloor(),
        objects = {},
        specialObjectsCount = 0,
        worldObjectsCount = 0,
    }

    local objects = square:getObjects()
    local objectCount = Safe.collectionSize(objects)

    for i = 0, objectCount - 1 do
        local object = Safe.collectionGet(objects, i)

        if object ~= nil then
            model.objects[#model.objects + 1] = objectEntry(object, i, square)
        end
    end

    model.specialObjectsCount = Safe.collectionSize(square:getSpecialObjects())
    model.worldObjectsCount = Safe.collectionSize(square:getWorldObjects())

    return model
end

function SquareScanner.scanMany(squares)
    local result = {}

    for _, square in ipairs(squares) do
        local model = SquareScanner.scan(square)

        if model ~= nil then
            result[#result + 1] = model
        end
    end

    return result
end

function SquareScanner.flattenObjects(squares)
    local result = {}
    local models = SquareScanner.scanMany(squares)

    for _, model in ipairs(models) do
        for _, entry in ipairs(model.objects) do
            result[#result + 1] = entry
        end
    end

    return result
end

return SquareScanner
