require "LMION/Debug/Inspect/PropertyReaders"

local PropertyReaders = LMION.Debug.Inspect.PropertyReaders

PropertyReaders.setDefault(function(properties, name)
    return properties:get(name)
end)

return PropertyReaders
