-- modules/menu_system.lua
_G.MenuSystem = {}
MenuSystem.ActiveMenus = {}

function MenuSystem.Show(playerId, title, items, callback, page)
    page = page or 1
    local perPage = 7
    local totalItems = #items
    local totalPages = math.ceil(totalItems / perPage)
    if totalPages == 0 then totalPages = 1 end
    if page > totalPages then page = totalPages end
    
    local text = "\\y" .. title .. " (" .. page .. "/" .. totalPages .. ")\\w\n\n"
    
    local startIdx = (page - 1) * perPage + 1
    local endIdx = math.min(page * perPage, totalItems)
    
    local keysMask = 0
    local slot = 1
    
    for i = startIdx, endIdx do
        text = text .. "\\r" .. slot .. ".\\w " .. items[i].text .. "\n"
        keysMask = keysMask + (2 ^ (slot - 1))
        slot = slot + 1
    end
    
    text = text .. "\n"
    
    local hasBack = page > 1
    local hasNext = page < totalPages
    
    if hasBack then
        text = text .. "\\r8.\\w Back\n"
        keysMask = keysMask + (2 ^ 7)
    end
    
    if hasNext then
        text = text .. "\\r9.\\w Next\n"
        keysMask = keysMask + (2 ^ 8)
    end
    
    text = text .. "\\r0.\\w Exit\n"
    keysMask = keysMask + (2 ^ 9)
    
    MenuSystem.ActiveMenus[playerId] = {
        title = title,
        items = items,
        cb = callback,
        page = page,
        perPage = perPage,
        hasBack = hasBack,
        hasNext = hasNext
    }
    
    ShowMenu(playerId, keysMask, -1, text)
end

function MenuSystem.HandleSelect(playerId, keyStr)
    local menu = MenuSystem.ActiveMenus[playerId]
    if not menu then return false end
    
    local key = tonumber(keyStr)
    
    if key == 10 then 
        MenuSystem.ActiveMenus[playerId] = nil
        return true 
    end
    
    if key == 8 and menu.hasBack then
        MenuSystem.Show(playerId, menu.title, menu.items, menu.cb, menu.page - 1)
        return true
    end
    
    if key == 9 and menu.hasNext then
        MenuSystem.Show(playerId, menu.title, menu.items, menu.cb, menu.page + 1)
        return true
    end
    
    local itemIndex = (menu.page - 1) * menu.perPage + key
    local selectedItem = menu.items[itemIndex]
    
    if selectedItem then
        MenuSystem.ActiveMenus[playerId] = nil
        menu.cb(playerId, selectedItem.value, menu.page)
    end
    
    return true
end
