LMION.Debug = LMION.Debug or {}
LMION.Debug.Inspect = LMION.Debug.Inspect or {}

local Options = LMION.Debug.Inspect.Options or {}
LMION.Debug.Inspect.Options = Options

-- Keep the current choice across reloads. New sessions default to the clean view.
if Options.fullDetails == nil then
    Options.fullDetails = false
end

function Options.isFullDetails()
    return Options.fullDetails == true
end

function Options.setFullDetails(enabled)
    Options.fullDetails = enabled == true
    return Options.fullDetails
end

function Options.toggleFullDetails()
    Options.fullDetails = not Options.isFullDetails()
    return Options.fullDetails
end

function Options.snapshot()
    return {
        fullDetails = Options.isFullDetails(),
    }
end

return Options
