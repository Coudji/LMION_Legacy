require "LMION/Debug/Registry"
require "LMION/Debug/Util/Safe"

LMION.Debug.Inspect = LMION.Debug.Inspect or {}
LMION.Debug.Inspect.ObjectInspector = LMION.Debug.Inspect.ObjectInspector or {}

local Debug = LMION.Debug
local Safe = Debug.Util.Safe
local ObjectInspector = Debug.Inspect.ObjectInspector

function ObjectInspector.inspect(object)
    if object == nil then
        local report = Debug.newReport(nil)
        report:section("Inspector")
        report:line("<nil object>")
        return report
    end

    local report = Debug.newReport(object)
    local sections = Debug.getOrderedInspectors()

    for _, section in ipairs(sections) do
        local ok, err = pcall(section.callback, object, report)

        if not ok then
            report:section("Inspector error")
            report:field("section", section.id)
            report:field("error", err)
        end
    end

    return report
end

function ObjectInspector.inspectMany(objects)
    local chunks = {}
    local count = #objects

    if count == 0 then
        return "<no objects selected>"
    end

    for i, object in ipairs(objects) do
        local square = nil

        if object ~= nil then
            square = Safe.value("object.getSquare", function()
                return object:getSquare()
            end, nil)
        end

        chunks[#chunks + 1] = "=== Object "
            .. tostring(i)
            .. " / "
            .. tostring(count)
            .. " | square "
            .. Safe.squareString(square)
            .. " | "
            .. Safe.objectLabel(object)
            .. " ===\n"
            .. ObjectInspector.inspect(object):toText()
    end

    return table.concat(chunks, "\n\n")
end

return ObjectInspector
