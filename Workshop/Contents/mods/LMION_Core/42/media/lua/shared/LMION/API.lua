local Bootstrap = require "LMION/Core/Bootstrap"
local Registry = require "LMION/Core/Registry"
local Resolver = require "LMION/Core/Resolver"
local Validation = require "LMION/Core/Validation"

local API = {}


local function registerList(list, register)
    if list == nil then
        return
    end

    for index = 1, #list do
        register(list[index])
    end
end


function API.registerDefault(definitionDefault)
    Validation.definitionDefault(definitionDefault)

    return Registry.registerDefault(definitionDefault)
end


function API.registerDefinition(definition)
    Validation.definition(definition)

    return Registry.registerDefinition(definition)
end


function API.registerExtension(extension)
    Validation.extension(extension)

    return Registry.registerExtension(extension)
end


function API.registerContent(content)
    Validation.content(content)

    registerList(content.defaults, API.registerDefault)
    registerList(content.definitions, API.registerDefinition)
    registerList(content.extensions, API.registerExtension)
end


function API.getEffectiveDefault(defaultId)
    return Resolver.resolveDefault(defaultId)
end


function API.getEffectiveDefinition(definitionId)
    return Resolver.resolveDefinition(definitionId)
end


Bootstrap.run(API)

return API
