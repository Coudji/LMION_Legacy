require "LMION/Core"
require "BuildingObjects/ISBuildIsoEntity"

LMION.Build = LMION.Build or {}
local Build = LMION.Build

Build.ID = "LMION_Build"
Build.VERSION = "0.0.3-dev"

local function isLmionDoorEntity(gameScript)
    return gameScript ~= nil
        and gameScript.getModID ~= nil
        and gameScript:getModID() == "LMION_Core"
end

local function normalizeBuiltDoor(square, gameScript)
    if square == nil or gameScript == nil then
        return
    end

    local objects = square:getSpecialObjects()
    for i = objects:size() - 1, 0, -1 do
        local object = objects:get(i)
        if instanceof(object, "IsoThumpable")
            and object:isDoor()
            and object.getEntityScript ~= nil
            and object:getEntityScript() == gameScript then
            local result = LMION.Doors.onCreateDoor({ thumpable = object })
            if result ~= nil and result.object ~= nil then
                result.object:transmitCompleteItemToClients()
            end
            return
        end
    end
end

if Build._originalSetInfo == nil then
    Build._originalSetInfo = ISBuildIsoEntity.setInfo
end

ISBuildIsoEntity.setInfo = function(self, square, north, sprite, openSprite)
    local result = Build._originalSetInfo(self, square, north, sprite, openSprite)
    local spriteScript = self.objectInfo and self.objectInfo:getScript() or nil
    local gameScript = spriteScript and spriteScript:getParent() or nil

    if isLmionDoorEntity(gameScript) then
        normalizeBuiltDoor(square, gameScript)
    end

    return result
end

LMION.registerModule(Build.ID, Build)
LMION.log("Build", "loaded " .. Build.VERSION)
