-- modules/admin_chat.lua
_G.AdminChat = {}

function AdminChat.Process(playerId, text)
  if string.sub(text, 1, 1) == "@" then
    if Auth.HasAccess(playerId, "i") then
      local msg = string.sub(text, 2)
      msg = string.match(msg, "^%s*(.-)$") 
      
      local senderName = GetPlayerName(playerId)
      local formattedMsg = "(ADMIN) " .. senderName .. " : " .. msg
      
      for i = 1, 32 do
        if GetPlayerName(i) ~= "" and Auth.HasAccess(i, "i") then
          ClientPrint(i, print_chat, formattedMsg)
        end
      end
    else
      ClientPrint(playerId, print_chat, "[LUA] You don't have access to admin chat.")
    end
    
    return true
  end
  
  return false
end
