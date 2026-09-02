local GhostRender = {}


local function getColor(valid)
    if valid then
        return 0.5, 1.0, 0.5
    end

    return 1.0, 0.0, 0.0
end


function GhostRender.sprite(sprite, square, valid, alpha)
    if sprite == nil or square == nil then
        return false
    end

    local r, g, b = getColor(valid == true)

    sprite:RenderGhostTileColor(
        square:getX(),
        square:getY(),
        square:getZ(),
        0,
        0,
        r,
        g,
        b,
        alpha
    )

    return true
end


function GhostRender.floor(square, valid, alpha)
    local floor = square and square:getFloor() or nil
    local sprite = floor and floor:getSprite() or nil

    return GhostRender.sprite(sprite, square, valid, alpha)
end


return GhostRender
