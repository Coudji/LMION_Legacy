--[[
    Let Me In... Or Not - Build
    Construction/crafting entry points for opening families.

    The current catalog is intentionally menu/research data.
    Canonical opening-family definitions shared with Pickup belong in Core.
]]

require "LMION/Core"

LMION.Build = LMION.Build or {}
local Build = LMION.Build

Build.ID = "LMION_Build"
Build.VERSION = "0.0.3-dev"
Build.Catalog = Build.Catalog or {}
Build.CatalogById = Build.CatalogById or {}

local whiteDoorInjected = false

local function componentNames(entity)
    local names = {}
    local components = entity and entity:getComponentScripts()
    if components then
        for i = 0, components:size() - 1 do
            local component = components:get(i)
            names[#names + 1] = tostring(component:getName())
        end
    end
    return table.concat(names, ", ")
end

local function tryInjectWhiteWoodenDoorBuildComponents(phase)
    if whiteDoorInjected then
        return true
    end

    local entity = ScriptManager.instance:getGameEntityScript("Base.WhiteWoodenDoor")
    if not entity then
        LMION.log("Build", "WhiteWoodenDoor unavailable at " .. tostring(phase))
        return false
    end

    LMION.log("Build", "WhiteWoodenDoor found at " .. tostring(phase)
        .. "; before injection: " .. componentNames(entity))

    local ok, err = pcall(function()
        entity:Load("WhiteWoodenDoor", [[
            entity WhiteWoodenDoor
            {
                component UiConfig
                {
                    xuiSkin = default,
                    entityStyle = ES_WhiteWoodenDoor,
                    uiEnabled = false,
                }

                component CraftRecipe
                {
                    timedAction = BuildWallHammer,
                    time = 20,
                    category = LMION,
                    SkillRequired = Woodwork:1,
                    xpAward = Woodwork:1,

                    inputs
                    {
                        item 1 tags[base:hammer] mode:keep flags[Prop1;MayDegradeVeryLight],
                        item 1 [Base.Plank],
                    }
                }
            }
        ]])
    end)

    if not ok then
        LMION.error("Build", "WhiteWoodenDoor injection failed at " .. tostring(phase)
            .. ": " .. tostring(err))
        return false
    end

    whiteDoorInjected = true
    LMION.log("Build", "WhiteWoodenDoor after injection at " .. tostring(phase)
        .. ": " .. componentNames(entity))
    return true
end

-- Probe several lifecycle points. The first point where the Core entity becomes
-- visible performs the injection; later callbacks become no-ops.
tryInjectWhiteWoodenDoorBuildComponents("Build.lua load")

if Events.OnLoadedTileDefinitions then
    Events.OnLoadedTileDefinitions.Add(function()
        tryInjectWhiteWoodenDoorBuildComponents("OnLoadedTileDefinitions")
    end)
end

if Events.OnLoadedMapZones then
    Events.OnLoadedMapZones.Add(function()
        tryInjectWhiteWoodenDoorBuildComponents("OnLoadedMapZones")
    end)
end

if Events.OnGameStart then
    Events.OnGameStart.Add(function()
        tryInjectWhiteWoodenDoorBuildComponents("OnGameStart")
    end)
end

function Build.registerCatalogEntry(entry)
    if type(entry) ~= "table" or type(entry.id) ~= "string" or entry.id == "" then
        LMION.error("Build", "registerCatalogEntry(): invalid entry")
        return false
    end

    if Build.CatalogById[entry.id] ~= nil then
        for i = #Build.Catalog, 1, -1 do
            if Build.Catalog[i].id == entry.id then
                table.remove(Build.Catalog, i)
            end
        end
    end

    Build.CatalogById[entry.id] = entry
    Build.Catalog[#Build.Catalog + 1] = entry

    table.sort(Build.Catalog, function(a, b)
        return (a.index or 999999) < (b.index or 999999)
    end)

    return true
end

function Build.getCatalogEntry(id)
    return Build.CatalogById[id]
end

function Build.getCatalogEntries()
    return Build.Catalog
end

function Build.getCatalogCount()
    return #Build.Catalog
end

LMION.registerModule(Build.ID, Build)
LMION.log("Build", "loaded " .. Build.VERSION)
