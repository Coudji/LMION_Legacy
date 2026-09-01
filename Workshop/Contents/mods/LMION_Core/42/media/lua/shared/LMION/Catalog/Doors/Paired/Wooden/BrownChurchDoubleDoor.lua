return {
    definitionId = "Doors.Wood.BrownChurchDoubleDoor",
    inherits = "Doors.Wood.FourPanels",
    frame = "paired",

    topology = {
        type = "paired",
        left = "Base.BrownChurchDoubleDoorLeft",
        right = "Base.BrownChurchDoubleDoorRight",
    },

    geometry = {
        N = {
            left = {
                closed = "location_community_church_small_01_65",
                open = "location_community_church_small_01_67",
            },
            right = {
                closed = "location_community_church_small_01_69",
                open = "location_community_church_small_01_71",
            },
        },
        W = {
            left = {
                closed = "location_community_church_small_01_68",
                open = "location_community_church_small_01_70",
            },
            right = {
                closed = "location_community_church_small_01_64",
                open = "location_community_church_small_01_66",
            },
        },
    },
}
