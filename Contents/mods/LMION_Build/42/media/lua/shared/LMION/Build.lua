require "LMION/Core"

LMION.Build = LMION.Build or {}
local Build = LMION.Build

Build.ID = "LMION_Build"
Build.VERSION = "0.0.5-dev"

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
        left = {
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
        left = {
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
        left = {
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

local function cloneProfile(source, id, fallbackName)
    if source == nil then
        return nil
    end

    return {
        id = id,
        fallbackName = fallbackName,
        class = source.class,
        frame = source.frame,
        requiresFrame = source.requiresFrame,
        durability = source.durability,
        materials = source.materials,
        sounds = source.sounds,
    }
end

local function installSplitProfiles()
    if LMION.Doors == nil or LMION.Doors.Profiles == nil then
        return false
    end

    local profiles = LMION.Doors.Profiles
    local doubleDoor = profiles.DoubleDoor or profiles.DoubleDoorRight
    local doubleWireGate = profiles.DoubleWireGate or profiles.DoubleWireGateRight
    local doubleFenceGate = profiles.DoubleFenceGate or profiles.DoubleFenceGateRight
    local largeFarmGate = profiles.LargeFarmGate or profiles.LargeFarmGateLeft or profiles.LargeFarmGateRight
    local largeHardenedWoodenGate = profiles.LargeHardenedWoodenGate or profiles.LargeHardenedWoodenGateLeft or profiles.LargeHardenedWoodenGateRight
    local largeWroughtIronGate = profiles.LargeWroughtIronGate or profiles.LargeWroughtIronGateLeft or profiles.LargeWroughtIronGateRight

    if doubleDoor ~= nil then
        profiles.DoubleDoor = cloneProfile(doubleDoor, "DoubleDoor", "Large Wooden Gate - Left Leaf")
        profiles.DoubleDoorRight = cloneProfile(doubleDoor, "DoubleDoorRight", "Large Wooden Gate - Right Leaf")
    end

    if doubleWireGate ~= nil then
        profiles.DoubleWireGate = cloneProfile(doubleWireGate, "DoubleWireGate", "Large Chain-Link Gate - Left Leaf")
        profiles.DoubleWireGateRight = cloneProfile(doubleWireGate, "DoubleWireGateRight", "Large Chain-Link Gate - Right Leaf")
    end

    if doubleFenceGate ~= nil then
        profiles.DoubleFenceGate = cloneProfile(doubleFenceGate, "DoubleFenceGate", "Large Scrap Metal Gate - Left Leaf")
        profiles.DoubleFenceGateRight = cloneProfile(doubleFenceGate, "DoubleFenceGateRight", "Large Scrap Metal Gate - Right Leaf")
    end

    if largeFarmGate ~= nil then
        profiles.LargeFarmGateLeft = cloneProfile(largeFarmGate, "LargeFarmGateLeft", "Large Farm Gate - Left Leaf")
        profiles.LargeFarmGateRight = cloneProfile(largeFarmGate, "LargeFarmGateRight", "Large Farm Gate - Right Leaf")
        profiles.LargeFarmGate = nil
    end

    if largeHardenedWoodenGate ~= nil then
        profiles.LargeHardenedWoodenGateLeft = cloneProfile(largeHardenedWoodenGate, "LargeHardenedWoodenGateLeft", "Large Hardened Wooden Gate - Left Leaf")
        profiles.LargeHardenedWoodenGateRight = cloneProfile(largeHardenedWoodenGate, "LargeHardenedWoodenGateRight", "Large Hardened Wooden Gate - Right Leaf")
        profiles.LargeHardenedWoodenGate = nil
    end

    if largeWroughtIronGate ~= nil then
        profiles.LargeWroughtIronGateLeft = cloneProfile(largeWroughtIronGate, "LargeWroughtIronGateLeft", "Large Wrought Iron Gate - Left Leaf")
        profiles.LargeWroughtIronGateRight = cloneProfile(largeWroughtIronGate, "LargeWroughtIronGateRight", "Large Wrought Iron Gate - Right Leaf")
        profiles.LargeWroughtIronGate = nil
    end

    return true
end

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

local function reloadAsLeftLeaf(spec, script, spriteConfig)
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

    local expectedLeft = makeSet(spec.left)
    local tileNames = reloaded:getAllTileNames()
    if tileNames:size() ~= #spec.left or countKnown(tileNames, expectedLeft) ~= #spec.left then
        return false, "left-leaf verification failed"
    end

    return true, nil
end

function Build.prepareSplitVanillaLargeGates()
    if not installSplitProfiles() then
        LMION.error("Build", "unable to install split large-gate profiles")
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
            LMION.error("Build", "refusing " .. spec.id .. " split: " .. tostring(reason))
            return false
        end

        prepared[#prepared + 1] = {
            spec = spec,
            script = script,
            spriteConfig = spriteConfig,
        }
    end

    for _, entry in ipairs(prepared) do
        local ok, reason = reloadAsLeftLeaf(entry.spec, entry.script, entry.spriteConfig)
        if not ok then
            LMION.error("Build", entry.spec.id .. " split failed: " .. tostring(reason))
            return false
        end
        LMION.log("Build", entry.spec.id .. " SpriteConfig reloaded as left leaf")
    end

    return true
end

installSplitProfiles()

if Events ~= nil and Events.OnGameBoot ~= nil then
    Events.OnGameBoot.Add(Build.prepareSplitVanillaLargeGates)
end

LMION.registerModule(Build.ID, Build)
LMION.log("Build", "loaded " .. Build.VERSION)

return Build
