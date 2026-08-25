require "LMION/Build"
require "BuildingObjects/ISBuildIsoEntity"

local Build = LMION.Build

local function isLmionBuild(self)
    return self ~= nil
        and self.craftRecipe ~= nil
        and self.craftRecipe.getModID ~= nil
        and self.craftRecipe:getModID() == "LMION_Build"
end

local function normalizeBuiltDoor(square, gameScript, effectiveMaxHealth)
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
            local result = LMION.Doors.onCreateDoor({
                thumpable = object,
                effectiveMaxHealth = effectiveMaxHealth,
            })
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
    local gameScriptBefore = nil
    if self ~= nil and self.objectInfo ~= nil and self.objectInfo:getScript() ~= nil then
        gameScriptBefore = self.objectInfo:getScript():getParent()
    end

    if isLmionBuild(self) then
        local profile = gameScriptBefore and LMION.Doors.getProfile(gameScriptBefore:getName()) or nil
        LMION.Doors.BuildContext = {
            profile = profile,
            craftRecipe = self.craftRecipe,
            character = self.character,
            effectiveMaxHealth = LMION.Doors.getConstructionMaxHealth(
                profile,
                self.craftRecipe,
                self.character
            ),
        }
    end

    local ok, result = pcall(Build._originalSetInfo, self, square, north, sprite, openSprite)
    LMION.Doors.BuildContext = nil

    if not ok then
        error(result)
    end

    local spriteScript = self.objectInfo and self.objectInfo:getScript() or nil
    local gameScript = spriteScript and spriteScript:getParent() or gameScriptBefore

    if isLmionBuild(self) then
        local profile = gameScript and LMION.Doors.getProfile(gameScript:getName()) or nil
        local effectiveMaxHealth = LMION.Doors.getConstructionMaxHealth(
            profile,
            self.craftRecipe,
            self.character
        )
        normalizeBuiltDoor(square, gameScript, effectiveMaxHealth)
    end

    return result
end

return Build
