local CursorRotation = {}

local installed = false


local function getLmionMoveProps(cursor)
    if cursor == nil
        or ISMoveableCursor == nil
        or ISMoveableCursor.mode[cursor.player] ~= "place"
    then
        return nil
    end

    local moveProps = cursor.currentMoveProps or cursor.origMoveProps

    if moveProps ~= nil and moveProps.lmionDefinitionId ~= nil then
        return moveProps
    end

    return nil
end


function CursorRotation.install()
    if installed then
        return
    end

    require "BuildingObjects/ISMoveableCursor"

    if ISMoveableCursor == nil then
        error("LMION: ISMoveableCursor is unavailable in Pickup cursor scope", 2)
    end

    local previousRotateMouse = ISMoveableCursor.rotateMouse
    ISMoveableCursor.rotateMouse = function(self, x, y)
        if getLmionMoveProps(self) ~= nil then
            return
        end

        return previousRotateMouse(self, x, y)
    end

    local previousRotateKey = ISMoveableCursor.rotateKey
    ISMoveableCursor.rotateKey = function(self, key, joypadTriggered)
        local moveProps = getLmionMoveProps(self)
        local wantsRotate = getCore():isKey("Rotate building", key)
            or joypadTriggered == true

        if moveProps ~= nil and wantsRotate then
            if moveProps.lmionFacing == "N" then
                self:setCursorFacing(2)
            else
                self:setCursorFacing(1)
            end

            return
        end

        return previousRotateKey(self, key, joypadTriggered)
    end

    installed = true
end


return CursorRotation
