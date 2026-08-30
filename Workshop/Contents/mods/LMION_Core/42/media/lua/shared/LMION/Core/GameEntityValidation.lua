local EntityIndex = require "LMION/Core/EntityIndex"

local GameEntityValidation = {}


function GameEntityValidation.validate()
    if ScriptManager == nil or ScriptManager.instance == nil then
        return {
            available = false,
            error = "ScriptManager.instance is unavailable",
        }
    end

    local entityIds = EntityIndex.getEntityIds()
    local missing = {}
    local found = 0

    for index = 1, #entityIds do
        local entityId = entityIds[index]
        local ok, script = pcall(function()
            return ScriptManager.instance:getGameEntityScript(entityId)
        end)

        if not ok then
            return {
                available = false,
                error = "getGameEntityScript failed for "
                    .. entityId
                    .. ": "
                    .. tostring(script),
            }
        end

        if script == nil then
            missing[#missing + 1] = {
                entityId = entityId,
                definitionId = EntityIndex.getDefinitionId(entityId),
            }
        else
            found = found + 1
        end
    end

    return {
        available = true,
        total = #entityIds,
        found = found,
        missing = missing,
    }
end


return GameEntityValidation
