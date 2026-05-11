-- modules/gag_system.lua
_G.GagSystem = {}
GagSystem.Muted = {}

function GagSystem.IsGagged(playerId)
  local authId = GetPlayerAuthId(playerId)
  
  if GagSystem.Muted[authId] then
    local expireTime = GagSystem.Muted[authId]
    
    if expireTime == 0 then 
      return true 
    end
    
    if GetTime() >= expireTime then
      GagSystem.Muted[authId] = nil
      return false
    end
    
    return true
  end
  
  return false
end

local function CmdGag(adminId, args)
  local targetStr, minutesStr = string.match(args, "^([#%d]+)%s*(%d*)")
  local targetId = FindPlayer(targetStr)
  local minutes = tonumber(minutesStr) or 10 

  if not targetId then
    ClientPrint(adminId, print_console, "[LUA] Usage: lua_gag <#userid or entityid> [minutes]")
    return
  end

  local targetAuth = GetPlayerAuthId(targetId)
  local targetName = GetPlayerName(targetId)

  if minutes == 0 then
    GagSystem.Muted[targetAuth] = 0
    ClientPrint(0, print_chat, "[LUA] Admin muted " .. targetName .. " permanently.")
  else
    GagSystem.Muted[targetAuth] = GetTime() + (minutes * 60)
    ClientPrint(0, print_chat, "[LUA] Admin muted " .. targetName .. " for " .. minutes .. " minutes.")
  end
end

local function CmdUnGag(adminId, args)
  local targetId = FindPlayer(args)
  
  if not targetId then
    ClientPrint(adminId, print_console, "[LUA] Usage: lua_ungag <#userid or entityid>")
    return
  end

  local targetAuth = GetPlayerAuthId(targetId)
  
  if GagSystem.Muted[targetAuth] then
    GagSystem.Muted[targetAuth] = nil
    ClientPrint(0, print_chat, "[LUA] Admin unmuted " .. GetPlayerName(targetId) .. ".")
  else
    ClientPrint(adminId, print_console, "[LUA] Player is not muted.")
  end
end

RegisterCommand("lua_gag", "c", CmdGag)
RegisterCommand("lua_ungag", "c", CmdUnGag)
