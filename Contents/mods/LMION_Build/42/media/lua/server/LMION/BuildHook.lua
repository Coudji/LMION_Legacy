require "LMION/Build"
require "BuildingObjects/ISBuildIsoEntity"

local Build = LMION.Build

local function isLmionBuild(self)
    return self ~= nil
        and self.craftRecipe ~= nil
        and self.craftRecipe.getModID ~= nil
        and self.craftRecipe:getModID() == "LMION_Build"
end

local function getGameScript(self)
    local spriteScript = self and self.objectInfo and self.objectInfo:getScript() or nil
    return spriteScript and spriteScript:getParent() or nil
end

local function getProfile(self)
    local gameScript = getGameScript(self)
    return gameScript and LMION.Doors.getProfile(gameScript:getName()) or nil
end

local function isLmionFrameValid(self, square)
    if not isLmionBuild(self) then
        return true
    end

    local profile = getProfile(self)
    if profile == nil or profile.requiresFrame ~= true then
        return true
    end

    return LMION.Doors.canPlaceDoorAt(
        square,
        self.north == true,
        true,
        profile.pairedFrameSide
    )
end

local function initializeBuiltDoor(square, gameScript, effectiveMaxHealth)
    if square == nil or gameScript == nil then
        return
    end

    local objects = square:getSpecialObjects()
    for i = objects:size() - 1, 0, -1 do
        local object = objects:get(i)
        if LMION.Doors.isDoorObject(object)
            and object.getEntityScript ~= nil
            and object:getEntityScript() == gameScript then
            if LMION.Doors.initializeConstructedDoor({
                object = object,
                effectiveMaxHealth = effectiveMaxHealth,
            }) and object.transmitCompleteItemToClients ~= nil then
                object:transmitCompleteItemToClients()
            end
            return
        end
    end
end

if Build._originalIsValid == nil then
    Build._originalIsValid = ISBuildIsoEntity.isValid
end

-- LMION framed doors use a stricter frame-class rule than vanilla:
-- standard doors reject DoubleDoor1/2 frames, paired Left requires DoubleDoor1,
-- paired Right requires DoubleDoor2. Vanilla validity still runs first.
ISBuildIsoEntity.isValid = function(self, square)
    if not Build._originalIsValid(self, square) then
        return false
    end

    return isLmionFrameValid(self, square)
end

if Build._originalIsValidPerSquare == nil then
    Build._originalIsValidPerSquare = ISBuildIsoEntity.isValidPerSquare
end

-- Vanilla colors the floor cursor through isValidPerSquare(), independently of
-- the final isValid() result used for the object ghost / actual construction.
-- Mirror the same frame-class rule here so invalid frames are visibly red.
ISBuildIsoEntity.isValidPerSquare = function(self, square, tileInfo, requiresFloor, extendsN, extendsW)
    if not Build._originalIsValidPerSquare(self, square, tileInfo, requiresFloor, extendsN, extendsW) then
        return false
    end

    return isLmionFrameValid(self, square)
end

if Build._originalSetInfo == nil then
    Build._originalSetInfo = ISBuildIsoEntity.setInfo
end

ISBuildIsoEntity.setInfo = function(self, square, north, sprite, openSprite)
    local gameScriptBefore = getGameScript(self)

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

    local gameScript = getGameScript(self) or gameScriptBefore

    if isLmionBuild(self) then
        local profile = gameScript and LMION.Doors.getProfile(gameScript:getName()) or nil
        local effectiveMaxHealth = LMION.Doors.getConstructionMaxHealth(
            profile,
            self.craftRecipe,
            self.character
        )
        initializeBuiltDoor(square, gameScript, effectiveMaxHealth)
    end

    return result
end

return Build
