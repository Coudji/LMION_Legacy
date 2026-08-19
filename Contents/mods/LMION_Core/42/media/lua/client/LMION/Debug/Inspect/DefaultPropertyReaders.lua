require "LMION/Debug/Inspect/PropertyReaders"

local PropertyReaders = LMION.Debug.Inspect.PropertyReaders

-- Build 42.18's PropertyContainer exposes get(String) for string property
-- lookup. The older Val(String) API still appears in stale documentation but
-- trips the debugger on current builds, so do not use it here.
PropertyReaders.register("DoorSound", function(properties)
    return properties:get("DoorSound")
end)

return PropertyReaders
