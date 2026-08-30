return {
    id = "FenceGates.Metal.SmallScrapMetal",
    defaults = {
        class = "metal", frame = false, materialType = "Metal_Light", doorSound = "MetalPoleGateSmall", thumpSound = "ZombieThumpMetalPoleGate",
        engineMaterials = { "MetalPipe", "MetalScrap" },
        durability = { worldHealth = 450, health = 250, skillBaseHealth = 175 },
        construction = { skill = { MetalWelding = 2 }, time = 80, xp = 10, tools = { "Base.WeldingMask" }, materials = { { item = "Base.BlowTorch", uses = 3 }, { item = "Base.MetalPipe", amount = 3 }, { item = "Base.Hinge", amount = 2 }, { item = "Base.ScrapMetal", amount = 1 }, { item = "Base.WeldingRods", uses = 3 } } },
        pickup = { skill = { MetalWelding = 1 }, tools = { "Base.BlowTorch", "Base.WeldingMask" }, breakChance = 0, packages = { count = 1, weight = 8 } },
        replacement = { packages = 1, tools = { "Base.BlowTorch", "Base.WeldingMask" }, materials = { { item = "Base.WeldingRods", uses = 2 } } },
    },
}
