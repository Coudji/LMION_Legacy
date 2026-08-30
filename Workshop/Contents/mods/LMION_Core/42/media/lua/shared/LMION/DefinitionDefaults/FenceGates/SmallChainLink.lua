return {
    id = "FenceGates.Metal.SmallChainLink",
    defaults = {
        class = "metal", frame = false, materialType = "Metal_Light", doorSound = "MetalGate", thumpSound = "ZombieThumpChainlinkFence",
        engineMaterials = { "MetalPipe", "MetalWire" },
        durability = { worldHealth = 450, health = 250, skillBaseHealth = 175 },
        construction = { skill = { MetalWelding = 2 }, time = 70, xp = 10, tools = { "Base.WeldingMask" }, materials = { { item = "Base.BlowTorch", uses = 2 }, { item = "Base.MetalPipe", amount = 2 }, { item = "Base.Wire", uses = 1 }, { item = "Base.Hinge", amount = 2 }, { item = "Base.ScrapMetal", amount = 1 }, { item = "Base.WeldingRods", uses = 2 } } },
        pickup = { skill = { MetalWelding = 1 }, tools = { "Base.BlowTorch", "Base.WeldingMask" }, breakChance = 0, packages = { count = 1, weight = 6 } },
        replacement = { packages = 1, tools = { "Base.BlowTorch", "Base.WeldingMask" }, materials = { { item = "Base.WeldingRods", uses = 1 } } },
    },
}
