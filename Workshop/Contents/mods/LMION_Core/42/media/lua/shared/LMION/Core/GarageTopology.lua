local GarageTopology = {}

local TOPOLOGY = {
    roles = {
        START = 1,
        MIDDLE = 2,
        END = 3,
    },

    roleNames = {
        [1] = "START",
        [2] = "MIDDLE",
        [3] = "END",
    },

    minLength = 2,

    step = {
        N = { x = 1, y = 0 },
        W = { x = 0, y = -1 },
    },
}


function GarageTopology.get()
    return TOPOLOGY
end


return GarageTopology
