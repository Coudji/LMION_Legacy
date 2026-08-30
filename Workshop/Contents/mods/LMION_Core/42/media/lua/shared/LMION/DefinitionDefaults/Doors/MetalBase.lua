return {
    id = "Doors.Metal.Base",

    defaults = {
        class = "metal",
        frame = "standard",
        materialType = "Metal_Solid",
        doorSound = "MetalDoor",
        thumpSound = "ZombieThumpMetal",

        engineMaterials = { "MetalPlates", "MetalBars" },

        durability = {
            worldHealth = 800,
            health = 425,
            skillBaseHealth = 275,
        },

        construction = {
            skill = { MetalWelding = 4 },
            time = 160,
            xp = 30,
            tools = { "Base.WeldingMask" },

            materials = {
                { item = "Base.BlowTorch", uses = 4 },
                { item = "Base.SheetMetal", amount = 1 },
                { item = "Base.MetalBar", amount = 2 },
                { item = "Base.Hinge", amount = 2 },
                { item = "Base.WeldingRods", uses = 4 },
                { item = "Base.Doorknob", amount = 1 },
            },
        },

        pickup = {
            skill = { MetalWelding = 2 },
            tools = { "Base.Screwdriver", "Base.Crowbar" },
            breakChance = 0,
            packages = {
                count = 1,
                weight = 24,
            },
        },

        replacement = {
            packages = 1,
            tools = { "Base.Screwdriver" },
            materials = {},
        },
    },
}
