return {
    id = "GarageDoors.Glazed",
    defaults = {
        class = "metal_glazed", frame = false, materialType = "Metal_Light", doorSound = "GarageDoor", thumpSound = "ZombieThumpGarageDoor",
        engineMaterials = { "MetalPlates", "MetalBars" },
        durability = { worldHealth = 1000, health = 500, skillBaseHealth = 350 },
        construction = { skill = { MetalWelding = 6 }, time = 200, xp = 50, tools = { "Base.WeldingMask" }, materials = { { item = "Base.BlowTorch", uses = 6 }, { item = "Base.SmallSheetMetal", amount = 6 }, { item = "Base.GlassPanel", amount = 3 }, { item = "Base.MetalBar", amount = 3 }, { item = "Base.Hinge", amount = 6 }, { item = "Base.WeldingRods", uses = 3 } } },
        pickup = { skill = { MetalWelding = 3 }, tools = { "Base.BlowTorch", "Base.WeldingMask" }, breakChance = 0, packages = { count = 3, weight = 20 } },
        replacement = { packages = 3, tools = { "Base.BlowTorch", "Base.WeldingMask" }, materials = { { item = "Base.WeldingRods", uses = 2 } } },
    },
}
