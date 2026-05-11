-- modules/admin_punish.lua

local slapSounds = {
  "player/pl_pain2.wav",
  "player/pl_pain4.wav",
  "player/pl_pain5.wav",
  "player/pl_pain6.wav",
  "player/pl_pain7.wav"
}

local function CmdSlay(adminId, args)
  local targetId = FindPlayer(args)
  
  if not targetId then
    ClientPrint(adminId, print_console, "[LUA] Usage: lua_slay <#userid or entityid>")
    return
  end
  
  if GetPlayerHealth(targetId) > 0 then
    UserKill(targetId)
    ClientCommand(0, "spk common/bodysplat.wav")
    ClientPrint(0, print_chat, "[LUA] " .. GetPlayerName(adminId) .. " slayed " .. GetPlayerName(targetId))
  end
end

local function CmdSlap(adminId, args)
  local targetStr, powerStr = string.match(args, "^([#%d]+)%s*(%d*)")
  local targetId = FindPlayer(targetStr)
  local power = tonumber(powerStr) or 0

  if not targetId then
    ClientPrint(adminId, print_console, "[LUA] Usage: lua_slap <#userid or entityid> [damage]")
    return
  end

  local hp = GetPlayerHealth(targetId)
  
  if hp > 0 then
    if hp > power then
      SetPlayerHealth(targetId, hp - power)
      
      local vx = math.random(-300, 300)
      local vy = math.random(-300, 300)
      local vz = math.random(150, 300)
      SetPlayerVelocity(targetId, vx, vy, vz)
      
      local randSound = slapSounds[math.random(1, #slapSounds)]
      ClientCommand(0, "spk " .. randSound)
      
      ClientPrint(0, print_chat, "[LUA] " .. GetPlayerName(adminId) .. " slapped " .. GetPlayerName(targetId) .. " with " .. power .. " damage")
    else
      UserKill(targetId)
      ClientCommand(0, "spk common/bodysplat.wav")
      ClientPrint(0, print_chat, "[LUA] " .. GetPlayerName(adminId) .. " slapped " .. GetPlayerName(targetId) .. " to death")
    end
  end
end

RegisterCommand("lua_slay", "c", CmdSlay)
RegisterCommand("lua_slap", "c", CmdSlap)
