return {
    definitionId = "LargeGates.Metal.DoubleFenceGate",
    displayName = "Large Scrap Metal Gate",
    entity = "Base.DoubleFenceGate",
    inherits = "LargeGates.Metal.Pipe",

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
                { closed = "fixtures_doors_fences_01_82", open = "fixtures_doors_fences_01_87" },
                { closed = "fixtures_doors_fences_01_83", open = "fixtures_doors_fences_01_86" },
            },
            B = {
                { closed = "fixtures_doors_fences_01_90", open = "fixtures_doors_fences_01_94" },
                { closed = "fixtures_doors_fences_01_91", open = "fixtures_doors_fences_01_95" },
            },
        },
        W = {
            A = {
                { closed = "fixtures_doors_fences_01_81", open = "fixtures_doors_fences_01_84" },
                { closed = "fixtures_doors_fences_01_80", open = "fixtures_doors_fences_01_85" },
            },
            B = {
                { closed = "fixtures_doors_fences_01_89", open = "fixtures_doors_fences_01_93" },
                { closed = "fixtures_doors_fences_01_88", open = "fixtures_doors_fences_01_92" },
            },
        },
    },
}
