require "LMION/Core"

LMION.Debug = LMION.Debug or {}

local Debug = LMION.Debug
Debug.Sections = Debug.Sections or {}

function Debug.isEnabled()
    return isDebugEnabled ~= nil and isDebugEnabled()
end

function Debug.registerInspector(id, priority, callback)
    if type(id) ~= "string" or id == "" then
        return false
    end

    if type(callback) ~= "function" then
        return false
    end

    -- Reload-friendly: same id replaces the previous section.
    Debug.Sections[id] = {
        id = id,
        priority = tonumber(priority) or 100,
        callback = callback,
    }

    return true
end

function Debug.unregisterInspector(id)
    Debug.Sections[id] = nil
end

function Debug.getOrderedInspectors()
    local result = {}

    for _, section in pairs(Debug.Sections) do
        result[#result + 1] = section
    end

    table.sort(result, function(a, b)
        if a.priority == b.priority then
            return a.id < b.id
        end

        return a.priority < b.priority
    end)

    return result
end

local Report = {}
Report.__index = Report

function Report:new(subject)
    local o = {
        subject = subject,
        lines = {},
    }

    setmetatable(o, self)
    return o
end

function Report:line(text)
    self.lines[#self.lines + 1] = tostring(text or "")
end

function Report:field(name, value)
    if value == nil then
        value = "<nil>"
    end

    self:line(tostring(name) .. " = " .. tostring(value))
end

function Report:section(name)
    if #self.lines > 0 then
        self:line("")
    end

    self:line("--- " .. tostring(name) .. " ---")
end

function Report:toText()
    return table.concat(self.lines, "\n")
end

Debug.Report = Report

function Debug.newReport(subject)
    return Report:new(subject)
end

return Debug
