local PlacementRules = {}


function PlacementRules.isCheat(character)
    return ISMoveableDefinitions.cheat
        or (character ~= nil and character:isMovablesCheat())
end


function PlacementRules.isSameLevel(character, square)
    local playerSquare = character and character:getSquare() or nil

    return playerSquare ~= nil
        and square ~= nil
        and playerSquare:getZ() == square:getZ()
end


function PlacementRules.isSameOrAdjacent(character, square)
    local playerSquare = character and character:getSquare() or nil

    return playerSquare ~= nil
        and square ~= nil
        and playerSquare:getZ() == square:getZ()
        and (playerSquare == square or playerSquare:isAdjacentTo(square))
end


function PlacementRules.isAnySquareAdjacent(character, count, getSquare)
    if character == nil or count == nil or getSquare == nil then
        return false
    end

    if PlacementRules.isCheat(character) then
        return true
    end

    for index = 1, count do
        if PlacementRules.isSameOrAdjacent(character, getSquare(index)) then
            return true
        end
    end

    return false
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


function PlacementRules.areAllSafehousesAllowed(character, count, getSquare)
    if count == nil or getSquare == nil then
        return false
    end

    for index = 1, count do
        if not PlacementRules.isSafehouseAllowed(
            character,
            getSquare(index)
        ) then
            return false
        end
    end

    return true
end


return PlacementRules
