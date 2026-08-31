require "BuildingObjects/ISBuildingObject"

local installed = false


local function renderFloor(square, valid)
    local floor = square and square:getFloor() or nil
    local sprite = floor and floor:getSprite() or nil
    if sprite == nil then
        return
    end

    local r = valid and 0.5 or 1.0
    local g = valid and 1.0 or 0.0
    local b = valid and 0.5 or 0.0

    sprite:RenderGhostTileColor(
        square:getX(),
        square:getY(),
        square:getZ(),
        0,
        0,
        r,
        g,
        b,
        0.25
    )
end


local function renderPreviewEntry(entry, planValid)
    if entry == nil or entry.square == nil then
        return
    end

    local valid = planValid and entry.valid == true
    renderFloor(entry.square, valid)

    local sprite = entry.sprite and getSprite(entry.sprite) or nil
    if sprite == nil then
        return
    end

    local r = valid and 0.5 or 1.0
    local g = valid and 1.0 or 0.0
    local b = valid and 0.5 or 0.0

    sprite:RenderGhostTileColor(
        entry.square:getX(),
        entry.square:getY(),
        entry.square:getZ(),
        0,
        0,
        r,
        g,
        b,
        0.8
    )
end


local function install()
    if installed
        or type(LMIONLargeGatePlacementCursor) ~= "table"
        or type(LMIONLargeGatePlacementCursor.render) ~= "function"
    then
        return
    end

    local previousRender = LMIONLargeGatePlacementCursor.render

    LMIONLargeGatePlacementCursor.render = function(self, x, y, z, square)
        if square == nil or self.getPlan == nil then
            return previousRender(self, x, y, z, square)
        end

        local plan = self:getPlan(square)
        local preview = plan and plan.preview or nil

        if preview == nil then
            return previousRender(self, x, y, z, square)
        end

        renderPreviewEntry(preview[1], plan.valid == true)
        renderPreviewEntry(preview[2], plan.valid == true)
    end

    installed = true
end


install()
Events.OnGameStart.Add(install)
