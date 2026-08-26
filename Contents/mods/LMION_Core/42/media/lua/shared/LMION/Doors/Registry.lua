local Doors = LMION.Doors

local spriteProfiles = nil

--[[
Sprite ownership is derived from GameEntity SpriteConfig data rather than guessed
from sprite-name conventions. The cache is rebuilt when engine-facing profiles
are reapplied after tile definitions load.
]]
local function buildSpriteProfiles()
    if spriteProfiles ~= nil then
        return
    end

    spriteProfiles = {}

    local scripts = ScriptManager.instance:getAllGameEntities()
    for i = 0, scripts:size() - 1 do
        local script = scripts:get(i)
        local profile = Doors.Profiles[script:getName()]

        if profile ~= nil then
            local spriteConfig = script:getComponentScriptFor(ComponentType.SpriteConfig)
            if spriteConfig ~= nil then
                local tileNames = spriteConfig:getAllTileNames()
                for j = 0, tileNames:size() - 1 do
                    spriteProfiles[tileNames:get(j)] = profile
                end
            end
        end
    end
end

function Doors.invalidateSpriteProfiles()
    spriteProfiles = nil
end

function Doors.getProfile(entityName)
    return entityName and Doors.Profiles[entityName] or nil
end

function Doors.getDisplayName(profile)
    if profile == nil then
        return nil
    end

    if profile.nameKey ~= nil then
        local translated = getText(profile.nameKey)
        if translated ~= nil and translated ~= profile.nameKey then
            return translated
        end
    end

    return profile.fallbackName or profile.id
end

function Doors.getProfileForSprite(sprite)
    if sprite == nil then
        return nil
    end

    if type(sprite) == "string" then
        sprite = getSprite(sprite)
    end

    if sprite == nil or sprite:getName() == nil then
        return nil
    end

    buildSpriteProfiles()
    return spriteProfiles[sprite:getName()]
end

return Doors
