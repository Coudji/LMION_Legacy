return {
    definitionId = "FenceGates.Metal.SmallWroughtIronGate",
    entity = "Base.SmallWroughtIronGate",
    inherits = "FenceGates.Metal.Forged",

    doorSound = "MetalPoleGateSmall",

    durability = {
        worldHealth = 650,
        health = 325,
        skillBaseHealth = 250,
    },

    construction = {
        skill = { MetalWelding = 3 },
        time = 100,
        xp = 20,
        materials = {
            { item = "Base.BlowTorch", uses = 3 },
            { anyOf = { "Base.MetalBar", "Base.IronBar" }, amount = 2 },
            { item = "Base.MetalPipe", amount = 1 },
            { item = "Base.Hinge", amount = 2 },
            { item = "Base.WeldingRods", uses = 2 },
        },
    },

    pickup = {
        skill = { MetalWelding = 1 },
        packages = { count = 1, weight = 12 },
    },

    geometry = {
        N = {
            closed = "fixtures_doors_fences_01_1",
            open = "fixtures_doors_fences_01_3",
        },
        W = {
            closed = "fixtures_doors_fences_01_0",
            open = "fixtures_doors_fences_01_2",
        },
    },
}
