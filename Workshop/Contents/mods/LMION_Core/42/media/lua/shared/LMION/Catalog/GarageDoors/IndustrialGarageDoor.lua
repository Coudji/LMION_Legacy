return {
    definitionId = "GarageDoors.IndustrialGarageDoor",
    displayName = "Industrial Garage Door",
    entity = "Base.IndustrialGarageDoor",
    inherits = "GarageDoors.Solid",

    geometry = {
        N = {
            START = { closed = "industry_trucks_01_35", open = "industry_trucks_01_43" },
            MIDDLE = { closed = "industry_trucks_01_36", open = "industry_trucks_01_44" },
            END = { closed = "industry_trucks_01_37", open = "industry_trucks_01_45" },
        },
        W = {
            START = { closed = "industry_trucks_01_32", open = "industry_trucks_01_40" },
            MIDDLE = { closed = "industry_trucks_01_33", open = "industry_trucks_01_41" },
            END = { closed = "industry_trucks_01_34", open = "industry_trucks_01_42" },
        },
    },
}
