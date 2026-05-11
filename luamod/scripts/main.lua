local mod_dir = "valve"
package.path = package.path .. ";" .. mod_dir .. "/addons/luamod/scripts/?.lua"

_G.print_console = 0
_G.print_center = 1
_G.print_chat = 2

require("modules.auth")
require("modules.commands")
require("modules.chat_router")
require("modules.menu_system")
require("modules.timers")

local function LoadPlugins()
  local file = io.open("valve/addons/luamod/configs/plugins.ini", "r")
  
  if not file then
    ServerPrint("Warning: plugins.ini not found!")
    return
  end

  for line in file:lines() do
    line = string.match(line, "^%s*(.-)%s*$")
    
    if line ~= "" and string.sub(line, 1, 1) ~= ";" then
      local status, err = pcall(require, "modules." .. line)
      
      if not status then
        ServerPrint("Failed to load: " .. line .. " | " .. tostring(err))
      else
        ServerPrint("Loaded: " .. line)
      end
    end
  end
  
  file:close()
end

LoadPlugins()

function OnClientConnect(playerId, name, ip)
  return Auth.CheckConnection(playerId, name, ip)
end

function OnClientCommand(playerId, cmd, args)
  local command = string.lower(cmd)
  args = args or ""

  if command == "menuselect" then
    if MenuSystem.HandleSelect(playerId, args) then return true end
  end

  if command == "say" or command == "say_team" then
    local text = string.gsub(args, '^"(.*)"$', '%1')

    if GagSystem.IsGagged(playerId) then
      ClientPrint(playerId, print_chat, "[LUA] You are currently muted.")
      return true
    end

    if AdminChat.Process(playerId, text) then
      return true
    end

    if ChatRouter.Process(playerId, text) then 
      return true 
    end
  end

  return CmdRouter.Process(playerId, cmd, args)
end
