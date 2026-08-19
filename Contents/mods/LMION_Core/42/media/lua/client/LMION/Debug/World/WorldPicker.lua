require "ISUI/ISPanel"
require "LMION/Debug/World/Highlight"
require "LMION/Debug/World/Selection"

LMION.Debug.World = LMION.Debug.World or {}

local Highlight = LMION.Debug.World.Highlight
local Selection = LMION.Debug.World.Selection

local WorldPicker = ISPanel:derive("LMIONDebugWorldPicker")
LMION.Debug.World.WorldPicker = WorldPicker

local function getTargetZ()
    local active = Selection.getActiveSquare()

    if active ~= nil then
        return active:getZ()
    end

    if getSpecificPlayer ~= nil then
        local player = getSpecificPlayer(0)

        if player ~= nil then
            return player:getZ()
        end
    end

    return 0
end

local function squareUnderMouse()
    if screenToIsoX == nil or screenToIsoY == nil or getCell == nil then
        return nil
    end

    local mouseX = getMouseXScaled()
    local mouseY = getMouseYScaled()
    local z = getTargetZ()

    local isoX = math.floor(screenToIsoX(0, mouseX, mouseY, z))
    local isoY = math.floor(screenToIsoY(0, mouseX, mouseY, z))

    return getCell():getGridSquare(isoX, isoY, z)
end

function WorldPicker:new(controller)
    local core = getCore()
    local o = ISPanel.new(
        self,
        0,
        0,
        core:getScreenWidth(),
        core:getScreenHeight()
    )

    o.controller = controller
    o.background = false
    o.border = false
    o.moveWithMouse = false
    o.consumeMouseEvents = true
    o.hoverSquare = nil
    o.cancelled = false
    return o
end

function WorldPicker:initialise()
    ISPanel.initialise(self)
end

function WorldPicker:createChildren()
    ISPanel.createChildren(self)
    self:setWantKeyEvents(true)
end

function WorldPicker:update()
    ISPanel.update(self)

    local square = squareUnderMouse()

    if square ~= self.hoverSquare then
        self.hoverSquare = square
        Highlight.setHover(square)
    end
end

function WorldPicker:onMouseDown(x, y)
    local square = self.hoverSquare or squareUnderMouse()

    if square ~= nil then
        Selection.addSquare(square, true)
    end

    self:finish()
    return true
end

function WorldPicker:onRightMouseDown(x, y)
    self.cancelled = true
    self:finish()
    return true
end

function WorldPicker:onKeyPress(key)
    if Keyboard ~= nil and key == Keyboard.KEY_ESCAPE then
        self.cancelled = true
        self:finish()
        return true
    end

    return false
end

function WorldPicker:finish()
    Highlight.clearHover()

    if self.controller ~= nil then
        self.controller.worldPicker = nil
        self.controller:setVisible(true)
        self.controller:addToUIManager()
        self.controller:refreshAll()
    end

    self:setVisible(false)
    self:removeFromUIManager()
end

function WorldPicker:start()
    self:initialise()
    self:instantiate()
    self:addToUIManager()
    self:setVisible(true)
    self:bringToTop()
end

return WorldPicker
