require "LMION/Core"

LMION.Doors = LMION.Doors or {}
local Doors = LMION.Doors

function Doors.onCreateDoor(params)
    local thumpable = params and params.thumpable or nil
    if thumpable == nil then
        return nil
    end

    local square = thumpable:getSquare()
    local door = IsoDoor.new(
        getCell(),
        square,
        thumpable:getSprite(),
        thumpable:getNorth()
    )

    door:setName(thumpable:getName())
    door:setModData(copyTable(thumpable:getModData()))
    door:setKeyId(thumpable:getKeyId())
    door:setIsLocked(false)
    door:setLockedByKey(false)
    door:setHealth(thumpable:getHealth())

    if GameEntityFactory ~= nil then
        local properties = door:getProperties()
        if properties ~= nil and properties:has(IsoFlagType.EntityScript) then
            GameEntityFactory.CreateIsoEntityFromCellLoading(door)
        end
    end

    square:AddSpecialObject(door)
    square:transmitRemoveItemFromSquare(thumpable)

    return {
        replaceObject = true,
        object = door,
    }
end

Doors.onCreateGarage = Doors.onCreateDoor

return Doors
