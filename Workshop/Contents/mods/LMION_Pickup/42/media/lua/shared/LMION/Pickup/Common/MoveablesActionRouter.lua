require "Moveables/ISMoveablesAction"

local MoveablesActionRouter = {}

local handlers = {}
local installed = false
local previousNew = nil
local previousComplete = nil


local function install()
    if installed then
        return
    end

    previousNew = ISMoveablesAction.new
    previousComplete = ISMoveablesAction.complete

    ISMoveablesAction.new = function(
        self,
        character,
        square,
        mode,
        origSpriteName,
        object,
        direction,
        item,
        moveCursor
    )
        for index = 1, #handlers do
            local handler = handlers[index]

            if handler.matchesNew(
                mode,
                item
            ) then
                local action = handler.createAction(
                    self,
                    character,
                    square,
                    mode,
                    origSpriteName,
                    object,
                    direction,
                    item,
                    moveCursor
                )

                if action ~= nil then
                    return action
                end

                break
            end
        end

        return previousNew(
            self,
            character,
            square,
            mode,
            origSpriteName,
            object,
            direction,
            item,
            moveCursor
        )
    end

    ISMoveablesAction.complete = function(self)
        for index = 1, #handlers do
            local handler = handlers[index]

            if handler.matchesComplete(self) then
                return handler.complete(self)
            end
        end

        return previousComplete(self)
    end

    installed = true
end


function MoveablesActionRouter.register(name, handler)
    if type(name) ~= "string" or name == "" or type(handler) ~= "table" then
        return false
    end

    if type(handler.matchesNew) ~= "function"
        or type(handler.createAction) ~= "function"
        or type(handler.matchesComplete) ~= "function"
        or type(handler.complete) ~= "function"
    then
        return false
    end

    for index = 1, #handlers do
        if handlers[index].name == name then
            return true
        end
    end

    handler.name = name
    table.insert(handlers, handler)
    install()
    return true
end


return MoveablesActionRouter
