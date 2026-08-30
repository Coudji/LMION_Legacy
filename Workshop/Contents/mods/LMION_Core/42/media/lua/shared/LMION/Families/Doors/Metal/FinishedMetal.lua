return {
    id = "Doors.Metal.FinishedMetal",

    defaults = {
        material = "metal",
        frame = "standard",
        durability = { health = 425, skillBaseHealth = 275 },
        construction = {
            skill = { MetalWelding = 4 },
            time = 160,
            xp = 30,
            tools = { "Base.BlowTorch", "Base.WeldingMask" },
            materials = {
                { item = "Base.SheetMetal", amount = 1 },
                { item = "Base.MetalBar", amount = 2 },
                { item = "Base.DoorHinge", amount = 2 },
                { item = "Base.WeldingRods", uses = 4 },
                { item = "Base.Doorknob", amount = 1 },
            },
        },
    },
}
