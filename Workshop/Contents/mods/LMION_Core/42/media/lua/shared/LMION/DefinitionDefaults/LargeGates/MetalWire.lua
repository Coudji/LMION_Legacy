return {
    defaultId = "LargeGates.Metal.Wire",

    defaults = {
        doorType = "LargeGate",
        frame = "none",
        materialType = "Metal_Light",
        doorSound = "MetalGate",
        thumpSound = "ZombieThumpChainlinkFence",
        engineMaterials = { "MetalPipe", "MetalWire" },
        durability = { worldHealth = 850, health = 400, skillBaseHealth = 275 },
        construction = {
            skill = { MetalWelding = 5 }, time = 220, xp = 40,
            tools = { { tag = "base:weldingmask" } },
            materials = {
                { item = "Base.BlowTorch", uses = 10 }, { item = "Base.MetalPipe", amount = 8 },
                { item = "Base.Wire", uses = 4 }, { item = "Base.Hinge", amount = 4 },
                { item = "Base.ScrapMetal", amount = 2 }, { item = "Base.WeldingRods", uses = 10 },
            },
        },
        pickup = { skill = { MetalWelding = 2 }, tools = { { tag = "base:crowbar" } }, breakChance = 0, packages = { count = 2, weight = 15 } },
        replacement = { packages = 2, tools = { { tag = "base:hammer" } }, materials = {} },
    },
}
