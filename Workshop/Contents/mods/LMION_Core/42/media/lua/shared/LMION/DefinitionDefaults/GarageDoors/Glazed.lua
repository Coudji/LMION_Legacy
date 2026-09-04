return {
    defaultId = "GarageDoors.Glazed",

    defaults = {
        doorType = "Garage",
        frame = "none",
        materialType = "Metal_Light",
        doorSound = "GarageDoor",
        thumpSound = "ZombieThumpGarageDoor",
        engineMaterials = { "MetalPlates", "MetalBars", "Glass" },
        durability = { worldHealth = 1000, health = 500, skillBaseHealth = 350 },
        construction = {
            skill = { MetalWelding = 6 }, time = 200, xp = 50,
            tools = { { tag = "base:weldingmask" } },
            materials = {
                { item = "Base.BlowTorch", uses = 6 }, { item = "Base.SmallSheetMetal", amount = 6 },
                { item = "Base.GlassPanel", amount = 3 }, { anyOf = { "Base.MetalBar", "Base.IronBar" }, amount = 3 },
                { item = "Base.Hinge", amount = 6 }, { item = "Base.WeldingRods", uses = 3 },
            },
        },
        pickup = {
            skill = { MetalWelding = 3 },
            tools = { { tag = "base:crowbar" } },
            breakChance = 0,
            packages = { weight = 20 },
        },
        replacement = {
            tools = { { tag = "base:hammer" } },
            materials = {},
        },
    },
}
