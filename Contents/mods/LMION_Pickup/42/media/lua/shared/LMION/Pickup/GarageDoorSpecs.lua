LMION.Pickup = LMION.Pickup or {}

local Pickup = LMION.Pickup
local GarageDoor = Pickup.GarageDoor or {}
Pickup.GarageDoor = GarageDoor

--[[
Garage-door transport is data-driven. `parts` is engine identity: normalized
GarageDoor 1/2/3. Runtime tracing on B42.20.4 confirms Industrial W sprites map
as 32=1, 33=2, 34=3; the remaining LMION garage SpriteConfigs use the same
vanilla closed-tile ordering and are validated against their live `GarageDoor`
properties before Moveables is enabled.

`gridPartOrder` is visual SpriteGrid order from local coordinate 0 toward +X/+Y.
It is identical to engine order in N and reversed in W because vanilla garage
linkage advances from member 1 toward decreasing Y when west-facing.
]]
local function makeFamily(id, nSprites, wSprites)
    local parts = {}
    for partIndex = 1, 3 do
        parts[partIndex] = {
            itemType = "Base.LMION_" .. id .. "_Part" .. tostring(partIndex),
            faces = {
                N = nSprites[partIndex],
                W = wSprites[partIndex],
            },
        }
    end

    return {
        id = id,
        pickUpTool = "LMIONMetalCrowbar",
        placeTool = "LMIONMetalHammer",
        pickUpLevel = 3,
        partWeight = 20,
        parts = parts,
        gridPartOrder = {
            N = {1, 2, 3},
            W = {3, 2, 1},
        },
    }
end

local families = {
    IndustrialGarageDoor = makeFamily(
        "IndustrialGarageDoor",
        {"industry_trucks_01_35", "industry_trucks_01_36", "industry_trucks_01_37"},
        {"industry_trucks_01_32", "industry_trucks_01_33", "industry_trucks_01_34"}
    ),
    GreenGarageDoor = makeFamily(
        "GreenGarageDoor",
        {"walls_garage_01_19", "walls_garage_01_20", "walls_garage_01_21"},
        {"walls_garage_01_16", "walls_garage_01_17", "walls_garage_01_18"}
    ),
    WhiteGarageDoor = makeFamily(
        "WhiteGarageDoor",
        {"walls_garage_01_3", "walls_garage_01_4", "walls_garage_01_5"},
        {"walls_garage_01_0", "walls_garage_01_1", "walls_garage_01_2"}
    ),
    GreyGarageDoor = makeFamily(
        "GreyGarageDoor",
        {"walls_garage_01_51", "walls_garage_01_52", "walls_garage_01_53"},
        {"walls_garage_01_48", "walls_garage_01_49", "walls_garage_01_50"}
    ),
    RollingGarageDoor = makeFamily(
        "RollingGarageDoor",
        {"walls_garage_02_3", "walls_garage_02_4", "walls_garage_02_5"},
        {"walls_garage_02_0", "walls_garage_02_1", "walls_garage_02_2"}
    ),
    RedWindowGarageDoor = makeFamily(
        "RedWindowGarageDoor",
        {"walls_garage_02_35", "walls_garage_02_36", "walls_garage_02_37"},
        {"walls_garage_02_32", "walls_garage_02_33", "walls_garage_02_34"}
    ),
    RollingWindowGarageDoor = makeFamily(
        "RollingWindowGarageDoor",
        {"walls_garage_02_51", "walls_garage_02_52", "walls_garage_02_53"},
        {"walls_garage_02_48", "walls_garage_02_49", "walls_garage_02_50"}
    ),
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

local function validateFamily(family)
    if family == nil or getSprite == nil then
        return false, "sprite definitions are unavailable"
    end

    for partIndex = 1, 3 do
        local part = family.parts[partIndex]
        if part == nil or part.faces == nil then
            return false, "missing part " .. tostring(partIndex)
        end

        for _, facing in ipairs({"N", "W"}) do
            local spriteName = part.faces[facing]
            local sprite = spriteName and getSprite(spriteName) or nil
            local properties = sprite and sprite:getProperties() or nil
            local rawIndex = nil

            if properties ~= nil and properties:has("GarageDoor") then
                rawIndex = tonumber(properties:get("GarageDoor"))
            end

            if rawIndex ~= partIndex then
                return false,
                    tostring(spriteName)
                    .. " GarageDoor=" .. tostring(rawIndex)
                    .. ", expected " .. tostring(partIndex)
            end
        end
    end

    return true
end

GarageDoor.Families = families
GarageDoor.SegmentsBySprite = segmentsBySprite
GarageDoor.validateFamily = validateFamily

return GarageDoor
