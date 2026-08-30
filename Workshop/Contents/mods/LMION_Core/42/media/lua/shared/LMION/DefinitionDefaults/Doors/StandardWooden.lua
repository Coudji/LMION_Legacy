return {
    id = "Doors.Wooden.StandardWooden",

    defaults = {
        class = "wood",
        frame = "standard",
        materialType = "Wood_Solid",
        doorSound = "WoodDoor",
        thumpSound = "ZombieThumpWood",

        engineMaterials = { "Wood", "Nails" },

        durability = {
            worldHealth = 500,
            health = 300,
            skillBaseHealth = 200,
        },

        construction = {
            skill = { Woodwork = 5 },
            time = 120,
            xp = 25,
            tools = { "Base.Hammer" },

            materials = {
                { item = "Base.Plank", amount = 4 },
                { item = "Base.Nails", amount = 4 },
                { item = "Base.Hinge", amount = 2 },
                { item = "Base.Doorknob", amount = 1 },
            },
        },

        pickup = {
            skill = { Woodwork = 2 },
            tools = { "Base.Hammer" },
            breakChance = 0,
            packages = {
                count = 1,
                weight = 15,
            },
        },

        replacement = {
            packages = 1,
            tools = { "Base.Hammer" },
            materials = {},
        },
    },
}
