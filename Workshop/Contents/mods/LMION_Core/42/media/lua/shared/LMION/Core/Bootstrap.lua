local Bootstrap = {}

local builtinContent = require "LMION/Core/BuiltinContent"
local hasRun = false


function Bootstrap.run(API)
    if hasRun then
        return false
    end

    API.registerContent(builtinContent)
    hasRun = true

    return true
end


return Bootstrap
