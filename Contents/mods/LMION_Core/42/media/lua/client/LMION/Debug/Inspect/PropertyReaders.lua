require "LMION/Debug/Inspect/Options"

LMION.Debug = LMION.Debug or {}
LMION.Debug.Inspect = LMION.Debug.Inspect or {}

local PropertyReaders = LMION.Debug.Inspect.PropertyReaders or {}
LMION.Debug.Inspect.PropertyReaders = PropertyReaders

PropertyReaders.readers = PropertyReaders.readers or {}
PropertyReaders.defaultReader = PropertyReaders.defaultReader or nil

function PropertyReaders.register(name, reader)
    if type(name) ~= "string" or name == "" or type(reader) ~= "function" then
        return false
    end

    -- Reload-friendly: a specific reader always overrides the default reader.
    PropertyReaders.readers[name] = reader
    return true
end

function PropertyReaders.unregister(name)
    PropertyReaders.readers[name] = nil
end

function PropertyReaders.setDefault(reader)
    if reader ~= nil and type(reader) ~= "function" then
        return false
    end

    PropertyReaders.defaultReader = reader
    return true
end

function PropertyReaders.has(name)
    return PropertyReaders.readers[name] ~= nil
        or PropertyReaders.defaultReader ~= nil
end

function PropertyReaders.read(properties, name)
    local reader = PropertyReaders.readers[name]
        or PropertyReaders.defaultReader

    if reader == nil then
        return false, "<unread>"
    end

    -- Keep the registry extensible: most properties can use the current
    -- PropertyContainer string getter, while exceptional properties may
    -- register a dedicated reader later.
    local ok, value = pcall(reader, properties, name)

    if not ok then
        return false, "<reader error: " .. tostring(value) .. ">"
    end

    if value == nil then
        return true, "<nil>"
    end

    return true, value
end

return PropertyReaders
