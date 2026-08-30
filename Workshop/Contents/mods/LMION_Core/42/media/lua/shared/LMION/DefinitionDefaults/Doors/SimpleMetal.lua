return {
    id = "Doors.Metal.SimpleMetal",

    defaults = {
        class = "metal",
        frame = "standard",
        materialType = "Metal_Light",
        doorSound = "MetalDoor",
        thumpSound = "ZombieThumpMetal",

        engineMaterials = { "MetalPlates" },

        durability = {
            worldHealth = 750,
            health = 400,
            skillBaseHealth = 275,
        },

        construction = {
            skill = { MetalWelding = 4 },
            time = 140,
            xp = 25,
            tools = { "Base.WeldingMask" },

            materials = {
                { item = "Base.BlowTorch", uses = 4 },
                { item = "Base.SmallSheetMetal", amount = 3 },
                { item = "Base.Hinge", amount = 2 },
                { item = "Base.WeldingRods", uses = 4 },
                { item = "Base.Doorknob", amount = 1 },
            },
        },

        pickup = {
            skill = { MetalWelding = 2 },
            tools = { "Base.Screwdriver", "Base.Crowbar" },
            breakChance = 0,
            packages = {
                count = 1,
                weight = 22,
            },
        },

        replacement = {
            packages = 1,
            tools = { "Base.Screwdriver" },
            materials = {},
        },
    },
}
