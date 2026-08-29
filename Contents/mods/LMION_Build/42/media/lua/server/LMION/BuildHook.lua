require "LMION/Build"
require "BuildingObjects/ISBuildIsoEntity"

local Build = LMION.Build
local GarageBuild = Build.GarageBuild

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

local function getGarageId(self)
    if not isLmionBuild(self) or GarageBuild == nil then
        return nil
    end
    return GarageBuild.getGarageIdFromObjectInfo(self.objectInfo)
end

local function getGarageLength(self)
    if self == nil or GarageBuild == nil then
        return nil
    end

    local length = tonumber(self.lmionGarageLength)
    if length ~= nil then
        return math.floor(length)
    end

    return GarageBuild.getLengthFromLogic(self.buildPanelLogic)
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

local function hasGarageMaterials(self, fresh)
    local garageId = getGarageId(self)
    if garageId == nil or self.character:isBuildCheat() then
        return true
    end

    return GarageBuild.hasRequirements(
        self.character,
        garageId,
        getGarageLength(self),
        fresh == true
    )
end

--[[
Post-build finalization scans the completed square by EntityScript and delegates
the final object contract to Core. Core canonicalizes any remaining temporary
IsoThumpable door to IsoDoor, then applies the Build-owned gameplay durability.

Garage SpriteConfigs perform the same canonicalization earlier in OnCreate for
engine-safety reasons, so this scan normally finds their already-final IsoDoor.
Build never implements or chooses a Java representation itself.
]]
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
            local finalObject = LMION.Doors.initializeConstructedDoor({
                object = object,
                effectiveMaxHealth = effectiveMaxHealth,
            })

            if finalObject ~= nil and finalObject.transmitCompleteItemToClients ~= nil then
                finalObject:transmitCompleteItemToClients()
            end
            return
        end
    end
end

if Build._originalGarageGetFace == nil then
    Build._originalGarageGetFace = ISBuildIsoEntity.getFace
end

-- Do not mutate SpriteConfigManager's shared FaceInfo. For garage constructions,
-- expose a per-cursor proxy whose first/interior/last tiles resolve to the
-- existing START/MIDDLE/END L3 definition at the selected width.
ISBuildIsoEntity.getFace = function(self)
    local face = Build._originalGarageGetFace(self)
    local garageId = getGarageId(self)
    if garageId == nil or face == nil then
        return face
    end

    local length = getGarageLength(self)
    if self._lmionGarageFaceSource ~= face
        or self._lmionGarageFaceLength ~= length
        or self._lmionGarageFaceProxy == nil then
        self._lmionGarageFaceSource = face
        self._lmionGarageFaceLength = length
        self._lmionGarageFaceProxy = GarageBuild.createFaceProxy(face, length)
    end

    return self._lmionGarageFaceProxy
end

if Build._originalIsValid == nil then
    Build._originalIsValid = ISBuildIsoEntity.isValid
end

-- LMION framed doors use a stricter frame-class rule than vanilla. Garages add
-- one more strict condition: the selected length must be fully affordable, not
-- merely the static L2 recipe that vanilla knows about.
ISBuildIsoEntity.isValid = function(self, square)
    if not Build._originalIsValid(self, square) then
        return false
    end

    if not isLmionFrameValid(self, square) then
        return false
    end

    return hasGarageMaterials(self, false)
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

if Build._originalGarageCreate == nil then
    Build._originalGarageCreate = ISBuildIsoEntity.create
end

-- Server/solo authority gets a fresh full-cost preflight immediately before the
-- vanilla construction pipeline begins. ISBuildAction does not call create() on
-- multiplayer clients, so variable resources are never charged twice.
ISBuildIsoEntity.create = function(self, x, y, z, north, sprite)
    local garageId = getGarageId(self)
    if garageId ~= nil and not hasGarageMaterials(self, true) then
        LMION.error("Build", "garage build rejected: selected length is no longer affordable")
        return false
    end

    self._lmionGarageExtrasConsumed = false
    return Build._originalGarageCreate(self, x, y, z, north, sprite)
end

if Build._originalSetInfo == nil then
    Build._originalSetInfo = ISBuildIsoEntity.setInfo
end

ISBuildIsoEntity.setInfo = function(self, square, north, sprite, openSprite)
    local gameScriptBefore = getGameScript(self)
    local garageId = getGarageId(self)

    -- Vanilla has already performed the static L2 recipe before entering its
    -- tile loop. Consume the exact L2->selected-length delta once, immediately
    -- before the first physical garage member is created. This avoids stealing
    -- items reserved by BuildLogic for the base recipe.
    if garageId ~= nil
        and not self.character:isBuildCheat()
        and not self._lmionGarageExtrasConsumed then
        if not GarageBuild.consumeExtras(self.character, garageId, getGarageLength(self)) then
            error("LMION_Build garage delta consumption failed after successful preflight")
        end
        self._lmionGarageExtrasConsumed = true
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
