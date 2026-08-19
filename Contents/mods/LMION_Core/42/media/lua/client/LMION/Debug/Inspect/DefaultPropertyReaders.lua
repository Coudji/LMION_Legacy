require "LMION/Debug/Inspect/PropertyReaders"

local PropertyReaders = LMION.Debug.Inspect.PropertyReaders

-- Start deliberately small. Each property reader is validated in-game before
-- being added here because blind PropertyContainer:Val() calls have already
-- proven capable of tripping PZ's Java/Kahlua debugger.
PropertyReaders.register("DoorSound", function(properties)
    return properties:Val("DoorSound")
end)

return PropertyReaders
