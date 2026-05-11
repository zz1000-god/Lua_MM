-- modules/admin_cmd.lua

-- =====================
-- lua_who
-- =====================
local function CmdWho(id, args)
  ClientPrint(id, print_console, "=== Players on server ===")
  ClientPrint(id, print_console, string.format(" %-2s  %-20s %-20s %-6s %s", "#", "name", "authid", "userid", "flags"))

  for i = 1, 32 do
    local name = GetPlayerName(i)
    if name and name ~= "" then
      local authid = GetPlayerAuthId(i) or "unknown"
      local userid = GetPlayerUserId(i) or 0
      local flags   = Auth.GetFlagsString(i)
      ClientPrint(id, print_console, string.format(" %-2d  %-20s %-20s %-6d %s", i, name, authid, userid, flags))
    end
  end
end

-- =====================
-- lua_nick
-- =====================
local function CmdNick(id, args)
  local target, newNick = string.match(args, "^%s*(%S+)%s+(.-)%s*$")

  if not target or not newNick or newNick == "" then
    ClientPrint(id, print_console, "[LUA] Usage: lua_nick <name or #userid> <newnick>")
    return
  end

  local targetId = FindPlayer(target)
  if not targetId then
    ClientPrint(id, print_console, "[LUA] Player not found: " .. target)
    return
  end

  local oldName = GetPlayerName(targetId) or "?"
  local adminName = GetPlayerName(id) or "Console"

  ClientCommand(targetId, "name \"" .. newNick .. "\"")

  ClientPrint(0, print_chat, adminName .. " changed " .. oldName .. "'s nick to " .. newNick)
  ServerPrint(string.format("[Admin] %s changed nick \"%s\" -> \"%s\"", adminName, oldName, newNick))
end

-- =====================
-- lua_cvar
-- =====================
local function CmdCvar(id, args)
  local cvarName, cvarValue = string.match(args, "^%s*(%S+)%s*(.-)%s*$")

  if not cvarName or cvarName == "" then
    ClientPrint(id, print_console, "[LUA] Usage: lua_cvar <cvar> [value]")
    return
  end

  local adminName = GetPlayerName(id) or "Console"

  if not cvarValue or cvarValue == "" then
    local val = GetCvarString(cvarName)
    ClientPrint(id, print_console, string.format("[LUA] %s = \"%s\"", cvarName, val))
  else
    SetCvarString(cvarName, cvarValue)
    ClientPrint(id, print_console, string.format("[LUA] %s changed to \"%s\"", cvarName, cvarValue))
    ClientPrint(0, print_chat, adminName .. " set " .. cvarName .. " to " .. cvarValue)
    ServerPrint(string.format("[Admin] %s set cvar \"%s\" = \"%s\"", adminName, cvarName, cvarValue))
  end
end

-- =====================
-- lua_cfg
-- =====================
local function CmdCfg(id, args)
  local fileName = string.match(args, "^%s*(.-)%s*$")

  if not fileName or fileName == "" then
    ClientPrint(id, print_console, "[LUA] Usage: lua_cfg <filename>")
    return
  end

  local file = io.open(fileName, "r")
  if not file then
    file = io.open("valve/" .. fileName, "r")
    if not file then
      ClientPrint(id, print_console, "[LUA] File not found: " .. fileName)
      return
    end
  end
  file:close()

  local adminName = GetPlayerName(id) or "Console"

  ClientPrint(id, print_console, "[LUA] Executing: " .. fileName)
  ClientPrint(0, print_chat, adminName .. " executed config: " .. fileName)
  ServerPrint(string.format("[Admin] %s exec \"%s\"", adminName, fileName))

  ServerCommand("exec " .. fileName .. "\n")
end

-- =====================
-- lua_banip
-- =====================
local function CmdBanIP(id, args)
  local target, minutes, reason = string.match(args, "^%s*(%S+)%s+(%S+)%s*(.-)%s*$")

  if not target or not minutes then
    ClientPrint(id, print_console, "[LUA] Usage: lua_banip <name or #userid> <minutes> [reason]")
    return
  end

  local targetId = FindPlayer(target)
  if not targetId then
    ClientPrint(id, print_console, "[LUA] Player not found: " .. target)
    return
  end

  local targetName = GetPlayerName(targetId) or "?"
  local targetIP   = GetUserInfoKey(targetId, "ip") or ""
  local userid     = GetPlayerUserId(targetId) or 0
  local adminName  = GetPlayerName(id) or "Console"
  local mins       = tonumber(minutes) or 0

  targetIP = string.match(targetIP, "^([^:]+)") or targetIP

  local kickMsg = "You were banned"
  if mins > 0 then
    kickMsg = kickMsg .. " for " .. minutes .. " minutes"
  else
    kickMsg = kickMsg .. " permanently"
  end
  if reason and reason ~= "" then
    kickMsg = kickMsg .. " (" .. reason .. ")"
  end

  ServerCommand(string.format("addip \"%s\" \"%s\"\n", minutes, targetIP))
  ServerCommand("writeip\n")
  ServerCommand(string.format("kick #%d \"%s\"\n", userid, kickMsg))

  if mins > 0 then
    ClientPrint(0, print_chat, adminName .. " banned " .. targetName .. " by IP for " .. minutes .. " min")
  else
    ClientPrint(0, print_chat, adminName .. " permanently banned " .. targetName .. " by IP")
  end

  ServerPrint(string.format("[Admin] %s banip \"%s\" ip=%s minutes=%s", adminName, targetName, targetIP, minutes))
end

-- =====================
-- lua_pause
-- =====================
local isPaused = false

local function CmdPause(id, args)
  local adminName = GetPlayerName(id) or "Console"

  if not isPaused then
    SetCvarFloat("pausable", 1.0)
    for i = 1, 32 do
      local name = GetPlayerName(i)
      if name and name ~= "" then
        ClientCommand(i, "pause")
        break
      end
    end
    isPaused = true
    ClientPrint(0, print_chat, adminName .. " paused the server")
    ServerPrint(string.format("[Admin] %s paused server", adminName))
  else
    for i = 1, 32 do
      local name = GetPlayerName(i)
      if name and name ~= "" then
        ClientCommand(i, "pause")
        break
      end
    end
    isPaused = false
    ClientPrint(0, print_chat, adminName .. " unpaused the server")
    ServerPrint(string.format("[Admin] %s unpaused server", adminName))
  end
end

-- =====================
-- say ff
-- =====================
local function CmdFF(id)
  local ff = GetCvarFloat("mp_friendlyfire")
  local status = ff ~= 0 and "ON" or "OFF"
  ClientPrint(0, print_chat, "Friendly Fire: " .. status)
end

-- =====================
-- Registration
-- =====================
RegisterCommand("lua_who",    "d", CmdWho)
RegisterCommand("lua_nick",   "d", CmdNick)
RegisterCommand("lua_cvar",   "d", CmdCvar)
RegisterCommand("lua_cfg",    "e", CmdCfg)
RegisterCommand("lua_banip",  "d", CmdBanIP)
RegisterCommand("lua_pause",  "d", CmdPause)

RegisterChatCommand("ff",  "", CmdFF)
RegisterChatCommand("/ff", "", CmdFF)
