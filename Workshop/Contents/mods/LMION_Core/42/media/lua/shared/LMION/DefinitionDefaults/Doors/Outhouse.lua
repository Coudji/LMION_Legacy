return {
    id = "Doors.Wooden.Outhouse",

    defaults = {
        class = "wood",
        frame = "standard",
        materialType = "Wood",
        doorSound = "WoodDoor",
        thumpSound = "ZombieThumpWood",

        engineMaterials = { "Wood", "Nails" },

        durability = {
            worldHealth = 250,
            health = 250,
            skillBaseHealth = 0,
        },

        construction = {
            skill = { Woodwork = 1 },
            time = 50,
            xp = 5,
            tools = { "Base.Hammer" },

            materials = {
                { item = "Base.Plank", amount = 3 },
                { item = "Base.Nails", amount = 4 },
                { item = "Base.Hinge", amount = 2 },
                { item = "Base.Doorknob", amount = 1 },
            },
        },

        pickup = {
            skill = { Woodwork = 0 },
            tools = { "Base.Hammer" },
            breakChance = 0,
            packages = {
                count = 1,
                weight = 10,
            },
        },

        replacement = {
            packages = 1,
            tools = { "Base.Hammer" },
            materials = {},
        },
    },
}
