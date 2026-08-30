return {
    id = "Base.DoubleWireGate",
    inherits = "LargeGates.Metal.ChainLink",

    topology = {
        type = "twoLeaves",
        A = { N = { 1, 2 }, W = { 4, 3 } },
        B = { N = { 3, 4 }, W = { 2, 1 } },
    },

    geometry = {
        N = { closed = {}, open = {} },
        W = { closed = {}, open = {} },
    },
}
