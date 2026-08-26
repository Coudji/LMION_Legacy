LMION.Pickup = LMION.Pickup or {}

local Pickup = LMION.Pickup
local GarageDoor = Pickup.GarageDoor or {}
Pickup.GarageDoor = GarageDoor

--[[
Garage-door transport is intentionally data-driven from the start, but the first
runtime implementation only enables IndustrialGarageDoor. Other families should
be added here only after the reference family has passed the full pickup/rotate/
replacement validation.
]]
local families = {
    IndustrialGarageDoor = {
        id = "IndustrialGarageDoor",
        pickUpTool = "LMIONMetalCrowbar",
        placeTool = "LMIONMetalHammer",
        pickUpLevel = 3,
        partWeight = 20,
        parts = {
            {
                itemType = "Base.LMION_IndustrialGarageDoor_Part1",
                faces = {
                    N = "industry_trucks_01_35",
                    W = "industry_trucks_01_34",
                },
            },
            {
                itemType = "Base.LMION_IndustrialGarageDoor_Part2",
                faces = {
                    N = "industry_trucks_01_36",
                    W = "industry_trucks_01_33",
                },
            },
            {
                itemType = "Base.LMION_IndustrialGarageDoor_Part3",
                faces = {
                    N = "industry_trucks_01_37",
                    W = "industry_trucks_01_32",
                },
            },
        },
        rotationSlots = {
            {
                N = "industry_trucks_01_35",
                W = "industry_trucks_01_32",
            },
            {
                N = "industry_trucks_01_36",
                W = "industry_trucks_01_33",
            },
            {
                N = "industry_trucks_01_37",
                W = "industry_trucks_01_34",
            },
        },
    },
}

local segmentsBySprite = {}

for familyId, family in pairs(families) do
    local rotationFacesBySprite = {}
    for _, rotationFaces in ipairs(family.rotationSlots or {}) do
        for _, spriteName in pairs(rotationFaces) do
            rotationFacesBySprite[spriteName] = rotationFaces
        end
    end

    for partIndex, part in ipairs(family.parts) do
        for facing, spriteName in pairs(part.faces) do
            segmentsBySprite[spriteName] = {
                familyId = familyId,
                family = family,
                partIndex = partIndex,
                itemType = part.itemType,
                faces = part.faces,
                rotationFaces = rotationFacesBySprite[spriteName] or part.faces,
                facing = facing,
                spriteName = spriteName,
            }
        end
    end
end

GarageDoor.Families = families
GarageDoor.SegmentsBySprite = segmentsBySprite

return GarageDoor
