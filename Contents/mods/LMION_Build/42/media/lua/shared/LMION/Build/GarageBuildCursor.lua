require "BuildingObjects/ISBuildIsoEntity"

local Build = LMION.Build
local GarageBuild = Build.GarageBuild

local function getGarageId(self)
    if self == nil or GarageBuild == nil then
        return nil
    end
    return GarageBuild.getGarageIdFromObjectInfo(self.objectInfo)
end

local function getGarageLength(self)
    local length = self and tonumber(self.lmionGarageLength) or nil
    if length ~= nil then
        return GarageBuild.normalizeLength(length)
    end
    return GarageBuild.getLengthFromLogic(self and self.buildPanelLogic or nil)
end

local function getGarageContainers(self)
    local logic = self and self.buildPanelLogic or nil
    if logic ~= nil and logic.getContainers ~= nil then
        return logic:getContainers()
    end
    return self and self.containers or nil
end

if Build._originalGarageCursorNew == nil then
    Build._originalGarageCursorNew = ISBuildIsoEntity.new
end

-- BuildAction serializes constructor parameters by name. Keeping the selected
-- length as an optional `new()` parameter makes it part of the vanilla network
-- payload and reconstructs the same width on the server.
ISBuildIsoEntity.new = function(self, character, objectInfo, nSprite, containers, logic, lmionGarageLength)
    local o = Build._originalGarageCursorNew(self, character, objectInfo, nSprite, containers, logic)
    local garageId = GarageBuild.getGarageIdFromObjectInfo(objectInfo)

    if garageId ~= nil then
        local length = tonumber(lmionGarageLength)
        if length == nil and logic ~= nil then
            length = GarageBuild.getLengthFromLogic(logic)
        end
        if length == nil then
            length = GarageBuild.DefaultLength
        end

        o.lmionGarageId = garageId
        o.lmionGarageLength = GarageBuild.normalizeLength(length)
    end

    return o
end

if Build._originalGarageCursorGetFace == nil then
    Build._originalGarageCursorGetFace = ISBuildIsoEntity.getFace
end

-- The source SpriteConfig stays L3. Only this cursor sees a variable FaceInfo
-- proxy that maps first -> START, interior -> MIDDLE and last -> END.
ISBuildIsoEntity.getFace = function(self)
    local face = Build._originalGarageCursorGetFace(self)
    if getGarageId(self) == nil or face == nil then
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

if Build._originalGarageCursorIsValid == nil then
    Build._originalGarageCursorIsValid = ISBuildIsoEntity.isValid
end

-- Vanilla only knows the static L2 base recipe. The cursor must additionally
-- reject placement when the complete selected-width cost is unavailable.
ISBuildIsoEntity.isValid = function(self, square)
    if not Build._originalGarageCursorIsValid(self, square) then
        return false
    end

    local garageId = getGarageId(self)
    if garageId == nil or self.character:isBuildCheat() then
        return true
    end

    return GarageBuild.hasRequirements(
        self.character,
        garageId,
        getGarageLength(self),
        getGarageContainers(self),
        false
    )
end

return Build
