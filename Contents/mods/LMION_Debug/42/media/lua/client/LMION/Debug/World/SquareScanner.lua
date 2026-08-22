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
        classShort = Safe.shortClassName(object),
        spriteName = Safe.spriteName(object),
    }
end

function SquareScanner.flattenObjects(squares)
    local result = {}

    for _, square in ipairs(squares or {}) do
        if square ~= nil then
            local objects = square:getObjects()
            local count = Safe.collectionSize(objects)

            for i = 0, count - 1 do
                local object = Safe.collectionGet(objects, i)

                if object ~= nil then
                    result[#result + 1] = objectEntry(object, i, square)
                end
            end
        end
    end

    return result
end

return SquareScanner
