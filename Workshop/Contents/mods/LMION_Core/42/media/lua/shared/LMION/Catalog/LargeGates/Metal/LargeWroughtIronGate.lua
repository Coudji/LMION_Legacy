return {
    definitionId = "LargeGates.Metal.LargeWroughtIronGate",
    displayName = "Large Wrought Iron Gate",
    entity = "Base.LargeWroughtIronGate",
    inherits = "LargeGates.Metal.Forged",

    topology = {
        type = "largeGate",
        leaves = {
            A = { indices = { N = { 1, 2 }, W = { 4, 3 } } },
            B = { indices = { N = { 3, 4 }, W = { 2, 1 } } },
        },
        layout = {
            N = { closed = { {0,0},{1,0},{2,0},{3,0} }, open = { {0,0},{0,1},{3,1},{3,0} } },
            W = { closed = { {0,0},{0,-1},{0,-2},{0,-3} }, open = { {0,0},{1,0},{1,-3},{0,-3} } },
        },
    },

    geometry = {
        N = { A = { { closed = "fixtures_doors_fences_01_34", open = "fixtures_doors_fences_01_39" }, { closed = "fixtures_doors_fences_01_35", open = "fixtures_doors_fences_01_38" } }, B = { { closed = "fixtures_doors_fences_01_42", open = "fixtures_doors_fences_01_46" }, { closed = "fixtures_doors_fences_01_43", open = "fixtures_doors_fences_01_47" } } },
        W = { A = { { closed = "fixtures_doors_fences_01_33", open = "fixtures_doors_fences_01_36" }, { closed = "fixtures_doors_fences_01_32", open = "fixtures_doors_fences_01_37" } }, B = { { closed = "fixtures_doors_fences_01_41", open = "fixtures_doors_fences_01_45" }, { closed = "fixtures_doors_fences_01_40", open = "fixtures_doors_fences_01_44" } } },
    },
}
