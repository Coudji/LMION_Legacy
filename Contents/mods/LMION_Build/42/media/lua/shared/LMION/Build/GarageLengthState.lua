require "LMION/Build/GarageConstruction"

local GarageBuild = LMION.Build.GarageBuild
local STATE_KEY = "_lmionGarageBuildLength"

local function getRecipeModData(logic)
    local recipeData = logic and logic.getRecipeData and logic:getRecipeData() or nil
    return recipeData and recipeData.getModData and recipeData:getModData() or nil
end

local function writeModData(logic, length)
    local modData = getRecipeModData(logic)
    if modData ~= nil then
        modData[GarageBuild.LengthModDataKey] = length
    end
end

-- CraftRecipeData is routinely replaced by BuildLogic.refresh()/manual input
-- changes. Keep the selected width on the BuildLogic instance as the durable UI
-- state, while mirroring it into CraftRecipeData modData for the existing cursor
-- and serialization paths.
GarageBuild.getLengthFromLogic = function(logic)
    if logic == nil then
        return GarageBuild.DefaultLength
    end

    local stored = tonumber(logic[STATE_KEY])
    if stored ~= nil then
        stored = GarageBuild.normalizeLength(stored)
        logic[STATE_KEY] = stored
        writeModData(logic, stored)
        return stored
    end

    local modData = getRecipeModData(logic)
    local fromData = modData and tonumber(modData[GarageBuild.LengthModDataKey]) or nil
    local length = GarageBuild.normalizeLength(fromData or GarageBuild.DefaultLength)
    logic[STATE_KEY] = length
    writeModData(logic, length)
    return length
end

GarageBuild.setLengthOnLogic = function(logic, length)
    if GarageBuild.getGarageIdFromLogic(logic) == nil then
        return nil
    end

    length = GarageBuild.normalizeLength(length)
    logic[STATE_KEY] = length
    writeModData(logic, length)
    return length
end

GarageBuild.ensureLengthOnLogic = function(logic)
    if GarageBuild.getGarageIdFromLogic(logic) == nil then
        return nil
    end
    return GarageBuild.getLengthFromLogic(logic)
end

return GarageBuild
