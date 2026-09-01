return {
    definitionId = "FenceGates.Metal.MetalWireFenceGateSmall",
    entity = "Base.MetalWireFenceGateSmall",
    inherits = "FenceGates.Metal.Wire",

    durability = {
        worldHealth = 450,
        health = 250,
        skillBaseHealth = 175,
    },

    construction = {
        skill = { MetalWelding = 2 },
        time = 70,
        xp = 10,
        materials = {
            { item = "Base.BlowTorch", uses = 2 },
            { item = "Base.MetalPipe", amount = 2 },
            { item = "Base.Wire", uses = 1 },
            { item = "Base.Hinge", amount = 2 },
            { item = "Base.ScrapMetal", amount = 1 },
            { item = "Base.WeldingRods", uses = 2 },
        },
    },

    pickup = {
        packages = { count = 1, weight = 6 },
    },

    geometry = {
        N = {
            closed = "fixtures_doors_fences_01_17",
            open = "fixtures_doors_fences_01_19",
        },
        W = {
            closed = "fixtures_doors_fences_01_16",
            open = "fixtures_doors_fences_01_18",
        },
    },
}
