require "LMION/Debug/Registry"
require "LMION/Debug/Showroom/Profiles"

LMION.Debug.Showroom = LMION.Debug.Showroom or {}

local Profiles = LMION.Debug.Showroom.Profiles
local Layout = LMION.Debug.Showroom.Layout or {}
LMION.Debug.Showroom.Layout = Layout

local function cloneFamily(family)
    local copy = {}
    for key, value in pairs(family) do
        copy[key] = value
    end
    return copy
end

local function profileFor(family)
    if family == nil or family.anchor == nil then
        return nil
    end
    return Profiles.get(family.anchor.name)
end

local function normalizeGarage(family)
    if family.kind ~= "garage" or #family.parts ~= 4 then
        return family
    end

    local copy = cloneFamily(family)
    copy.parts = {
        family.parts[1],
        family.parts[2],
        family.parts[4],
    }
    return copy
end

function Layout.prepare(families)
    local byAnchor = {}
    local consumed = {}
    local prepared = {}

    for _, family in ipairs(families or {}) do
        if family.anchor ~= nil then
            byAnchor[family.anchor.name] = family
        end
    end

    for _, source in ipairs(families or {}) do
        local anchorName = source.anchor ~= nil and source.anchor.name or nil

        if anchorName ~= nil and not consumed[anchorName] then
            local profile = profileFor(source)

            if profile ~= nil and profile.kind == "paired" and profile.side == "left" then
                local partner = byAnchor[profile.pair]

                if partner ~= nil then
                    local paired = cloneFamily(source)
                    paired.kind = "paired"
                    paired.parts = { source.anchor, partner.anchor }
                    paired.profile = profile
                    paired.partnerProfile = profileFor(partner)
                    paired.displayName = profile.displayName
                    prepared[#prepared + 1] = paired
                    consumed[anchorName] = true
                    consumed[profile.pair] = true
                else
                    local copy = normalizeGarage(source)
                    copy.kind = profile.kind
                    copy.profile = profile
                    copy.displayName = profile.displayName
                    prepared[#prepared + 1] = copy
                    consumed[anchorName] = true
                end
            elseif profile ~= nil and profile.kind == "paired" and profile.side == "right" then
                if not consumed[anchorName] then
                    local copy = normalizeGarage(source)
                    copy.kind = "paired-orphan"
                    copy.profile = profile
                    copy.displayName = profile.displayName
                    prepared[#prepared + 1] = copy
                    consumed[anchorName] = true
                end
            else
                local copy = normalizeGarage(source)
                if profile ~= nil then
                    copy.kind = profile.kind or copy.kind
                    copy.profile = profile
                    copy.displayName = profile.displayName
                else
                    copy.displayName = Profiles.getName(anchorName)
                end
                prepared[#prepared + 1] = copy
                consumed[anchorName] = true
            end
        end
    end

    return prepared
end

function Layout.getFrameMode(family)
    if family ~= nil and family.profile ~= nil and family.profile.frame ~= nil then
        return family.profile.frame
    end
    return "standard"
end

function Layout.getDisplayName(family)
    if family == nil then
        return nil
    end
    if family.displayName ~= nil then
        return family.displayName
    end
    if family.anchor ~= nil then
        return Profiles.getName(family.anchor.name)
    end
    return nil
end

return Layout
