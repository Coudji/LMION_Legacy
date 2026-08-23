require "Moveables/ISMoveableSpriteProps"

LMION = LMION or {}
LMION.Debug = LMION.Debug or {}

local Debug = LMION.Debug
Debug.MoveablesTrace = Debug.MoveablesTrace or {}
local Trace = Debug.MoveablesTrace

local function spriteName(moveProps)
    return moveProps and moveProps.spriteName or "<nil>"
end

local function objectLabel(object)
    if object == nil then
        return "<nil>"
    end

    local sprite = object:getSprite()
    local name = sprite and sprite:getName() or "<no sprite>"
    local square = object:getSquare()
    local pos = square and (tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ())) or "<no square>"
    return tostring(object) .. " | " .. name .. " @ " .. pos
end

local function inventoryCount(character)
    if character == nil or character:getInventory() == nil then
        return -1
    end
    return character:getInventory():getItems():size()
end

local function itemSavedHealth(item)
    if item == nil or not item:hasModData() then
        return nil
    end
    return item:getModData().lmionDoorHealth
end

local function doorHealthOnSquare(square)
    if square == nil then
        return "<nil>"
    end

    local objects = square:getSpecialObjects()
    for i = objects:size() - 1, 0, -1 do
        local object = objects:get(i)
        if instanceof(object, "IsoDoor") then
            return tostring(object:getHealth()) .. "/" .. tostring(object:getMaxHealth())
        end
    end

    return "<none>"
end

local function trace(message)
    print("[LMION:Debug:Moveables] " .. tostring(message))
end

if Trace._originalPickUpMoveableViaCursor == nil then
    Trace._originalPickUpMoveableViaCursor = ISMoveableSpriteProps.pickUpMoveableViaCursor
    ISMoveableSpriteProps.pickUpMoveableViaCursor = function(self, character, square, origSpriteName, moveCursor)
        trace("viaCursor BEGIN sprite=" .. spriteName(self)
            .. " orig=" .. tostring(origSpriteName)
            .. " inventory=" .. tostring(inventoryCount(character)))
        local result = Trace._originalPickUpMoveableViaCursor(self, character, square, origSpriteName, moveCursor)
        trace("viaCursor END sprite=" .. spriteName(self)
            .. " result=" .. tostring(result)
            .. " inventory=" .. tostring(inventoryCount(character)))
        return result
    end
end

if Trace._originalPickUpMoveable == nil then
    Trace._originalPickUpMoveable = ISMoveableSpriteProps.pickUpMoveable
    ISMoveableSpriteProps.pickUpMoveable = function(self, character, square, createItem, forceAllow)
        local foundObject = nil
        if square ~= nil and self ~= nil and self.spriteName ~= nil and self.findOnSquare ~= nil then
            foundObject = self:findOnSquare(square, self.spriteName)
        end

        trace("pickup BEGIN sprite=" .. spriteName(self)
            .. " found=" .. objectLabel(foundObject)
            .. " foundHealth=" .. tostring(foundObject and foundObject:getHealth() or "<nil>")
            .. " createItem=" .. tostring(createItem)
            .. " forceAllow=" .. tostring(forceAllow)
            .. " inventory=" .. tostring(inventoryCount(character)))
        local result = Trace._originalPickUpMoveable(self, character, square, createItem, forceAllow)
        trace("pickup END sprite=" .. spriteName(self)
            .. " result=" .. tostring(result)
            .. " resultSavedHealth=" .. tostring(itemSavedHealth(result))
            .. " inventory=" .. tostring(inventoryCount(character)))
        return result
    end
end

if Trace._originalPickUpMoveableInternal == nil then
    Trace._originalPickUpMoveableInternal = ISMoveableSpriteProps.pickUpMoveableInternal
    ISMoveableSpriteProps.pickUpMoveableInternal = function(self, character, square, object, sprInstance, targetSpriteName, createItem, rotating)
        local testItem = self:instanceItem(targetSpriteName)
        trace("internal BEGIN sprite=" .. spriteName(self)
            .. " target=" .. tostring(targetSpriteName)
            .. " object=" .. objectLabel(object)
            .. " objectHealth=" .. tostring(object and object:getHealth() or "<nil>")
            .. " item=" .. tostring(testItem)
            .. " itemType=" .. tostring(testItem and testItem:getFullType() or "<nil>")
            .. " testItemSavedHealth=" .. tostring(itemSavedHealth(testItem))
            .. " createItem=" .. tostring(createItem)
            .. " rotating=" .. tostring(rotating)
            .. " inventory=" .. tostring(inventoryCount(character)))
        local result = Trace._originalPickUpMoveableInternal(self, character, square, object, sprInstance, targetSpriteName, createItem, rotating)
        trace("internal END sprite=" .. spriteName(self)
            .. " result=" .. tostring(result)
            .. " resultSavedHealth=" .. tostring(itemSavedHealth(result))
            .. " inventory=" .. tostring(inventoryCount(character)))
        return result
    end
end

if Trace._originalPlaceMoveableInternal == nil then
    Trace._originalPlaceMoveableInternal = ISMoveableSpriteProps.placeMoveableInternal
    ISMoveableSpriteProps.placeMoveableInternal = function(self, square, item, targetSpriteName)
        trace("placeInternal BEGIN sprite=" .. spriteName(self)
            .. " target=" .. tostring(targetSpriteName)
            .. " item=" .. tostring(item)
            .. " itemType=" .. tostring(item and item:getFullType() or "<nil>")
            .. " savedHealth=" .. tostring(itemSavedHealth(item))
            .. " doorBefore=" .. doorHealthOnSquare(square))
        local result = Trace._originalPlaceMoveableInternal(self, square, item, targetSpriteName)
        trace("placeInternal END sprite=" .. spriteName(self)
            .. " result=" .. tostring(result)
            .. " savedHealth=" .. tostring(itemSavedHealth(item))
            .. " doorAfter=" .. doorHealthOnSquare(square))
        return result
    end
end

trace("runtime pickup tracing enabled")

return Trace
