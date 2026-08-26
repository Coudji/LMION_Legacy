LMION.Pickup = LMION.Pickup or {}

local Pickup = LMION.Pickup
local GarageDoor = Pickup.GarageDoor or {}
Pickup.GarageDoor = GarageDoor

--[[
Garage-door transport is intentionally data-driven from the start, but the first
runtime implementation only enables IndustrialGarageDoor. Other families should
be added here only after the reference family has passed the full pickup/rotate/
replacement validation.

`parts` is engine identity: GarageDoor 1/2/3.
`gridPartOrder` is visual SpriteGrid order from local coordinate 0 toward +X/+Y.
Those orders are identical in N and reversed in W because vanilla garage linkage
advances from member 1 toward decreasing Y when west-facing.
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
        gridPartOrder = {
            N = {1, 2, 3},
            W = {3, 2, 1},
        },
    },
}

local segmentsBySprite = {}

for familyId, family in pairs(families) do
    local rotationFacesBySprite = {}
    family.rotationSlots = {}

    for slot = 1, 3 do
        local nPartIndex = family.gridPartOrder.N[slot]
        local wPartIndex = family.gridPartOrder.W[slot]
        local rotationFaces = {
            N = family.parts[nPartIndex].faces.N,
            W = family.parts[wPartIndex].faces.W,
        }

        family.rotationSlots[slot] = rotationFaces
        rotationFacesBySprite[rotationFaces.N] = rotationFaces
        rotationFacesBySprite[rotationFaces.W] = rotationFaces
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
