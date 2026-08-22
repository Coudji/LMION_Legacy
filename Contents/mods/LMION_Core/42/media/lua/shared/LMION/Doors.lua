require "LMION/Core"

LMION.Doors = LMION.Doors or {}
local Doors = LMION.Doors

function Doors.onCreateGarage(params)
    local thumpable = params and params.thumpable or nil
    if thumpable == nil then
        return nil
    end

    local square = thumpable:getSquare()
    local garageDoor = IsoDoor.new(
        getCell(),
        square,
        thumpable:getSprite(),
        thumpable:getNorth()
    )

    garageDoor:setName(thumpable:getName())
    garageDoor:setModData(copyTable(thumpable:getModData()))
    garageDoor:setKeyId(thumpable:getKeyId())
    garageDoor:setIsLocked(false)
    garageDoor:setLockedByKey(false)
    garageDoor:setHealth(thumpable:getHealth())

    if GameEntityFactory ~= nil then
        local properties = garageDoor:getProperties()
        if properties ~= nil and properties:has(IsoFlagType.EntityScript) then
            GameEntityFactory.CreateIsoEntityFromCellLoading(garageDoor)
        end
    end

    square:AddSpecialObject(garageDoor)
    square:transmitRemoveItemFromSquare(thumpable)

    return {
        replaceObject = true,
        object = garageDoor,
    }
end

return Doors
