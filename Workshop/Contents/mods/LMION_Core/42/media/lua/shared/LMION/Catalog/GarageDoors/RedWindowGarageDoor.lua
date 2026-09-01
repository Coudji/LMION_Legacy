return {
    definitionId = "GarageDoors.RedWindowGarageDoor",
    displayName = "Red Window Garage Door",
    entity = "Base.RedWindowGarageDoor",
    inherits = "GarageDoors.Glazed",

    geometry = {
        N = {
            START = { closed = "walls_garage_02_35", open = "walls_garage_02_43" },
            MIDDLE = { closed = "walls_garage_02_36", open = "walls_garage_02_44" },
            END = { closed = "walls_garage_02_37", open = "walls_garage_02_45" },
        },
        W = {
            START = { closed = "walls_garage_02_32", open = "walls_garage_02_40" },
            MIDDLE = { closed = "walls_garage_02_33", open = "walls_garage_02_41" },
            END = { closed = "walls_garage_02_34", open = "walls_garage_02_42" },
        },
    },
}
