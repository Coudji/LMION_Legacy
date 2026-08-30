local ToolAdapter = {}

local installed = false

local TOOL_NAMES = {
    ["base:screwdriver"] = {
        Woodwork = "Screwdriver",
        MetalWelding = "LMIONMetalScrewdriver",
    },
    ["base:crowbar"] = {
        Woodwork = "Crowbar",
        MetalWelding = "LMIONMetalCrowbar",
    },
    ["base:hammer"] = {
        Woodwork = "Hammer",
        MetalWelding = "LMIONMetalHammer",
    },
}


local function getSingleSkill(skill)
    if type(skill) ~= "table" then
        return nil, nil, "pickup.skill must be a table"
    end

    local skillName = nil
    local level = nil
    local count = 0

    for name, value in pairs(skill) do
        count = count + 1
        skillName = name
        level = tonumber(value)
    end

    if count ~= 1
        or type(skillName) ~= "string"
        or skillName == ""
        or level == nil
        or level < 0
    then
        return nil, nil, "pickup.skill must contain exactly one valid skill"
    end

    if skillName ~= "Woodwork" and skillName ~= "MetalWelding" then
        return nil, nil, "unsupported pickup skill " .. tostring(skillName)
    end

    return skillName, level, nil
end


local function resolveTool(tools, skillName, label)
    if tools == nil then
        return nil, nil
    end

    if type(tools) ~= "table" then
        return nil, label .. " tools must be a table"
    end

    if #tools == 0 then
        return nil, nil
    end

    if #tools ~= 1 then
        return nil, label .. " currently supports exactly one tool"
    end

    local tool = tools[1]
    local tag = type(tool) == "table" and tool.tag or nil

    if type(tag) ~= "string" or tag == "" then
        return nil, label .. " tool must use a semantic tag"
    end

    local bySkill = TOOL_NAMES[string.lower(tag)]
    local toolName = bySkill and bySkill[skillName] or nil

    if toolName == nil then
        return nil,
            "unsupported "
                .. label
                .. " tool/skill combination "
                .. tostring(tag)
                .. " + "
                .. tostring(skillName)
    end

    return toolName, nil
end


function ToolAdapter.resolve(definition)
    local pickup = definition and definition.pickup or nil
    local replacement = definition and definition.replacement or nil

    if type(pickup) ~= "table" or type(replacement) ~= "table" then
        return nil, "pickup and replacement contracts are required"
    end

    local skillName, level, skillError = getSingleSkill(pickup.skill)
    if skillError ~= nil then
        return nil, skillError
    end

    local pickUpTool, pickUpError = resolveTool(
        pickup.tools,
        skillName,
        "pickup"
    )

    if pickUpError ~= nil then
        return nil, pickUpError
    end

    local placeTool, placeError = resolveTool(
        replacement.tools,
        skillName,
        "replacement"
    )

    if placeError ~= nil then
        return nil, placeError
    end

    return {
        skillName = skillName,
        level = level,
        pickUpTool = pickUpTool,
        placeTool = placeTool,
    }, nil
end


function ToolAdapter.install()
    if installed then
        return
    end

    require "Moveables/ISMoveableDefinitions"

    local definitions = ISMoveableDefinitions:getInstance()

    definitions.removeToolDefinition("LMIONMetalScrewdriver")
    definitions.addToolDefinition(
        "LMIONMetalScrewdriver",
        { "Base.Screwdriver" },
        Perks.MetalWelding,
        100,
        "Dismantle",
        true
    )

    definitions.removeToolDefinition("LMIONMetalCrowbar")
    definitions.addToolDefinition(
        "LMIONMetalCrowbar",
        { "Tag.Crowbar", "Crowbar" },
        Perks.MetalWelding,
        100,
        "Dismantle",
        true
    )

    definitions.removeToolDefinition("LMIONMetalHammer")
    definitions.addToolDefinition(
        "LMIONMetalHammer",
        { "Base.Hammer" },
        Perks.MetalWelding,
        100,
        "Dismantle",
        true
    )

    installed = true
end


return ToolAdapter
