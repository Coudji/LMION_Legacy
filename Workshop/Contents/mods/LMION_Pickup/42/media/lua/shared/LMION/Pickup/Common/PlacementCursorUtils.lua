local PlacementCursorUtils = {}


function PlacementCursorUtils.configure(cursor, character, item, facing)
    cursor:init()
    cursor.character = character
    cursor.player = character:getPlayerNum()
    cursor.item = item
    cursor.facing = facing
    cursor:setDragNilAfterPlace(true)
    cursor.noNeedHammer = true
    cursor.skipBuildAction = true
    cursor.skipWalk2 = true

    return cursor
end


function PlacementCursorUtils.rotateFacing(cursor, key)
    if not getCore():isKey("Rotate building", key) then
        return false
    end

    cursor.facing = cursor.facing == "N" and "W" or "N"
    getSoundManager():playUISound("UIObjectMenuObjectRotateOutline")
    return true
end


return PlacementCursorUtils
