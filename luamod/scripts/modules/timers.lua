-- modules/timers.lua
_G.Timers = {}
_G.FrameHooks = {} -- Table for multiple OnFrame callbacks
local activeTimers = {}

function Timers.Create(delay, callback)
  local triggerTime = GetTime() + delay
  table.insert(activeTimers, { time = triggerTime, cb = callback })
end

-- Allows any module to hook into the frame loop safely
function _G.AddFrameHook(hookName, callback)
  FrameHooks[hookName] = callback
end

function _G.RemoveFrameHook(hookName)
  FrameHooks[hookName] = nil
end

function _G.OnFrame(currentTime)
  -- 1. Process Timers
  for i = #activeTimers, 1, -1 do
    local t = activeTimers[i]
    if currentTime >= t.time then
      t.cb()
      table.remove(activeTimers, i)
    end
  end

  -- 2. Process external frame hooks
  for _, hookCb in pairs(FrameHooks) do
    hookCb(currentTime)
  end
end
