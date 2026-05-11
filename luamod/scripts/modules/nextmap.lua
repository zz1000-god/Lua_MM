-- modules/nextmap.lua
local lastMapName = ""
local nextMapInitialized = false

local function FindNextMap(currentMap)
  local mapcycleFile = GetCvarString("mapcyclefile")
  if not mapcycleFile or mapcycleFile == "" then
    mapcycleFile = "mapcycle.txt"
  end

  local file = io.open(mapcycleFile, "r")
  if not file then
    file = io.open("valve/" .. mapcycleFile, "r")
    if not file then return nil end
  end

  local maps = {}
  for line in file:lines() do
    line = string.match(line, "^%s*(.-)%s*$")
    line = string.gsub(line, "%.bsp$", "")
    if line ~= "" and string.match(line, "^%w") then
      table.insert(maps, line)
    end
  end
  file:close()

  if #maps == 0 then return nil end

  for i, map in ipairs(maps) do
    if string.lower(map) == string.lower(currentMap) then
      return (i < #maps) and maps[i + 1] or maps[1]
    end
  end

  return maps[1]
end

local function InitNextMapHook(currentTime)
  local currentMap = GetMapName()
  if not currentMap or currentMap == "" then return end

  if currentMap ~= lastMapName then
    lastMapName = currentMap
    nextMapInitialized = false
    return
  end

  if nextMapInitialized then return end
  nextMapInitialized = true

  local nextMap = FindNextMap(currentMap)
  if not nextMap then
    ServerPrint("NextMap: cant fine the nextmap")
    return
  end

  SetCvarString("amx_nextmap", nextMap)
  SetCvarString("lua_nextmap", nextMap)

  ServerPrint(string.format("NextMap: current=%s | next=%s", currentMap, nextMap))

  RemoveFrameHook("InitNextMapHook")
end

AddFrameHook("InitNextMapHook", InitNextMapHook)

local function CmdNextMap(id)
  local nextmap = GetCvarString("lua_nextmap")
  if not nextmap or nextmap == "" then
    ClientPrint(id, print_chat, "[LUA] Next map is not yet determined.")
  else
    ClientPrint(id, print_chat, "[LUA] Next map: " .. nextmap)
  end
end

local function CmdCurrentMap(id)
  ClientPrint(id, print_chat, "[LUA] Current map: " .. tostring(GetMapName()))
end

RegisterChatCommand("nextmap", "", CmdNextMap)
RegisterChatCommand("/nextmap", "", CmdNextMap)
RegisterChatCommand("currentmap", "", CmdCurrentMap)
RegisterChatCommand("/currentmap", "", CmdCurrentMap)
