local Doors = LMION.Doors

--[[
PropertyContainer values are alias-backed. A write is accepted only when exact
readback matches the requested value; otherwise the previous property is restored.
]]
local function setAliasedProperty(properties, name, value)
    if properties == nil or value == nil then
        return true
    end

    local expected = tostring(value)
    local hadValue = properties:has(name)
    local previous = hadValue and properties:get(name) or nil

    properties:set(name, expected)

    if properties:has(name) and properties:get(name) == expected then
        return true
    end

    if hadValue and previous ~= nil then
        properties:set(name, previous)
    else
        properties:unset(name)
    end

    return false
end

local function clearProperty(properties, name)
    if properties ~= nil and properties:has(name) then
        properties:unset(name)
    end
end

local function applyEngineProfileToSprite(sprite, profile)
    if sprite == nil or profile == nil then
        return false
    end

    local properties = sprite:getProperties()
    if properties == nil then
        return false
    end

    local ok = true
    local materials = profile.materials

    if materials ~= nil then
        if materials.primary ~= nil then
            ok = setAliasedProperty(properties, "Material", materials.primary) and ok
        else
            clearProperty(properties, "Material")
        end

        if materials.secondary ~= nil then
            ok = setAliasedProperty(properties, "Material2", materials.secondary) and ok
        else
            clearProperty(properties, "Material2")
        end

        if materials.tertiary ~= nil then
            ok = setAliasedProperty(properties, "Material3", materials.tertiary) and ok
        else
            clearProperty(properties, "Material3")
        end

        if materials.materialType ~= nil then
            ok = setAliasedProperty(properties, "MaterialType", materials.materialType) and ok
        else
            clearProperty(properties, "MaterialType")
        end
    end

    local sounds = profile.sounds
    if sounds ~= nil then
        if sounds.door ~= nil then
            ok = setAliasedProperty(properties, "DoorSound", sounds.door) and ok
        end

        if sounds.thump ~= nil then
            ok = setAliasedProperty(properties, "ThumpSound", sounds.thump) and ok
        end
    end

    return ok
end

function Doors.applyEngineProfiles()
    if ScriptManager == nil or ScriptManager.instance == nil or getSprite == nil then
        return 0, 0
    end

    Doors.invalidateSpriteProfiles()

    local scripts = ScriptManager.instance:getAllGameEntities()
    local applied = 0
    local rejected = 0

    for i = 0, scripts:size() - 1 do
        local script = scripts:get(i)
        local profile = Doors.Profiles[script:getName()]

        if profile ~= nil then
            local spriteConfig = script:getComponentScriptFor(ComponentType.SpriteConfig)
            if spriteConfig ~= nil then
                local tileNames = spriteConfig:getAllTileNames()
                for j = 0, tileNames:size() - 1 do
                    local sprite = getSprite(tileNames:get(j))
                    if sprite ~= nil then
                        if applyEngineProfileToSprite(sprite, profile) then
                            applied = applied + 1
                        else
                            rejected = rejected + 1
                        end
                    end
                end
            end
        end
    end

    if LMION.log ~= nil then
        LMION.log("Core", "engine profiles applied=" .. tostring(applied) .. ", rejected=" .. tostring(rejected))
    end

    return applied, rejected
end

return Doors
