-- modules/auth.lua
local Users = require("configs.users")

_G.Auth = {}
Auth.Players = {} -- Active sessions cache

-- Initialize empty rights for a specific slot
function Auth.InitPlayer(playerId)
  Auth.Players[playerId] = { flags = "" }
end

-- Check access on connection
function Auth.CheckConnection(playerId, name, ip)
  Auth.InitPlayer(playerId)
  
  local lowerName = string.lower(name)
  local authId = GetPlayerAuthId(playerId)
  local pw = GetUserInfoKey(playerId, "_pw")

  for _, user in ipairs(Users) do
    local isMatch = false

    if user.type == "steamid" and user.auth == authId then
      isMatch = true
    elseif user.type == "name" and string.lower(user.auth) == lowerName then
      isMatch = true
    end

    if isMatch then
      if user.password and user.password ~= "" and user.password ~= pw then
        return false, "Invalid password. Use: setinfo _pw <password>"
      end

      Auth.Players[playerId].flags = user.flags
      return true, ""
    end
  end

  return true, ""
end

-- Check if player has at least one of the required flags
function Auth.HasAccess(playerId, requiredFlags)
  if not requiredFlags or requiredFlags == "" then return true end
  
  local p = Auth.Players[playerId]
  if not p then return false end

  -- Iterate through required flags. If player has one, grant access.
  for i = 1, #requiredFlags do
    local flag = string.sub(requiredFlags, i, i)
    if string.find(p.flags, flag) then
      return true
    end
  end

  return false
end

function Auth.GetFlagsString(playerId)
  local p = Auth.Players[playerId]
  if not p or p.flags == "" then return "none" end
  return p.flags
end

function Auth.ReloadAll()
  for i = 1, 32 do
    local name = GetPlayerName(i)
    
    if name and name ~= "" then
      local success, reason = Auth.CheckConnection(i, name, "")
      
      if not success then
        ServerCommand(string.format("kick #%d \"%s\"\n", GetPlayerUserId(i), reason))
      end
    end
  end
end

Auth.ReloadAll()
