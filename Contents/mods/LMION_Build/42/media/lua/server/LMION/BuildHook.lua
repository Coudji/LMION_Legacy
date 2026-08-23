require "LMION/Build"
require "BuildingObjects/ISBuildIsoEntity"

local Build = LMION.Build

local function isLmionBuild(self)
    return self ~= nil
        and self.craftRecipe ~= nil
        and self.craftRecipe.getModID ~= nil
        and self.craftRecipe:getModID() == "LMION_Build"
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

    if isLmionBuild(self) then
        normalizeBuiltDoor(square, gameScript)
    end

    return result
end

return Build
