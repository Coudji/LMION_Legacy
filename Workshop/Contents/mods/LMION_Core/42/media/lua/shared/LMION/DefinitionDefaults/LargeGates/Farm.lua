return {
    id = "LargeGates.Metal.Farm",

    defaults = {
        class = "metal",
        frame = false,
        materialType = "Metal_Light",
        doorSound = "FarmGate",
        thumpSound = "ZombieThumpMetalPoleGate",

        engineMaterials = { "MetalPipe" },

        durability = {
            worldHealth = 500,
            health = 300,
            skillBaseHealth = 200,
        },

        construction = {
            skill = { MetalWelding = 4 },
            time = 160,
            xp = 30,
            tools = { "Base.WeldingMask" },

            materials = {
                { item = "Base.BlowTorch", uses = 6 },
                { item = "Base.MetalPipe", amount = 8 },
                { item = "Base.Hinge", amount = 4 },
                { item = "Base.WeldingRods", uses = 4 },
            },
        },

        pickup = {
            skill = { MetalWelding = 2 },
            tools = { "Base.BlowTorch", "Base.WeldingMask" },
            breakChance = 0,
            packages = {
                count = 2,
                weight = 12,
            },
        },

        replacement = {
            packages = 2,
            tools = { "Base.BlowTorch", "Base.WeldingMask" },
            materials = {
                { item = "Base.WeldingRods", uses = 2 },
            },
        },
    },
}
