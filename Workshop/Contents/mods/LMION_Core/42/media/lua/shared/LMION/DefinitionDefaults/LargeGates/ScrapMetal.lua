return {
    id = "LargeGates.Metal.ScrapMetal",

    defaults = {
        class = "metal",
        frame = false,
        materialType = "Metal_Light",
        doorSound = "MetalGate",
        thumpSound = "ZombieThumpChainlinkFence",

        engineMaterials = { "MetalPipe", "MetalScrap" },

        durability = {
            worldHealth = 850,
            health = 400,
            skillBaseHealth = 275,
        },

        construction = {
            skill = { MetalWelding = 5 },
            time = 240,
            xp = 40,
            tools = { "Base.WeldingMask" },

            materials = {
                { item = "Base.BlowTorch", uses = 10 },
                { item = "Base.MetalPipe", amount = 10 },
                { item = "Base.Hinge", amount = 4 },
                { item = "Base.ScrapMetal", amount = 4 },
                { item = "Base.WeldingRods", uses = 10 },
            },
        },

        pickup = {
            skill = { MetalWelding = 2 },
            tools = { "Base.BlowTorch", "Base.WeldingMask" },
            breakChance = 0,
            packages = {
                count = 2,
                weight = 20,
            },
        },

        replacement = {
            packages = 2,
            tools = { "Base.BlowTorch", "Base.WeldingMask" },
            materials = {
                { item = "Base.WeldingRods", uses = 5 },
            },
        },
    },
}
