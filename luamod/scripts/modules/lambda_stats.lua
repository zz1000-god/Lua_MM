local MAX_CLIENTS = 32

PlayerStats = {}

function InitPlayer(id)
  if not PlayerStats[id] then
    PlayerStats[id] = {
      kills = 0,
      headshots = 0,
      deaths = 0,
      suicides = 0,
      hits = 0,
      damage = 0,
      hitgroups = { 0, 0, 0, 0, 0, 0, 0 },
      last_killer = nil,
      last_killer_hp = 0,
      last_killer_weapon = ""
    }
  end
end

local AttackerData = {}
local VictimData   = {}

local function NewDmgEntry()
  return { hits = 0, damage = 0, hg = { 0,0,0,0,0,0,0 } }
end

local function InitRoundData(id)
  AttackerData[id] = {}
  VictimData[id]   = {}
end

local function TrackHit(victimId, attackerId, damage, hitGroup)
  AttackerData[victimId] = AttackerData[victimId] or {}
  AttackerData[victimId][attackerId] = AttackerData[victimId][attackerId] or NewDmgEntry()
  local a = AttackerData[victimId][attackerId]
  a.hits = a.hits + 1
  a.damage = a.damage + damage
  if hitGroup >= 1 and hitGroup <= 7 then a.hg[hitGroup] = a.hg[hitGroup] + 1 end

  VictimData[attackerId] = VictimData[attackerId] or {}
  VictimData[attackerId][victimId] = VictimData[attackerId][victimId] or NewDmgEntry()
  local v = VictimData[attackerId][victimId]
  v.hits = v.hits + 1
  v.damage = v.damage + damage
  if hitGroup >= 1 and hitGroup <= 7 then v.hg[hitGroup] = v.hg[hitGroup] + 1 end
end

local KillStreak = {}
local MultiKill  = {}
local MKTimer    = {}
local MK_WINDOW  = 3.0

local STREAK_LABELS = {
  [3]  = "Triple Kill!",      [5]  = "Multi Kill!",
  [8]  = "Mega Kill!",        [12] = "Ultra Kill!",
  [15] = "Killing Spree!",    [20] = "Rampage!",
  [25] = "Dominating!",       [30] = "Unstoppable!",
  [35] = "Ludicrous Kill!",   [40] = "Holy Shit!",
  [45] = "Godlike!",          [50] = "Monster Kill!",
}

local MK_LABELS = {
  [2] = "Double Kill!",  [3] = "Triple Kill!",
  [4] = "Multi Kill!",   [5] = "Mega Kill!",
  [6] = "Ultra Kill!",   [7] = "Ludicrous Kill!",
  [8] = "Monster Kill!",
}

local function OnKillStreak(killerId)
  KillStreak[killerId] = (KillStreak[killerId] or 0) + 1
  local k = KillStreak[killerId]
  local now = GetTime()

  if not MKTimer[killerId] or (now - MKTimer[killerId]) > MK_WINDOW then
    MultiKill[killerId] = 1
  else
    MultiKill[killerId] = (MultiKill[killerId] or 1) + 1
  end
  MKTimer[killerId] = now

  local sk = STREAK_LABELS[k]
  if sk then
    local name = GetPlayerName(killerId) or "?"
    ClientPrint(0, 2, string.format("[Lambda] %s - %s (%d kills)", name, sk, k))
  end

  local mk = MK_LABELS[MultiKill[killerId]]
  if mk then
    local name = GetPlayerName(killerId) or "?"
    ClientPrint(0, 2, string.format("[Lambda] %s - %s", name, mk))
  end
end

local function ResetStreak(id)
  if (KillStreak[id] or 0) >= 5 then
    local name = GetPlayerName(id) or "?"
    ClientPrint(0, 2, string.format("[Lambda] %s's killing spree ended!", name))
  end
  KillStreak[id] = 0
  MultiKill[id]  = 0
  MKTimer[id]    = nil
end

local FirstBloodDone = false

local function ShowKillReport(killerId, victimId)
  local vd = VictimData[killerId] and VictimData[killerId][victimId]
  if not vd then return end
  local khp = math.floor(GetPlayerHealth(killerId))
  local vname = GetPlayerName(victimId) or "?"
  ClientPrint(killerId, 2, string.format("[Lambda] -> %s  Hits: %d  Dmg: %d  Your HP: %d", vname, vd.hits, vd.damage, khp))
end

local function ShowAttackerReport(victimId, killerId)
  local ad = AttackerData[victimId] and AttackerData[victimId][killerId]
  if not ad then return end
  local kname = GetPlayerName(killerId) or "?"
  ClientPrint(victimId, 2, string.format("[Lambda] Killed by %s  Hits: %d  Dmg: %d", kname, ad.hits, ad.damage))
end

local function CmdStatsMe(id)
  InitPlayer(id)
  local st = PlayerStats[id]
  local name = GetPlayerName(id) or "Unknown"

  local eff = 0.0
  if (st.kills + st.deaths) > 0 then
    eff = st.kills / (st.kills + st.deaths) * 100.0
  end
  local hspct = 0.0
  if st.hits > 0 then
    hspct = st.headshots / st.hits * 100.0
  end

  local motd = string.format(
    "Player Stats: %s\n" ..
    "Kills: %d (Headshots: %d)\n" ..
    "Deaths: %d (Suicides: %d)\n" ..
    "Damage Dealt: %d\n" ..
    "Efficiency: %.2f%%\n" ..
    "Accuracy (Headshots/Hits): %.2f%%\n" ..
    "Hit Distribution:\n" ..
    "---------------------------\n" ..
    "Head:     %d\n" ..
    "Chest:    %d\n" ..
    "Stomach:  %d\n" ..
    "Arms:     %d\n" ..
    "Legs:     %d\n" ..
    "---------------------------\n",
    name,
    st.kills, st.headshots,
    st.deaths, st.suicides,
    st.damage, eff, hspct,
    st.hitgroups[1], st.hitgroups[2], st.hitgroups[3],
    st.hitgroups[4] + st.hitgroups[5],
    st.hitgroups[6] + st.hitgroups[7]
  )

  ShowMotd(id, motd, "Your Stats")
end

local function CmdStats(id)
  ClientPrint(id, 2, "[Lambda] ===== Player Stats =====")
  for i = 1, MAX_CLIENTS do
    local name = GetPlayerName(i)
    if name and name ~= "" then
      InitPlayer(i)
      local st = PlayerStats[i]
      local eff = 0.0
      if (st.kills + st.deaths) > 0 then
        eff = st.kills / (st.kills + st.deaths) * 100.0
      end
      ClientPrint(id, 2, string.format("[Lambda] %-15s K:%-3d D:%-3d HS:%-3d DMG:%-5d EFF:%.0f%%", name, st.kills, st.deaths, st.headshots, st.damage, eff))
    end
  end
end

function OnClientConnect(id, name, ip)
  InitPlayer(id)
  InitRoundData(id)
  KillStreak[id] = 0
  MultiKill[id]  = 0
  return true
end

function OnPlayerSpawn(id)
  InitPlayer(id)
  InitRoundData(id)
end

function OnTakeDamage(victimId, attackerId, damage, hitGroup)
  if attackerId <= 0 or attackerId > MAX_CLIENTS then return end
  if attackerId == victimId then return end

  InitPlayer(attackerId)
  local st = PlayerStats[attackerId]
  st.damage = st.damage + damage
  st.hits   = st.hits   + 1
  if hitGroup >= 1 and hitGroup <= 7 then
    st.hitgroups[hitGroup] = st.hitgroups[hitGroup] + 1
    if hitGroup == 1 then
      st.headshots = st.headshots + 1
      ClientPrint(attackerId, 2, "[Lambda] Headshot!")
    end
  end

  TrackHit(victimId, attackerId, damage, hitGroup)
end

function OnPlayerKilled(victimId, killerId, weaponName)
  InitPlayer(victimId)

  if killerId == 0 or killerId == victimId then
    PlayerStats[victimId].deaths = PlayerStats[victimId].deaths + 1
    PlayerStats[victimId].suicides = PlayerStats[victimId].suicides + 1
    PlayerStats[victimId].last_killer = nil
    ResetStreak(victimId)
    local name = GetPlayerName(victimId) or "?"
    ClientPrint(0, 2, string.format("[Lambda] %s committed suicide.", name))
  else
    InitPlayer(killerId)
    PlayerStats[killerId].kills = PlayerStats[killerId].kills + 1
    PlayerStats[victimId].deaths = PlayerStats[victimId].deaths + 1
    
    PlayerStats[victimId].last_killer = GetPlayerName(killerId)
    PlayerStats[victimId].last_killer_hp = math.floor(GetPlayerHealth(killerId))
    PlayerStats[victimId].last_killer_weapon = weaponName

    if not FirstBloodDone then
      FirstBloodDone = true
      local kname = GetPlayerName(killerId) or "?"
      ClientPrint(0, 2, string.format("[Lambda] %s drew FIRST BLOOD!", kname))
    end

    OnKillStreak(killerId)
    ResetStreak(victimId)
    ShowKillReport(killerId, victimId)
    ShowAttackerReport(victimId, killerId)
  end
end

local _lastMap = ""

AddFrameHook("LambdaStatsMapCheck", function(t)
  local map = GetMapName()
  if map ~= _lastMap then
    _lastMap = map
    FirstBloodDone = false
    PlayerStats = {}
    AttackerData = {}
    VictimData = {}
    KillStreak = {}
    MultiKill = {}
    MKTimer = {}
  end
end)

local function BuildRanking()
  local list = {}
  for i = 1, MAX_CLIENTS do
    local name = GetPlayerName(i)
    if name and name ~= "" then
      InitPlayer(i)
      list[#list + 1] = { id = i, name = name, st = PlayerStats[i] }
    end
  end
  table.sort(list, function(a, b)
    if a.st.kills ~= b.st.kills then return a.st.kills > b.st.kills end
    return a.st.deaths < b.st.deaths
  end)
  return list
end

local function CmdRank(id)
  InitPlayer(id)
  local list = BuildRanking()
  local total = #list
  local pos = total

  for i, entry in ipairs(list) do
    if entry.id == id then pos = i break end
  end

  local st = PlayerStats[id]
  local eff = 0.0
  if (st.kills + st.deaths) > 0 then
    eff = st.kills / (st.kills + st.deaths) * 100.0
  end

  ClientPrint(id, 2, string.format("[Lambda] Your rank is %d of %d with %d kill(s), %d death(s), %.1f%% eff.", pos, total, st.kills, st.deaths, eff))
end

local function CmdTop(id, args)
  local list = BuildRanking()
  local total = #list
  local limit = tonumber(args) or 15
  if limit < 1 then limit = 1 end
  if limit > 15 then limit = 15 end
  if limit > total then limit = total end

  local lines = string.format("=== Top %d Players ===\n\n", limit)
  lines = lines .. string.format("%-4s %-20s %5s %5s %5s %6s %6s\n", "#", "Name", "K", "D", "HS", "DMG", "EFF%")
  lines = lines .. string.rep("-", 52) .. "\n"

  for i = 1, limit do
    local e = list[i]
    local st = e.st
    local eff = 0.0
    if (st.kills + st.deaths) > 0 then
      eff = st.kills / (st.kills + st.deaths) * 100.0
    end
    local name = e.name
    if #name > 20 then name = name:sub(1, 17) .. "..." end

    lines = lines .. string.format("%-4d %-20s %5d %5d %5d %6d %5.1f%%\n", i, name, st.kills, st.deaths, st.headshots, st.damage, eff)
  end

  ShowMotd(id, lines, "Top Players")
end

local function CmdHp(id)
  InitPlayer(id)
  local st = PlayerStats[id]
  if not st.last_killer then
    ClientPrint(id, 2, "[Lambda] You have no killer...")
    return
  end
  
  ClientPrint(id, 2, string.format("[Lambda] Killed by %s with %s. He has %d HP left.", st.last_killer, st.last_killer_weapon, st.last_killer_hp))
end

RegisterChatCommand("/statsme", "", CmdStatsMe)
RegisterChatCommand("/stats",   "", CmdStats)
RegisterChatCommand("/rank",    "", CmdRank)
RegisterChatCommand("/top15",   "", function(id) CmdTop(id, "15") end)
RegisterChatCommand("/top",     "", CmdTop)
RegisterChatCommand("/hp",      "", CmdHp)
