return {
    id = "Doors.Metal.TwoGlass",

    defaults = {
        class = "metal_glazed",
        frame = "standard",
        materialType = "Metal_Solid",
        doorSound = "MetalDoor",
        thumpSound = "ZombieThumpWindow",

        engineMaterials = { "MetalPlates", "MetalBars" },

        durability = {
            worldHealth = 650,
            health = 350,
            skillBaseHealth = 225,
        },

        construction = {
            skill = { MetalWelding = 5 },
            time = 190,
            xp = 35,
            tools = { "Base.WeldingMask" },

            materials = {
                { item = "Base.BlowTorch", uses = 4 },
                { item = "Base.SheetMetal", amount = 1 },
                { item = "Base.MetalBar", amount = 2 },
                { item = "Base.Hinge", amount = 2 },
                { item = "Base.WeldingRods", uses = 4 },
                { item = "Base.Doorknob", amount = 1 },
                { item = "Base.GlassPanel", amount = 2 },
            },
        },

        pickup = {
            skill = { MetalWelding = 2 },
            tools = { "Base.Screwdriver", "Base.Crowbar" },
            breakChance = 0,
            packages = {
                count = 1,
                weight = 21,
            },
        },

        replacement = {
            packages = 1,
            tools = { "Base.Screwdriver" },
            materials = {},
        },
    },
}
