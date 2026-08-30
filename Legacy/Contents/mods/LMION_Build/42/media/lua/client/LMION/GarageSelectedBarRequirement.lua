require "LMION/Build"
require "Entity/ISUI/BuildRecipe/ISWidgetBuildControl"
require "Entity/ISUI/BuildRecipe/ISBuildPanel"
require "Entity/ISUI/Controls/ISWidgetTitleHeader"

local Build = LMION.Build
local GarageBuild = Build.GarageBuild

local function getGarageContext(logic)
    local id = GarageBuild.getGarageIdFromLogic(logic)
    if id == nil then
        return nil, nil
    end
    return id, GarageBuild.getLengthFromLogic(logic)
end

local function hasSelectedBars(logic, length)
    return GarageBuild.hasSelectedBars(logic, length)
end

if Build._originalGarageSelectedBarsTitleUpdateLabels == nil then
    Build._originalGarageSelectedBarsTitleUpdateLabels = ISWidgetTitleHeader.updateLabels
end

ISWidgetTitleHeader.updateLabels = function(self)
    Build._originalGarageSelectedBarsTitleUpdateLabels(self)

    local id, length = getGarageContext(self.logic)
    if id == nil or self.errorLabel == nil or self.player:isBuildCheat() then
        return
    end

    if not hasSelectedBars(self.logic, length) then
        local text = getText("IGUI_CraftingWindow_Error_NotAvailable")
            .. getText("IGUI_CraftingWindow_Error_Inputs")
        self.errorLabel.errorText = text
        self.errorLabel:setName(text)
        self.errorLabel:setVisible(true)
    end
end

if Build._originalGarageSelectedBarsBuildControlPrerender == nil then
    Build._originalGarageSelectedBarsBuildControlPrerender = ISWidgetBuildControl.prerender
end

ISWidgetBuildControl.prerender = function(self)
    Build._originalGarageSelectedBarsBuildControlPrerender(self)

    local id, length = getGarageContext(self.logic)
    if id ~= nil and self.buttonCraft ~= nil and not self.player:isBuildCheat() then
        self.buttonCraft.enable = self.buttonCraft.enable
            and hasSelectedBars(self.logic, length)
    end
end

if Build._originalGarageSelectedBarsCreateBuildIsoEntity == nil then
    Build._originalGarageSelectedBarsCreateBuildIsoEntity = ISBuildPanel.createBuildIsoEntity
end

ISBuildPanel.createBuildIsoEntity = function(self, dontSetDrag)
    local id, length = getGarageContext(self.logic)
    local result = Build._originalGarageSelectedBarsCreateBuildIsoEntity(self, dontSetDrag)

    if id ~= nil
        and self.buildEntity ~= nil
        and not self.player:isBuildCheat()
        and not hasSelectedBars(self.logic, length) then
        self.buildEntity.blockBuild = true
    end

    return result
end

return Build
