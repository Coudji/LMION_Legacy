require "LMION/Core"

if isDebugEnabled ~= nil and not isDebugEnabled() then
    return
end

LMION.DebugServerReload = LMION.DebugServerReload or {}
local ReloadServer = LMION.DebugServerReload

local NET_MODULE = "LMION_Debug"
local NET_COMMAND_RELOAD = "ReloadAllLua"
local NAMESPACE_TOKEN = "/LMION/"
local SELF_SUFFIX = "/LMION/Debug/ReloadServer.lua"

local function normalize(path)
    if path == nil then
        return nil
    end

    return tostring(path):gsub("\\", "/")
end

local function isLMIONLua(path)
    local normalized = normalize(path)

    if normalized == nil then
        return false
    end

    return ("/" .. normalized):find(NAMESPACE_TOKEN, 1, true) ~= nil
end

local function isSelf(path)
    local normalized = normalize(path)

    if normalized == nil then
        return false
    end

    return ("/" .. normalized):sub(-#SELF_SUFFIX) == SELF_SUFFIX
end

local function canReload(player)
    if player == nil then
        return false
    end

    if player.isAccessLevel ~= nil then
        return player:isAccessLevel("admin")
            or player:isAccessLevel("moderator")
            or player:isAccessLevel("overseer")
    end

    local level = player.getAccessLevel ~= nil and player:getAccessLevel() or ""
    return level == "admin" or level == "moderator" or level == "overseer"
end

local function collectLoadedLMIONFiles()
    local files = {}
    local seen = {}
    local selfFile = nil

    if getLoadedLuaCount == nil or getLoadedLua == nil then
        return files, selfFile
    end

    local count = getLoadedLuaCount()

    for i = 0, count - 1 do
        local path = getLoadedLua(i)

        if path ~= nil and isLMIONLua(path) and not seen[path] then
            seen[path] = true

            if isSelf(path) then
                selfFile = path
            else
                files[#files + 1] = path
            end
        end
    end

    return files, selfFile
end

local function reloadAllServerLua(player)
    if reloadLuaFile == nil then
        LMION.warn("ReloadServer", "reloadLuaFile() is unavailable on server")
        return false
    end

    local files, selfFile = collectLoadedLMIONFiles()
    local total = #files + (selfFile ~= nil and 1 or 0)

    LMION.log(
        "ReloadServer",
        "reloading " .. tostring(total) .. " loaded LMION Lua files on server"
    )

    for _, path in ipairs(files) do
        LMION.log("ReloadServer", "-> " .. tostring(path))
        reloadLuaFile(path)
    end

    if selfFile ~= nil then
        LMION.log("ReloadServer", "-> " .. tostring(selfFile))
        reloadLuaFile(selfFile)
    end

    LMION.log("ReloadServer", "server LMION Lua reload complete")

    if sendServerCommand ~= nil and player ~= nil then
        sendServerCommand(player, NET_MODULE, "ReloadComplete", { count = total })
    end

    return true
end

function ReloadServer.onClientCommand(module, command, player, args)
    if module ~= NET_MODULE or command ~= NET_COMMAND_RELOAD then
        return
    end

    if not canReload(player) then
        LMION.warn(
            "ReloadServer",
            "reload request denied for " .. tostring(player ~= nil and player:getUsername() or "<unknown>")
        )

        if sendServerCommand ~= nil and player ~= nil then
            sendServerCommand(player, NET_MODULE, "ReloadDenied", {})
        end

        return
    end

    reloadAllServerLua(player)
end

if ReloadServer._clientCommandHandler ~= nil then
    Events.OnClientCommand.Remove(ReloadServer._clientCommandHandler)
end

ReloadServer._clientCommandHandler = ReloadServer.onClientCommand
Events.OnClientCommand.Add(ReloadServer._clientCommandHandler)

LMION.log("ReloadServer", "server reload endpoint ready")

return ReloadServer
