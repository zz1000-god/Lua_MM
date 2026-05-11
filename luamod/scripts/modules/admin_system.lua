-- modules/admin_system.lua

local function CmdKick(adminId, args)
  if not args or args == "" then
    ClientPrint(adminId, print_console, "Usage: lua_kick <#userid or entityid> [reason]")
    return
  end

  local targetStr, reason = string.match(args, "^([#%d]+)%s*(.*)")
  local targetId = FindPlayer(targetStr)

  if not targetId then
    ClientPrint(adminId, print_console, "Player not found.")
    return
  end

  reason = (reason and reason ~= "") and reason or "Kicked by Admin"
  reason = string.gsub(reason, '^"(.*)"$', '%1')

  local targetName = GetPlayerName(targetId)
  local targetUserId = GetPlayerUserId(targetId)
  
  if not targetName or not targetUserId then
    ClientPrint(adminId, print_console, "Could not retrieve player data.")
    return
  end

  ServerCommand(string.format('kick #%d "%s"\n', targetUserId, reason))
  ServerPrint("[Admin] Kicked player " .. targetName .. ". Reason: " .. reason)
  ClientPrint(adminId, print_console, "Player " .. targetName .. " was kicked.")
end

local function CmdBan(adminId, args)
  if not args or args == "" then
    ClientPrint(adminId, print_console, "Usage: lua_ban <#userid or entityid> <minutes> [reason]")
    return
  end

  local targetStr, minutesStr, reason = string.match(args, "^([#%d]+)%s+(%d+)%s*(.*)")
  local minutes = tonumber(minutesStr)
  local targetId = FindPlayer(targetStr)

  if not targetId or not minutes then
    ClientPrint(adminId, print_console, "Usage: lua_ban <#userid or entityid> <minutes> [reason] (0 = perm)")
    return
  end

  reason = (reason and reason ~= "") and reason or "Banned by Admin"
  reason = string.gsub(reason, '^"(.*)"$', '%1')

  local targetName = GetPlayerName(targetId)
  local targetUserId = GetPlayerUserId(targetId)
  local targetAuthId = GetPlayerAuthId(targetId)

  if not targetName or not targetUserId or not targetAuthId then
    ClientPrint(adminId, print_console, "Player data could not be retrieved.")
    return
  end

  ServerCommand(string.format('banid %d %s\n', minutes, targetAuthId))
  ServerCommand('writeid\n')
  
  ServerCommand(string.format('kick #%d "Banned: %s"\n', targetUserId, reason))

  local banTimeStr = minutes == 0 and "permanently" or (minutes .. " minutes")
  ServerPrint(string.format("[Admin] Banned %s %s. Reason: %s", targetName, banTimeStr, reason))
  ClientPrint(adminId, print_console, string.format("Player %s was banned.", targetName))
end

local function CmdUnban(adminId, args)
  local targetAuthId = string.match(args or "", "(STEAM_[%d:]+)")
  if not targetAuthId then
    ClientPrint(adminId, print_console, "Usage: lua_unban <STEAM_0:X:XXXXXX>")
    return
  end

  ServerCommand(string.format('removeid %s\nwriteid\n', targetAuthId))
  ServerPrint("[Admin] Unbanned " .. targetAuthId)
  ClientPrint(adminId, print_console, "SteamID " .. targetAuthId .. " has been unbanned.")
end

RegisterCommand("lua_kick", "c", CmdKick)
RegisterCommand("lua_ban", "d", CmdBan)
RegisterCommand("lua_unban", "d", CmdUnban)
