-- modules/admin_hud.lua

local colors = {
  red = {255, 0, 0},
  green = {0, 255, 0},
  blue = {0, 0, 255},
  yellow = {255, 255, 0},
  magenta = {255, 0, 255},
  cyan = {0, 255, 255},
  white = {255, 255, 255}
}

local function ParseHudCmd(args)
  local colorStr, message = string.match(args, "^(%w+)%s+(.+)$")
  local r, g, b = 255, 255, 255
  
  if colorStr and colors[colorStr] then
    r, g, b = unpack(colors[colorStr])
  else
    message = args
  end
  
  return r, g, b, message
end

local function CmdTsay(adminId, args)
  local r, g, b, message = ParseHudCmd(args)
  
  if not message or message == "" then
    ClientPrint(adminId, print_console, "[LUA] Usage: lua_tsay [color] <message>")
    return
  end
  
  local fullMsg = GetPlayerName(adminId) .. " : " .. message
  
  ShowHudMessage(0, fullMsg, r, g, b, 0.05, 0.55, 3, 6.0)
end

local function CmdCsay(adminId, args)
  local r, g, b, message = ParseHudCmd(args)
  
  if not message or message == "" then
    ClientPrint(adminId, print_console, "[LUA] Usage: lua_csay [color] <message>")
    return
  end
  
  local fullMsg = GetPlayerName(adminId) .. " : " .. message
  
  ShowHudMessage(0, fullMsg, r, g, b, -1.0, 0.2, 4, 6.0)
end

RegisterCommand("lua_tsay", "c", CmdTsay)
RegisterCommand("lua_csay", "c", CmdCsay)
