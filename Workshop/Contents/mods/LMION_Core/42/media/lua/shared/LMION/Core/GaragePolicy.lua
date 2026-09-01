local GaragePolicy = {}

local DEFAULT_MAX_LENGTH = 6
local MIN_CONFIGURED_MAX_LENGTH = 3


local function getSandboxOptions()
    local root = SandboxVars
    return type(root) == "table" and root.LMION_Core or nil
end


function GaragePolicy.getMaxLength()
    local options = getSandboxOptions()

    if options ~= nil and options.UnlimitedGarageWidth == true then
        return nil
    end

    local maximum = options and tonumber(options.GarageMaxLength) or nil
    maximum = math.floor(maximum or DEFAULT_MAX_LENGTH)

    return math.max(MIN_CONFIGURED_MAX_LENGTH, maximum)
end


function GaragePolicy.isLengthAllowed(length)
    length = tonumber(length)
    if length == nil then
        return false
    end

    length = math.floor(length)
    if length < 2 then
        return false
    end

    local maximum = GaragePolicy.getMaxLength()
    return maximum == nil or length <= maximum
end


return GaragePolicy
