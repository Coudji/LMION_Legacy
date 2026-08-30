return {
    defaultId = "FenceGates.Metal.Forged",

    defaults = {
        frame = false,
        materialType = "Metal_Solid",
        doorSound = "MetalPoleGate",
        thumpSound = "ZombieThumpMetalPoleGate",

        engineMaterials = { "MetalBars", "MetalPipe" },

        durability = { worldHealth = 850, health = 400, skillBaseHealth = 300 },

        construction = {
            skill = { MetalWelding = 4 }, time = 140, xp = 25,
            tools = { { tag = "base:weldingmask" } },
            materials = {
                { item = "Base.BlowTorch", uses = 5 },
                { anyOf = { "Base.MetalBar", "Base.IronBar" }, amount = 4 },
                { item = "Base.MetalPipe", amount = 2 },
                { item = "Base.Hinge", amount = 2 },
                { item = "Base.WeldingRods", uses = 4 },
            },
        },

        pickup = {
            skill = { MetalWelding = 2 },
            tools = { { tag = "base:crowbar" } },
            breakChance = 0,
            packages = { count = 1, weight = 25 },
        },

        replacement = {
            packages = 1,
            tools = { { tag = "base:hammer" } },
            materials = {},
        },
    },
}
