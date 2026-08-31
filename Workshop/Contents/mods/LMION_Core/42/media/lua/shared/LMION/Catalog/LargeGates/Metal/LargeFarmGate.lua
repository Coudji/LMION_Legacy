return {
    definitionId = "LargeGates.Metal.LargeFarmGate",
    displayName = "Large Farm Gate",
    entity = "Base.LargeFarmGate",
    inherits = "LargeGates.Metal.Pipe",

    engineMaterials = { "MetalPipe" },
    doorSound = "FarmGate",
    thumpSound = "ZombieThumpMetalPoleGate",
    durability = {
        worldHealth = 500,
        health = 300,
        skillBaseHealth = 200,
    },
    construction = {
        skill = { MetalWelding = 4 },
        time = 160,
        xp = 30,
        materials = {
            { item = "Base.BlowTorch", uses = 6 },
            { item = "Base.MetalPipe", amount = 8 },
            { item = "Base.Hinge", amount = 4 },
            { item = "Base.WeldingRods", uses = 4 },
        },
    },
    pickup = {
        packages = { count = 2, weight = 12 },
    },

    geometry = {
        N = {
            A = {
                { closed = "fixtures_doors_fences_01_114", open = "fixtures_doors_fences_01_119" },
                { closed = "fixtures_doors_fences_01_115", open = "fixtures_doors_fences_01_118" },
            },
            B = {
                { closed = "fixtures_doors_fences_01_122", open = "fixtures_doors_fences_01_126" },
                { closed = "fixtures_doors_fences_01_123", open = "fixtures_doors_fences_01_127" },
            },
        },
        W = {
            A = {
                { closed = "fixtures_doors_fences_01_113", open = "fixtures_doors_fences_01_116" },
                { closed = "fixtures_doors_fences_01_112", open = "fixtures_doors_fences_01_117" },
            },
            B = {
                { closed = "fixtures_doors_fences_01_121", open = "fixtures_doors_fences_01_125" },
                { closed = "fixtures_doors_fences_01_120", open = "fixtures_doors_fences_01_124" },
            },
        },
    },
}
