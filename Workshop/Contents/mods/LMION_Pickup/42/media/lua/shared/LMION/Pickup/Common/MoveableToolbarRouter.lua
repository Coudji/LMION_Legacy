require "BuildingObjects/ISMoveableCursor"

local MoveableToolbarRouter = {}

local providers = {}
local installed = false
local previousGetInventoryObjectList = nil
local previousCreate = nil


local function getProvider(name)
    for index = 1, #providers do
        if providers[index].name == name then
            return providers[index]
        end
    end

    return nil
end


local function getSelectedEntry(cursor)
    local objects = cursor.objectListCache

    if type(objects) ~= "table" then
        return nil
    end

    if cursor.objectIndex < 1 or cursor.objectIndex > #objects then
        return nil
    end

    return objects[cursor.objectIndex]
end


local function resolveInventoryItem(cursor, entry)
    local item = entry and entry.object or nil
    local itemId = item and item.getID ~= nil and item:getID() or nil
    local player = getSpecificPlayer(cursor.player)
    local inventory = player and player:getInventory() or nil

    if inventory == nil or itemId == nil then
        return nil, nil
    end

    return inventory:getItemById(itemId), inventory
end


local function install()
    if installed then
        return
    end

    previousGetInventoryObjectList = ISMoveableCursor.getInventoryObjectList
    previousCreate = ISMoveableCursor.create

    ISMoveableCursor.getInventoryObjectList = function(self)
        local objects = previousGetInventoryObjectList(self)

        for index = 1, #providers do
            local provider = providers[index]
            local entries = provider.getEntries(self)

            if type(entries) == "table" then
                for entryIndex = 1, #entries do
                    local entry = entries[entryIndex]
                    if type(entry) == "table"
                        and entry.object ~= nil
                        and entry.moveProps ~= nil
                    then
                        entry.lmionToolbarProvider = provider.name
                        objects[#objects + 1] = entry
                    end
                end
            end
        end

        return objects
    end

    ISMoveableCursor.create = function(self, x, y, z, north, sprite)
        local mode = ISMoveableCursor.mode and ISMoveableCursor.mode[self.player] or nil
        local entry = mode == "place" and getSelectedEntry(self) or nil
        local providerName = entry and entry.lmionToolbarProvider or nil

        if providerName == nil or getProvider(providerName) == nil then
            return previousCreate(self, x, y, z, north, sprite)
        end

        local item, inventory = resolveInventoryItem(self, entry)
        local moveProps = self.currentMoveProps

        if item == nil or inventory == nil or moveProps == nil then
            return previousCreate(self, x, y, z, north, sprite)
        end

        local previousFind = rawget(moveProps, "findInInventory")

        moveProps.findInInventory = function()
            return item, inventory
        end

        local ok, result = pcall(
            previousCreate,
            self,
            x,
            y,
            z,
            north,
            sprite
        )

        moveProps.findInInventory = previousFind

        if not ok then
            error(result)
        end

        return result
    end

    installed = true
end


function MoveableToolbarRouter.register(name, provider)
    if type(name) ~= "string"
        or name == ""
        or type(provider) ~= "table"
        or type(provider.getEntries) ~= "function"
    then
        return false
    end

    if getProvider(name) ~= nil then
        return true
    end

    provider.name = name
    providers[#providers + 1] = provider
    install()
    return true
end


return MoveableToolbarRouter
