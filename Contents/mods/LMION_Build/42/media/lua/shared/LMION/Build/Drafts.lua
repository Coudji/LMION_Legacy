LMION.Build = LMION.Build or {}

local Drafts = LMION.Build.Drafts or {}
LMION.Build.Drafts = Drafts

local entries = {
    ["industry_trucks_01_35"] = { index = 1, displayName = "Door 001", kind = "garage", materialClass = "wood", useVanillaRecipe = false },
    ["walls_garage_01_19"] = { index = 2, displayName = "3 Tiles Green Garage Door", kind = "garage", materialClass = "metal", useVanillaRecipe = false },
    ["walls_garage_01_3"] = { index = 3, displayName = "3 Tiles White Garage Door", kind = "garage", materialClass = "metal", useVanillaRecipe = false },
    ["walls_garage_01_51"] = { index = 4, displayName = "3 Tiles Gray Garage Door", kind = "garage", materialClass = "metal", useVanillaRecipe = false },
    ["walls_garage_02_3"] = { index = 5, displayName = "3 Tiles Rolling Garage Door", kind = "garage", materialClass = "metal", useVanillaRecipe = false },
    ["walls_garage_02_35"] = { index = 6, displayName = "3 Tiles Red Window Garage Door", kind = "garage", materialClass = "metal-glass", useVanillaRecipe = false },
    ["walls_garage_02_51"] = { index = 7, displayName = "3 Tiles Rolling Window Garage Door", kind = "garage", materialClass = "metal-glass", useVanillaRecipe = false },
    ["fixtures_doors_fences_01_114"] = { index = 8, displayName = "Door 008", kind = "double", materialClass = "metal", useVanillaRecipe = false },
    ["fixtures_doors_fences_01_34"] = { index = 9, displayName = "Double Wrought Iron Gate", kind = "double", materialClass = "metal", useVanillaRecipe = false },
    ["fixtures_doors_fences_01_50"] = { index = 10, displayName = "Door 010", kind = "double", materialClass = "wood", useVanillaRecipe = false },
    ["fixtures_doors_fences_01_66"] = { index = 11, displayName = "DoubleWireGate", kind = "double", materialClass = "metal", useVanillaRecipe = true, sourceEntity = "DoubleWireGate" },
    ["fixtures_doors_fences_01_82"] = { index = 12, displayName = "DoubleFenceGate", kind = "double", materialClass = "metal", useVanillaRecipe = true, sourceEntity = "DoubleFenceGate" },
    ["fixtures_doors_fences_01_98"] = { index = 13, displayName = "DoubleDoor", kind = "double", materialClass = "wood", useVanillaRecipe = true, sourceEntity = "DoubleDoor" },
    ["carpentry_01_49"] = { index = 14, displayName = "WoodenDoorLvl1", kind = "entity", materialClass = "wood", useVanillaRecipe = true, sourceEntity = "WoodenDoorLvl1" },
    ["carpentry_01_53"] = { index = 15, displayName = "WoodenDoorLvl2", kind = "entity", materialClass = "wood", useVanillaRecipe = true, sourceEntity = "WoodenDoorLvl2" },
    ["carpentry_01_57"] = { index = 16, displayName = "WoodenDoorLvl3", kind = "entity", materialClass = "wood", useVanillaRecipe = true, sourceEntity = "WoodenDoorLvl3" },
    ["fixtures_doors_01_1"] = { index = 17, displayName = "White Door", kind = "entity", materialClass = "wood", useVanillaRecipe = true, sourceEntity = "WhiteWoodenDoor" },
    ["fixtures_doors_01_53"] = { index = 18, displayName = "MetalDoorLvl2", kind = "entity", materialClass = "metal", useVanillaRecipe = true, sourceEntity = "MetalDoorLvl2" },
    ["fixtures_doors_01_69"] = { index = 19, displayName = "MetalDoorLvl1", kind = "entity", materialClass = "metal", useVanillaRecipe = true, sourceEntity = "MetalDoorLvl1" },
    ["fixtures_doors_fences_01_129"] = { index = 20, displayName = "Big Wire Fence Gate", kind = "fence-high", materialClass = "metal", useVanillaRecipe = true, sourceEntity = "MetalWireFenceGate" },
    ["fixtures_doors_fences_01_17"] = { index = 21, displayName = "Metal Wire Fence Gate", kind = "fence-low", materialClass = "metal", useVanillaRecipe = true, sourceEntity = "MetalWireFenceGateSmall" },
    ["fixtures_doors_fences_01_25"] = { index = 22, displayName = "Big Pole Fence Gate", kind = "fence-high", materialClass = "metal", useVanillaRecipe = true, sourceEntity = "MetalPoleFenceGate" },
    ["fixtures_doors_fences_01_29"] = { index = 23, displayName = "Metal Pole Fence Gate", kind = "fence-low", materialClass = "metal", useVanillaRecipe = true, sourceEntity = "MetalPoleFenceGateSmall" },
    ["fixtures_doors_fences_01_5"] = { index = 24, displayName = "Wooden Fence Gate", kind = "fence-low", materialClass = "wood", useVanillaRecipe = true, sourceEntity = "WoodFenceGate" },
    ["fixtures_bathroom_01_49"] = { index = 25, displayName = "Small Bathroom Door A", kind = "small", materialClass = "wood", useVanillaRecipe = false },
    ["fixtures_bathroom_01_65"] = { index = 26, displayName = "Small Bathroom Door B", kind = "small", materialClass = "wood", useVanillaRecipe = false },
    ["fixtures_bathroom_02_17"] = { index = 27, displayName = "Door 027", kind = "single", materialClass = "wood", useVanillaRecipe = false },
    ["fixtures_bathroom_02_33"] = { index = 28, displayName = "Door 028", kind = "single", materialClass = "wood", useVanillaRecipe = false },
    ["fixtures_doors_01_109"] = { index = 29, displayName = "Brown Sliding Glass Door", kind = "sliding", materialClass = "metal-glass", useVanillaRecipe = false },
    ["fixtures_doors_01_117"] = { index = 30, displayName = "White Sliding Glass Door", kind = "sliding", materialClass = "metal-glass", useVanillaRecipe = false },
    ["fixtures_doors_01_13"] = { index = 31, displayName = "Cherry Door", kind = "single", materialClass = "wood", useVanillaRecipe = false },
    ["fixtures_doors_01_17"] = { index = 32, displayName = "Tan Door", kind = "single", materialClass = "wood-glass", useVanillaRecipe = false },
    ["fixtures_doors_01_21"] = { index = 33, displayName = "Black Door", kind = "single", materialClass = "wood-glass", useVanillaRecipe = false },
    ["fixtures_doors_01_25"] = { index = 34, displayName = "Blue Metal", kind = "single", materialClass = "metal", useVanillaRecipe = false },
    ["fixtures_doors_01_29"] = { index = 35, displayName = "Rough Wooden Door", kind = "single", materialClass = "wood", useVanillaRecipe = false },
    ["fixtures_doors_01_33"] = { index = 36, displayName = "Security Door", kind = "single", materialClass = "metal-glass", useVanillaRecipe = false },
    ["fixtures_doors_01_37"] = { index = 37, displayName = "Single Pane Chestnut Door", kind = "single", materialClass = "wood-glass", useVanillaRecipe = false },
    ["fixtures_doors_01_41"] = { index = 38, displayName = "Single Pane Black Door", kind = "single", materialClass = "metal-glass", useVanillaRecipe = false },
    ["fixtures_doors_01_45"] = { index = 39, displayName = "White Door with Windows", kind = "single", materialClass = "wood-glass", useVanillaRecipe = false },
    ["fixtures_doors_01_49"] = { index = 40, displayName = "Black 2 Pane Door", kind = "single", materialClass = "metal-glass", useVanillaRecipe = false },
    ["fixtures_doors_01_5"] = { index = 41, displayName = "Brown Door", kind = "single", materialClass = "wood", useVanillaRecipe = false },
    ["fixtures_doors_01_57"] = { index = 42, displayName = "White Metal Door", kind = "single", materialClass = "wood", useVanillaRecipe = false },
    ["fixtures_doors_01_61"] = { index = 43, displayName = "White Metal Door with Window", kind = "single", materialClass = "wood", useVanillaRecipe = false },
    ["fixtures_doors_01_65"] = { index = 44, displayName = "Tan Metal Door", kind = "single", materialClass = "wood", useVanillaRecipe = false },
    ["fixtures_doors_01_9"] = { index = 45, displayName = "Wooden Door", kind = "single", materialClass = "wood", useVanillaRecipe = false },
    ["fixtures_doors_02_1"] = { index = 46, displayName = "Blue Door", kind = "single", materialClass = "wood-glass", useVanillaRecipe = false },
    ["fixtures_doors_02_13"] = { index = 47, displayName = "Black Metal Door", kind = "single", materialClass = "metal", useVanillaRecipe = false },
    ["fixtures_doors_02_17"] = { index = 48, displayName = "Brown Panel Door", kind = "small", materialClass = "wood", useVanillaRecipe = false },
    ["fixtures_doors_02_21"] = { index = 49, displayName = "White Panel Door", kind = "small", materialClass = "wood", useVanillaRecipe = false },
    ["fixtures_doors_02_25"] = { index = 50, displayName = "Black Panel Door", kind = "small", materialClass = "wood", useVanillaRecipe = false },
    ["fixtures_doors_02_41"] = { index = 51, displayName = "Double Black Glass Door - Left", kind = "paired", materialClass = "metal-glass", useVanillaRecipe = false, pairedWith = "fixtures_doors_02_45" },
    ["fixtures_doors_02_45"] = { index = 52, displayName = "Double Black Glass Door - Right", kind = "paired", materialClass = "metal-glass", useVanillaRecipe = false, pairedWith = "fixtures_doors_02_41" },
    ["fixtures_doors_02_49"] = { index = 53, displayName = "Double Grey Metal Door - Left", kind = "paired", materialClass = "metal", useVanillaRecipe = false, pairedWith = "fixtures_doors_02_53" },
    ["fixtures_doors_02_5"] = { index = 54, displayName = "Brown Door with Windows", kind = "single", materialClass = "wood-glass", useVanillaRecipe = false },
    ["fixtures_doors_02_53"] = { index = 55, displayName = "Double Grey Metal Door - Right", kind = "paired", materialClass = "metal", useVanillaRecipe = false, pairedWith = "fixtures_doors_02_49" },
    ["fixtures_doors_02_57"] = { index = 56, displayName = "Double Orange Kitchen Metal Door - Left", kind = "paired", materialClass = "wood", useVanillaRecipe = false, pairedWith = "fixtures_doors_02_61" },
    ["fixtures_doors_02_61"] = { index = 57, displayName = "Double Orange Kitchen Metal Door - Right", kind = "paired", materialClass = "wood", useVanillaRecipe = false, pairedWith = "fixtures_doors_02_57" },
    ["fixtures_doors_02_9"] = { index = 58, displayName = "Red Metal Door", kind = "single", materialClass = "metal", useVanillaRecipe = false },
    ["fixtures_doors_fences_01_1"] = { index = 59, displayName = "Metal Fence Gate", kind = "fence-low", materialClass = "metal", useVanillaRecipe = false },
    ["fixtures_doors_fences_01_13"] = { index = 60, displayName = "Wooden Fence Gate", kind = "fence-high", materialClass = "wood", useVanillaRecipe = false },
    ["fixtures_doors_fences_01_21"] = { index = 61, displayName = "Wrought Iron Gate", kind = "fence-high", materialClass = "metal", useVanillaRecipe = false },
    ["fixtures_doors_fences_01_9"] = { index = 62, displayName = "White Wooden Fence Gate", kind = "fence-low", materialClass = "wood", useVanillaRecipe = false },
    ["location_community_church_small_01_25"] = { index = 63, displayName = "Church Paired Door A - Left", kind = "paired", materialClass = "wood", useVanillaRecipe = false, pairedWith = "location_community_church_small_01_29" },
    ["location_community_church_small_01_29"] = { index = 64, displayName = "Church Paired Door A - Right", kind = "paired", materialClass = "wood", useVanillaRecipe = false, pairedWith = "location_community_church_small_01_25" },
    ["location_community_church_small_01_65"] = { index = 65, displayName = "Church Paired Door B - Left", kind = "paired", materialClass = "wood", useVanillaRecipe = false, pairedWith = "location_community_church_small_01_69" },
    ["location_community_church_small_01_69"] = { index = 66, displayName = "Church Paired Door B - Right", kind = "paired", materialClass = "wood", useVanillaRecipe = false, pairedWith = "location_community_church_small_01_65" },
    ["location_community_police_01_5"] = { index = 67, displayName = "Jail Door", kind = "single", materialClass = "metal", useVanillaRecipe = false },
    ["location_restaurant_pileocrepe_01_49"] = { index = 68, displayName = "Pile O' Crepe Blue Door with Window", kind = "single", materialClass = "wood-glass", useVanillaRecipe = false },
    ["location_restaurant_pileocrepe_01_53"] = { index = 69, displayName = "Pile O' Crepe Orange Door", kind = "single", materialClass = "wood", useVanillaRecipe = false },
    ["location_restaurant_pizzawhirled_01_57"] = { index = 70, displayName = "Pizza Whirled Brown Glass Door", kind = "single", materialClass = "wood-glass", useVanillaRecipe = false },
    ["location_restaurant_pizzawhirled_01_61"] = { index = 71, displayName = "Pizza Whirled Green Metal Door", kind = "single", materialClass = "wood", useVanillaRecipe = false },
    ["location_restaurant_seahorse_01_49"] = { index = 72, displayName = "Sea Horse Glass Door", kind = "single", materialClass = "wood-glass", useVanillaRecipe = false },
    ["location_restaurant_spiffos_01_49"] = { index = 73, displayName = "Spiffos Glass Door", kind = "single", materialClass = "wood-glass", useVanillaRecipe = false },
    ["location_restaurant_spiffos_01_53"] = { index = 74, displayName = "Spiffos Red Metal Door", kind = "single", materialClass = "wood", useVanillaRecipe = false },
    ["location_shop_fossoil_01_61"] = { index = 75, displayName = "Blue Fossoil Glass Door", kind = "single", materialClass = "wood-glass", useVanillaRecipe = false },
    ["location_shop_gas2go_01_61"] = { index = 76, displayName = "Red Gas 2 Go Glass Door", kind = "single", materialClass = "wood-glass", useVanillaRecipe = false },
    ["walls_logs_41"] = { index = 77, displayName = "Door 077", kind = "single", materialClass = "wood", useVanillaRecipe = false },
}

local function add(items, item, amount)
    items[#items + 1] = { item = item, amount = amount }
end

local function makeRecipe(entry)
    if entry.useVanillaRecipe then return nil end

    local kind = entry.kind
    local materialClass = entry.materialClass
    local small = kind == "small" or kind == "fence-low"
    local metal = materialClass == "metal" or materialClass == "metal-glass"
    local glass = materialClass == "metal-glass" or materialClass == "wood-glass"
    local recipe = {
        skill = metal and "MetalWelding" or "Woodwork",
        level = small and 3 or 4,
        xp = small and 20 or 40,
        tools = metal and { "base:screwdriver" } or { "base:hammer", "base:screwdriver" },
        items = {},
    }

    if kind == "sliding" then
        recipe.skill = "MetalWelding"
        recipe.level = 4
        recipe.tools = { "base:screwdriver" }
        add(recipe.items, "Base.SmallSheetMetal", 2)
        add(recipe.items, "Base.MetalBar", 2)
        add(recipe.items, "Base.GlassPanel", 2)
        add(recipe.items, "Base.Screws", 6)
        recipe.drain = {
            { item = "Base.BlowTorch", amount = 4 },
            { item = "Base.WeldingRods", amount = 4 },
        }
        return recipe
    end

    if metal then
        add(recipe.items, "Base.SmallSheetMetal", small and 1 or 2)
        add(recipe.items, "Base.MetalBar", small and 1 or 2)
        add(recipe.items, "Base.Hinge", 2)
        add(recipe.items, "Base.Screws", 4)
        if string.sub(kind, 1, 5) ~= "fence" then add(recipe.items, "Base.Doorknob", 1) end
        if glass then add(recipe.items, "Base.GlassPanel", 1) end
        recipe.drain = {
            { item = "Base.BlowTorch", amount = 4 },
            { item = "Base.WeldingRods", amount = 4 },
        }
    else
        add(recipe.items, "Base.Plank", small and 2 or 4)
        add(recipe.items, "Base.Nails", small and 2 or 4)
        add(recipe.items, "Base.Hinge", 2)
        add(recipe.items, "Base.Screws", 4)
        if string.sub(kind, 1, 5) ~= "fence" then add(recipe.items, "Base.Doorknob", 1) end
        if glass then add(recipe.items, "Base.GlassPanel", 1) end
    end

    return recipe
end

for _, entry in pairs(entries) do
    entry.recipe = makeRecipe(entry)
end

Drafts.byAnchor = entries

function Drafts.get(anchor)
    return Drafts.byAnchor[anchor]
end

return Drafts
