return {
    definitionId = "FenceGates.Metal.Wire",

    defaults = {
        frame = false,
        materialType = "Metal_Light",
        doorSound = "MetalGate",
        thumpSound = "ZombieThumpChainlinkFence",

        engineMaterials = { "MetalPipe", "MetalWire" },

        durability = {
            worldHealth = 600,
            health = 300,
            skillBaseHealth = 225,
        },

        construction = {
            skill = { MetalWelding = 3 },
            time = 110,
            xp = 15,
            tools = {
                { tag = "base:weldingmask" },
            },

            materials = {
                { item = "Base.BlowTorch", uses = 4 },
                { item = "Base.MetalPipe", amount = 4 },
                { item = "Base.Wire", uses = 2 },
                { item = "Base.Hinge", amount = 2 },
                { item = "Base.ScrapMetal", amount = 1 },
                { item = "Base.WeldingRods", uses = 4 },
            },
        },

        pickup = {
            skill = { MetalWelding = 1 },
            tools = {
                { tag = "base:crowbar" },
            },
            breakChance = 0,
            packages = {
                count = 1,
                weight = 12,
            },
        },

        replacement = {
            packages = 1,
            tools = {
                { tag = "base:hammer" },
            },
            materials = {},
        },
    },
}
