return {
    definitionId = "GarageDoors.Solid",

    defaults = {
        frame = false,
        materialType = "Metal_Light",
        doorSound = "GarageDoor",
        thumpSound = "ZombieThumpGarageDoor",

        engineMaterials = { "MetalPlates", "MetalBars" },

        durability = {
            worldHealth = 1200,
            health = 600,
            skillBaseHealth = 400,
        },

        construction = {
            skill = { MetalWelding = 6 },
            time = 200,
            xp = 50,
            tools = {
                { tag = "base:weldingmask" },
            },

            materials = {
                { item = "Base.BlowTorch", uses = 6 },
                { item = "Base.SmallSheetMetal", amount = 9 },
                { anyOf = { "Base.MetalBar", "Base.IronBar" }, amount = 3 },
                { item = "Base.Hinge", amount = 6 },
                { item = "Base.WeldingRods", uses = 3 },
            },
        },

        pickup = {
            skill = { MetalWelding = 3 },
            tools = {
                { tag = "base:crowbar" },
            },
            breakChance = 0,
            packages = {
                count = 3,
                weight = 20,
            },
        },

        replacement = {
            packages = 3,
            tools = {
                { tag = "base:hammer" },
            },
            materials = {},
        },
    },
}
