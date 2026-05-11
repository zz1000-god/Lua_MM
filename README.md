# GoldSrc Lua Engine(Not fully implemented, maybe have many bugs)

An engine for Half-Life (Metamod) servers that allows writing full-fledged plugins and modifications in Lua. It provides direct access to the internal game API (Game DLL), entity manipulation, visual effects, and network messages.

You need to compile plugin and luajit alone

## Features

* **Hot Reloading:** The `lua_reload` command updates all scripts on the fly without the need to restart the server.
* **Metamod Integration:** Access to `g_engfuncs` and `gpGamedllFuncs` for direct interaction with the GoldSrc engine.
* **Hook System:** Ability to hook into global events such as `OnFrame` (every server tick), player connections, damage events, and deaths.
* **Entity Manipulation:** Modify `pev` parameters, give items bypassing console commands, teleport entities, and apply `RenderFx` effects.
* **User Interface:** Built-in functions for handling HUD messages, menus, and MOTD windows.

## Installation

1. Compile the C++ project into a dynamic library (e.g., `luamod.dll` or `luamod.so`).
2. Create the `addons/luamod/` directory in your server's root folder (usually `valve/`).
3. Place the compiled binary file into `addons/luamod/dlls/`.
4. Open your `addons/metamod/plugins.ini` file and add the following line:
   `win32 addons/luamod/dlls/luamod.dll` (or `linux addons/luamod/dlls/luamod.so`).
5. Place your Lua scripts (including `main.lua`) into the `addons/luamod/scripts/` directory.
6. Start the server.

## Directory Structure

```text
valve/
  addons/
    luamod/
      dlls/
        luamod.dll
      scripts/
        main.lua
        modules/
          auth.lua
          cheat.lua
          timers.lua
```

## Usage Example (Lua)

Below is a basic example of creating a chat command to give a player maximum health and armor, accompanied by a sound and a visual effect.

```lua
local kRenderFxGlowShell = 19
local kRenderNormal = 0

-- Cache resources during map load
PrecacheSound("items/suitchargeok1.wav")

local function CmdSuperBoost(id, args)
  -- Restore stats
  SetPlayerHealth(id, 100)
  SetPlayerArmor(id, 100)

  -- Apply green glow
  SetEntityRendering(id, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 50)

  -- Play sound and show message
  EmitSound(id, "items/suitchargeok1.wav", 1.0, 0.8, 100)
  ClientPrint(id, print_chat, "[LUA] Stats restored!")
end

-- Register commands
RegisterCommand("lua_boost", "d", CmdSuperBoost)
RegisterChatCommand("/boost", "d", CmdSuperBoost)
```

## API Quick Reference

Some key functions available in the Lua environment:

**Engine Interaction:**
* `ServerPrint(msg)` — Prints text to the server console.
* `ServerCommand(cmd)` — Executes a console command on the server.
* `GetCvarFloat(name)` / `SetCvarString(name, value)` — Cvar manipulation.
* `GetTime()` — Returns the current server time (`gpGlobals->time`).

**Players and Entities:**
* `GetPlayerName(id)` / `GetPlayerAuthId(id)` — Retrieves player data.
* `SetPlayerHealth(id, hp)` / `SetPlayerArmor(id, armor)` — Modifies player stats.
* `GiveItem(id, item_class)` — Safely spawns and gives an item to a player.
* `SetEntityOrigin(id, x, y, z)` — Teleports an entity.
* `SetEntityRendering(id, fx, r, g, b, render, amt)` — Applies visual effects.
* `SetPlayerMoveType(id, type)` — Changes movement type (e.g., Noclip).

**Communication and Effects:**
* `ClientPrint(id, type, msg)` — Sends a message to a player's chat or console.
* `ShowHudMessage(id, text, r, g, b, x, y, channel, holdTime)` — Displays on-screen text.
* `EmitSound(id, sample, vol, attn, pitch)` — Plays a spatial sound from an entity.

## Author
**Kv4sMan**
