local function CmdHelp(id)
  ClientPrint(id, print_console, "=== Chat Commands ===")
  for trigger, data in pairs(ChatRouter.Commands) do
    if data.flags == "" or Auth.HasAccess(id, data.flags) then
      ClientPrint(id, print_console, "  " .. trigger)
    end
  end

  ClientPrint(id, print_console, "=== Console Commands ===")
  for cmdName, data in pairs(CmdRouter.List) do
    if data.flags == "" or Auth.HasAccess(id, data.flags) then
      ClientPrint(id, print_console, "  " .. cmdName)
    end
  end
end

RegisterCommand("lua_help", "", CmdHelp)
RegisterChatCommand("/help", "", CmdHelp)
RegisterChatCommand("help", "", CmdHelp)
