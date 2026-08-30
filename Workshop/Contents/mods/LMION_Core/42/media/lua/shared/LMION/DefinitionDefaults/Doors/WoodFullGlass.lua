return {
    id = "Doors.Wood.FullGlass",

    defaults = {
        class = "wood_glazed",
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
            tools = { "Base.Hammer", "Base.Screwdriver" },

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
            tools = { "Base.Hammer", "Base.Screwdriver" },
            breakChance = 0,
            packages = {
                count = 1,
                weight = 14,
            },
        },

        replacement = {
            packages = 1,
            tools = { "Base.Hammer", "Base.Screwdriver" },
            materials = {},
        },
    },
}
