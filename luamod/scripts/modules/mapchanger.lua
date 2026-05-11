local function CmdMap(adminId, args)
  local mapName = string.match(args, "^%s*(%S+)%s*$")

  if not mapName or mapName == "" then
    ClientPrint(adminId, print_console, "[LUA] Usage: lua_map <mapname>")
    return
  end

  local file = io.open("valve/maps/" .. mapName .. ".bsp", "r")
  if not file then
    ClientPrint(adminId, print_console, "[LUA] Map '" .. mapName .. "' not found.")
    return
  end
  file:close()

  local adminName = GetPlayerName(adminId) or "Console"

  ClientPrint(0, print_chat, adminName .. " changed map to " .. mapName)

  ServerPrint(string.format("[Admin] %s changelevel \"%s\"", adminName, mapName))

  for i = 1, 32 do
    local name = GetPlayerName(i)
    if name and name ~= "" then
      ShowHudMessage(i, "Changing map to " .. mapName, 255, 255, 255, -1.0, 0.5, 0, 2.0, 0, 0.0, 0.5)
    end
  end

  SendIntermission()

  Timers.Create(2, function()
    ServerCommand("changelevel " .. mapName .. "\n")
  end)
end

RegisterCommand("lua_map", "f", CmdMap)
