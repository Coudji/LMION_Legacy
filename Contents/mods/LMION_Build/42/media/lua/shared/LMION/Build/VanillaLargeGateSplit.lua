require "LMION/Build/LargeGateProfiles"

local Build = LMION.Build

--[[
The vanilla Double* GameEntities own all eight closed-face sprites. Build needs a
separate GameEntity for leaf B so it can expose A and B as independent recipes.
While Build is active, narrow the vanilla entity ownership to leaf A. Core still
owns the permanent logical topology (A+B); this file only prepares engine sprite
ownership for Build's per-leaf construction feature.
]]
local splitSpecs = {
    {
        id = "DoubleDoor",
        expected = {
            "fixtures_doors_fences_01_96",
            "fixtures_doors_fences_01_97",
            "fixtures_doors_fences_01_98",
            "fixtures_doors_fences_01_99",
            "fixtures_doors_fences_01_104",
            "fixtures_doors_fences_01_105",
            "fixtures_doors_fences_01_106",
            "fixtures_doors_fences_01_107",
        },
        leafA = {
            "fixtures_doors_fences_01_96",
            "fixtures_doors_fences_01_97",
            "fixtures_doors_fences_01_98",
            "fixtures_doors_fences_01_99",
        },
        body = [[
entity DoubleDoor
{
    component SpriteConfig
    {
        skillBaseHealth = 300,
        dontNeedFrame = true,
        BreakSound = BreakDoor,

        face W
        {
            layer
            {
                row = fixtures_doors_fences_01_97,
                row = fixtures_doors_fences_01_96,
            }
        }

        face N
        {
            layer
            {
                row = fixtures_doors_fences_01_98 fixtures_doors_fences_01_99,
            }
        }
    }
}
]],
    },
    {
        id = "DoubleWireGate",
        expected = {
            "fixtures_doors_fences_01_64",
            "fixtures_doors_fences_01_65",
            "fixtures_doors_fences_01_66",
            "fixtures_doors_fences_01_67",
            "fixtures_doors_fences_01_72",
            "fixtures_doors_fences_01_73",
            "fixtures_doors_fences_01_74",
            "fixtures_doors_fences_01_75",
        },
        leafA = {
            "fixtures_doors_fences_01_64",
            "fixtures_doors_fences_01_65",
            "fixtures_doors_fences_01_66",
            "fixtures_doors_fences_01_67",
        },
        body = [[
entity DoubleWireGate
{
    component SpriteConfig
    {
        skillBaseHealth = 300,
        dontNeedFrame = true,
        BreakSound = BreakDoor,

        face W
        {
            layer
            {
                row = fixtures_doors_fences_01_65,
                row = fixtures_doors_fences_01_64,
            }
        }

        face N
        {
            layer
            {
                row = fixtures_doors_fences_01_66 fixtures_doors_fences_01_67,
            }
        }
    }
}
]],
    },
    {
        id = "DoubleFenceGate",
        expected = {
            "fixtures_doors_fences_01_80",
            "fixtures_doors_fences_01_81",
            "fixtures_doors_fences_01_82",
            "fixtures_doors_fences_01_83",
            "fixtures_doors_fences_01_88",
            "fixtures_doors_fences_01_89",
            "fixtures_doors_fences_01_90",
            "fixtures_doors_fences_01_91",
        },
        leafA = {
            "fixtures_doors_fences_01_80",
            "fixtures_doors_fences_01_81",
            "fixtures_doors_fences_01_82",
            "fixtures_doors_fences_01_83",
        },
        body = [[
entity DoubleFenceGate
{
    component SpriteConfig
    {
        skillBaseHealth = 300,
        dontNeedFrame = true,
        BreakSound = BreakDoor,

        face W
        {
            layer
            {
                row = fixtures_doors_fences_01_81,
                row = fixtures_doors_fences_01_80,
            }
        }

        face N
        {
            layer
            {
                row = fixtures_doors_fences_01_82 fixtures_doors_fences_01_83,
            }
        }
    }
}
]],
    },
}

local function makeSet(values)
    local result = {}
    for _, value in ipairs(values) do
        result[value] = true
    end
    return result
end

local function countKnown(tileNames, known)
    local count = 0
    for i = 0, tileNames:size() - 1 do
        if known[tostring(tileNames:get(i))] then
            count = count + 1
        end
    end
    return count
end

local function getScript(id)
    local script = ScriptManager.instance:getGameEntityScript("Base." .. id)
    if script == nil then
        script = ScriptManager.instance:getGameEntityScript(id)
    end
    return script
end

local function validateCurrentSpriteConfig(spec, script)
    local spriteConfig = script:getComponentScriptFor(ComponentType.SpriteConfig)
    if spriteConfig == nil then
        return nil, "SpriteConfig not found"
    end

    local expected = makeSet(spec.expected)
    local tileNames = spriteConfig:getAllTileNames()
    if tileNames:size() ~= #spec.expected or countKnown(tileNames, expected) ~= #spec.expected then
        return nil, "expected exact vanilla closed-tile set"
    end

    return spriteConfig, nil
end

local function reloadAsLeafA(spec, script, spriteConfig)
    spriteConfig:PreReload()

    local ok, err = pcall(function()
        script:Load(spec.id, spec.body)
    end)
    if not ok then
        return false, "reload failed: " .. tostring(err)
    end

    local reloaded = script:getComponentScriptFor(ComponentType.SpriteConfig)
    if reloaded == nil then
        return false, "reload produced no SpriteConfig"
    end

    local expectedA = makeSet(spec.leafA)
    local tileNames = reloaded:getAllTileNames()
    if tileNames:size() ~= #spec.leafA or countKnown(tileNames, expectedA) ~= #spec.leafA then
        return false, "leaf-A verification failed"
    end

    return true, nil
end

function Build.prepareVanillaLargeGateLeafConstruction()
    if not Build.installLargeGateLeafProfiles() then
        LMION.error("Build", "unable to install large-gate leaf profiles")
        return false
    end

    if ScriptManager == nil or ScriptManager.instance == nil or ComponentType == nil then
        return false
    end

    local prepared = {}
    for _, spec in ipairs(splitSpecs) do
        local script = getScript(spec.id)
        if script == nil then
            LMION.error("Build", spec.id .. " GameEntityScript not found")
            return false
        end

        local spriteConfig, reason = validateCurrentSpriteConfig(spec, script)
        if spriteConfig == nil then
            LMION.error("Build", "refusing " .. spec.id .. " leaf preparation: " .. tostring(reason))
            return false
        end

        prepared[#prepared + 1] = {
            spec = spec,
            script = script,
            spriteConfig = spriteConfig,
        }
    end

    for _, entry in ipairs(prepared) do
        local ok, reason = reloadAsLeafA(entry.spec, entry.script, entry.spriteConfig)
        if not ok then
            LMION.error("Build", entry.spec.id .. " leaf preparation failed: " .. tostring(reason))
            return false
        end
        LMION.log("Build", entry.spec.id .. " SpriteConfig prepared for leaf A construction")
    end

    return true
end

if Events ~= nil and Events.OnGameBoot ~= nil then
    Events.OnGameBoot.Add(Build.prepareVanillaLargeGateLeafConstruction)
end

return Build
