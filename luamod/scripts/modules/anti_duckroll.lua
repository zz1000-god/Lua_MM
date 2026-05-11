local IN_DUCK = 4 

local duckStartTime = {}
local isDucking = {}

local function AntiDuckRollCheck(currentTime)
  for id = 1, 32 do
    local name = GetPlayerName(id)
    
    if name and name ~= "" then
      local buttons = GetPlayerButtons(id)
      local holdingDuck = bit.band(buttons, IN_DUCK) ~= 0

      if holdingDuck and not isDucking[id] then
        isDucking[id] = true
        duckStartTime[id] = currentTime
        
      elseif not holdingDuck and isDucking[id] then
        isDucking[id] = false
        
        local timeSpentDucking = currentTime - (duckStartTime[id] or 0)
        
        if timeSpentDucking > 0.0 and timeSpentDucking < 0.07 then
          local vx, vy, vz = GetPlayerVelocity(id)
          
          if math.abs(vx) > 500 or math.abs(vy) > 500 then
            SetPlayerVelocity(id, vx * 0.8, vy * 0.8, vz)
          end
        end
      end
    end
  end
end

AddFrameHook("AntiDuckrollLogic", AntiDuckRollCheck)
