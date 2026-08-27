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

local function appendDoorHealth(tooltip, item)
    local current, maximum = getStoredDoorHealth(item)
    if current == nil or maximum == nil then
        return
    end

    local text = getText("UI_LMION_HitPoints")
        .. " : " .. tostring(current)
        .. " / " .. tostring(maximum)

    local y = tooltip:getHeight() - tooltip.padBottom
    tooltip:DrawText(
        tooltip:getFont(),
        text,
        tooltip.padLeft,
        y,
        1,
        1,
        0.8,
        1
    )
    tooltip:adjustWidth(tooltip.padLeft, text)
    tooltip:setHeight(tooltip:getHeight() + tooltip:getLineSpacing())
end

--[[
InventoryItem:DoTooltip() is Java-owned in B42, so LMION extends the client
inventory tooltip at the surrounding ISToolTipInv render layer. Keep the vanilla
render flow intact and append one line after both the measurement and draw passes.
This makes the panel size include the extra line without changing item scripts or
reimplementing any of vanilla's per-item tooltip content.
]]
if Pickup._originalInventoryTooltipRender == nil then
    Pickup._originalInventoryTooltipRender = ISToolTipInv.render
end

ISToolTipInv.render = function(self)
    if ISContextMenu.instance and ISContextMenu.instance.visibleCheck then
        return
    end

    local mx = getMouseX() + 24
    local my = getMouseY() + 24
    if not self.followMouse then
        mx = self:getX()
        my = self:getY()
        if self.anchorBottomLeft then
            mx = self.anchorBottomLeft.x
            my = self.anchorBottomLeft.y
        end
    end

    local PADX = 0

    self.tooltip:setX(mx + PADX)
    self.tooltip:setY(my)

    self.tooltip:setWidth(50)
    self.tooltip:setMeasureOnly(true)
    if self.item then
        self.item:DoTooltip(self.tooltip)
        appendDoorHealth(self.tooltip, self.item)
    end
    self.tooltip:setMeasureOnly(false)

    local myCore = getCore()
    local maxX = myCore:getScreenWidth()
    local maxY = myCore:getScreenHeight()

    local tw = self.tooltip:getWidth()
    local th = self.tooltip:getHeight()

    self.tooltip:setX(math.max(0, math.min(mx + PADX, maxX - tw - 1)))
    if not self.followMouse and self.anchorBottomLeft then
        self.tooltip:setY(math.max(0, math.min(my - th, maxY - th - 1)))
    else
        self.tooltip:setY(math.max(0, math.min(my, maxY - th - 1)))
    end

    if self.contextMenu and self.contextMenu.joyfocus then
        local playerNum = self.contextMenu.player
        self.tooltip:setX(getPlayerScreenLeft(playerNum) + 60)
        self.tooltip:setY(getPlayerScreenTop(playerNum) + 60)
    elseif self.contextMenu and self.contextMenu.currentOptionRect then
        if self.contextMenu.currentOptionRect.height > 32 then
            self:setY(my + self.contextMenu.currentOptionRect.height)
        end
        self:adjustPositionToAvoidOverlap(self.contextMenu.currentOptionRect)
    end

    self:setX(self.tooltip:getX() - PADX)
    self:setY(self.tooltip:getY())
    self:setWidth(tw + PADX)
    self:setHeight(th)

    if self.followMouse and self.contextMenu == nil then
        self:adjustPositionToAvoidOverlap({
            x = mx - 24 * 2,
            y = my - 24 * 2,
            width = 24 * 2,
            height = 24 * 2,
        })
    end

    self:drawRect(
        0,
        0,
        self.width,
        self.height,
        self.backgroundColor.a,
        self.backgroundColor.r,
        self.backgroundColor.g,
        self.backgroundColor.b
    )
    self:drawRectBorder(
        0,
        0,
        self.width,
        self.height,
        self.borderColor.a,
        self.borderColor.r,
        self.borderColor.g,
        self.borderColor.b
    )

    if self.item then
        self.item:DoTooltip(self.tooltip)
        appendDoorHealth(self.tooltip, self.item)
    end
end

return Pickup
