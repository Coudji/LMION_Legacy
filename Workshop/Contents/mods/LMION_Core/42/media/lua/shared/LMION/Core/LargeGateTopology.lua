local LargeGateTopology = {}

local TOPOLOGY = {
    leaves = {
        A = {
            indices = {
                N = { 1, 2 },
                W = { 4, 3 },
            },
        },
        B = {
            indices = {
                N = { 3, 4 },
                W = { 2, 1 },
            },
        },
    },

    layout = {
        N = {
            closed = {
                { 0, 0 },
                { 1, 0 },
                { 2, 0 },
                { 3, 0 },
            },
            open = {
                { 0, 0 },
                { 0, 1 },
                { 3, 1 },
                { 3, 0 },
            },
        },
        W = {
            closed = {
                { 0, 0 },
                { 0, -1 },
                { 0, -2 },
                { 0, -3 },
            },
            open = {
                { 0, 0 },
                { 1, 0 },
                { 1, -3 },
                { 0, -3 },
            },
        },
    },
}


function LargeGateTopology.get()
    return TOPOLOGY
end


return LargeGateTopology
