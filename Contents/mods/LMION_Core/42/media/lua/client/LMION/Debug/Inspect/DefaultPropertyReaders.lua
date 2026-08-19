require "LMION/Debug/Inspect/PropertyReaders"

local PropertyReaders = LMION.Debug.Inspect.PropertyReaders

-- Build 42.18's PropertyContainer exposes get(String) for string property
-- lookup. Use it as the default reader for discovered property names.
PropertyReaders.setDefault(function(properties, name)
    return properties:get(name)
end)

return PropertyReaders
