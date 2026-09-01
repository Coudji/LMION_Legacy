return {
    definitionId = "Doors.Metal.GreyMetalDoubleDoor",
    inherits = "Doors.Metal.Base",
    frame = "paired",

    entities = {
        left = "Base.GreyMetalDoubleDoorLeft",
        right = "Base.GreyMetalDoubleDoorRight",
    },

    geometry = {
        N = {
            left = {
                closed = "fixtures_doors_02_49",
                open = "fixtures_doors_02_51",
            },
            right = {
                closed = "fixtures_doors_02_53",
                open = "fixtures_doors_02_55",
            },
        },
        W = {
            left = {
                closed = "fixtures_doors_02_52",
                open = "fixtures_doors_02_54",
            },
            right = {
                closed = "fixtures_doors_02_48",
                open = "fixtures_doors_02_50",
            },
        },
    },
}
