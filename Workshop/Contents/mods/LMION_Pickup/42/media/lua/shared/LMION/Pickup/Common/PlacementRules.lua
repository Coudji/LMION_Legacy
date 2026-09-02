local PlacementRules = {}


function PlacementRules.isCheat(character)
    return ISMoveableDefinitions.cheat
        or (character ~= nil and character:isMovablesCheat())
end


function PlacementRules.isSameOrAdjacent(character, square)
    local playerSquare = character and character:getSquare() or nil

    return playerSquare ~= nil
        and square ~= nil
        and playerSquare:getZ() == square:getZ()
        and (playerSquare == square or playerSquare:isAdjacentTo(square))
end


function PlacementRules.isSafehouseAllowed(character, square)
    if not isClient() then
        return true
    end

    if character == nil or square == nil then
        return false
    end

    return not (
        SafeHouse.isSafeHouse(
            square,
            character:getUsername(),
            true
        )
        and not SafeHouse.isSafehouseAllowLoot(square, character)
    )
end


return PlacementRules
