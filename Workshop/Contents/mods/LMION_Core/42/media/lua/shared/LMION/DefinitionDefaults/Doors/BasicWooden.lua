return {
    id = "Doors.Wooden.BasicWooden",

    defaults = {
        class = "wood",
        frame = "standard",
        materialType = "Wood_Solid",
        doorSound = "WoodDoor",
        thumpSound = "ZombieThumpWood",

        engineMaterials = { "Wood", "Nails" },

        durability = {
            worldHealth = 400,
            health = 250,
            skillBaseHealth = 150,
        },

        construction = {
            skill = { Woodwork = 3 },
            time = 90,
            xp = 15,
            tools = { "Base.Hammer" },

            materials = {
                { item = "Base.Plank", amount = 4 },
                { item = "Base.Nails", amount = 4 },
                { item = "Base.Hinge", amount = 2 },
                { item = "Base.Doorknob", amount = 1 },
            },
        },

        pickup = {
            skill = { Woodwork = 1 },
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
