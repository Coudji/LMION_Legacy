require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "ISUI/ISButton"
require "LMION/Debug/World/Selection"

LMION.Debug.UI = LMION.Debug.UI or {}

local Selection = LMION.Debug.World.Selection
local SquarePanel = ISPanel:derive("LMIONDebugSquarePanel")
LMION.Debug.UI.SquarePanel = SquarePanel

local ROWS_PER_PAGE = 6

function SquarePanel:new(x, y, width, height, controller)
    local o = ISPanel.new(self, x, y, width, height)
    o.controller = controller
    o.page = 1
    o.rowButtons = {}
    o.background = true
    o.borderColor = { r = 0.45, g = 0.45, b = 0.45, a = 1 }
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.35 }
    return o
end

function SquarePanel:initialise()
    ISPanel.initialise(self)
end

function SquarePanel:createChildren()
    ISPanel.createChildren(self)

    local pad = 8

    self.titleLabel = ISLabel:new(
        pad, pad, 18,
        "Selected squares",
        1, 1, 1, 1,
        UIFont.Small,
        true
    )
    self.titleLabel:initialise()
    self:addChild(self.titleLabel)

    self.reloadButton = ISButton:new(
        self.width - pad - 96,
        5,
        96,
        22,
        "Reload LMION",
        self,
        SquarePanel.onReload
    )
    self.reloadButton:initialise()
    self:addChild(self.reloadButton)

    self.infoLabel = ISLabel:new(
        pad, 28, 18,
        "0 selected",
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
            SquarePanel.onSquareRow
        )
        button.internal = i
        button:initialise()
        self:addChild(button)
        self.rowButtons[i] = button
    end

    local controlY = rowY + ROWS_PER_PAGE * (rowH + 2) + 4
    local smallW = 42

    self.northButton = ISButton:new(pad + smallW, controlY, smallW, 22, "+N", self, SquarePanel.onNorth)
    self.northButton:initialise()
    self:addChild(self.northButton)

    self.westButton = ISButton:new(pad, controlY + 24, smallW, 22, "+W", self, SquarePanel.onWest)
    self.westButton:initialise()
    self:addChild(self.westButton)

    self.eastButton = ISButton:new(pad + smallW * 2, controlY + 24, smallW, 22, "+E", self, SquarePanel.onEast)
    self.eastButton:initialise()
    self:addChild(self.eastButton)

    self.southButton = ISButton:new(pad + smallW, controlY + 48, smallW, 22, "+S", self, SquarePanel.onSouth)
    self.southButton:initialise()
    self:addChild(self.southButton)

    self.prevButton = ISButton:new(150, controlY, 56, 22, "Prev", self, SquarePanel.onPrev)
    self.prevButton:initialise()
    self:addChild(self.prevButton)

    self.nextButton = ISButton:new(210, controlY, 56, 22, "Next", self, SquarePanel.onNext)
    self.nextButton:initialise()
    self:addChild(self.nextButton)

    self.pickButton = ISButton:new(270, controlY, 42, 22, "Pick", self, SquarePanel.onPick)
    self.pickButton:initialise()
    self:addChild(self.pickButton)

    self.removeButton = ISButton:new(150, controlY + 24, 116, 22, "Remove active", self, SquarePanel.onRemove)
    self.removeButton:initialise()
    self:addChild(self.removeButton)

    self.clearButton = ISButton:new(150, controlY + 48, 116, 22, "Clear squares", self, SquarePanel.onClear)
    self.clearButton:initialise()
    self:addChild(self.clearButton)
end

function SquarePanel:refresh()
    local entries = Selection.getEntries()
    local count = #entries
    local maxPage = math.max(1, math.ceil(count / ROWS_PER_PAGE))

    if self.page > maxPage then
        self.page = maxPage
    end

    self.infoLabel:setName(tostring(count) .. " selected | page " .. tostring(self.page) .. "/" .. tostring(maxPage))

    local first = (self.page - 1) * ROWS_PER_PAGE + 1

    for row = 1, ROWS_PER_PAGE do
        local button = self.rowButtons[row]
        local entry = entries[first + row - 1]

        if entry ~= nil then
            local isActive = entry.key == Selection.activeKey
            button:setTitle(entry.text)
            button.squareKey = entry.key

            if isActive then
                button.backgroundColor = { r = 0.35, g = 0.35, b = 0.35, a = 0.90 }
                button.backgroundColorMouseOver = { r = 0.45, g = 0.45, b = 0.45, a = 0.95 }
            else
                button.backgroundColor = { r = 0, g = 0, b = 0, a = 0.35 }
                button.backgroundColorMouseOver = { r = 0.25, g = 0.25, b = 0.25, a = 0.60 }
            end

            button:setVisible(true)
        else
            button.squareKey = nil
            button:setTitle("")
            button:setVisible(false)
        end
    end

    local hasMultiplePages = maxPage > 1
    self.prevButton:setVisible(hasMultiplePages)
    self.nextButton:setVisible(hasMultiplePages)
end

function SquarePanel:onSquareRow(button)
    if button.squareKey ~= nil then
        Selection.setActive(button.squareKey)
        self.controller:refreshAll()
    end
end

function SquarePanel:addAdjacent(dx, dy)
    Selection.addAdjacent(dx, dy, 0)
    self.controller:refreshAll()
end

function SquarePanel:onNorth()
    self:addAdjacent(0, -1)
end

function SquarePanel:onSouth()
    self:addAdjacent(0, 1)
end

function SquarePanel:onWest()
    self:addAdjacent(-1, 0)
end

function SquarePanel:onEast()
    self:addAdjacent(1, 0)
end

function SquarePanel:onPick()
    self.controller:startWorldPicker()
end

function SquarePanel:onReload()
    self.controller:reloadLMION()
end

function SquarePanel:onPrev()
    self.page = math.max(1, self.page - 1)
    self:refresh()
end

function SquarePanel:onNext()
    local count = #Selection.getEntries()
    local maxPage = math.max(1, math.ceil(count / ROWS_PER_PAGE))
    self.page = math.min(maxPage, self.page + 1)
    self:refresh()
end

function SquarePanel:onRemove()
    Selection.removeActiveSquare()
    self.controller:refreshAll()
end

function SquarePanel:onClear()
    Selection.clearSquares()
    self.page = 1
    self.controller:refreshAll()
end

return SquarePanel
