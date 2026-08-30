return {
    defaultId = "LargeGates.Metal.Forged",

    defaults = {
        frame = false,
        materialType = "Metal_Solid",
        doorSound = "MetalPoleGateDouble",
        thumpSound = "ZombieThumpMetalPoleGate",
        engineMaterials = { "MetalBars", "MetalPipe" },
        durability = { worldHealth = 1200, health = 500, skillBaseHealth = 375 },
        construction = {
            skill = { MetalWelding = 6 }, time = 260, xp = 50,
            tools = { { tag = "base:weldingmask" } },
            materials = {
                { item = "Base.BlowTorch", uses = 8 }, { anyOf = { "Base.MetalBar", "Base.IronBar" }, amount = 8 },
                { item = "Base.MetalPipe", amount = 4 }, { item = "Base.Hinge", amount = 4 },
                { item = "Base.WeldingRods", uses = 6 },
            },
        },
        pickup = { skill = { MetalWelding = 3 }, tools = { { tag = "base:crowbar" } }, breakChance = 0, packages = { count = 2, weight = 30 } },
        replacement = { packages = 2, tools = { { tag = "base:hammer" } }, materials = {} },
    },
}
