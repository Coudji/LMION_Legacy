return {
    id = "Doors.Metal.PatchworkMetal",

    defaults = {
        class = "metal",
        frame = "standard",
        materialType = "Metal_Light",
        doorSound = "MetalDoor",
        thumpSound = "ZombieThumpMetal",

        engineMaterials = { "MetalPlates", "MetalScrap" },

        durability = {
            worldHealth = 650,
            health = 350,
            skillBaseHealth = 250,
        },

        construction = {
            skill = { MetalWelding = 3 },
            time = 120,
            xp = 20,
            tools = { "Base.WeldingMask" },

            materials = {
                { item = "Base.BlowTorch", uses = 4 },
                { item = "Base.SmallSheetMetal", amount = 3 },
                { item = "Base.Hinge", amount = 2 },
                { item = "Base.WeldingRods", uses = 4 },
                { item = "Base.Doorknob", amount = 1 },
            },
        },

        pickup = {
            skill = { MetalWelding = 1 },
            tools = { "Base.Screwdriver" },
            breakChance = 0,
            packages = {
                count = 1,
                weight = 20,
            },
        },

        replacement = {
            packages = 1,
            tools = { "Base.Screwdriver" },
            materials = {},
        },
    },
}
