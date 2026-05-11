-- modules/mapchooser.lua
local SELECTMAPS = 5
local votingActive = false
local mapList = {}
local nextMaps = {}
local votes = {}

RegisterCvar("lua_nextmap", "")

local function LoadMapList()
    local file = io.open("valve/addons/luamod/configs/maps.ini", "r")
    if not file then return end
    
    local current = GetMapName()
    for line in file:lines() do
        line = string.match(line, "^%s*(.-)%s*$")
        if line ~= "" and line ~= current and string.sub(line, 1, 1) ~= ";" then
            table.insert(mapList, line)
        end
    end
    file:close()
end

local function EndVoting()
    votingActive = false
    local winnerIdx = 1
    local max = -1
    
    for i = 1, #votes do
        if votes[i] > max then
            max = votes[i]
            winnerIdx = i
        end
    end

    if winnerIdx == (SELECTMAPS + 1) then
        local step = GetCvarFloat("mp_extendmap_step") or 15.0
        local newLimit = GetCvarFloat("mp_timelimit") + step
        SetCvarFloat("mp_timelimit", newLimit)
        ClientPrint(0, print_chat, "[LUA] Поточну карту продовжено на " .. step .. " хв.")
    else
        local winnerMap = nextMaps[winnerIdx]
        SetCvarString("lua_nextmap", winnerMap)
        ClientPrint(0, print_chat, "[LUA] Голосування завершено! Наступна карта: " .. winnerMap)
    end
end

local function StartVoting()
    if votingActive or #mapList == 0 then return end
    votingActive = true

    nextMaps = {}
    local pool = {table.unpack(mapList)}
    for i = 1, math.min(SELECTMAPS, #pool) do
        local idx = math.random(1, #pool)
        table.insert(nextMaps, pool[idx])
        table.remove(pool, idx)
        votes[i] = 0
    end
    
    local extendIdx = #nextMaps + 1
    votes[extendIdx] = 0

    local items = {}
    for i, m in ipairs(nextMaps) do table.insert(items, {text = m, value = i}) end
    table.insert(items, {text = "Extend Current Map", value = extendIdx})

    for i = 1, 32 do
        if GetPlayerName(i) ~= "" then
            MenuSystem.Show(i, "Vote for Next Map", items, function(id, val)
                if votingActive then 
                    votes[val] = votes[val] + 1 
                    ClientPrint(0, print_chat, GetPlayerName(id) .. " проголосував.")
                end
            end)
        end
    end

    ClientCommand(0, "spk Gman/Gman_Choose2")
    Timers.Create(15.0, EndVoting)
end

local function CheckTime()
    if votingActive then return end
    
    local limit = GetCvarFloat("mp_timelimit")
    if limit <= 0 then 
        Timers.Create(30.0, CheckTime)
        return 
    end

    local timeleft = (limit * 60.0) - GetTime()
    
    if timeleft <= 120.0 and timeleft > 0 then
        StartVoting()
    else
        Timers.Create(10.0, CheckTime)
    end
end

LoadMapList()
Timers.Create(20.0, CheckTime)
