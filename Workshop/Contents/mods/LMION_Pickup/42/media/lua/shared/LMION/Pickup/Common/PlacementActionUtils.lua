local PlacementActionUtils = {}


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


return PlacementActionUtils
