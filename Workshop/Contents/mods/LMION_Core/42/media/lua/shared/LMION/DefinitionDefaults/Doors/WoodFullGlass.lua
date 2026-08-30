return {
    definitionId = "Doors.Wood.FullGlass",

    defaults = {
        frame = "standard",
        materialType = "Glass_Solid",
        doorSound = "MetalDoor",
        thumpSound = "ZombieThumpWindow",

        engineMaterials = { "Wood", "Nails", "Screws" },

        durability = {
            worldHealth = 425,
            health = 300,
            skillBaseHealth = 175,
        },

        construction = {
            skill = { Woodwork = 7 },
            time = 170,
            xp = 40,
            tools = {
                { tag = "base:hammer" },
                { tag = "base:screwdriver" },
            },

            materials = {
                { item = "Base.Plank", amount = 2 },
                { item = "Base.Nails", amount = 2 },
                { item = "Base.Hinge", amount = 2 },
                { item = "Base.Screws", amount = 4 },
                { item = "Base.Doorknob", amount = 1 },
                { item = "Base.GlassPanel", amount = 3 },
            },
        },

        pickup = {
            skill = { Woodwork = 3 },
            tools = {
                { tag = "base:screwdriver" },
            },
            breakChance = 0,
            packages = {
                count = 1,
                weight = 14,
            },
        },

        replacement = {
            packages = 1,
            tools = {
                { tag = "base:screwdriver" },
            },
            materials = {},
        },
    },
}
