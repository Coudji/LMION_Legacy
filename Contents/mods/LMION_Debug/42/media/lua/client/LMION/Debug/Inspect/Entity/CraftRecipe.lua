require "LMION/Debug/Inspect/Entity/Common"

local Entity = LMION.Debug.Inspect.Entity
local Common = Entity.Common
local Safe = LMION.Debug.Util.Safe
local Reflection = LMION.Debug.Util.Reflection

local CraftRecipe = Entity.CraftRecipe or {}
Entity.CraftRecipe = CraftRecipe

local function itemLabel(item)
    if item == nil then return "<nil>" end
    if Reflection.hasMethod(item, "getFullName", 0) then return tostring(item:getFullName()) end
    if Reflection.hasMethod(item, "getFullType", 0) then return tostring(item:getFullType()) end
    if Reflection.hasMethod(item, "getName", 0) then return tostring(item:getName()) end
    return tostring(item)
end

local function dumpInput(input, index, report, prefix)
    if input == nil then return end
    local p = prefix .. "[" .. tostring(index) .. "]."
    report:field(p .. "class", Safe.className(input))

    local zeroArg = {
        { "resourceType", "getResourceType" },
        { "originalLine", "getOriginalLine" },
        { "amount", "getAmount" },
        { "intAmount", "getIntAmount" },
        { "maxAmount", "getMaxAmount" },
        { "intMaxAmount", "getIntMaxAmount" },
        { "itemApplyMode", "getItemApplyMode" },
        { "shapedIndex", "getShapedIndex" },
        { "acceptsAnyItem", "isAcceptsAnyItem" },
        { "acceptsAnyFluid", "isAcceptsAnyFluid" },
        { "acceptsAnyEnergy", "isAcceptsAnyEnergy" },
        { "allowDestroyedItem", "allowDestroyedItem" },
        { "allowFavorites", "allowFavorites" },
        { "allowFrozenItem", "allowFrozenItem" },
        { "allowRottenItem", "allowRottenItem" },
        { "dontPutBack", "dontPutBack" },
        { "inheritCondition", "inheritCondition" },
        { "inheritColor", "inheritColor" },
        { "inheritSharpness", "inheritSharpness" },
        { "inheritUses", "inheritUses" },
    }
    for _, field in ipairs(zeroArg) do
        if Reflection.hasMethod(input, field[2], 0) then
            report:field(p .. field[1], input[field[2]](input))
        end
    end

    if Reflection.hasMethod(input, "getTags", 0) then
        Common.dumpCollection(report, p .. "tags", input:getTags())
    end

    if Reflection.hasMethod(input, "getPossibleInputItems", 0) then
        Common.dumpCollection(report, p .. "possibleItems", input:getPossibleInputItems(), function(item)
            return itemLabel(item)
        end)
    end
end

local function dumpOutput(output, index, report)
    if output == nil then return end
    local p = "output[" .. tostring(index) .. "]."
    report:field(p .. "class", Safe.className(output))

    local zeroArg = {
        { "resourceType", "getResourceType" },
        { "originalLine", "getOriginalLine" },
        { "amount", "getAmount" },
        { "intAmount", "getIntAmount" },
        { "maxAmount", "getMaxAmount" },
        { "intMaxAmount", "getIntMaxAmount" },
        { "chance", "getChance" },
        { "itemApplyMode", "getItemApplyMode" },
        { "shapedIndex", "getShapedIndex" },
        { "applyOnTick", "isApplyOnTick" },
        { "automationOnly", "isAutomationOnly" },
        { "handcraftOnly", "isHandcraftOnly" },
        { "replaceInput", "isReplaceInput" },
        { "variableAmount", "isVariableAmount" },
    }
    for _, field in ipairs(zeroArg) do
        if Reflection.hasMethod(output, field[2], 0) then
            report:field(p .. field[1], output[field[2]](output))
        end
    end

    if Reflection.hasMethod(output, "getPossibleResultItems", 0) then
        Common.dumpCollection(report, p .. "possibleItems", output:getPossibleResultItems(), function(item)
            return itemLabel(item)
        end)
    end
end

local function dumpSkill(skill, index, report, prefix)
    if skill == nil then return end
    local p = prefix .. "[" .. tostring(index) .. "]."
    if Reflection.hasMethod(skill, "getPerk", 0) then report:field(p .. "perk", skill:getPerk()) end
    if Reflection.hasMethod(skill, "getLevel", 0) then report:field(p .. "level", skill:getLevel()) end
end

local function dumpTool(recipe, methodName, label, report)
    if Reflection.hasMethod(recipe, methodName, 0) then
        local tool = recipe[methodName](recipe)
        if tool ~= nil then dumpInput(tool, label, report, "tool") end
    end
end

function CraftRecipe.dump(script, report)
    if ComponentType == nil or ComponentType.CraftRecipe == nil then return end
    local component = Common.getComponent(script, ComponentType.CraftRecipe)
    if component == nil then return end

    report:section("Entity CraftRecipe component")
    report:field("class", Safe.className(component))
    if Reflection.hasMethod(component, "getBuildCategory", 0) then
        report:field("buildCategory", component:getBuildCategory())
    end
    if Reflection.hasMethod(component, "isoMasterOnly", 0) then
        report:field("isoMasterOnly", component:isoMasterOnly())
    end
    Common.dumpScriptSource(component, report, "source")

    if not Reflection.hasMethod(component, "getCraftRecipe", 0) then return end
    local recipe = component:getCraftRecipe()
    if recipe == nil then return end

    report:section("Entity CraftRecipe")
    report:field("class", Safe.className(recipe))

    local zeroArg = {
        { "name", "getName" },
        { "translationName", "getTranslationName" },
        { "category", "getCategory" },
        { "time", "getTime" },
        { "animation", "getAnimation" },
        { "tooltip", "getTooltip" },
        { "iconName", "getIconName" },
        { "modID", "getModID" },
        { "modName", "getModName" },
        { "vanilla", "isVanilla" },
        { "existsAsVanilla", "getExistsAsVanilla" },
        { "buildable", "isBuildableRecipe" },
        { "usesTools", "isUsesTools" },
        { "needToBeLearn", "needToBeLearn" },
        { "allowBatchCraft", "isAllowBatchCraft" },
        { "canWalk", "isCanWalk" },
        { "canBeDoneFromFloor", "isCanBeDoneFromFloor" },
        { "requiresPlayer", "isRequiresPlayer" },
        { "shapeless", "isShapeless" },
        { "smithing", "isSmithing" },
        { "researchAll", "isResearchAll" },
        { "researchSkillLevel", "getResearchSkillLevel" },
        { "inputCount", "getInputCount" },
        { "outputCount", "getOutputCount" },
        { "requiredSkillCount", "getRequiredSkillCount" },
        { "autoLearnAllSkillCount", "getAutoLearnAllSkillCount" },
        { "autoLearnAnySkillCount", "getAutoLearnAnySkillCount" },
        { "xpAwardCount", "getXPAwardCount" },
    }
    for _, field in ipairs(zeroArg) do
        if Reflection.hasMethod(recipe, field[2], 0) then
            report:field(field[1], recipe[field[2]](recipe))
        end
    end

    if Reflection.hasMethod(recipe, "getTags", 0) then
        Common.dumpCollection(report, "tags", recipe:getTags())
    end

    if Reflection.hasMethod(recipe, "getInputs", 0) then
        local inputs = recipe:getInputs()
        report:field("inputs.count", Safe.collectionSize(inputs))
        for i = 0, Safe.collectionSize(inputs) - 1 do dumpInput(Safe.collectionGet(inputs, i), i, report, "input") end
    end

    if Reflection.hasMethod(recipe, "getOutputs", 0) then
        local outputs = recipe:getOutputs()
        report:field("outputs.count", Safe.collectionSize(outputs))
        for i = 0, Safe.collectionSize(outputs) - 1 do dumpOutput(Safe.collectionGet(outputs, i), i, report) end
    end

    if Reflection.hasMethod(recipe, "getRequiredSkillCount", 0)
        and Reflection.hasMethod(recipe, "getRequiredSkill", 1) then
        for i = 0, recipe:getRequiredSkillCount() - 1 do dumpSkill(recipe:getRequiredSkill(i), i, report, "requiredSkill") end
    end

    if Reflection.hasMethod(recipe, "getAutoLearnAllSkillCount", 0)
        and Reflection.hasMethod(recipe, "getAutoLearnAllSkill", 1) then
        for i = 0, recipe:getAutoLearnAllSkillCount() - 1 do dumpSkill(recipe:getAutoLearnAllSkill(i), i, report, "autoLearnAll") end
    end

    if Reflection.hasMethod(recipe, "getAutoLearnAnySkillCount", 0)
        and Reflection.hasMethod(recipe, "getAutoLearnAnySkill", 1) then
        for i = 0, recipe:getAutoLearnAnySkillCount() - 1 do dumpSkill(recipe:getAutoLearnAnySkill(i), i, report, "autoLearnAny") end
    end

    if Reflection.hasMethod(recipe, "getXPAwardCount", 0)
        and Reflection.hasMethod(recipe, "getXPAward", 1) then
        for i = 0, recipe:getXPAwardCount() - 1 do
            local xp = recipe:getXPAward(i)
            if xp ~= nil then
                if Reflection.hasMethod(xp, "getPerk", 0) then report:field("xpAward[" .. i .. "].perk", xp:getPerk()) end
                if Reflection.hasMethod(xp, "getAmount", 0) then report:field("xpAward[" .. i .. "].amount", xp:getAmount()) end
            end
        end
    end

    dumpTool(recipe, "getToolLeft", "left", report)
    dumpTool(recipe, "getToolRight", "right", report)
    dumpTool(recipe, "getToolBoth", "both", report)

    if Reflection.hasMethod(recipe, "generateDebugText", 0) then
        report:field("debugText", recipe:generateDebugText())
    end
    Common.dumpScriptSource(recipe, report, "source")
end

return CraftRecipe
