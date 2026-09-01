return {
    definitionId = "Doors.Wood.BlueChurchDoubleDoor",
    inherits = "Doors.Wood.FourPanels",
    frame = "paired",

    entities = {
        left = "Base.BlueChurchDoubleDoorLeft",
        right = "Base.BlueChurchDoubleDoorRight",
    },

    geometry = {
        N = {
            left = {
                closed = "location_community_church_small_01_25",
                open = "location_community_church_small_01_27",
            },
            right = {
                closed = "location_community_church_small_01_29",
                open = "location_community_church_small_01_31",
            },
        },
        W = {
            left = {
                closed = "location_community_church_small_01_28",
                open = "location_community_church_small_01_30",
            },
            right = {
                closed = "location_community_church_small_01_24",
                open = "location_community_church_small_01_26",
            },
        },
    },
}
