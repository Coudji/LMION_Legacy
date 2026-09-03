local PlacementActionUtils = {}


function PlacementActionUtils.resolveFacing(moveProps, fieldName, fallback)
    local facing = moveProps and moveProps[fieldName] or nil

    if facing == "N" or facing == "W" then
        return facing
    end

    if fallback == "N" or fallback == "W" then
        return fallback
    end

    return "N"
end


function PlacementActionUtils.resolveToolbarFacing(
    direction,
    moveCursor,
    fieldName
)
    if direction == "N" or direction == "W" then
        return direction
    end

    if moveCursor ~= nil then
        return PlacementActionUtils.resolveFacing(
            moveCursor.currentMoveProps,
            fieldName,
            "N"
        )
    end

    return "N"
end


function PlacementActionUtils.configure(
    action,
    character,
    square,
    item,
    facing,
    moveProps
)
    action.playerNum = character:getPlayerNum()
    action.square = square
    action.item = item
    action.facing = facing
    action.mode = "place"
    action.moveProps = moveProps
    action.origMoveProps = moveProps
    action.origSpriteName = moveProps and moveProps.spriteName or nil
    action.maxTime = action:getDuration()

    return action
end


function PlacementActionUtils.configureToolbar(
    action,
    character,
    square,
    mode,
    object,
    item,
    moveCursor,
    facing,
    moveProps,
    facingField
)
    action.playerNum = character:getPlayerNum()
    action.square = square
    action.origSpriteName = moveProps.spriteName
    action.spriteFrame = 0
    action.mode = mode
    action.object = object
    action.direction = facing
    action.item = item
    action.moveProps = moveProps
    action.origMoveProps = moveProps
    action.moveCursor = moveCursor
    action[facingField] = facing

    if isServer() then
        action.moveCursor = nil
    end

    action.maxTime = action:getDuration()
    return action
end


return PlacementActionUtils
