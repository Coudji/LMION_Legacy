return {
    id = "Base.IndustrialGarageDoor",
    inherits = "GarageDoors.Solid",

    topology = {
        type = "garageChain",
        roles = { "START", "MIDDLE", "END" },
    },

    geometry = {
        N = { closed = {}, open = {} },
        W = { closed = {}, open = {} },
    },
}
