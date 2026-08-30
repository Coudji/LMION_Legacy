return {
    id = "Doors.Wooden.Paneled",

    defaults = {
        material = "wood",
        frame = "standard",

        durability = {
            health = 450,
            skillBaseHealth = 275,
        },

        construction = {
            skill = { Woodwork = 6 },
            time = 150,
            xp = 35,
            tools = { "Base.Hammer", "Base.Screwdriver" },
            materials = {
                { item = "Base.Plank", amount = 4 },
                { item = "Base.Nails", amount = 4 },
                { item = "Base.DoorHinge", amount = 2 },
                { item = "Base.Screws", amount = 4 },
                { item = "Base.Doorknob", amount = 1 },
            },
        },

        pickup = {
            skill = { Woodwork = 3 },
            tools = { "Base.Hammer", "Base.Screwdriver" },
            weight = 17,
        },
    },
}
