-- modules/commands.lua
_G.CmdRouter = {}
CmdRouter.List = {}

-- The "Macro" for registering commands globally
function _G.RegisterCommand(cmdName, requiredFlags, callback)
  CmdRouter.List[string.lower(cmdName)] = {
    flags = requiredFlags,
    cb = callback
  }
end

-- Main handler triggered by C++
function CmdRouter.Process(playerId, cmd, args)
  local cmdData = CmdRouter.List[string.lower(cmd)]
  
  if cmdData then
    if not Auth.HasAccess(playerId, cmdData.flags) then
      ClientPrint(playerId, print_console, "You have no access to this command.")
      return true
    end
    
    cmdData.cb(playerId, args)
    return true
  end

  return false
end
