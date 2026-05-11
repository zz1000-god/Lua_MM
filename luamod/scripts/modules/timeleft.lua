local function GetNumberVox(num)
  if num <= 0 then return "" end
  
  local words = {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", 
                 "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"}
  if num < 20 then
    return words[num]
  end
  
  local tens = {"twenty", "thirty", "fourty", "fifty", "sixty"}
  local ten = math.floor(num / 10) - 1
  local unit = num % 10
  
  if unit == 0 then
    return tens[ten] or ""
  end
  
  return (tens[ten] or "") .. " " .. words[unit]
end

local timeAnnouncements = {
  [1800] = "vox/thirty minutes remaining",
  [900]  = "vox/fifteen minutes remaining",
  [600]  = "vox/ten minutes remaining",
  [300]  = "vox/five minutes remaining",
  [180]  = "vox/three minutes remaining",
  [60]   = "vox/one minutes remaining"
}

local countdownAnnouncements = {
  [9] = "vox/nine", [8] = "vox/eight", [7] = "vox/seven", [6] = "vox/six",
  [5] = "vox/five", [4] = "vox/four", [3] = "vox/three", [2] = "vox/two", [1] = "vox/one"
}

local lastRemaining = -1

local timeHudText = {
  [1800] = "30 minutes",
  [900]  = "15 minutes",
  [600]  = "10 minutes",
  [300]  = "5 minutes",
  [180]  = "3 minutes",
  [60]   = "1 minute"
}

local function SendHudToAll(text)
  for i = 1, 32 do
    local name = GetPlayerName(i)
    if name and name ~= "" then
      ShowHudMessage(i, text, 255, 255, 255, -1.0, 0.8, 0, 3.0, 0, 0.0, 1.5)
    end
  end
end

local function CheckTimeleftFrame(currentTime)
  local limit = GetCvarFloat("mp_timelimit")
  if limit <= 0 then return end

  local currentRemaining = math.floor((limit * 60.0) - currentTime)

  if lastRemaining ~= -1 and currentRemaining < lastRemaining then
    if lastRemaining - currentRemaining > 2 then
      lastRemaining = currentRemaining
      return
    end

    for _, target in ipairs({1800, 900, 600, 300, 180, 60}) do
      if lastRemaining > target and currentRemaining <= target then
        local t = target
        Timers.Create(1, function()
          local lim = GetCvarFloat("mp_timelimit")
          local rem = math.floor((lim * 60.0) - GetTime())
          if rem > 0 then
            ClientCommand(0, "spk \"" .. timeAnnouncements[t] .. "\"")
            SendHudToAll(timeHudText[t])
          end
        end)
      end
    end

    for target = 9, 1, -1 do
      if lastRemaining > target and currentRemaining <= target then
        local t = target
        Timers.Create(1, function()
          local lim = GetCvarFloat("mp_timelimit")
          local rem = math.floor((lim * 60.0) - GetTime())
          if rem > 0 then
            ClientCommand(0, "spk \"" .. countdownAnnouncements[t] .. "\"")
          end
        end)
      end
    end

  end

  lastRemaining = currentRemaining
end

AddFrameHook("TimeleftSystem", CheckTimeleftFrame)

local function CmdTimeLeft(id)
  local limit = GetCvarFloat("mp_timelimit")
  
  if limit <= 0 then
    ClientPrint(id, print_chat, "[LUA] Map has no time limit.")
    return
  end

  local timeLeftSec = math.floor((limit * 60.0) - GetTime()) + 1
  
  if timeLeftSec <= 0 then
    ClientPrint(id, print_chat, "[LUA] Time is up!")
  else
    local hours = math.floor(timeLeftSec / 3600)
    local mins = math.floor((timeLeftSec % 3600) / 60)
    local secs = math.floor(timeLeftSec % 60)
    
    if hours > 0 then
      ClientPrint(id, print_chat, string.format("[LUA] Time remaining: %d:%02d:%02d", hours, mins, secs))
    else
      ClientPrint(id, print_chat, string.format("[LUA] Time remaining: %02d:%02d", mins, secs))
    end
    
    local voxStr = "vox/"
    
    if hours > 0 then voxStr = voxStr .. GetNumberVox(hours) .. " hours " end
    if mins > 0 then voxStr = voxStr .. GetNumberVox(mins) .. " minutes " end
    if secs > 0 then voxStr = voxStr .. GetNumberVox(secs) .. " seconds " end
    
    voxStr = voxStr .. "remaining"
    
    ClientCommand(id, "spk \"" .. voxStr .. "\"")
  end
end

local function CmdTheTime(id)
  ClientPrint(id, print_chat, "[LUA] Server time: " .. tostring(os.date("%H:%M:%S (%d.%m.%Y)")))
end

RegisterChatCommand("timeleft", "", CmdTimeLeft)
RegisterChatCommand("/timeleft", "", CmdTimeLeft)
RegisterChatCommand("thetime", "", CmdTheTime)
RegisterChatCommand("/thetime", "", CmdTheTime)
