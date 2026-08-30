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
        return GarageBuild.normalizeLength(length)
    end

    return GarageBuild.getLengthFromLogic(self.buildPanelLogic)
end

local function getGarageContainers(self)
    local logic = self and self.buildPanelLogic or nil
    if logic ~= nil and logic.getContainers ~= nil then
        return logic:getContainers()
    end
    return self and self.containers or nil
end

local function getRecordedVanillaBarCount(self)
    local modData = self and self.modData or nil
    if modData == nil then
        return 0
    end

    return (tonumber(modData["need:Base.MetalBar"]) or 0)
        + (tonumber(modData["need:Base.IronBar"]) or 0)
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
        getGarageContainers(self),
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

if Build._originalIsValid == nil then
    Build._originalIsValid = ISBuildIsoEntity.isValid
end

-- The shared garage cursor has already applied full-cost validation. The server
-- hook keeps the existing LMION frame-class rule on top of that result.
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

    -- Vanilla has already consumed its CraftRecipe inputs and updateModData() has
    -- recorded the actual selected bar alternatives before entering this tile
    -- loop. Since the bar input is native-variable, vanilla may have paid from 2
    -- up to the whole selected width. LMION consumes only the remainder plus the
    -- explicit deltas for the other materials.
    if garageId ~= nil
        and not self.character:isBuildCheat()
        and not self._lmionGarageExtrasConsumed then
        local length = getGarageLength(self)
        if not GarageBuild.consumeExtras(
            self.character,
            garageId,
            length,
            getGarageContainers(self),
            getRecordedVanillaBarCount(self)
        ) then
            error("LMION_Build garage delta consumption failed after successful preflight")
        end
        GarageBuild.recordExtrasOnBuildObject(self, garageId, length)
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
