function _G.FindPlayer(target)
  local userid = string.match(target, "^#(%d+)$")
  if userid then
    userid = tonumber(userid)
    for i = 1, 32 do
      if GetPlayerUserId(i) == userid then return i end
    end
    return nil
  end

  local lowerTarget = string.lower(target)
  for i = 1, 32 do
    local name = GetPlayerName(i)
    if name and string.find(string.lower(name), lowerTarget, 1, true) then
      return i
    end
  end

  return nil
end
