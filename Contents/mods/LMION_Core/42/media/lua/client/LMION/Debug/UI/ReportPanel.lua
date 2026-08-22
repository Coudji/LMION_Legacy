require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "ISUI/ISRichTextPanel"
require "ISUI/ISButton"
require "LMION/Debug/Registry"
require "LMION/Debug/Inspect/Options"

LMION.Debug.UI = LMION.Debug.UI or {}

local Options = LMION.Debug.Inspect.Options
local ReportPanel = ISPanel:derive("LMIONDebugReportPanel")
LMION.Debug.UI.ReportPanel = ReportPanel

function ReportPanel:new(x, y, width, height, controller)
    local o = ISPanel.new(self, x, y, width, height)
    o.controller = controller
    o.background = true
    o.borderColor = { r = 0.45, g = 0.45, b = 0.45, a = 1 }
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.45 }
    o.plainText = ""
    return o
end

function ReportPanel:initialise()
    ISPanel.initialise(self)
end

function ReportPanel:createChildren()
    ISPanel.createChildren(self)

    local pad = 8
    local titleH = 20
    local buttonH = 24
    local copyW = 90
    local detailsW = 132
    local actionW = 132
    local actionGap = 6

    self.titleLabel = ISLabel:new(
        pad,
        pad,
        titleH,
        "Inspection report",
        1, 1, 1, 1,
        UIFont.Small,
        true
    )
    self.titleLabel:initialise()
    self:addChild(self.titleLabel)

    self.output = ISRichTextPanel:new(
        pad,
        pad + titleH + 4,
        self.width - pad * 2,
        self.height - (pad * 3 + titleH + buttonH + 4)
    )
    self.output:initialise()
    self.output.autosetheight = false
    self.output.background = true
    self.output.clip = true
    self.output.marginLeft = 8
    self.output.marginTop = 8
    self.output.marginRight = 18
    self.output.marginBottom = 8
    self.output.text = self.plainText
    self.output:addScrollBars()
    self.output:paginate()
    self:addChild(self.output)

    self.detailsButton = ISButton:new(
        pad,
        self.height - pad - buttonH,
        detailsW,
        buttonH,
        "",
        self,
        ReportPanel.onToggleDetails
    )
    self.detailsButton:initialise()
    self.detailsButton.anchorTop = false
    self.detailsButton.anchorBottom = true
    self.detailsButton.anchorLeft = true
    self.detailsButton.anchorRight = false
    self:addChild(self.detailsButton)

    self.rebuildShowroomButton = ISButton:new(
        pad + detailsW + actionGap,
        self.height - pad - buttonH,
        actionW,
        buttonH,
        "Rebuild showroom",
        self,
        ReportPanel.onRebuildShowroom
    )
    self.rebuildShowroomButton:initialise()
    self.rebuildShowroomButton.anchorTop = false
    self.rebuildShowroomButton.anchorBottom = true
    self.rebuildShowroomButton.anchorLeft = true
    self.rebuildShowroomButton.anchorRight = false
    self:addChild(self.rebuildShowroomButton)

    self.rebuildTestZoneButton = ISButton:new(
        pad + detailsW + actionGap + actionW + actionGap,
        self.height - pad - buttonH,
        actionW,
        buttonH,
        "Rebuild test zone",
        self,
        ReportPanel.onRebuildTestZone
    )
    self.rebuildTestZoneButton:initialise()
    self.rebuildTestZoneButton.anchorTop = false
    self.rebuildTestZoneButton.anchorBottom = true
    self.rebuildTestZoneButton.anchorLeft = true
    self.rebuildTestZoneButton.anchorRight = false
    self:addChild(self.rebuildTestZoneButton)

    self.copyButton = ISButton:new(
        self.width - pad - copyW,
        self.height - pad - buttonH,
        copyW,
        buttonH,
        "Copy",
        self,
        ReportPanel.onCopy
    )
    self.copyButton:initialise()
    self.copyButton.anchorTop = false
    self.copyButton.anchorBottom = true
    self.copyButton.anchorLeft = false
    self.copyButton.anchorRight = true
    self:addChild(self.copyButton)

    self:updateDetailsButton()
    self:layout()
end

function ReportPanel:updateDetailsButton()
    if self.detailsButton == nil then
        return
    end

    self.detailsButton:setTitle(
        Options.isFullDetails() and "Full details: ON" or "Full details: OFF"
    )
end

function ReportPanel:layout()
    local pad = 8
    local titleH = 20
    local buttonH = 24
    local copyW = 90
    local detailsW = 132
    local actionW = 132
    local actionGap = 6

    if self.output ~= nil then
        self.output:setWidth(self.width - pad * 2)
        self.output:setHeight(
            self.height
            - (pad * 3 + titleH + buttonH + 4)
        )

        if self.output.vscroll ~= nil then
            self.output.vscroll:setX(self.output:getWidth() - self.output.vscroll:getWidth())
            self.output.vscroll:setHeight(self.output:getHeight())
        end

        self.output.textDirty = true
        self.output:paginate()
    end

    local buttonY = self.height - pad - buttonH

    if self.detailsButton ~= nil then
        self.detailsButton:setX(pad)
        self.detailsButton:setY(buttonY)
    end

    if self.rebuildShowroomButton ~= nil then
        self.rebuildShowroomButton:setX(pad + detailsW + actionGap)
        self.rebuildShowroomButton:setY(buttonY)
    end

    if self.rebuildTestZoneButton ~= nil then
        self.rebuildTestZoneButton:setX(pad + detailsW + actionGap + actionW + actionGap)
        self.rebuildTestZoneButton:setY(buttonY)
    end

    if self.copyButton ~= nil then
        self.copyButton:setX(self.width - pad - copyW)
        self.copyButton:setY(buttonY)
    end
end

function ReportPanel:onResize()
    self:layout()
end

function ReportPanel:setText(text)
    self.plainText = tostring(text or "")
    self.output.text = self.plainText
    self.output.textDirty = true
    self.output:paginate()
    self.output:setYScroll(0)

    if self.copyButton ~= nil then
        self.copyButton:setTitle("Copy")
    end

    self:updateDetailsButton()
end

function ReportPanel:appendText(text)
    text = tostring(text or "")

    if self.plainText ~= "" and text ~= "" then
        self.plainText = self.plainText .. "\n\n" .. text
    else
        self.plainText = self.plainText .. text
    end

    self.output.text = self.plainText
    self.output.textDirty = true
    self.output:paginate()

    if self.copyButton ~= nil then
        self.copyButton:setTitle("Copy")
    end
end

function ReportPanel:onToggleDetails()
    Options.toggleFullDetails()
    self:updateDetailsButton()

    if self.controller ~= nil and self.controller.refreshReportFromSelection ~= nil then
        self.controller:refreshReportFromSelection()
    end
end

function ReportPanel:onRebuildShowroom()
    if self.controller ~= nil and self.controller.rebuildDoorShowroom ~= nil then
        self.controller:rebuildDoorShowroom()
    end
end

function ReportPanel:onRebuildTestZone()
    if self.controller ~= nil and self.controller.rebuildTestZone ~= nil then
        self.controller:rebuildTestZone()
    end
end

function ReportPanel:onCopy()
    if Clipboard ~= nil and Clipboard.setClipboard ~= nil then
        Clipboard.setClipboard(self.plainText or "")
        self.copyButton:setTitle("Copied")
    elseif LMION ~= nil and LMION.warn ~= nil then
        LMION.warn("Debug", "Clipboard API unavailable")
    end
end

return ReportPanel
