require "LMION/Debug/Util/Safe"

LMION.Debug.Util.Reflection = LMION.Debug.Util.Reflection or {}

local Safe = LMION.Debug.Util.Safe
local Reflection = LMION.Debug.Util.Reflection

function Reflection.hasMethod(object, wantedName, parameterCount)
    if object == nil
        or getNumClassFunctions == nil
        or getClassFunction == nil then
        return false
    end

    local count = Safe.value("getNumClassFunctions", function()
        return getNumClassFunctions(object)
    end, 0)

    for i = 0, count - 1 do
        local method = Safe.value("getClassFunction", function()
            return getClassFunction(object, i)
        end, nil)

        if method ~= nil then
            local name = Safe.value("Method.getName", function()
                return method:getName()
            end, nil)

            if name == wantedName then
                if parameterCount == nil then
                    return true
                end

                local countParams = Safe.value("Method.getParameterCount", function()
                    return method:getParameterCount()
                end, nil)

                if countParams == parameterCount then
                    return true
                end
            end
        end
    end

    return false
end

function Reflection.getField(object, wantedName)
    if object == nil then
        return nil, "<nil object>"
    end

    if getNumClassFields == nil
        or getClassField == nil
        or getClassFieldVal == nil then
        return nil, "<reflection API unavailable>"
    end

    local count = Safe.value("getNumClassFields", function()
        return getNumClassFields(object)
    end, nil)

    if type(count) ~= "number" then
        return nil, "<field count unavailable>"
    end

    for i = 0, count - 1 do
        local field = Safe.value("getClassField", function()
            return getClassField(object, i)
        end, nil)

        if field ~= nil then
            local fieldName = Safe.value("Field.getName", function()
                return field:getName()
            end, nil)

            if fieldName == wantedName then
                local value = Safe.value("getClassFieldVal." .. wantedName, function()
                    return getClassFieldVal(object, field)
                end, nil)

                return value, nil
            end
        end
    end

    return nil, "<field not found>"
end

function Reflection.getSpriteFieldName(object, fieldName)
    local sprite, err = Reflection.getField(object, fieldName)

    if sprite == nil then
        return err or "<nil>"
    end

    local name = Safe.value(fieldName .. ".getName", function()
        return sprite:getName()
    end, nil)

    if name ~= nil then
        return name
    end

    return tostring(sprite)
end

return Reflection
