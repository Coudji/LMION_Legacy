return {
    defaultId = "SlidingDoors.SlidingGlass",

    defaults = {
        doorType = "Sliding",
        frame = "none",
        materialType = "Glass_Solid",
        doorSound = "SlidingGlassDoor",
        thumpSound = "ZombieThumpWindow",
        engineMaterials = { "MetalPlates", "MetalBars", "Glass" },
        durability = { worldHealth = 250, health = 250, skillBaseHealth = 0 },
        construction = {
            skill = { MetalWelding = 3 }, time = 100, xp = 15,
            tools = { { tag = "base:weldingmask" } },
            materials = {
                { item = "Base.BlowTorch", uses = 4 }, { item = "Base.SmallSheetMetal", amount = 2 },
                { anyOf = { "Base.MetalBar", "Base.IronBar" }, amount = 2 }, { item = "Base.GlassPanel", amount = 2 },
                { item = "Base.WeldingRods", uses = 4 },
            },
        },
        pickup = { skill = { MetalWelding = 1 }, tools = { { tag = "base:crowbar" } }, breakChance = 0, packages = { count = 1, weight = 20 } },
        replacement = { packages = 1, tools = { { tag = "base:hammer" } }, materials = {} },
    },
}
