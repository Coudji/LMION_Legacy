return {
    definitionId = "FenceGates.Metal.MetalPoleFenceGateSmall",
    entity = "Base.MetalPoleFenceGateSmall",
    inherits = "FenceGates.Metal.Pipe",

    doorSound = "MetalPoleGateSmall",

    durability = {
        worldHealth = 450,
        health = 250,
        skillBaseHealth = 175,
    },

    construction = {
        skill = { MetalWelding = 2 },
        time = 80,
        xp = 10,
        materials = {
            { item = "Base.BlowTorch", uses = 3 },
            { item = "Base.MetalPipe", amount = 3 },
            { item = "Base.Hinge", amount = 2 },
            { item = "Base.ScrapMetal", amount = 1 },
            { item = "Base.WeldingRods", uses = 3 },
        },
    },

    pickup = {
        packages = { count = 1, weight = 8 },
    },

    geometry = {
        N = {
            closed = "fixtures_doors_fences_01_29",
            open = "fixtures_doors_fences_01_31",
        },
        W = {
            closed = "fixtures_doors_fences_01_28",
            open = "fixtures_doors_fences_01_30",
        },
    },
}
