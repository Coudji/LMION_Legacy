require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "ISUI/ISButton"
require "LMION/Debug/Inspect/Door"
require "LMION/Debug/Inspect/Frame"
require "LMION/Debug/World/Selection"
require "LMION/Debug/World/SquareScanner"

LMION.Debug.UI = LMION.Debug.UI or {}

local Door = LMION.Debug.Inspect.Door
local Frame = LMION.Debug.Inspect.Frame
local Selection = LMION.Debug.World.Selection
local SquareScanner = LMION.Debug.World.SquareScanner
local ObjectPanel = ISPanel:derive("LMIONDebugObjectPanel")
LMION.Debug.UI.ObjectPanel = ObjectPanel

local ROWS_PER_PAGE = 7

function ObjectPanel:new(x, y, width, height, controller)
    local o = ISPanel.new(self, x, y, width, height)
    o.controller = controller
    o.page = 1
    o.entries = {}
    o.rowButtons = {}
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
        "Doors / gates / frames in selected squares",
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

    local rowY = 50
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

    self.prevButton = ISButton:new(pad, controlY, 56, 22, "Prev", self, ObjectPanel.onPrev)
    self.prevButton:initialise()
    self:addChild(self.prevButton)

    self.nextButton = ISButton:new(pad + 60, controlY, 56, 22, "Next", self, ObjectPanel.onNext)
    self.nextButton:initialise()
    self:addChild(self.nextButton)

    self.selectAllButton = ISButton:new(pad, controlY + 24, 116, 22, "Select shown", self, ObjectPanel.onSelectAll)
    self.selectAllButton:initialise()
    self:addChild(self.selectAllButton)

    self.clearSelectionButton = ISButton:new(130, controlY + 24, 130, 22, "Clear selection", self, ObjectPanel.onClearSelection)
    self.clearSelectionButton:initialise()
    self:addChild(self.clearSelectionButton)
end

function ObjectPanel:refresh()
    self.entries = {}

    for _, entry in ipairs(SquareScanner.flattenObjects(Selection.getSquares())) do
        if Door.isDoorLike(entry.object) or (Frame ~= nil and Frame.isFrameLike(entry.object)) then
            self.entries[#self.entries + 1] = entry
        end
    end

    local count = #self.entries
    local selectedCount = #Selection.getSelectedObjects()
    local maxPage = math.max(1, math.ceil(count / ROWS_PER_PAGE))

    if self.page > maxPage then
        self.page = maxPage
    end

    self.infoLabel:setName(
        tostring(count)
            .. " objects | "
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
            local shortSquare = tostring(entry.square:getX()) .. "," .. tostring(entry.square:getY())

            button:setTitle(shortSquare .. " | " .. tostring(entry.classShort) .. " | " .. tostring(sprite))
            button.entry = entry

            if selected then
                button.backgroundColor = { r = 0.35, g = 0.35, b = 0.35, a = 0.90 }
                button.backgroundColorMouseOver = { r = 0.45, g = 0.45, b = 0.45, a = 0.95 }
            else
                button.backgroundColor = { r = 0, g = 0, b = 0, a = 0.35 }
                button.backgroundColorMouseOver = { r = 0.25, g = 0.25, b = 0.25, a = 0.60 }
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
