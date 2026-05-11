local function GetValidPlayers()
  local items = {}
  for i = 1, 32 do
    local name = GetPlayerName(i)
    local userId = GetPlayerUserId(i)
    if name and name ~= "" and userId then
      table.insert(items, { text = name, value = i })
    end
  end
  return items
end

local function PlaySoundToAll(soundPath)
  for i = 1, 32 do
    local name = GetPlayerName(i)
    if name and name ~= "" then
      ClientCommand(i, "spk \"" .. soundPath .. "\"")
    end
  end
end

local SoundList = {
  { text = "Hello!", value = "vox/hello" },
  { text = "Don't think so", value = "barney/dontguess" },
  { text = "Don't ask me", value = "barney/dontaskme" },
  { text = "Hey! Stop that!", value = "barney/donthurtem" },
  { text = "Yup", value = "barney/yup" },
  { text = "Nope", value = "barney/nope" },
  { text = "Maybe", value = "barney/maybe" },
  { text = "Seeya", value = "barney/seeya" },
  { text = "Man that sounded bad", value = "barney/soundsbad" },
  { text = "Hello and die", value = "vox/hello and die" },
  { text = "Move!", value = "hgrunt/move! _comma yessir!" },
  { text = "You will definitely pay!", value = "hgrunt/c2a2_hg_chat5a" },
  { text = "Laughter", value = "hgrunt/c2a3_hg_laugh" },
  { text = "Silence!", value = "hgrunt/silence!" },
  { text = "You talk too much", value = "barney/youtalkmuch" },
  { text = "You thinkin?", value = "barney/thinking" },
  { text = "Open fire Gordon!", value = "barney/openfire" },
  { text = "Couldnt make a bigger mess", value = "barney/bigmess" },
  { text = "I have a Bad feeling", value = "barney/badfeeling" },
  { text = "Yes sir!", value = "hgrunt/yessir!" },
  { text = "No sir", value = "barney/nosir" }
}

local function OpenSoundMenu(adminId, page)
  MenuSystem.Show(adminId, "Play Sound", SoundList, function(id, selectedSound, currentPage)
    PlaySoundToAll(selectedSound)
    OpenSoundMenu(id, currentPage)
  end, page)
end

local function OpenKickMenu(adminId)
  local items = GetValidPlayers()

  if #items == 0 then
    ClientPrint(adminId, print_chat, "[Menu] No players available to kick.")
    return
  end

  MenuSystem.Show(adminId, "Select Player to Kick", items, function(id, selectedEntityId)
    ClientCommand(id, "lua_kick " .. selectedEntityId)
  end)
end

local function OpenBanTimeMenu(adminId, targetEntityId, targetName)
  local items = {
    { text = "5 Minutes", value = 5 },
    { text = "30 Minutes", value = 30 },
    { text = "1 Hour", value = 60 },
    { text = "1 Day", value = 1440 },
    { text = "Permanent", value = 0 }
  }

  MenuSystem.Show(adminId, "Ban Time: " .. targetName, items, function(id, timeVal)
    ClientCommand(id, string.format('lua_ban %d %d "Banned from menu"', targetEntityId, timeVal))
  end)
end

local function OpenBanMenu(adminId)
  local items = GetValidPlayers()

  if #items == 0 then
    ClientPrint(adminId, print_chat, "[Menu] No players available to ban.")
    return
  end

  MenuSystem.Show(adminId, "Select Player to Ban", items, function(id, selectedEntityId)
    local targetName = GetPlayerName(selectedEntityId)
    if targetName and targetName ~= "" then
      OpenBanTimeMenu(id, selectedEntityId, targetName)
    else
      ClientPrint(id, print_chat, "[Menu] Player disconnected.")
    end
  end)
end

local function CmdAdminMenu(adminId, args)
  local items = {
    { text = "Kick Player", value = "kick" },
    { text = "Ban Player", value = "ban" },
    { text = "Play Sound", value = "sound" }
  }

  MenuSystem.Show(adminId, "Admin Menu", items, function(id, action)
    if action == "kick" then
      OpenKickMenu(id)
    elseif action == "ban" then
      OpenBanMenu(id)
    elseif action == "sound" then
      OpenSoundMenu(id)
    end
  end)
end

RegisterCommand("lua_menu", "c", CmdAdminMenu)
RegisterChatCommand("/menu", "c", function(id) ClientCommand(id, "lua_menu") end)
RegisterChatCommand("/admin", "c", function(id) ClientCommand(id, "lua_menu") end)
