require "LMION/Build/GarageConstruction"

local GarageBuild = LMION.Build.GarageBuild
GarageBuild._lengthByLogic = GarageBuild._lengthByLogic or {}
local lengthByLogic = GarageBuild._lengthByLogic

local function getRecipeData(logic)
    return logic and logic.getRecipeData and logic:getRecipeData() or nil
end

local function getRecipeModData(logic)
    local recipeData = getRecipeData(logic)
    return recipeData and recipeData.getModData and recipeData:getModData() or nil
end

local function isBarInput(inputScript)
    if inputScript == nil or inputScript.isVariableAmount == nil or not inputScript:isVariableAmount() then
        return false
    end

    local possible = inputScript.getPossibleInputItems and inputScript:getPossibleInputItems() or nil
    if possible == nil then
        return false
    end

    local hasMetalBar = false
    local hasIronBar = false
    for i = 0, possible:size() - 1 do
        local item = possible:get(i)
        local fullType = item and item.getFullName and item:getFullName() or nil
        if fullType == "Base.MetalBar" then
            hasMetalBar = true
        elseif fullType == "Base.IronBar" then
            hasIronBar = true
        end
    end

    return hasMetalBar and hasIronBar
end

local function trimAutoSelectedBars(logic, length)
    local recipeData = getRecipeData(logic)
    local recipe = recipeData and recipeData.getRecipe and recipeData:getRecipe() or nil
    local inputs = recipe and recipe.getInputs and recipe:getInputs() or nil
    if recipeData == nil or inputs == nil then
        return
    end

    for i = 0, inputs:size() - 1 do
        local inputScript = inputs:get(i)
        if isBarInput(inputScript) then
            local inputData = recipeData:getDataForInputScript(inputScript)
            while inputData ~= nil
                and inputData:getInputItemCount() > length
                and inputData:getLastInputItem() ~= nil do
                recipeData:removeInputItem(inputData:getLastInputItem())
            end
            return
        end
    end
end

local function syncVariableRatio(logic, length)
    if logic ~= nil and logic.setTargetVariableInputRatio ~= nil then
        -- Only the garage bar input is declared variable. Its base amount is 2,
        -- so length / 2 makes vanilla expose exactly L selectable bars while all
        -- other LMION garage costs remain under the explicit variable-width model.
        logic:setTargetVariableInputRatio(length / GarageBuild.MinLength)

        -- BuildLogic:setRecipe() auto-populates inputs before LMION can restore
        -- the selected garage length. A variable input therefore initially uses
        -- vanilla's unlimited/default ratio and may grab every available bar.
        -- Once the LMION ratio is known, discard only that excess selection.
        trimAutoSelectedBars(logic, length)
    end
end

local function writeState(logic, length)
    local modData = getRecipeModData(logic)
    if modData ~= nil then
        modData[GarageBuild.LengthModDataKey] = length
    end
    syncVariableRatio(logic, length)
end

-- BuildLogic is a Java object, so arbitrary Lua fields cannot be stored on it.
-- CraftRecipeData is also routinely replaced by BuildLogic.refresh()/manual
-- input changes. Keep the selected width in a Lua side table keyed by the
-- BuildLogic object, while mirroring it into CraftRecipeData modData and its
-- native variable-input ratio for the existing UI/cursor/serialization paths.
GarageBuild.getLengthFromLogic = function(logic)
    if logic == nil then
        return GarageBuild.DefaultLength
    end

    local stored = tonumber(lengthByLogic[logic])
    if stored ~= nil then
        stored = GarageBuild.normalizeLength(stored)
        lengthByLogic[logic] = stored
        writeState(logic, stored)
        return stored
    end

    local modData = getRecipeModData(logic)
    local fromData = modData and tonumber(modData[GarageBuild.LengthModDataKey]) or nil
    local length = GarageBuild.normalizeLength(fromData or GarageBuild.DefaultLength)
    lengthByLogic[logic] = length
    writeState(logic, length)
    return length
end

GarageBuild.setLengthOnLogic = function(logic, length)
    if GarageBuild.getGarageIdFromLogic(logic) == nil then
        return nil
    end

    length = GarageBuild.normalizeLength(length)
    lengthByLogic[logic] = length
    writeState(logic, length)
    return length
end

GarageBuild.ensureLengthOnLogic = function(logic)
    if GarageBuild.getGarageIdFromLogic(logic) == nil then
        return nil
    end
    return GarageBuild.getLengthFromLogic(logic)
end

return GarageBuild
