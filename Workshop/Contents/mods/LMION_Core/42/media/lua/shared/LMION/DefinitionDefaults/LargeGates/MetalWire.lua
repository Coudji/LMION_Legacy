return {
    id = "LargeGates.Metal.Wire",

    defaults = {
        class = "metal",
        frame = false,
        materialType = "Metal_Light",
        doorSound = "MetalGate",
        thumpSound = "ZombieThumpChainlinkFence",

        engineMaterials = { "MetalPipe", "MetalWire" },

        durability = {
            worldHealth = 850,
            health = 400,
            skillBaseHealth = 275,
        },

        construction = {
            skill = { MetalWelding = 5 },
            time = 220,
            xp = 40,
            tools = { "Base.WeldingMask" },

            materials = {
                { item = "Base.BlowTorch", uses = 10 },
                { item = "Base.MetalPipe", amount = 8 },
                { item = "Base.Wire", uses = 4 },
                { item = "Base.Hinge", amount = 4 },
                { item = "Base.ScrapMetal", amount = 2 },
                { item = "Base.WeldingRods", uses = 10 },
            },
        },

        pickup = {
            skill = { MetalWelding = 2 },
            tools = { "Base.BlowTorch", "Base.WeldingMask" },
            breakChance = 0,
            packages = {
                count = 2,
                weight = 15,
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
