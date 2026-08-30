return {
    id = "FenceGates.Metal.SmallWroughtIron",
    defaults = {
        class = "metal", frame = false, materialType = "Metal_Solid", doorSound = "MetalPoleGateSmall", thumpSound = "ZombieThumpMetalPoleGate",
        engineMaterials = { "MetalBars", "MetalPipe" },
        durability = { worldHealth = 650, health = 325, skillBaseHealth = 250 },
        construction = { skill = { MetalWelding = 3 }, time = 100, xp = 20, tools = { "Base.WeldingMask" }, materials = { { item = "Base.BlowTorch", uses = 3 }, { item = "Base.MetalBar", amount = 2 }, { item = "Base.MetalPipe", amount = 1 }, { item = "Base.Hinge", amount = 2 }, { item = "Base.WeldingRods", uses = 2 } } },
        pickup = { skill = { MetalWelding = 1 }, tools = { "Base.BlowTorch", "Base.WeldingMask" }, breakChance = 0, packages = { count = 1, weight = 12 } },
        replacement = { packages = 1, tools = { "Base.BlowTorch", "Base.WeldingMask" }, materials = { { item = "Base.WeldingRods", uses = 1 } } },
    },
}
