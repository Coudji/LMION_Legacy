return {
    definitionId = "Doors.Metal.BlackTwoPaneDoubleDoor",
    inherits = "Doors.Metal.TwoGlass",
    doorType = "Paired",
    frame = "paired",

    entities = {
        left = "Base.BlackTwoPaneDoubleDoorLeft",
        right = "Base.BlackTwoPaneDoubleDoorRight",
    },

    geometry = {
        N = {
            left = {
                closed = "fixtures_doors_02_41",
                open = "fixtures_doors_02_43",
            },
            right = {
                closed = "fixtures_doors_02_45",
                open = "fixtures_doors_02_47",
            },
        },
        W = {
            left = {
                closed = "fixtures_doors_02_44",
                open = "fixtures_doors_02_46",
            },
            right = {
                closed = "fixtures_doors_02_40",
                open = "fixtures_doors_02_42",
            },
        },
    },
}
