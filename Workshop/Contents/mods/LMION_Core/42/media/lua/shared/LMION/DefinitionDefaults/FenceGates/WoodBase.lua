return {
    definitionId = "FenceGates.Wood.Base",

    defaults = {
        frame = false,
        materialType = "Wood_Solid",
        doorSound = "WoodGate",
        thumpSound = "ZombieThumpWood",

        engineMaterials = { "Wood", "Nails" },

        durability = {
            worldHealth = 500,
            health = 300,
            skillBaseHealth = 225,
        },

        construction = {
            skill = { Woodwork = 3 },
            time = 100,
            xp = 15,
            tools = {
                { tag = "base:hammer" },
            },

            materials = {
                { item = "Base.Plank", amount = 4 },
                { item = "Base.Nails", amount = 4 },
                { item = "Base.Hinge", amount = 2 },
                { item = "Base.Doorknob", amount = 1 },
            },
        },

        pickup = {
            skill = { Woodwork = 1 },
            tools = {
                { tag = "base:crowbar" },
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
                { tag = "base:hammer" },
            },
            materials = {},
        },
    },
}
