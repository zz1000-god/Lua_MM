-- modules/admin_rcon.lua

local function CmdRcon(adminId, args)
  if not args or args == "" then
    ClientPrint(adminId, print_console, "Usage: lua_rcon <command>")
    return
  end

  ServerCommand(args .. "\n")
  
  local adminName = GetPlayerName(adminId)
  
  ServerPrint("RCON executed by " .. adminName .. ": " .. args)
  ClientPrint(adminId, print_console, "RCON command sent: " .. args)
end

RegisterCommand("lua_rcon", "l", CmdRcon)
