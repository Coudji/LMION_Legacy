return {
    id = "FenceGates.Metal.ScrapMetal",
    defaults = {
        class = "metal", frame = false, materialType = "Metal_Light", doorSound = "MetalPoleGate", thumpSound = "ZombieThumpMetalPoleGate",
        engineMaterials = { "MetalPipe", "MetalScrap" },
        durability = { worldHealth = 600, health = 300, skillBaseHealth = 225 },
        construction = { skill = { MetalWelding = 3 }, time = 120, xp = 15, tools = { "Base.WeldingMask" }, materials = { { item = "Base.BlowTorch", uses = 5 }, { item = "Base.MetalPipe", amount = 5 }, { item = "Base.Hinge", amount = 2 }, { item = "Base.ScrapMetal", amount = 2 }, { item = "Base.WeldingRods", uses = 5 } } },
        pickup = { skill = { MetalWelding = 1 }, tools = { "Base.BlowTorch", "Base.WeldingMask" }, breakChance = 0, packages = { count = 1, weight = 16 } },
        replacement = { packages = 1, tools = { "Base.BlowTorch", "Base.WeldingMask" }, materials = { { item = "Base.WeldingRods", uses = 3 } } },
    },
}
