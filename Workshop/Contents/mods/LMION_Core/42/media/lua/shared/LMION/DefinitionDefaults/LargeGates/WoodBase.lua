return {
    definitionId = "LargeGates.Wood.Base",

    defaults = {
        frame = false,
        materialType = "Wood_Solid",
        doorSound = "WoodGate",
        thumpSound = "ZombieThumpWood",

        engineMaterials = { "Wood", "Nails" },

        durability = {
            worldHealth = 650,
            health = 400,
            skillBaseHealth = 300,
        },

        construction = {
            skill = { Woodwork = 4 },
            time = 180,
            xp = 30,
            tools = {
                { tag = "base:hammer" },
            },

            materials = {
                { item = "Base.Plank", amount = 8 },
                { item = "Base.Nails", amount = 8 },
                { item = "Base.Hinge", amount = 4 },
                { item = "Base.Doorknob", amount = 2 },
            },
        },

        pickup = {
            skill = { Woodwork = 2 },
            tools = {
                { tag = "base:crowbar" },
            },
            breakChance = 0,
            packages = {
                count = 2,
                weight = 18,
            },
        },

        replacement = {
            packages = 2,
            tools = {
                { tag = "base:hammer" },
            },
            materials = {},
        },
    },
}
