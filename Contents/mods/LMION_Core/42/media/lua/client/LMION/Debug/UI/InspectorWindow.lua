require "ISUI/ISCollapsableWindow"
require "LMION/Debug/Registry"
require "LMION/Debug/World/Selection"
require "LMION/Debug/Inspect/ObjectInspector"
require "LMION/Debug/UI/SquarePanel"
require "LMION/Debug/UI/ObjectPanel"
require "LMION/Debug/UI/ReportPanel"

LMION.Debug.UI = LMION.Debug.UI or {}

local Debug = LMION.Debug
local Selection = Debug.World.Selection
local ObjectInspector = Debug.Inspect.ObjectInspector
local SquarePanel = Debug.UI.SquarePanel
local ObjectPanel = Debug.UI.ObjectPanel
local ReportPanel = Debug.UI.ReportPanel

local InspectorWindow = ISCollapsableWindow:derive("LMIONInspectorWindow")
Debug.UI.InspectorWindow = InspectorWindow
Debug.Window = Debug.Window or {}

function InspectorWindow:new(x, y, width, height)
    local o = ISCollapsableWindow.new(self, x, y, width, height)
    o.title = "LMION Inspector"
    o.resizable = true
    o.minimumWidth = 900
    o.minimumHeight = 640
    return o
end

function InspectorWindow:initialise()
    ISCollapsableWindow.initialise(self)
end

function InspectorWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    local pad = 8
    local top = 28
    local leftW = 320
    local gap = 8
    local contentH = self.height - top - pad
    local squareH = 285

    self.squarePanel = SquarePanel:new(
        pad,
        top,
        leftW,
        squareH,
        self
    )
    self.squarePanel:initialise()
    self.squarePanel:instantiate()
    self:addChild(self.squarePanel)

    self.objectPanel = ObjectPanel:new(
        pad,
        top + squareH + gap,
        leftW,
        contentH - squareH - gap,
        self
    )
    self.objectPanel:initialise()
    self.objectPanel:instantiate()
    self:addChild(self.objectPanel)

    self.reportPanel = ReportPanel:new(
        pad + leftW + gap,
        top,
        self.width - (pad * 2 + leftW + gap),
        contentH
    )
    self.reportPanel:initialise()
    self.reportPanel:instantiate()
    self.reportPanel.anchorRight = true
    self.reportPanel.anchorBottom = true
    self:addChild(self.reportPanel)

    self:layout()
    self:refreshAll()
end

function InspectorWindow:layout()
    local pad = 8
    local top = 28
    local leftW = 320
    local gap = 8

    local contentH = self.height - top - pad

    if self.reportPanel ~= nil then
        self.reportPanel:setX(pad + leftW + gap)
        self.reportPanel:setY(top)

        self.reportPanel:setWidth(
            self.width - (pad * 2 + leftW + gap)
        )

        self.reportPanel:setHeight(contentH)

        if self.reportPanel.layout ~= nil then
            self.reportPanel:layout()
        end
    end
end

function InspectorWindow:onResize()
    self:layout()
end

function InspectorWindow:refreshAll()
    if self.squarePanel ~= nil then
        self.squarePanel:refresh()
    end

    if self.objectPanel ~= nil then
        self.objectPanel:refresh()
    end

    self:refreshReportFromSelection()
end

function InspectorWindow:refreshReportFromSelection()
    local objects = Selection.getSelectedObjects()

    if #objects == 0 then
        self.reportPanel:setText("")
        return
    end

    if #objects == 1 then
        local report = ObjectInspector.inspect(objects[1])
        self.reportPanel:setText(report:toText())
        return
    end

    self.reportPanel:setText(
        ObjectInspector.inspectMany(objects)
    )
end


function InspectorWindow:refreshObjectSelection()
    if self.objectPanel ~= nil then
        self.objectPanel:refresh()
    end

    self:refreshReportFromSelection()
end

function InspectorWindow:addSquare(square)
    if square ~= nil then
        Selection.addSquare(square, true)
    end

    self:refreshAll()
end

function InspectorWindow:close()
    Selection.reset()
    Debug.Window.instance = nil
    ISCollapsableWindow.close(self)
end

function Debug.Window.ensure()
    if Debug.Window.instance ~= nil then
        Debug.Window.instance:setVisible(true)
        Debug.Window.instance:addToUIManager()
        return Debug.Window.instance
    end

    local width = 1100
    local height = 680
    local x = 70
    local y = 60

    local window = InspectorWindow:new(x, y, width, height)
    window:initialise()
    window:addToUIManager()
    window:setVisible(true)

    Debug.Window.instance = window
    return window
end

function Debug.Window.openAtSquare(square)
    local window = Debug.Window.ensure()
    window:addSquare(square)
    return window
end

function Debug.Window.inspectObject(object)
    local window = Debug.Window.ensure()
    window:inspectOne(object)
end

return InspectorWindow
