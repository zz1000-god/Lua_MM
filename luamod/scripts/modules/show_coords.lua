local activePlayers = {}

local function CmdToggleCoords(id)
  activePlayers[id] = not activePlayers[id]
  
  if activePlayers[id] then
    ClientPrint(id, print_console, "[LUA] Coordinates HUD enabled.")
  else
    ClientPrint(id, print_console, "[LUA] Coordinates HUD disabled.")
  end
end

RegisterChatCommand("/coords", "", CmdToggleCoords)

local function UpdateCoordsHUD()
  for id, isActive in pairs(activePlayers) do
    if isActive then
      local name = GetPlayerName(id)
      
      if name and name ~= "" then
        local x, y, z = GetPlayerOrigin(id)
        local msg = string.format("X: %.1f | Y: %.1f | Z: %.1f", x, y, z)
        
        ShowHudMessage(id, msg, 0, 255, 0, -1.0, 0.8, 1, 60.0, 0, 0.0, 0.0)
      else
        activePlayers[id] = nil
      end
    end
  end
  
  Timers.Create(0.1, UpdateCoordsHUD)
end

UpdateCoordsHUD()
