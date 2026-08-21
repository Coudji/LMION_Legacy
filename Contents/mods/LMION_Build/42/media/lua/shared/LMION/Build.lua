require "LMION/Core"

LMION.Build = LMION.Build or {}
local Build = LMION.Build

Build.ID = "LMION_Build"
Build.VERSION = "0.0.3-dev"
Build.Catalog = Build.Catalog or {}
Build.CatalogById = Build.CatalogById or {}

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
require "LMION/Build/Drafts"
LMION.log("Build", "loaded " .. Build.VERSION)
