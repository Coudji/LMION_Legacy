require "ISUI/ISToolTipInv"

local TransportState = require "LMION/Pickup/Common/TransportState"


local function getStoredHealth(item)
    local state = item and TransportState.read(item) or nil
    local current = state and tonumber(state.health) or nil
    local maximum = state and tonumber(state.maxHealth) or nil

    if current == nil or maximum == nil or maximum <= 0 then
        return nil, nil
    end

    current = math.max(0, math.floor(current + 0.5))
    maximum = math.max(1, math.floor(maximum + 0.5))

    return current, maximum
end


if not ISToolTipInv._lmionPickupOriginalRender then
    ISToolTipInv._lmionPickupOriginalRender = ISToolTipInv.render
end


ISToolTipInv.render = function(self)
    ISToolTipInv._lmionPickupOriginalRender(self)

    local current, maximum = getStoredHealth(self.item)
    if current == nil or maximum == nil then
        return
    end

    local font = UIFont.Small
    local lineHeight = getTextManager():getFontFromEnum(font):getLineHeight()
    local padX = 7
    local padY = 5
    local extensionHeight = lineHeight + (padY * 2)
    local label = getTextOrNull ~= nil
        and getTextOrNull("UI_LMION_HitPoints")
        or nil
    local text = (label or "Hit Points")
        .. ": "
        .. tostring(current)
        .. " / "
        .. tostring(maximum)

    local oldWidth = self:getWidth()
    local oldHeight = self:getHeight()
    local screenHeight = getCore():getScreenHeight()

    if self:getY() + oldHeight + extensionHeight > screenHeight - 2 then
        self:setY(math.max(0, self:getY() - extensionHeight))
    end

    self:setHeight(oldHeight + extensionHeight)

    local joinY = oldHeight - 1
    local extensionDrawHeight = extensionHeight + 1

    self:drawRect(
        1,
        joinY,
        oldWidth - 2,
        extensionDrawHeight,
        self.backgroundColor.a,
        self.backgroundColor.r,
        self.backgroundColor.g,
        self.backgroundColor.b
    )
    self:drawRect(
        0,
        joinY,
        1,
        extensionDrawHeight,
        self.borderColor.a,
        self.borderColor.r,
        self.borderColor.g,
        self.borderColor.b
    )
    self:drawRect(
        oldWidth - 1,
        joinY,
        1,
        extensionDrawHeight,
        self.borderColor.a,
        self.borderColor.r,
        self.borderColor.g,
        self.borderColor.b
    )
    self:drawRect(
        0,
        oldHeight + extensionHeight - 1,
        oldWidth,
        1,
        self.borderColor.a,
        self.borderColor.r,
        self.borderColor.g,
        self.borderColor.b
    )

    self:drawText(
        text,
        padX,
        oldHeight + padY,
        1.0,
        1.0,
        0.8,
        1.0,
        font
    )
end
