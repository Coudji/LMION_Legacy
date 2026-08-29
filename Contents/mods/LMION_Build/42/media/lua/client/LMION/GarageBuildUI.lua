require "LMION/Build"
require "BuildingObjects/ISBuildIsoEntity"
require "Entity/ISUI/BuildRecipe/ISBuildRecipePanel"
require "Entity/ISUI/BuildRecipe/ISWidgetBuildControl"
require "Entity/ISUI/BuildRecipe/ISWidgetInput"
require "Entity/ISUI/BuildRecipe/ISBuildPanel"

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

    -- The vanilla ingredient widgets update their values every prerender. Re-run
    -- layout here because counts can gain/lose digits as width changes.
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

    -- Row 0 is the recipe header. Vanilla deliberately inserts row 1 as a fill
    -- row before "Objets requis"; this is the exact empty area reserved for the
    -- LMION garage length control.
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

    local available = GarageBuild.getAvailable(self.player, fullType, requirement.uses, false)
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
                false
            )
    end
end

if Build._originalGarageCreateBuildIsoEntity == nil then
    Build._originalGarageCreateBuildIsoEntity = ISBuildPanel.createBuildIsoEntity
end

ISBuildPanel.createBuildIsoEntity = function(self, dontSetDrag)
    local id, length = getGarageContext(self.logic)
    local result = Build._originalGarageCreateBuildIsoEntity(self, dontSetDrag)

    if id ~= nil and self.buildEntity ~= nil then
        self.buildEntity.lmionGarageId = id
        self.buildEntity.lmionGarageLength = length
        if not self.player:isBuildCheat() then
            self.buildEntity.blockBuild = self.buildEntity.blockBuild
                or not GarageBuild.hasRequirements(self.player, id, length, false)
        end
    end

    return result
end

return Build
