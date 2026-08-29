require "LMION/Build/GarageConstruction"

local GarageBuild = LMION.Build.GarageBuild
GarageBuild._lengthByLogic = GarageBuild._lengthByLogic or {}
local lengthByLogic = GarageBuild._lengthByLogic

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

-- BuildLogic is a Java object, so arbitrary Lua fields cannot be stored on it.
-- CraftRecipeData is also routinely replaced by BuildLogic.refresh()/manual
-- input changes. Keep the selected width in a Lua side table keyed by the
-- BuildLogic object, while mirroring it into CraftRecipeData modData for the
-- existing cursor and serialization paths.
GarageBuild.getLengthFromLogic = function(logic)
    if logic == nil then
        return GarageBuild.DefaultLength
    end

    local stored = tonumber(lengthByLogic[logic])
    if stored ~= nil then
        stored = GarageBuild.normalizeLength(stored)
        lengthByLogic[logic] = stored
        writeModData(logic, stored)
        return stored
    end

    local modData = getRecipeModData(logic)
    local fromData = modData and tonumber(modData[GarageBuild.LengthModDataKey]) or nil
    local length = GarageBuild.normalizeLength(fromData or GarageBuild.DefaultLength)
    lengthByLogic[logic] = length
    writeModData(logic, length)
    return length
end

GarageBuild.setLengthOnLogic = function(logic, length)
    if GarageBuild.getGarageIdFromLogic(logic) == nil then
        return nil
    end

    length = GarageBuild.normalizeLength(length)
    lengthByLogic[logic] = length
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
