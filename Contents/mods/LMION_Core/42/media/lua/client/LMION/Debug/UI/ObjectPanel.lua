require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "ISUI/ISButton"
require "ISUI/ISComboBox"
require "LMION/Debug/World/Selection"
require "LMION/Debug/World/SquareScanner"

LMION.Debug.UI = LMION.Debug.UI or {}

local Selection = LMION.Debug.World.Selection
local SquareScanner = LMION.Debug.World.SquareScanner
local ObjectPanel = ISPanel:derive("LMIONDebugObjectPanel")
LMION.Debug.UI.ObjectPanel = ObjectPanel

local ROWS_PER_PAGE = 7

local function hasProperty(object, name)
    if object == nil then
        return false
    end

    local properties = object:getProperties()
    return properties ~= nil and properties:has(name)
end

local function propertyValue(object, name)
    if object == nil then
        return nil
    end

    local properties = object:getProperties()

    if properties == nil or not properties:has(name) then
        return nil
    end

    return properties:get(name)
end

local function looksLikeDoor(entry)
    if entry == nil or entry.object == nil then
        return false
    end

    if entry.classShort == "IsoDoor" then
        return true
    end

    if entry.classShort ~= "IsoThumpable" then
        return false
    end

    if hasProperty(entry.object, "DoubleDoor") or hasProperty(entry.object, "GarageDoor") then
        return true
    end

    local entityScriptName = propertyValue(entry.object, "EntityScriptName")

    if entityScriptName ~= nil then
        local lower = string.lower(tostring(entityScriptName))
        return string.find(lower, "door", 1, true) ~= nil
            or string.find(lower, "gate", 1, true) ~= nil
    end

    return false
end

local function matchesFilter(entry, filter)
    if filter == "doors" then
        return looksLikeDoor(entry)
    end

    if filter == "floor" then
        return entry ~= nil
            and entry.square ~= nil
            and entry.object == entry.square:getFloor()
    end

    if filter == "items" then
        return entry ~= nil and entry.classShort == "IsoWorldInventoryObject"
    end

    return true
end

function ObjectPanel:new(x, y, width, height, controller)
    local o = ISPanel.new(self, x, y, width, height)
    o.controller = controller
    o.page = 1
    o.entries = {}
    o.allEntries = {}
    o.rowButtons = {}
    o.filter = "all"
    o.background = true
    o.borderColor = { r = 0.45, g = 0.45, b = 0.45, a = 1 }
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.35 }
    return o
end

local function isCtrlDown()
    if isKeyDown == nil then
        return false
    end

    if Keyboard ~= nil then
        local left = Keyboard.KEY_LCONTROL
        local right = Keyboard.KEY_RCONTROL

        if left ~= nil and isKeyDown(left) then
            return true
        end

        if right ~= nil and isKeyDown(right) then
            return true
        end
    end

    return isKeyDown(29) or isKeyDown(157)
end

function ObjectPanel:initialise()
    ISPanel.initialise(self)
end

function ObjectPanel:createChildren()
    ISPanel.createChildren(self)

    local pad = 8

    self.titleLabel = ISLabel:new(
        pad, pad, 18,
        "Objects in selected squares",
        1, 1, 1, 1,
        UIFont.Small,
        true
    )
    self.titleLabel:initialise()
    self:addChild(self.titleLabel)

    self.infoLabel = ISLabel:new(
        pad, 28, 18,
        "0 objects",
        0.8, 0.8, 0.8, 1,
        UIFont.Small,
        true
    )
    self.infoLabel:initialise()
    self:addChild(self.infoLabel)

    self.filterCombo = ISComboBox:new(
        pad,
        48,
        self.width - pad * 2,
        22,
        self,
        ObjectPanel.onFilterChanged
    )
    self.filterCombo:initialise()
    self:addChild(self.filterCombo)
    self.filterCombo:addOptionWithData("All objects", "all")
    self.filterCombo:addOptionWithData("Doors / gates", "doors")
    self.filterCombo:addOptionWithData("Floor tiles", "floor")
    self.filterCombo:addOptionWithData("World items", "items")
    self.filterCombo.selected = 1

    local rowY = 76
    local rowH = 24

    for i = 1, ROWS_PER_PAGE do
        local button = ISButton:new(
            pad,
            rowY + (i - 1) * (rowH + 2),
            self.width - pad * 2,
            rowH,
            "",
            self,
            ObjectPanel.onObjectRow
        )
        button.internal = i
        button:initialise()
        self:addChild(button)
        self.rowButtons[i] = button
    end

    local controlY = rowY + ROWS_PER_PAGE * (rowH + 2) + 4

    self.prevButton = ISButton:new(
        pad,
        controlY,
        56,
        22,
        "Prev",
        self,
        ObjectPanel.onPrev
    )
    self.prevButton:initialise()
    self:addChild(self.prevButton)

    self.nextButton = ISButton:new(
        pad + 60,
        controlY,
        56,
        22,
        "Next",
        self,
        ObjectPanel.onNext
    )
    self.nextButton:initialise()
    self:addChild(self.nextButton)

    self.selectAllButton = ISButton:new(
        pad,
        controlY + 24,
        116,
        22,
        "Select shown",
        self,
        ObjectPanel.onSelectAll
    )
    self.selectAllButton:initialise()
    self:addChild(self.selectAllButton)

    self.clearSelectionButton = ISButton:new(
        130,
        controlY + 24,
        130,
        22,
        "Clear selection",
        self,
        ObjectPanel.onClearSelection
    )
    self.clearSelectionButton:initialise()
    self:addChild(self.clearSelectionButton)
end

function ObjectPanel:applyFilter()
    self.entries = {}

    for _, entry in ipairs(self.allEntries) do
        if matchesFilter(entry, self.filter) then
            self.entries[#self.entries + 1] = entry
        end
    end
end

function ObjectPanel:refresh()
    self.allEntries = SquareScanner.flattenObjects(Selection.getSquares())
    self:applyFilter()

    local count = #self.entries
    local totalCount = #self.allEntries
    local selectedCount = #Selection.getSelectedObjects()
    local maxPage = math.max(1, math.ceil(count / ROWS_PER_PAGE))

    if self.page > maxPage then
        self.page = maxPage
    end

    self.infoLabel:setName(
        tostring(count)
            .. "/"
            .. tostring(totalCount)
            .. " shown | "
            .. tostring(selectedCount)
            .. " selected | page "
            .. tostring(self.page)
            .. "/"
            .. tostring(maxPage)
    )

    local first = (self.page - 1) * ROWS_PER_PAGE + 1

    for row = 1, ROWS_PER_PAGE do
        local button = self.rowButtons[row]
        local entry = self.entries[first + row - 1]

        if entry ~= nil then
            local selected = Selection.isObjectSelected(entry)
            local sprite = entry.spriteName or "<no sprite>"
            local shortSquare = tostring(entry.square:getX())
                .. ","
                .. tostring(entry.square:getY())

            local title = shortSquare
                .. " | "
                .. tostring(entry.classShort)
                .. " | "
                .. tostring(sprite)

            button:setTitle(title)
            button.entry = entry

            if selected then
                button.backgroundColor = {
                    r = 0.35,
                    g = 0.35,
                    b = 0.35,
                    a = 0.90
                }
                button.backgroundColorMouseOver = {
                    r = 0.45,
                    g = 0.45,
                    b = 0.45,
                    a = 0.95
                }
            else
                button.backgroundColor = {
                    r = 0,
                    g = 0,
                    b = 0,
                    a = 0.35
                }
                button.backgroundColorMouseOver = {
                    r = 0.25,
                    g = 0.25,
                    b = 0.25,
                    a = 0.60
                }
            end

            button:setVisible(true)
        else
            button.entry = nil
            button:setTitle("")
            button:setVisible(false)
        end
    end

    local hasMultiplePages = maxPage > 1
    self.prevButton:setVisible(hasMultiplePages)
    self.nextButton:setVisible(hasMultiplePages)
end

function ObjectPanel:onFilterChanged(combo)
    self.filter = combo:getOptionData(combo.selected) or "all"
    self.page = 1
    self:refresh()
end

function ObjectPanel:onObjectRow(button)
    if button.entry == nil then
        return
    end

    if isCtrlDown() then
        Selection.toggleObject(button.entry)
    else
        Selection.selectOnlyObject(button.entry)
    end

    self.controller:refreshObjectSelection()
end

function ObjectPanel:onPrev()
    self.page = math.max(1, self.page - 1)
    self:refresh()
end

function ObjectPanel:onNext()
    local maxPage = math.max(1, math.ceil(#self.entries / ROWS_PER_PAGE))
    self.page = math.min(maxPage, self.page + 1)
    self:refresh()
end

function ObjectPanel:onSelectAll()
    Selection.selectObjectEntries(self.entries)
    self.controller:refreshObjectSelection()
end

function ObjectPanel:onClearSelection()
    Selection.clearObjectSelection()
    self.controller:refreshObjectSelection()
end

return ObjectPanel
