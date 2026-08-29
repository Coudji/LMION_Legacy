require "LMION/Build"
require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "ISUI/ISButton"
require "Entity/ISUI/BuildRecipe/ISBuildRecipePanel"
require "Entity/ISUI/BuildRecipe/ISWidgetBuildControl"
require "Entity/ISUI/CraftRecipe/ISWidgetInput"
require "Entity/ISUI/BuildRecipe/ISBuildPanel"
require "Entity/ISUI/Controls/ISWidgetTitleHeader"

local Build = LMION.Build
local GarageBuild = Build.GarageBuild

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local BUTTON_HGT = FONT_HGT_SMALL + 8
local SPACING = 8

LMIONGarageLengthSelector = ISPanel:derive("LMIONGarageLengthSelector")

function LMIONGarageLengthSelector:initialise()
    ISPanel.initialise(self)
end

function LMIONGarageLengthSelector:createChildren()
    ISPanel.createChildren(self)

    self.lengthLabel = ISLabel:new(0, 0, BUTTON_HGT, getText("UI_LMION_GarageBuild_Length"), 1, 1, 1, 1, UIFont.Small, true)
    self.lengthLabel:initialise()
    self.lengthLabel:instantiate()
    self:addChild(self.lengthLabel)

    self.buttonLess = ISButton:new(0, 0, BUTTON_HGT, BUTTON_HGT, "-", self, LMIONGarageLengthSelector.onButtonClick)
    self.buttonLess:initialise()
    self.buttonLess:instantiate()
    self:addChild(self.buttonLess)

    self.valueLabel = ISLabel:new(0, 0, BUTTON_HGT, "3", 1, 1, 1, 1, UIFont.Small, true)
    self.valueLabel:initialise()
    self.valueLabel:instantiate()
    self:addChild(self.valueLabel)

    self.buttonMore = ISButton:new(0, 0, BUTTON_HGT, BUTTON_HGT, "+", self, LMIONGarageLengthSelector.onButtonClick)
    self.buttonMore:initialise()
    self.buttonMore:instantiate()
    self:addChild(self.buttonMore)

    self:updateState()
end

function LMIONGarageLengthSelector:updateState()
    local length = GarageBuild.getLengthFromLogic(self.logic)
    self.valueLabel:setName(tostring(length))
    self.buttonLess.enable = length > GarageBuild.MinLength

    local maximum = LMION.Doors.getGarageMaxLength()
    self.buttonMore.enable = maximum == nil or length < maximum
end

function LMIONGarageLengthSelector:setLength(length)
    local newLength = GarageBuild.setLengthOnLogic(self.logic, length)
    if newLength == nil then
        return
    end

    GarageBuild.invalidateStock(self.player)
    self:updateState()

    if self.recipePanel ~= nil then
        self.recipePanel:xuiRecalculateLayout()
    end
end

function LMIONGarageLengthSelector:onButtonClick(button)
    local length = GarageBuild.getLengthFromLogic(self.logic)
    if button == self.buttonLess then
        self:setLength(length - 1)
    elseif button == self.buttonMore then
        self:setLength(length + 1)
    end
end

function LMIONGarageLengthSelector:calculateLayout(preferredWidth, preferredHeight)
    local width = math.max(preferredWidth or 0, 180)
    local height = math.max(preferredHeight or 0, BUTTON_HGT + SPACING * 2)

    local contentWidth = self.lengthLabel:getWidth()
        + SPACING
        + self.buttonLess:getWidth()
        + SPACING
        + math.max(24, self.valueLabel:getWidth())
        + SPACING
        + self.buttonMore:getWidth()

    local x = math.max(SPACING, math.floor((width - contentWidth) / 2))
    local y = math.max(SPACING, math.floor((height - BUTTON_HGT) / 2))

    self.lengthLabel:setX(x)
    self.lengthLabel:setY(y)
    x = self.lengthLabel:getRight() + SPACING

    self.buttonLess:setX(x)
    self.buttonLess:setY(y)
    x = self.buttonLess:getRight() + SPACING

    self.valueLabel:setX(x + math.max(0, math.floor((24 - self.valueLabel:getWidth()) / 2)))
    self.valueLabel:setY(y)
    x = x + math.max(24, self.valueLabel:getWidth()) + SPACING

    self.buttonMore:setX(x)
    self.buttonMore:setY(y)

    self:setWidth(width)
    self:setHeight(height)
end

function LMIONGarageLengthSelector:new(x, y, width, height, player, logic, recipePanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.logic = logic
    o.recipePanel = recipePanel
    o.background = false
    o.borderColor = {r = 1, g = 1, b = 1, a = 0}
    o.minimumWidth = 180
    o.minimumHeight = BUTTON_HGT + SPACING * 2
    return o
end

local function getGarageContext(logic)
    local id = GarageBuild.getGarageIdFromLogic(logic)
    if id == nil then
        return nil, nil
    end
    return id, GarageBuild.ensureLengthOnLogic(logic)
end

local function getContainers(logic)
    if logic ~= nil and logic.getContainers ~= nil then
        return logic:getContainers()
    end
    return nil
end

if Build._originalGarageRecipePanelCreateDynamicChildren == nil then
    Build._originalGarageRecipePanelCreateDynamicChildren = ISBuildRecipePanel.createDynamicChildren
end

ISBuildRecipePanel.createDynamicChildren = function(self)
    Build._originalGarageRecipePanelCreateDynamicChildren(self)

    local id = getGarageContext(self.logic)
    if id == nil or self.rootTable == nil then
        self.lmionGarageLengthSelector = nil
        return
    end

    local selector = LMIONGarageLengthSelector:new(0, 0, 10, BUTTON_HGT + SPACING * 2, self.player, self.logic, self)
    selector:initialise()
    selector:instantiate()
    self.lmionGarageLengthSelector = selector

    -- Row 0 is the recipe header. B42 deliberately inserts row 1 as an
    -- auto-fill row before "Objets requis". This is the empty panel selected
    -- for the garage length control, and ISTableLayout:setElement() is the
    -- supported way to populate it.
    self.rootTable:setElement(0, 1, selector)
    self:xuiRecalculateLayout()
end

local function getInputFullType(widget)
    local inputScript = widget and widget.inputScript or nil
    if inputScript == nil or inputScript.getPossibleInputItems == nil then
        return nil
    end

    local items = inputScript:getPossibleInputItems()
    if items == nil or items:size() < 1 then
        return nil
    end

    local scriptItem = items:get(0)
    return scriptItem and scriptItem:getFullName() or nil
end

if Build._originalGarageWidgetInputUpdateValues == nil then
    Build._originalGarageWidgetInputUpdateValues = ISWidgetInput.updateValues
end

ISWidgetInput.updateValues = function(self)
    Build._originalGarageWidgetInputUpdateValues(self)

    local id, length = getGarageContext(self.logic)
    if id == nil or self.primary == nil or self.primary.label == nil then
        return
    end

    local fullType = getInputFullType(self)
    local requirement = fullType and GarageBuild.getRequirement(id, length, fullType) or nil
    if requirement == nil then
        return
    end

    local available = GarageBuild.getAvailable(
        self.player,
        fullType,
        requirement.uses,
        getContainers(self.logic),
        false
    )
    local satisfied = available >= requirement.amount
    local amountText

    if requirement.uses then
        if satisfied then
            amountText = tostring(requirement.amount) .. " " .. getText("Attributes_Type_Uses")
        else
            amountText = tostring(available) .. "/" .. tostring(requirement.amount) .. " " .. getText("Attributes_Type_Uses")
        end
    else
        amountText = tostring(available) .. "/" .. tostring(requirement.amount)
    end

    self.primary.label:setName(amountText)
    self.primary.label.amountValue = requirement.amount
    self.primary.label.satisfiedValue = available

    if satisfied then
        self.primary.label.textColor = self.textColor
        self.borderColor = self.normalBorderColor
        self.primary.icon.backgroundColor.a = 1.0
    else
        self.primary.label.textColor = self.colBad
        self.borderColor = self.colBad
        if available <= 0 then
            self.primary.icon.backgroundColor.a = 0.25
        end
    end
end

if Build._originalGarageTitleUpdateLabels == nil then
    Build._originalGarageTitleUpdateLabels = ISWidgetTitleHeader.updateLabels
end

ISWidgetTitleHeader.updateLabels = function(self)
    Build._originalGarageTitleUpdateLabels(self)

    local id, length = getGarageContext(self.logic)
    if id == nil or self.errorLabel == nil or self.player:isBuildCheat() then
        return
    end

    if not GarageBuild.hasRequirements(self.player, id, length, getContainers(self.logic), false) then
        local text = getText("IGUI_CraftingWindow_Error_NotAvailable")
            .. getText("IGUI_CraftingWindow_Error_Inputs")
        self.errorLabel.errorText = text
        self.errorLabel:setName(text)
        self.errorLabel:setVisible(true)
    elseif self.logic:cachedCanPerformCurrentRecipe() then
        self.errorLabel:setVisible(false)
    end
end

if Build._originalGarageBuildControlPrerender == nil then
    Build._originalGarageBuildControlPrerender = ISWidgetBuildControl.prerender
end

ISWidgetBuildControl.prerender = function(self)
    Build._originalGarageBuildControlPrerender(self)

    local id = GarageBuild.getGarageIdFromLogic(self.logic)
    if id ~= nil and self.buttonCraft ~= nil and not self.player:isBuildCheat() then
        self.buttonCraft.enable = self.buttonCraft.enable
            and GarageBuild.hasRequirements(
                self.player,
                id,
                GarageBuild.getLengthFromLogic(self.logic),
                getContainers(self.logic),
                false
            )
    end
end

if Build._originalGarageCreateBuildIsoEntity == nil then
    Build._originalGarageCreateBuildIsoEntity = ISBuildPanel.createBuildIsoEntity
end

ISBuildPanel.createBuildIsoEntity = function(self, dontSetDrag)
    local id, length = getGarageContext(self.logic)
    if id ~= nil and self._lmionGarageRepeatLength ~= nil then
        length = GarageBuild.normalizeLength(self._lmionGarageRepeatLength)
    end

    local result = Build._originalGarageCreateBuildIsoEntity(self, dontSetDrag)

    if id ~= nil and self.buildEntity ~= nil then
        self.buildEntity.lmionGarageId = id
        self.buildEntity.lmionGarageLength = length
        if not self.player:isBuildCheat() then
            self.buildEntity.blockBuild = self.buildEntity.blockBuild
                or not GarageBuild.hasRequirements(
                    self.player,
                    id,
                    length,
                    getContainers(self.logic),
                    false
                )
        end
    end

    return result
end

if Build._originalGarageOnStopCraft == nil then
    Build._originalGarageOnStopCraft = ISBuildPanel.onStopCraft
end

-- Vanilla refreshes BuildLogic before recreating the quick-repeat cursor. That
-- refresh replaces CraftRecipeData and therefore loses our per-logic modData.
-- Keep the selected width only for this panel instance while vanilla refreshes,
-- then restore it before the next frame. The world cursor remains frozen once
-- each individual placement starts.
ISBuildPanel.onStopCraft = function(self)
    local garageId = GarageBuild.getGarageIdFromLogic(self.logic)
    local savedLength = garageId and GarageBuild.getLengthFromLogic(self.logic) or nil

    if garageId == nil or savedLength == nil then
        return Build._originalGarageOnStopCraft(self)
    end

    self._lmionGarageRepeatLength = savedLength
    local ok, result = pcall(Build._originalGarageOnStopCraft, self)
    self._lmionGarageRepeatLength = nil

    GarageBuild.setLengthOnLogic(self.logic, savedLength)

    if self.buildEntity ~= nil
        and GarageBuild.getGarageIdFromObjectInfo(self.buildEntity.objectInfo) == garageId then
        self.buildEntity.lmionGarageId = garageId
        self.buildEntity.lmionGarageLength = GarageBuild.normalizeLength(savedLength)
    end

    local selector = self.craftRecipePanel and self.craftRecipePanel.lmionGarageLengthSelector or nil
    if selector ~= nil then
        selector:updateState()
    end

    if not ok then
        error(result)
    end

    return result
end

return Build
