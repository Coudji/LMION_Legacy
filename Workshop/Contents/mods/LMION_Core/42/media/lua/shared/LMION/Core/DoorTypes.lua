local DoorTypes = {}

local TYPES = {
    Simple = {
        frame = "standard",
    },
    Paired = {
        frame = "paired",
    },
    FenceGate = {
        frame = "none",
    },
    Sliding = {
        frame = "none",
    },
    LargeGate = {
        frame = "none",
    },
    Garage = {
        frame = "none",
    },
}


function DoorTypes.get(doorType)
    return TYPES[doorType]
end


function DoorTypes.isSupported(doorType)
    return TYPES[doorType] ~= nil
end


function DoorTypes.getFrame(doorType)
    local definition = TYPES[doorType]
    return definition and definition.frame or nil
end


function DoorTypes.getNames()
    return {
        "Simple",
        "Paired",
        "FenceGate",
        "Sliding",
        "LargeGate",
        "Garage",
    }
end


return DoorTypes
