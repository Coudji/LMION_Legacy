require "LMION/Debug/Inspect/Options"

LMION.Debug = LMION.Debug or {}
LMION.Debug.Inspect = LMION.Debug.Inspect or {}

local PropertyReaders = LMION.Debug.Inspect.PropertyReaders or {}
LMION.Debug.Inspect.PropertyReaders = PropertyReaders

PropertyReaders.readers = PropertyReaders.readers or {}

function PropertyReaders.register(name, reader)
    if type(name) ~= "string" or name == "" or type(reader) ~= "function" then
        return false
    end

    -- Reload-friendly: replace the reader registered for this property name.
    PropertyReaders.readers[name] = reader
    return true
end

function PropertyReaders.unregister(name)
    PropertyReaders.readers[name] = nil
end

function PropertyReaders.has(name)
    return PropertyReaders.readers[name] ~= nil
end

function PropertyReaders.read(properties, name)
    local reader = PropertyReaders.readers[name]

    if reader == nil then
        return false, "<unread>"
    end

    -- Only explicitly registered readers are executed here. This is deliberate:
    -- calling PropertyContainer:Val() blindly for every discovered property has
    -- already proven unsafe under PZ Debug Mode / Break On Error.
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
