return {
    id = "GarageDoors.Solid",

    defaults = {
        class = "metal",
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
            tools = { "Base.WeldingMask" },

            materials = {
                { item = "Base.BlowTorch", uses = 6 },
                { item = "Base.SmallSheetMetal", amount = 9 },
                { item = "Base.MetalBar", amount = 3 },
                { item = "Base.Hinge", amount = 6 },
                { item = "Base.WeldingRods", uses = 3 },
            },
        },

        pickup = {
            skill = { MetalWelding = 3 },
            tools = { "Base.BlowTorch", "Base.WeldingMask" },
            breakChance = 0,
            packages = {
                count = 3,
                weight = 20,
            },
        },

        replacement = {
            packages = 3,
            tools = { "Base.BlowTorch", "Base.WeldingMask" },
            materials = {
                { item = "Base.WeldingRods", uses = 2 },
            },
        },
    },
}
