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

local function isPairedFrameValid(self, square)
    if not isLmionBuild(self) then
        return true
    end

    local profile = getProfile(self)
    if profile == nil or profile.pairedFrameSide == nil then
        return true
    end

    return LMION.Doors.canPlaceDoorAt(
        square,
        self.north == true,
        true,
        profile.pairedFrameSide
    )
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

if Build._originalIsValid == nil then
    Build._originalIsValid = ISBuildIsoEntity.isValid
end

-- Paired LMION doors use the same strict structural frame rule as Pickup:
-- Left -> DoubleDoor1, Right -> DoubleDoor2. Vanilla's original build validity
-- still runs first so materials, collision, safehouse and all other rules remain
-- authoritative. This hook only tightens LMION paired-frame compatibility.
ISBuildIsoEntity.isValid = function(self, square)
    if not Build._originalIsValid(self, square) then
        return false
    end

    return isPairedFrameValid(self, square)
end

if Build._originalIsValidPerSquare == nil then
    Build._originalIsValidPerSquare = ISBuildIsoEntity.isValidPerSquare
end

-- Vanilla colors the floor cursor through isValidPerSquare(), independently of
-- the final isValid() result used for the object ghost / actual construction.
-- Mirror the paired-frame rule here so a wrong DoubleDoor side is visibly red.
ISBuildIsoEntity.isValidPerSquare = function(self, square, tileInfo, requiresFloor, extendsN, extendsW)
    if not Build._originalIsValidPerSquare(self, square, tileInfo, requiresFloor, extendsN, extendsW) then
        return false
    end

    return isPairedFrameValid(self, square)
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
        normalizeBuiltDoor(square, gameScript, effectiveMaxHealth)
    end

    return result
end

return Build
