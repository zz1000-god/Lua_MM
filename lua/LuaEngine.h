#pragma once

#include <string>
#include "lua.hpp"

class CLuaEngine
{
public:
	static CLuaEngine& Get()
	{
		static CLuaEngine instance;
		return instance;
	}

	bool Init();
	void Shutdown();
	bool LoadScript(const std::string& scriptName);

	bool CallClientCommand(int playerId, const char* cmd, const char* args);
	bool CallClientConnect(int playerId, const char* name, const char* ip, char* rejectReason);

	bool CallEvent_PlayerKilled(int victimId, int killerId, const char* weaponName);
	bool CallEvent_TakeDamage(int victimId, int attackerId, float damage, int hitGroup);
	bool CallEvent_PlayerSpawn(int playerId);

	void Think();

	void Reload();
	static void Cmd_Reload();

private:
	CLuaEngine() = default;
	~CLuaEngine() = default;

	CLuaEngine(const CLuaEngine&) = delete;
	CLuaEngine& operator=(const CLuaEngine&) = delete;

	void RegisterAPI();

	static int API_ServerPrint(lua_State* L);
	static int API_ServerCommand(lua_State* L);
	static int API_GetPlayerName(lua_State* L);
	static int API_GetPlayerAuthId(lua_State* L);
	static int API_ClientPrint(lua_State* L);
	static int API_ClientCommand(lua_State* L);
	static int API_GetPlayerUserId(lua_State* L);
	static int API_GetUserInfoKey(lua_State* L);
	static int API_ShowMenu(lua_State* L);
	static int API_GetTime(lua_State* L);
	static int API_GetCvarFloat(lua_State* L);
	static int API_GetMapName(lua_State* L);
	static int API_RegisterCvar(lua_State* L);
	static int API_SetCvarString(lua_State* L);
	static int API_GetCvarString(lua_State* L);
	static int API_SetCvarFloat(lua_State* L);
	static int API_GetPlayerHealth(lua_State* L);
	static int API_SetPlayerHealth(lua_State* L);
	static int API_SetPlayerVelocity(lua_State* L);
	static int API_UserKill(lua_State* L);
	static int API_ShowHudMessage(lua_State* L);
	static int API_GetPlayerOrigin(lua_State* L);
	static int API_GetPlayerFrags(lua_State* L);
	static int API_GetPlayerTeam(lua_State* L);
	static int API_ShowMotd(lua_State* L);	
	static int API_SendIntermission(lua_State* L);
	static int API_SetPlayerFlags(lua_State* L);
	static int API_GetPlayerFlags(lua_State* L);
	static int API_SetPlayerMoveType(lua_State* L);
	static int API_GetPlayerMoveType(lua_State* L);
	static int API_GiveItem(lua_State* L);
	static int API_SetPlayerArmor(lua_State* L);
	static int API_GetPlayerArmor(lua_State* L);
	static int API_SetEntityRendering(lua_State* L);
	static int API_SetEntityOrigin(lua_State* L);
	static int API_EmitSound(lua_State* L);
	static int API_PrecacheSound(lua_State* L);
	static int API_PrecacheModel(lua_State* L);

	lua_State* m_L = nullptr;
	std::string m_BaseDir;
};
