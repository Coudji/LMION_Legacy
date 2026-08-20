require "LMION/Debug/Registry"

LMION.Debug.Showroom = LMION.Debug.Showroom or {}

local Profiles = LMION.Debug.Showroom.Profiles or {}
LMION.Debug.Showroom.Profiles = Profiles

Profiles.names = {
    ["fixtures_bathroom_01_49"] = "Small Bathroom Door A",
    ["fixtures_bathroom_01_65"] = "Small Bathroom Door B",
    ["fixtures_doors_01_1"] = "White Door",
    ["fixtures_doors_01_109"] = "Brown Sliding Glass Door",
    ["fixtures_doors_01_117"] = "White Sliding Glass Door",
    ["fixtures_doors_01_13"] = "Cherry Door",
    ["fixtures_doors_01_17"] = "Tan Door",
    ["fixtures_doors_01_21"] = "Black Door",
    ["fixtures_doors_01_25"] = "Blue Metal",
    ["fixtures_doors_01_29"] = "Rough Wooden Door",
    ["fixtures_doors_01_33"] = "Security Door",
    ["fixtures_doors_01_37"] = "Single Pane Chestnut Door",
    ["fixtures_doors_01_41"] = "Single Pane Black Door",
    ["fixtures_doors_01_45"] = "White Door with Windows",
    ["fixtures_doors_01_49"] = "Black 2 Pane Door",
    ["fixtures_doors_01_5"] = "Brown Door",
    ["fixtures_doors_01_57"] = "White Metal Door",
    ["fixtures_doors_01_61"] = "White Metal Door with Window",
    ["fixtures_doors_01_65"] = "Tan Metal Door",
    ["fixtures_doors_01_9"] = "Wooden Door",
    ["fixtures_doors_02_1"] = "Blue Door",
    ["fixtures_doors_02_13"] = "Black Metal Door",
    ["fixtures_doors_02_17"] = "Brown Panel Door",
    ["fixtures_doors_02_21"] = "White Panel Door",
    ["fixtures_doors_02_25"] = "Black Panel Door",
    ["fixtures_doors_02_41"] = "Double Black Glass Door - Left",
    ["fixtures_doors_02_45"] = "Double Black Glass Door - Right",
    ["fixtures_doors_02_49"] = "Double Grey Metal Door - Left",
    ["fixtures_doors_02_5"] = "Brown Door with Windows",
    ["fixtures_doors_02_53"] = "Double Grey Metal Door - Right",
    ["fixtures_doors_02_57"] = "Double Orange Kitchen Metal Door - Left",
    ["fixtures_doors_02_61"] = "Double Orange Kitchen Metal Door - Right",
    ["fixtures_doors_02_9"] = "Red Metal Door",
    ["fixtures_doors_fences_01_1"] = "Metal Fence Gate",
    ["fixtures_doors_fences_01_129"] = "Big Wire Fence Gate",
    ["fixtures_doors_fences_01_13"] = "Wooden Fence Gate",
    ["fixtures_doors_fences_01_17"] = "Metal Wire Fence Gate",
    ["fixtures_doors_fences_01_21"] = "Wrought Iron Gate",
    ["fixtures_doors_fences_01_25"] = "Big Pole Fence Gate",
    ["fixtures_doors_fences_01_29"] = "Metal Pole Fence Gate",
    ["fixtures_doors_fences_01_34"] = "Double Wrought Iron Gate",
    ["fixtures_doors_fences_01_5"] = "Wooden Fence Gate",
    ["fixtures_doors_fences_01_9"] = "White Wooden Fence Gate",
    ["location_community_church_small_01_25"] = "Church Paired Door A - Left",
    ["location_community_church_small_01_29"] = "Church Paired Door A - Right",
    ["location_community_church_small_01_65"] = "Church Paired Door B - Left",
    ["location_community_church_small_01_69"] = "Church Paired Door B - Right",
    ["location_community_police_01_5"] = "Jail Door",
    ["location_restaurant_pileocrepe_01_49"] = "Pile O' Crepe Blue Door with Window",
    ["location_restaurant_pileocrepe_01_53"] = "Pile O' Crepe Orange Door",
    ["location_restaurant_pizzawhirled_01_57"] = "Pizza Whirled Brown Glass Door",
    ["location_restaurant_pizzawhirled_01_61"] = "Pizza Whirled Green Metal Door",
    ["location_restaurant_seahorse_01_49"] = "Sea Horse Glass Door",
    ["location_restaurant_spiffos_01_49"] = "Spiffos Glass Door",
    ["location_restaurant_spiffos_01_53"] = "Spiffos Red Metal Door",
    ["location_shop_fossoil_01_61"] = "Blue Fossoil Glass Door",
    ["location_shop_gas2go_01_61"] = "Red Gas 2 Go Glass Door",
    ["walls_garage_01_19"] = "3 Tiles Green Garage Door",
    ["walls_garage_01_3"] = "3 Tiles White Garage Door",
    ["walls_garage_01_51"] = "3 Tiles Gray Garage Door",
    ["walls_garage_02_3"] = "3 Tiles Rolling Garage Door",
    ["walls_garage_02_35"] = "3 Tiles Red Window Garage Door",
    ["walls_garage_02_51"] = "3 Tiles Rolling Window Garage Door",
}

Profiles.special = {
    ["fixtures_bathroom_01_49"] = {
        kind = "small",
        frame = "standard",
        displayName = "Small Bathroom Door A",
    },
    ["fixtures_bathroom_01_65"] = {
        kind = "small",
        frame = "standard",
        displayName = "Small Bathroom Door B",
    },
    ["fixtures_doors_01_109"] = {
        kind = "sliding",
        frame = "none",
        displayName = "Brown Sliding Glass Door",
    },
    ["fixtures_doors_01_117"] = {
        kind = "sliding",
        frame = "none",
        displayName = "White Sliding Glass Door",
    },
    ["fixtures_doors_02_17"] = {
        kind = "small",
        frame = "standard",
        displayName = "Brown Panel Door",
    },
    ["fixtures_doors_02_21"] = {
        kind = "small",
        frame = "standard",
        displayName = "White Panel Door",
    },
    ["fixtures_doors_02_25"] = {
        kind = "small",
        frame = "standard",
        displayName = "Black Panel Door",
    },
    ["fixtures_doors_02_41"] = {
        kind = "paired",
        frame = "paired",
        side = "left",
        pair = "fixtures_doors_02_45",
        displayName = "Double Black Glass Door - Left",
    },
    ["fixtures_doors_02_45"] = {
        kind = "paired",
        frame = "paired",
        side = "right",
        pair = "fixtures_doors_02_41",
        displayName = "Double Black Glass Door - Right",
    },
    ["fixtures_doors_02_49"] = {
        kind = "paired",
        frame = "paired",
        side = "left",
        pair = "fixtures_doors_02_53",
        displayName = "Double Grey Metal Door - Left",
    },
    ["fixtures_doors_02_53"] = {
        kind = "paired",
        frame = "paired",
        side = "right",
        pair = "fixtures_doors_02_49",
        displayName = "Double Grey Metal Door - Right",
    },
    ["fixtures_doors_02_57"] = {
        kind = "paired",
        frame = "paired",
        side = "left",
        pair = "fixtures_doors_02_61",
        displayName = "Double Orange Kitchen Metal Door - Left",
    },
    ["fixtures_doors_02_61"] = {
        kind = "paired",
        frame = "paired",
        side = "right",
        pair = "fixtures_doors_02_57",
        displayName = "Double Orange Kitchen Metal Door - Right",
    },
    ["fixtures_doors_fences_01_1"] = {
        kind = "fence-low",
        frame = "none",
        displayName = "Metal Fence Gate",
    },
    ["fixtures_doors_fences_01_129"] = {
        kind = "fence-high",
        frame = "none",
        displayName = "Big Wire Fence Gate",
    },
    ["fixtures_doors_fences_01_13"] = {
        kind = "fence-high",
        frame = "none",
        displayName = "Wooden Fence Gate",
    },
    ["fixtures_doors_fences_01_17"] = {
        kind = "fence-low",
        frame = "none",
        displayName = "Metal Wire Fence Gate",
    },
    ["fixtures_doors_fences_01_21"] = {
        kind = "fence-high",
        frame = "none",
        displayName = "Wrought Iron Gate",
    },
    ["fixtures_doors_fences_01_25"] = {
        kind = "fence-high",
        frame = "none",
        displayName = "Big Pole Fence Gate",
    },
    ["fixtures_doors_fences_01_29"] = {
        kind = "fence-low",
        frame = "none",
        displayName = "Metal Pole Fence Gate",
    },
    ["fixtures_doors_fences_01_5"] = {
        kind = "fence-low",
        frame = "none",
        displayName = "Wooden Fence Gate",
    },
    ["fixtures_doors_fences_01_9"] = {
        kind = "fence-low",
        frame = "none",
        displayName = "White Wooden Fence Gate",
    },
    ["location_community_church_small_01_25"] = {
        kind = "paired",
        frame = "paired",
        side = "left",
        pair = "location_community_church_small_01_29",
        displayName = "Church Paired Door A - Left",
    },
    ["location_community_church_small_01_29"] = {
        kind = "paired",
        frame = "paired",
        side = "right",
        pair = "location_community_church_small_01_25",
        displayName = "Church Paired Door A - Right",
    },
    ["location_community_church_small_01_65"] = {
        kind = "paired",
        frame = "paired",
        side = "left",
        pair = "location_community_church_small_01_69",
        displayName = "Church Paired Door B - Left",
    },
    ["location_community_church_small_01_69"] = {
        kind = "paired",
        frame = "paired",
        side = "right",
        pair = "location_community_church_small_01_65",
        displayName = "Church Paired Door B - Right",
    },
}

function Profiles.get(anchor)
    return Profiles.special[anchor]
end

function Profiles.getName(anchor)
    return Profiles.names[anchor]
end

return Profiles
