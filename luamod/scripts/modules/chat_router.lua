-- modules/chat_router.lua
_G.ChatRouter = {}
ChatRouter.Commands = {}

function _G.RegisterChatCommand(trigger, flags, cb)
    ChatRouter.Commands[string.lower(trigger)] = {
        flags = flags,
        cb = cb
    }
end

function ChatRouter.Process(playerId, text)
    local lowerText = string.lower(text)
    
    -- 1. Check if the exact full text is a command (e.g., "timeleft")
    local cmdData = ChatRouter.Commands[lowerText]
    
    -- 2. If not found, check if the first word is a command (e.g., "/map de_dust2")
    if not cmdData then
        local firstWord = string.match(lowerText, "^(%S+)")
        if firstWord then
            cmdData = ChatRouter.Commands[firstWord]
        end
    end

    if cmdData then
        if not Auth.HasAccess(playerId, cmdData.flags) then
            -- Optional: notify player
            return true 
        end

        cmdData.cb(playerId)
        return true -- Block message from showing in public chat
    end

    return false
end
