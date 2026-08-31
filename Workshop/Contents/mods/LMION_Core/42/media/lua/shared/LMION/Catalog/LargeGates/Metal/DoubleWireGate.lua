return {
    definitionId = "LargeGates.Metal.DoubleWireGate",
    entity = "Base.DoubleWireGate",
    inherits = "LargeGates.Metal.Wire",

    topology = {
        type = "largeGate",
        leaves = {
            A = { indices = { N = { 1, 2 }, W = { 4, 3 } } },
            B = { indices = { N = { 3, 4 }, W = { 2, 1 } } },
        },
        layout = {
            N = {
                closed = { { 0, 0 }, { 1, 0 }, { 2, 0 }, { 3, 0 } },
                open = { { 0, 0 }, { 0, 1 }, { 3, 1 }, { 3, 0 } },
            },
            W = {
                closed = { { 0, 0 }, { 0, -1 }, { 0, -2 }, { 0, -3 } },
                open = { { 0, 0 }, { 1, 0 }, { 1, -3 }, { 0, -3 } },
            },
        },
    },

    geometry = {
        N = {
            A = {
                { closed = "fixtures_doors_fences_01_66", open = "fixtures_doors_fences_01_71" },
                { closed = "fixtures_doors_fences_01_67", open = "fixtures_doors_fences_01_70" },
            },
            B = {
                { closed = "fixtures_doors_fences_01_74", open = "fixtures_doors_fences_01_78" },
                { closed = "fixtures_doors_fences_01_75", open = "fixtures_doors_fences_01_79" },
            },
        },
        W = {
            A = {
                { closed = "fixtures_doors_fences_01_65", open = "fixtures_doors_fences_01_68" },
                { closed = "fixtures_doors_fences_01_64", open = "fixtures_doors_fences_01_69" },
            },
            B = {
                { closed = "fixtures_doors_fences_01_73", open = "fixtures_doors_fences_01_77" },
                { closed = "fixtures_doors_fences_01_72", open = "fixtures_doors_fences_01_76" },
            },
        },
    },
}
