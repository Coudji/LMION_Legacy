require "ISUI/ISToolTipInv"

local Pickup = LMION.Pickup

local function getStoredDoorHealth(item)
    if item == nil or not item:hasModData() then
        return nil, nil
    end

    local modData = item:getModData()
    local current = tonumber(modData.lmionDoorHealth)
    local maximum = tonumber(modData.lmionDoorMaxHealth)

    if current == nil or maximum == nil or maximum <= 0 then
        return nil, nil
    end

    current = math.max(0, math.floor(current + 0.5))
    maximum = math.max(1, math.floor(maximum + 0.5))
    return current, maximum
end

--[[
InventoryItem:DoTooltip() is Java-owned in B42. Do not try to draw directly on
ObjectTooltip: some of its padding members are Java-side accessors rather than
plain Lua numbers in B42.20.4.

Instead, keep vanilla's ISToolTipInv rendering completely intact, then extend the
already-rendered inventory panel by one small line. This is the same stable UI
pattern used by VHSInsight: vanilla owns the original tooltip, LMION only owns
its appended block.
]]
if Pickup._originalInventoryTooltipRender == nil then
    Pickup._originalInventoryTooltipRender = ISToolTipInv.render
end

ISToolTipInv.render = function(self)
    Pickup._originalInventoryTooltipRender(self)

    local current, maximum = getStoredDoorHealth(self.item)
    if current == nil or maximum == nil then
        return
    end

    local font = UIFont.Small
    local lineHeight = getTextManager():getFontFromEnum(font):getLineHeight()
    local padX = 7
    local padY = 5
    local extensionHeight = lineHeight + (padY * 2)

    local text = getText("UI_LMION_HitPoints")
        .. " : " .. tostring(current)
        .. " / " .. tostring(maximum)

    local oldWidth = self:getWidth()
    local oldHeight = self:getHeight()

    -- Keep the appended block on-screen when the vanilla tooltip is near the
    -- bottom edge, matching the behavior used by VHSInsight.
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

return Pickup
