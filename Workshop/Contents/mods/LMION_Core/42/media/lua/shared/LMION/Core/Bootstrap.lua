local Bootstrap = {}

local builtinContent = require "LMION/Core/BuiltinContent"


function Bootstrap.run(API)
    API.registerContent(builtinContent)
end


return Bootstrap
