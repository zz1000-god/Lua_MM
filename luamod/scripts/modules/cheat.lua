-- modules/cheat.lua

-- Правильні константи GoldSrc
local FL_GODMODE  = 64
local FL_NOTARGET = 128

local MOVETYPE_WALK   = 3
local MOVETYPE_NOCLIP = 8

local IMPULSE_101 = {
  "item_longjump",
  "item_battery", "item_battery", "item_battery", "item_battery", "item_battery", "item_battery", "item_battery",
  "item_healthkit", "item_healthkit", "item_healthkit", "item_healthkit", "item_healthkit", "item_healthkit", "item_healthkit",
  "weapon_crowbar",
  "weapon_9mmhandgun",
  "weapon_357",
  "weapon_9mmAR",
  "weapon_shotgun",
  "weapon_crossbow",
  "weapon_rpg",
  "weapon_gauss",
  "weapon_egon",
  "weapon_hornetgun",
  "weapon_handgrenade", "weapon_handgrenade",
  "weapon_tripmine", "weapon_tripmine", "weapon_tripmine", "weapon_tripmine", "weapon_tripmine",
  "weapon_satchel", "weapon_satchel", "weapon_satchel", "weapon_satchel", "weapon_satchel",
  "weapon_snark", "weapon_snark", "weapon_snark",
  "ammo_ARgrenades", "ammo_ARgrenades", "ammo_ARgrenades", "ammo_ARgrenades", "ammo_ARgrenades",
  "ammo_buckshot", "ammo_buckshot", "ammo_buckshot", "ammo_buckshot", "ammo_buckshot", "ammo_buckshot", "ammo_buckshot", "ammo_buckshot",
  "ammo_9mmbox", "ammo_9mmbox", "ammo_9mmbox", "ammo_9mmbox", "ammo_9mmbox", "ammo_9mmbox",
  "ammo_357", "ammo_357", "ammo_357", "ammo_357", "ammo_357", "ammo_357",
  "ammo_crossbow", "ammo_crossbow", "ammo_crossbow", "ammo_crossbow", "ammo_crossbow", "ammo_crossbow", "ammo_crossbow",
  "ammo_rpgclip", "ammo_rpgclip", "ammo_rpgclip", "ammo_rpgclip", "ammo_rpgclip",
  "ammo_gaussclip", "ammo_gaussclip", "ammo_gaussclip", "ammo_gaussclip", "ammo_gaussclip"
}

-- =====================
-- lua_god
-- =====================
local function CmdGod(adminId, args)
  local target = string.match(args, "^%s*(.-)%s*$")
  local targetId = adminId

  if target and target ~= "" then
    targetId = FindPlayer(target)
    if not targetId then
      ClientPrint(adminId, print_console, "[LUA] Player not found: " .. target)
      return
    end
  end

  local flags = GetPlayerFlags(targetId)
  local hasGod = bit.band(flags, FL_GODMODE) ~= 0
  local adminName = GetPlayerName(adminId) or "Console"
  local targetName = GetPlayerName(targetId) or "?"

  if hasGod then
    SetPlayerFlags(targetId, FL_GODMODE, false)
    ClientPrint(targetId, print_chat, "[LUA] God mode: OFF")
    if targetId ~= adminId then
      ClientPrint(adminId, print_console, "[LUA] God mode OFF for " .. targetName)
    end
  else
    SetPlayerFlags(targetId, FL_GODMODE, true)
    SetPlayerHealth(targetId, 100)
    ClientPrint(targetId, print_chat, "[LUA] God mode: ON")
    if targetId ~= adminId then
      ClientPrint(adminId, print_console, "[LUA] God mode ON for " .. targetName)
    end
  end

  ServerPrint(string.format("[Admin] %s toggled god on %s -> %s", adminName, targetName, hasGod and "OFF" or "ON"))
end

-- =====================
-- lua_noclip
-- =====================
local function CmdNoClip(adminId, args)
  local target = string.match(args, "^%s*(.-)%s*$")
  local targetId = adminId

  if target and target ~= "" then
    targetId = FindPlayer(target)
    if not targetId then
      ClientPrint(adminId, print_console, "[LUA] Player not found: " .. target)
      return
    end
  end

  local movetype = GetPlayerMoveType(targetId)
  local hasNoclip = (movetype == MOVETYPE_NOCLIP)
  local adminName = GetPlayerName(adminId) or "Console"
  local targetName = GetPlayerName(targetId) or "?"

  if hasNoclip then
    SetPlayerMoveType(targetId, MOVETYPE_WALK)
    ClientPrint(targetId, print_chat, "[LUA] Noclip: OFF")
    if targetId ~= adminId then
      ClientPrint(adminId, print_console, "[LUA] Noclip OFF for " .. targetName)
    end
  else
    SetPlayerMoveType(targetId, MOVETYPE_NOCLIP)
    ClientPrint(targetId, print_chat, "[LUA] Noclip: ON")
    if targetId ~= adminId then
      ClientPrint(adminId, print_console, "[LUA] Noclip ON for " .. targetName)
    end
  end

  ServerPrint(string.format("[Admin] %s toggled noclip on %s -> %s", adminName, targetName, hasNoclip and "OFF" or "ON"))
end

-- =====================
-- lua_weapons
-- =====================
local function CmdWeapons(adminId, args)
  local target = string.match(args, "^%s*(.-)%s*$")
  local targetId = adminId

  if target and target ~= "" then
    targetId = FindPlayer(target)
    if not targetId then
      ClientPrint(adminId, print_console, "[LUA] Player not found: " .. target)
      return
    end
  end

  local targetName = GetPlayerName(targetId) or "?"
  local adminName  = GetPlayerName(adminId) or "Console"

  for _, item in ipairs(IMPULSE_101) do
    GiveItem(targetId, item)
  end

  ClientPrint(targetId, print_chat, "[LUA] All weapons and max ammo received.")
  if targetId ~= adminId then
    ClientPrint(adminId, print_console, "[LUA] All weapons given to " .. targetName)
  end

  ServerPrint(string.format("[Admin] %s gave all weapons to %s", adminName, targetName))
end

-- =====================
-- Реєстрація
-- =====================
RegisterCommand("lua_god",     "d", CmdGod)
RegisterCommand("lua_noclip",  "d", CmdNoClip)
RegisterCommand("lua_weapons", "d", CmdWeapons)

RegisterChatCommand("/god",     "d", function(id) CmdGod(id, "") end)
RegisterChatCommand("/noclip",  "d", function(id) CmdNoClip(id, "") end)
RegisterChatCommand("/weapons", "d", function(id) CmdWeapons(id, "") end)
