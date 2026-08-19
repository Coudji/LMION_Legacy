require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "ISUI/ISRichTextPanel"
require "ISUI/ISButton"
require "LMION/Debug/Registry"

LMION.Debug.UI = LMION.Debug.UI or {}

local ReportPanel = ISPanel:derive("LMIONDebugReportPanel")
LMION.Debug.UI.ReportPanel = ReportPanel

function ReportPanel:new(x, y, width, height)
    local o = ISPanel.new(self, x, y, width, height)
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
    local buttonW = 90

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

    self.copyButton = ISButton:new(
        self.width - pad - buttonW,
        self.height - pad - buttonH,
        buttonW,
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

    self:layout()
end

function ReportPanel:layout()
    local pad = 8
    local titleH = 20
    local buttonH = 24
    local buttonW = 90

    if self.output ~= nil then
        self.output:setWidth(self.width - pad * 2)
        self.output:setHeight(
            self.height
            - (pad * 3 + titleH + buttonH + 4)
        )

        -- addScrollBars() creates the scrollbar using the panel size at that time.
        -- Keep it synced when the Inspector window is resized afterwards.
        if self.output.vscroll ~= nil then
            self.output.vscroll:setX(self.output:getWidth() - self.output.vscroll:getWidth())
            self.output.vscroll:setHeight(self.output:getHeight())
        end

        self.output.textDirty = true
        self.output:paginate()
    end

    if self.copyButton ~= nil then
        self.copyButton:setX(self.width - pad - buttonW)
        self.copyButton:setY(self.height - pad - buttonH)
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

function ReportPanel:onCopy()
    if Clipboard ~= nil and Clipboard.setClipboard ~= nil then
        Clipboard.setClipboard(self.plainText or "")
        self.copyButton:setTitle("Copied")
    elseif LMION ~= nil and LMION.warn ~= nil then
        LMION.warn("Debug", "Clipboard API unavailable")
    end
end

return ReportPanel
