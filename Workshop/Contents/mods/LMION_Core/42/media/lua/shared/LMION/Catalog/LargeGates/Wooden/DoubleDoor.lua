return {
    definitionId = "LargeGates.Wood.DoubleDoor",
    entity = "Base.DoubleDoor",
    inherits = "LargeGates.Wood.Base",

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
                { closed = "fixtures_doors_fences_01_98", open = "fixtures_doors_fences_01_103" },
                { closed = "fixtures_doors_fences_01_99", open = "fixtures_doors_fences_01_102" },
            },
            B = {
                { closed = "fixtures_doors_fences_01_106", open = "fixtures_doors_fences_01_110" },
                { closed = "fixtures_doors_fences_01_107", open = "fixtures_doors_fences_01_111" },
            },
        },
        W = {
            A = {
                { closed = "fixtures_doors_fences_01_97", open = "fixtures_doors_fences_01_100" },
                { closed = "fixtures_doors_fences_01_96", open = "fixtures_doors_fences_01_101" },
            },
            B = {
                { closed = "fixtures_doors_fences_01_105", open = "fixtures_doors_fences_01_109" },
                { closed = "fixtures_doors_fences_01_104", open = "fixtures_doors_fences_01_108" },
            },
        },
    },
}
