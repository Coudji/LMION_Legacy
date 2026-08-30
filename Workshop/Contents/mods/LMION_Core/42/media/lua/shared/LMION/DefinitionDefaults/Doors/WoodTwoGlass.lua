return {
    definitionId = "Doors.Wood.TwoGlass",

    defaults = {
        frame = "standard",
        materialType = "Wood_Solid",
        doorSound = "MetalDoor",
        thumpSound = "ZombieThumpWindow",

        engineMaterials = { "Wood", "Nails", "Screws" },

        durability = {
            worldHealth = 500,
            health = 350,
            skillBaseHealth = 225,
        },

        construction = {
            skill = { Woodwork = 7 },
            time = 180,
            xp = 45,
            tools = {
                { tag = "base:hammer" },
                { tag = "base:screwdriver" },
            },

            materials = {
                { item = "Base.Plank", amount = 4 },
                { item = "Base.Nails", amount = 4 },
                { item = "Base.Hinge", amount = 2 },
                { item = "Base.Screws", amount = 4 },
                { item = "Base.Doorknob", amount = 1 },
                { item = "Base.GlassPanel", amount = 2 },
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
                weight = 16,
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
