return {
    id = "Doors.Wood.OneGlass",

    defaults = {
        class = "wood_glazed",
        frame = "standard",
        materialType = "Wood_Solid",
        doorSound = "WoodDoor",
        thumpSound = "ZombieThumpWood",

        engineMaterials = { "Wood", "Nails", "Screws" },

        durability = {
            worldHealth = 550,
            health = 400,
            skillBaseHealth = 250,
        },

        construction = {
            skill = { Woodwork = 6 },
            time = 160,
            xp = 35,
            tools = { "Base.Hammer", "Base.Screwdriver" },

            materials = {
                { item = "Base.Plank", amount = 4 },
                { item = "Base.Nails", amount = 4 },
                { item = "Base.Hinge", amount = 2 },
                { item = "Base.Screws", amount = 4 },
                { item = "Base.Doorknob", amount = 1 },
                { item = "Base.GlassPanel", amount = 1 },
            },
        },

        pickup = {
            skill = { Woodwork = 3 },
            tools = { "Base.Hammer", "Base.Screwdriver" },
            breakChance = 0,
            packages = {
                count = 1,
                weight = 16,
            },
        },

        replacement = {
            packages = 1,
            tools = { "Base.Hammer", "Base.Screwdriver" },
            materials = {},
        },
    },
}
