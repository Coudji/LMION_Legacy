return {
    definitionId = "LargeGates.Wood.LargeHardenedWoodenGate",
    entity = "Base.LargeHardenedWoodenGate",
    inherits = "LargeGates.Wood.Hard",

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
                { closed = "fixtures_doors_fences_01_50", open = "fixtures_doors_fences_01_55" },
                { closed = "fixtures_doors_fences_01_51", open = "fixtures_doors_fences_01_54" },
            },
            B = {
                { closed = "fixtures_doors_fences_01_58", open = "fixtures_doors_fences_01_62" },
                { closed = "fixtures_doors_fences_01_59", open = "fixtures_doors_fences_01_63" },
            },
        },
        W = {
            A = {
                { closed = "fixtures_doors_fences_01_49", open = "fixtures_doors_fences_01_52" },
                { closed = "fixtures_doors_fences_01_48", open = "fixtures_doors_fences_01_53" },
            },
            B = {
                { closed = "fixtures_doors_fences_01_57", open = "fixtures_doors_fences_01_61" },
                { closed = "fixtures_doors_fences_01_56", open = "fixtures_doors_fences_01_60" },
            },
        },
    },
}
