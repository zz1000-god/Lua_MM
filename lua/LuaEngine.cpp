#include "LuaEngine.h"
#include <extdll.h>
#include <meta_api.h>

extern enginefuncs_t g_engfuncs;
extern gamedll_funcs_t* gpGamedllFuncs;

bool CLuaEngine::Init()
{
	if (m_L) return true;

	m_L = luaL_newstate();
	if (!m_L)
	{
		g_engfuncs.pfnServerPrint("[LUA] FATAL: Cannot create Lua state!\n");
		return false;
	}

	luaL_openlibs(m_L);

	char gameDir[256];
	g_engfuncs.pfnGetGameDir(gameDir);
	m_BaseDir = std::string(gameDir) + "/addons/luamod/scripts/";

	RegisterAPI();

	g_engfuncs.pfnAddServerCommand("lua_reload", Cmd_Reload);

	return true;
}

void CLuaEngine::Shutdown()
{
	if (m_L)
	{
		lua_close(m_L);
		m_L = nullptr;
		g_engfuncs.pfnServerPrint("[LUA] Engine shut down gracefully.\n");
	}
}

bool CLuaEngine::LoadScript(const std::string& scriptName)
{
	if (!m_L) return false;

	std::string fullPath = m_BaseDir + scriptName;

	if (luaL_dofile(m_L, fullPath.c_str()) != LUA_OK)
	{
		g_engfuncs.pfnServerPrint("[LUA] Script Error (");
		g_engfuncs.pfnServerPrint(fullPath.c_str());
		g_engfuncs.pfnServerPrint("): ");
		g_engfuncs.pfnServerPrint(lua_tostring(m_L, -1));
		g_engfuncs.pfnServerPrint("\n");

		lua_pop(m_L, 1);
		return false;
	}

	return true;
}

bool CLuaEngine::CallClientCommand(int playerId, const char* cmd, const char* args)
{
	if (!m_L) return false;

	lua_getglobal(m_L, "OnClientCommand");

	if (lua_isfunction(m_L, -1))
	{
		lua_pushinteger(m_L, playerId);
		lua_pushstring(m_L, cmd);
		lua_pushstring(m_L, args);

		if (lua_pcall(m_L, 3, 1, 0) != LUA_OK)
		{
			g_engfuncs.pfnServerPrint("[LUA] Error in OnClientCommand: ");
			g_engfuncs.pfnServerPrint(lua_tostring(m_L, -1));
			g_engfuncs.pfnServerPrint("\n");
			lua_pop(m_L, 1);
			return false;
		}

		bool blockCommand = lua_toboolean(m_L, -1);
		lua_pop(m_L, 1);

		return blockCommand;
	}

	lua_pop(m_L, 1);
	return false;
}

bool CLuaEngine::CallClientConnect(int playerId, const char* name, const char* ip, char* rejectReason)
{
	if (!m_L) return true;

	lua_getglobal(m_L, "OnClientConnect");
	if (lua_isfunction(m_L, -1))
	{
		lua_pushinteger(m_L, playerId);
		lua_pushstring(m_L, name ? name : "Connecting...");
		lua_pushstring(m_L, ip ? ip : "127.0.0.1");

		if (lua_pcall(m_L, 3, 2, 0) != LUA_OK)
		{
			g_engfuncs.pfnServerPrint("[LUA] Error in OnClientConnect: ");
			const char* err = lua_tostring(m_L, -1);
			g_engfuncs.pfnServerPrint(err ? err : "Unknown Lua Error");
			g_engfuncs.pfnServerPrint("\n");
			lua_pop(m_L, 1);
			return true;
		}

		bool allowConnect = lua_toboolean(m_L, -2);
		if (!allowConnect)
		{
			const char* reason = lua_tostring(m_L, -1);
			if (reason)
			{
				strncpy(rejectReason, reason, 127);
				rejectReason[127] = '\0';
			}
		}

		lua_pop(m_L, 2);
		return allowConnect;
	}

	lua_pop(m_L, 1);
	return true;
}

bool CLuaEngine::CallEvent_PlayerKilled(int victimId, int killerId, const char* weaponName)
{
	if (!m_L) return false;

	lua_getglobal(m_L, "OnPlayerKilled");
	if (lua_isfunction(m_L, -1))
	{
		lua_pushinteger(m_L, victimId);
		lua_pushinteger(m_L, killerId);
		lua_pushstring(m_L, weaponName ? weaponName : "world");

		if (lua_pcall(m_L, 3, 0, 0) != LUA_OK)
		{
			g_engfuncs.pfnServerPrint("[LUA] Error in OnPlayerKilled: ");
			g_engfuncs.pfnServerPrint(lua_tostring(m_L, -1));
			g_engfuncs.pfnServerPrint("\n");
			lua_pop(m_L, 1);
			return false;
		}
		return true;
	}
	lua_pop(m_L, 1);
	return false;
}

bool CLuaEngine::CallEvent_TakeDamage(int victimId, int attackerId, float damage, int hitGroup)
{
	if (!m_L) return false;

	lua_getglobal(m_L, "OnTakeDamage");
	if (lua_isfunction(m_L, -1))
	{
		lua_pushinteger(m_L, victimId);
		lua_pushinteger(m_L, attackerId);
		lua_pushnumber(m_L, damage);
		lua_pushinteger(m_L, hitGroup);

		if (lua_pcall(m_L, 4, 0, 0) != LUA_OK)
		{
			g_engfuncs.pfnServerPrint("[LUA] Error in OnTakeDamage: ");
			g_engfuncs.pfnServerPrint(lua_tostring(m_L, -1));
			g_engfuncs.pfnServerPrint("\n");
			lua_pop(m_L, 1);
			return false;
		}
		return true;
	}
	lua_pop(m_L, 1);
	return false;
}

bool CLuaEngine::CallEvent_PlayerSpawn(int playerId)
{
	if (!m_L) return false;

	lua_getglobal(m_L, "OnPlayerSpawn");
	if (lua_isfunction(m_L, -1))
	{
		lua_pushinteger(m_L, playerId);

		if (lua_pcall(m_L, 1, 0, 0) != LUA_OK)
		{
			g_engfuncs.pfnServerPrint("[LUA] Error in OnPlayerSpawn: ");
			g_engfuncs.pfnServerPrint(lua_tostring(m_L, -1));
			g_engfuncs.pfnServerPrint("\n");
			lua_pop(m_L, 1);
			return false;
		}
		return true;
	}
	lua_pop(m_L, 1);
	return false;
}

void CLuaEngine::Think()
{
	if (!m_L) return;

	lua_getglobal(m_L, "OnFrame");

	if (lua_isfunction(m_L, -1))
	{
		lua_pushnumber(m_L, gpGlobals->time);

		if (lua_pcall(m_L, 1, 0, 0) != LUA_OK)
		{
			g_engfuncs.pfnServerPrint("[LUA] Error in OnFrame: ");
			const char* err = lua_tostring(m_L, -1);
			g_engfuncs.pfnServerPrint(err ? err : "Unknown error");
			g_engfuncs.pfnServerPrint("\n");

			lua_pop(m_L, 1);
		}
	}
	else
	{
		lua_pop(m_L, 1);
	}
}

void CLuaEngine::Reload()
{
	g_engfuncs.pfnServerPrint("[LUA] Reloading scripts...\n");

	Shutdown();

	if (Init())
	{
		LoadScript("main.lua");
	}
}

void CLuaEngine::Cmd_Reload()
{
	CLuaEngine::Get().Reload();
}

void CLuaEngine::RegisterAPI()
{
	lua_register(m_L, "ServerPrint", API_ServerPrint);
	lua_register(m_L, "ServerCommand", API_ServerCommand);
	lua_register(m_L, "GetPlayerName", API_GetPlayerName);
	lua_register(m_L, "GetPlayerAuthId", API_GetPlayerAuthId);
	lua_register(m_L, "ClientPrint", API_ClientPrint);
	lua_register(m_L, "ClientCommand", API_ClientCommand);
	lua_register(m_L, "GetPlayerUserId", API_GetPlayerUserId);
	lua_register(m_L, "GetUserInfoKey", API_GetUserInfoKey);
	lua_register(m_L, "ShowMenu", API_ShowMenu);
	lua_register(m_L, "GetTime", API_GetTime);
	lua_register(m_L, "GetCvarFloat", API_GetCvarFloat);
	lua_register(m_L, "GetMapName", API_GetMapName);
	lua_register(m_L, "RegisterCvar", API_RegisterCvar);
	lua_register(m_L, "GetCvarString", API_GetCvarString);
	lua_register(m_L, "SetCvarString", API_SetCvarString);
	lua_register(m_L, "SetCvarFloat", API_SetCvarFloat);
	lua_register(m_L, "GetPlayerHealth", API_GetPlayerHealth);
	lua_register(m_L, "SetPlayerHealth", API_SetPlayerHealth);
	lua_register(m_L, "SetPlayerVelocity", API_SetPlayerVelocity);
	lua_register(m_L, "UserKill", API_UserKill);
	lua_register(m_L, "ShowHudMessage", API_ShowHudMessage);
	lua_register(m_L, "GetPlayerOrigin", API_GetPlayerOrigin);
	lua_register(m_L, "GetPlayerFrags", API_GetPlayerFrags);
	lua_register(m_L, "GetPlayerTeam", API_GetPlayerTeam);
	lua_register(m_L, "ShowMotd", API_ShowMotd);
	lua_register(m_L, "SendIntermission", API_SendIntermission);
	lua_register(m_L, "SetPlayerFlags", API_SetPlayerFlags);
	lua_register(m_L, "GetPlayerFlags", API_GetPlayerFlags);
	lua_register(m_L, "SetPlayerMoveType", API_SetPlayerMoveType);
	lua_register(m_L, "GetPlayerMoveType", API_GetPlayerMoveType);
	lua_register(m_L, "GiveItem", API_GiveItem);
	lua_register(m_L, "SetPlayerArmor", API_SetPlayerArmor);
	lua_register(m_L, "GetPlayerArmor", API_GetPlayerArmor);
	lua_register(m_L, "SetEntityRendering", API_SetEntityRendering);
	lua_register(m_L, "SetEntityOrigin", API_SetEntityOrigin);
	lua_register(m_L, "EmitSound", API_EmitSound);
	lua_register(m_L, "PrecacheSound", API_PrecacheSound);
	lua_register(m_L, "PrecacheModel", API_PrecacheModel);
	lua_register(m_L, "GetPlayerButtons", API_GetPlayerButtons);
	lua_register(m_L, "GetPlayerVelocity", API_GetPlayerVelocity);
}

// =========================================================================
// API REALISATION
// =========================================================================

int CLuaEngine::API_ServerPrint(lua_State* L)
{
	const char* msg = luaL_checkstring(L, 1);
	g_engfuncs.pfnServerPrint("[LUA] ");
	g_engfuncs.pfnServerPrint(msg);
	g_engfuncs.pfnServerPrint("\n");
	return 0;
}

int CLuaEngine::API_ServerCommand(lua_State* L)
{
	const char* cmd = luaL_checkstring(L, 1);
	g_engfuncs.pfnServerCommand((char*)cmd);
	g_engfuncs.pfnServerExecute();
	return 0;
}

int CLuaEngine::API_GetPlayerName(lua_State* L)
{
	int playerId = luaL_checkinteger(L, 1);
	edict_t* pEntity = INDEXENT(playerId);

	if (pEntity && !FNullEnt(pEntity)) {
		const char* name = STRING(pEntity->v.netname);
		lua_pushstring(L, name);
	}
	else {
		lua_pushnil(L);
	}
	return 1;
}

int CLuaEngine::API_GetPlayerAuthId(lua_State* L)
{
	int playerId = luaL_checkinteger(L, 1);
	edict_t* pEntity = INDEXENT(playerId);

	if (pEntity && !FNullEnt(pEntity)) {
		const char* authid = g_engfuncs.pfnGetPlayerAuthId(pEntity);
		lua_pushstring(L, authid ? authid : "STEAM_ID_PENDING");
	}
	else {
		lua_pushnil(L);
	}
	return 1;
}

int CLuaEngine::API_ClientPrint(lua_State* L)
{
	int playerId = luaL_checkinteger(L, 1);
	int printType = luaL_checkinteger(L, 2);
	const char* msg = luaL_checkstring(L, 3);

	if (printType == 2)
	{
		static int msgSayText = 0;
		if (msgSayText == 0) msgSayText = g_engfuncs.pfnRegUserMsg("SayText", -1);

		if (playerId == 0)
		{
			g_engfuncs.pfnMessageBegin(MSG_ALL, msgSayText, NULL, NULL);
			g_engfuncs.pfnWriteByte(0);
			g_engfuncs.pfnWriteString(msg);
			g_engfuncs.pfnMessageEnd();
		}
		else
		{
			edict_t* pEntity = INDEXENT(playerId);
			if (pEntity && !FNullEnt(pEntity))
			{
				g_engfuncs.pfnMessageBegin(MSG_ONE, msgSayText, NULL, pEntity);
				g_engfuncs.pfnWriteByte(playerId);
				g_engfuncs.pfnWriteString(msg);
				g_engfuncs.pfnMessageEnd();
			}
		}
	}
	else
	{
		char buffer[256];
		snprintf(buffer, sizeof(buffer), "%s\n", msg);

		if (playerId == 0)
		{
			for (int i = 1; i <= gpGlobals->maxClients; i++)
			{
				edict_t* pEnt = INDEXENT(i);
				if (pEnt && !FNullEnt(pEnt))
				{
					g_engfuncs.pfnClientPrintf(pEnt, (PRINT_TYPE)printType, buffer);
				}
			}
		}
		else
		{
			edict_t* pEntity = INDEXENT(playerId);
			if (pEntity && !FNullEnt(pEntity))
			{
				g_engfuncs.pfnClientPrintf(pEntity, (PRINT_TYPE)printType, buffer);
			}
		}
	}
	return 0;
}

int CLuaEngine::API_ClientCommand(lua_State* L)
{
	int playerId = luaL_checkinteger(L, 1);
	const char* cmd = luaL_checkstring(L, 2);

	if (playerId == 0)
	{
		for (int i = 1; i <= gpGlobals->maxClients; i++)
		{
			edict_t* pEnt = INDEXENT(i);
			if (pEnt && !FNullEnt(pEnt) && (pEnt->v.flags & FL_CLIENT))
			{
				g_engfuncs.pfnClientCommand(pEnt, "%s\n", cmd);
			}
		}
	}
	else
	{
		edict_t* pEntity = INDEXENT(playerId);
		if (pEntity && !FNullEnt(pEntity) && (pEntity->v.flags & FL_CLIENT))
		{
			g_engfuncs.pfnClientCommand(pEntity, "%s\n", cmd);
		}
	}
	return 0;
}

int CLuaEngine::API_GetPlayerUserId(lua_State* L)
{
	int playerId = luaL_checkinteger(L, 1);
	edict_t* pEntity = INDEXENT(playerId);

	if (pEntity && !FNullEnt(pEntity)) {
		int userid = g_engfuncs.pfnGetPlayerUserId(pEntity);
		lua_pushinteger(L, userid);
	}
	else {
		lua_pushnil(L);
	}
	return 1;
}

int CLuaEngine::API_GetUserInfoKey(lua_State* L)
{
	int playerId = luaL_checkinteger(L, 1);
	const char* key = luaL_checkstring(L, 2);

	edict_t* pEntity = INDEXENT(playerId);
	if (pEntity && !FNullEnt(pEntity)) {
		char* infoBuffer = g_engfuncs.pfnGetInfoKeyBuffer(pEntity);

		if (infoBuffer) {
			const char* value = g_engfuncs.pfnInfoKeyValue(infoBuffer, (char*)key);
			lua_pushstring(L, value ? value : "");
		}
		else {
			lua_pushstring(L, "");
		}
	}
	else {
		lua_pushnil(L);
	}
	return 1;
}

int CLuaEngine::API_ShowMenu(lua_State* L)
{
	int playerId = luaL_checkinteger(L, 1);
	int keys = luaL_checkinteger(L, 2);
	int time = luaL_checkinteger(L, 3);
	const char* menuText = luaL_checkstring(L, 4); 

	edict_t* pEntity = INDEXENT(playerId);
	if (!pEntity || FNullEnt(pEntity)) return 0;

	static int msgShowMenu = 0;
	if (msgShowMenu == 0) {
		msgShowMenu = g_engfuncs.pfnRegUserMsg("ShowMenu", -1);
	}

	int len = strlen(menuText);
	int pos = 0;

	while (pos < len)
	{
		int chunkLen = len - pos;
		bool more = false;
		if (chunkLen > 175) {
			chunkLen = 175;
			more = true;
		}

		char buffer[256];
		strncpy(buffer, menuText + pos, chunkLen);
		buffer[chunkLen] = '\0';

		g_engfuncs.pfnMessageBegin(MSG_ONE, msgShowMenu, NULL, pEntity);
		g_engfuncs.pfnWriteShort(keys);
		g_engfuncs.pfnWriteChar(time);
		g_engfuncs.pfnWriteByte(more ? 1 : 0);
		g_engfuncs.pfnWriteString(buffer);
		g_engfuncs.pfnMessageEnd();

		pos += chunkLen;
	}
	return 0;
}

int CLuaEngine::API_GetTime(lua_State* L)
{
	lua_pushnumber(L, gpGlobals->time);
	return 1;
}

int CLuaEngine::API_GetCvarFloat(lua_State* L)
{
	const char* cvarName = luaL_checkstring(L, 1);
	cvar_t* pCvar = g_engfuncs.pfnCVarGetPointer(cvarName);

	if (pCvar) {
		lua_pushnumber(L, pCvar->value);
	}
	else {
		lua_pushnumber(L, 0.0);
	}
	return 1;
}

int CLuaEngine::API_GetMapName(lua_State* L)
{
	const char* mapName = STRING(gpGlobals->mapname);
	lua_pushstring(L, mapName ? mapName : "unknown");
	return 1;
}

int CLuaEngine::API_RegisterCvar(lua_State* L)
{
	const char* name = luaL_checkstring(L, 1);
	const char* value = luaL_checkstring(L, 2);

	cvar_t* pCvar = new cvar_t;
	pCvar->name = strdup(name);
	pCvar->string = strdup(value);
	pCvar->flags = FCVAR_SERVER | FCVAR_EXTDLL;
	pCvar->value = (float)atof(value);
	pCvar->next = nullptr;

	g_engfuncs.pfnCVarRegister(pCvar);
	return 0;
}

int CLuaEngine::API_SetCvarString(lua_State* L)
{
	const char* name = luaL_checkstring(L, 1);
	const char* value = luaL_checkstring(L, 2);
	g_engfuncs.pfnCVarSetString(name, (char*)value);
	return 0;
}

int CLuaEngine::API_GetCvarString(lua_State* L)
{
	const char* cvarName = luaL_checkstring(L, 1);
	cvar_t* pCvar = g_engfuncs.pfnCVarGetPointer(cvarName);

	if (pCvar && pCvar->string) {
		lua_pushstring(L, pCvar->string);
	}
	else {
		lua_pushstring(L, "");
	}
	return 1;
}

int CLuaEngine::API_SetCvarFloat(lua_State* L)
{
	const char* cvarName = luaL_checkstring(L, 1);
	float cvarValue = luaL_checknumber(L, 2);
	g_engfuncs.pfnCvar_DirectSet((cvar_t*)g_engfuncs.pfnCVarGetPointer(cvarName), (char*)std::to_string(cvarValue).c_str());
	return 0;
}

int CLuaEngine::API_GetPlayerHealth(lua_State* L)
{
	int id = luaL_checkinteger(L, 1);
	edict_t* pEnt = INDEXENT(id);
	if (pEnt && !FNullEnt(pEnt)) lua_pushnumber(L, pEnt->v.health);
	else lua_pushnumber(L, 0);
	return 1;
}

int CLuaEngine::API_SetPlayerHealth(lua_State* L)
{
	int id = luaL_checkinteger(L, 1);
	float hp = (float)luaL_checknumber(L, 2);
	edict_t* pEnt = INDEXENT(id);
	if (pEnt && !FNullEnt(pEnt)) pEnt->v.health = hp;
	return 0;
}

int CLuaEngine::API_SetPlayerVelocity(lua_State* L)
{
	int id = luaL_checkinteger(L, 1);
	float x = (float)luaL_checknumber(L, 2);
	float y = (float)luaL_checknumber(L, 3);
	float z = (float)luaL_checknumber(L, 4);
	edict_t* pEnt = INDEXENT(id);
	if (pEnt && !FNullEnt(pEnt)) {
		pEnt->v.velocity.x = x;
		pEnt->v.velocity.y = y;
		pEnt->v.velocity.z = z;
	}
	return 0;
}

int CLuaEngine::API_UserKill(lua_State* L)
{
	int id = luaL_checkinteger(L, 1);
	edict_t* pEnt = INDEXENT(id);
	if (pEnt && !FNullEnt(pEnt) && pEnt->v.health > 0) {
		g_engfuncs.pfnClientCommand(pEnt, "kill\n");
	}
	return 0;
}

int CLuaEngine::API_ShowHudMessage(lua_State* L)
{
	int id = luaL_checkinteger(L, 1);
	const char* text = luaL_checkstring(L, 2);
	int r = luaL_checkinteger(L, 3);
	int g = luaL_checkinteger(L, 4);
	int b = luaL_checkinteger(L, 5);
	float x = (float)luaL_checknumber(L, 6);
	float y = (float)luaL_checknumber(L, 7);
	int channel = luaL_checkinteger(L, 8);
	float holdTime = (float)luaL_checknumber(L, 9);

	int effect = 0;
	float fadein = 0.5f;
	float fadeout = 0.5f;

	if (lua_gettop(L) >= 10) effect = luaL_checkinteger(L, 10);
	if (lua_gettop(L) >= 11) fadein = (float)luaL_checknumber(L, 11);
	if (lua_gettop(L) >= 12) fadeout = (float)luaL_checknumber(L, 12);

	short fix_x = (short)(x * 8192.0f);
	short fix_y = (short)(y * 8192.0f);
	unsigned short fix_fadein = (unsigned short)(fadein * 256.0f);
	unsigned short fix_fadeout = (unsigned short)(fadeout * 256.0f);
	unsigned short fix_hold = (unsigned short)(holdTime * 256.0f);
	unsigned short fix_fx = (unsigned short)(0.0f * 256.0f);

	auto WritePayload = [&]() {
		g_engfuncs.pfnWriteByte(29);
		g_engfuncs.pfnWriteByte(channel & 0xFF);
		g_engfuncs.pfnWriteShort(fix_x);
		g_engfuncs.pfnWriteShort(fix_y);
		g_engfuncs.pfnWriteByte(effect);

		g_engfuncs.pfnWriteByte(r); g_engfuncs.pfnWriteByte(g); g_engfuncs.pfnWriteByte(b); g_engfuncs.pfnWriteByte(0);
		g_engfuncs.pfnWriteByte(255); g_engfuncs.pfnWriteByte(255); g_engfuncs.pfnWriteByte(255); g_engfuncs.pfnWriteByte(255);

		g_engfuncs.pfnWriteShort(fix_fadein);
		g_engfuncs.pfnWriteShort(fix_fadeout);
		g_engfuncs.pfnWriteShort(fix_hold);

		if (effect == 2) {
			g_engfuncs.pfnWriteShort(fix_fx);
		}

		g_engfuncs.pfnWriteString(text);
		};

	if (id == 0) {
		g_engfuncs.pfnMessageBegin(MSG_ALL, SVC_TEMPENTITY, NULL, NULL);
		WritePayload();
		g_engfuncs.pfnMessageEnd();
	}
	else {
		edict_t* pEnt = INDEXENT(id);
		if (pEnt && !FNullEnt(pEnt)) {
			g_engfuncs.pfnMessageBegin(MSG_ONE, SVC_TEMPENTITY, NULL, pEnt);
			WritePayload();
			g_engfuncs.pfnMessageEnd();
		}
	}
	return 0;
}

int CLuaEngine::API_GetPlayerOrigin(lua_State* L)
{
	int id = luaL_checkinteger(L, 1);
	edict_t* pEnt = INDEXENT(id);

	if (pEnt && !FNullEnt(pEnt) && (pEnt->v.flags & FL_CLIENT))
	{
		lua_pushnumber(L, pEnt->v.origin.x);
		lua_pushnumber(L, pEnt->v.origin.y);
		lua_pushnumber(L, pEnt->v.origin.z);
		return 3;
	}

	lua_pushnumber(L, 0.0);
	lua_pushnumber(L, 0.0);
	lua_pushnumber(L, 0.0);
	return 3;
}

int CLuaEngine::API_GetPlayerFrags(lua_State* L)
{
	int id = luaL_checkinteger(L, 1);
	edict_t* pEnt = INDEXENT(id);

	if (pEnt && !FNullEnt(pEnt) && (pEnt->v.flags & FL_CLIENT))
	{
		lua_pushnumber(L, pEnt->v.frags);
		return 1;
	}

	lua_pushnumber(L, 0.0);
	return 1;
}

int CLuaEngine::API_GetPlayerTeam(lua_State* L)
{
	int id = luaL_checkinteger(L, 1);
	edict_t* pEnt = INDEXENT(id);

	if (pEnt && !FNullEnt(pEnt) && (pEnt->v.flags & FL_CLIENT))
	{
		lua_pushinteger(L, pEnt->v.team);
		return 1;
	}

	lua_pushinteger(L, 0);
	return 1;
}

int CLuaEngine::API_ShowMotd(lua_State* L)
{
	int         playerId = luaL_checkinteger(L, 1);
	const char* message = luaL_checkstring(L, 2);

	edict_t* pEntity = INDEXENT(playerId);
	if (!pEntity || FNullEnt(pEntity) || !(pEntity->v.flags & FL_CLIENT))
		return 0;

	static int msgMOTD = 0;
	if (msgMOTD == 0)
		msgMOTD = g_engfuncs.pfnRegUserMsg("MOTD", -1);

	int len = (int)strlen(message);
	int pos = 0;

	while (true)
	{
		int  remaining = len - pos;
		int  chunkLen = (remaining > 60) ? 60 : remaining;
		bool isFinal = (remaining <= 60);

		char buffer[64];
		memcpy(buffer, message + pos, chunkLen);
		buffer[chunkLen] = '\0';

		g_engfuncs.pfnMessageBegin(MSG_ONE, msgMOTD, NULL, pEntity);
		g_engfuncs.pfnWriteByte(isFinal ? 1 : 0);
		g_engfuncs.pfnWriteString(buffer);
		g_engfuncs.pfnMessageEnd();

		pos += chunkLen;
		if (isFinal) break;
	}
	return 0;
}

int CLuaEngine::API_SendIntermission(lua_State* L)
{
	g_engfuncs.pfnMessageBegin(MSG_ALL, SVC_INTERMISSION, NULL, NULL);
	g_engfuncs.pfnMessageEnd();
	return 0;
}

int CLuaEngine::API_SetPlayerFlags(lua_State* L)
{
	int id = luaL_checkinteger(L, 1);
	int flags = luaL_checkinteger(L, 2);
	bool enable = lua_toboolean(L, 3);
	edict_t* pEnt = INDEXENT(id);
	if (pEnt && !FNullEnt(pEnt)) {
		if (enable)
			pEnt->v.flags |= flags;
		else
			pEnt->v.flags &= ~flags;
	}
	return 0;
}

int CLuaEngine::API_GetPlayerFlags(lua_State* L)
{
	int id = luaL_checkinteger(L, 1);
	edict_t* pEnt = INDEXENT(id);
	if (pEnt && !FNullEnt(pEnt))
		lua_pushinteger(L, pEnt->v.flags);
	else
		lua_pushinteger(L, 0);
	return 1;
}

int CLuaEngine::API_SetPlayerMoveType(lua_State* L)
{
	int id = luaL_checkinteger(L, 1);
	int movetype = luaL_checkinteger(L, 2);
	edict_t* pEnt = INDEXENT(id);

	if (pEnt && !FNullEnt(pEnt) && (pEnt->v.flags & FL_CLIENT)) {
		pEnt->v.movetype = movetype;
	}
	return 0;
}

int CLuaEngine::API_GetPlayerMoveType(lua_State* L)
{
	int id = luaL_checkinteger(L, 1);
	edict_t* pEnt = INDEXENT(id);

	if (pEnt && !FNullEnt(pEnt) && (pEnt->v.flags & FL_CLIENT)) {
		lua_pushinteger(L, pEnt->v.movetype);
	}
	else {
		lua_pushinteger(L, 0);
	}
	return 1;
}

int CLuaEngine::API_GiveItem(lua_State* L)
{
	int id = luaL_checkinteger(L, 1);
	const char* itemName = luaL_checkstring(L, 2);
	edict_t* pPlayer = INDEXENT(id);

	if (!pPlayer || FNullEnt(pPlayer) || !(pPlayer->v.flags & FL_CLIENT)) {
		return 0;
	}

	int iszItem = g_engfuncs.pfnAllocString(itemName);
	edict_t* pItem = g_engfuncs.pfnCreateNamedEntity(iszItem);

	if (FNullEnt(pItem)) {
		return 0;
	}

	pItem->v.origin = pPlayer->v.origin;
	pItem->v.spawnflags |= (1 << 30); // SF_NORESPAWN

	gpGamedllFuncs->dllapi_table->pfnSpawn(pItem);

	int saveSolid = pItem->v.solid;

	gpGamedllFuncs->dllapi_table->pfnTouch(pItem, pPlayer);

	if (pItem->v.solid == saveSolid) {
		g_engfuncs.pfnRemoveEntity(pItem);
	}

	return 0;
}

int CLuaEngine::API_SetPlayerArmor(lua_State* L)
{
	int id = luaL_checkinteger(L, 1);
	float armor = (float)luaL_checknumber(L, 2);
	edict_t* pEnt = INDEXENT(id);
	if (pEnt && !FNullEnt(pEnt)) {
		pEnt->v.armorvalue = armor;
	}
	return 0;
}

int CLuaEngine::API_GetPlayerArmor(lua_State* L)
{
	int id = luaL_checkinteger(L, 1);
	edict_t* pEnt = INDEXENT(id);
	if (pEnt && !FNullEnt(pEnt)) {
		lua_pushnumber(L, pEnt->v.armorvalue);
	}
	else {
		lua_pushnumber(L, 0);
	}
	return 1;
}

int CLuaEngine::API_SetEntityRendering(lua_State* L)
{
	int id = luaL_checkinteger(L, 1);
	int fx = luaL_checkinteger(L, 2);
	int r = luaL_checkinteger(L, 3);
	int g = luaL_checkinteger(L, 4);
	int b = luaL_checkinteger(L, 5);
	int render = luaL_checkinteger(L, 6);
	float amount = (float)luaL_checknumber(L, 7);

	edict_t* pEnt = INDEXENT(id);
	if (pEnt && !FNullEnt(pEnt)) {
		pEnt->v.renderfx = fx;
		pEnt->v.rendercolor.x = r;
		pEnt->v.rendercolor.y = g;
		pEnt->v.rendercolor.z = b;
		pEnt->v.rendermode = render;
		pEnt->v.renderamt = amount;
	}
	return 0;
}

int CLuaEngine::API_SetEntityOrigin(lua_State* L)
{
	int id = luaL_checkinteger(L, 1);
	float x = (float)luaL_checknumber(L, 2);
	float y = (float)luaL_checknumber(L, 3);
	float z = (float)luaL_checknumber(L, 4);

	edict_t* pEnt = INDEXENT(id);
	if (pEnt && !FNullEnt(pEnt)) {
		pEnt->v.origin.x = x;
		pEnt->v.origin.y = y;
		pEnt->v.origin.z = z;
		g_engfuncs.pfnSetOrigin(pEnt, pEnt->v.origin);
	}
	return 0;
}

int CLuaEngine::API_EmitSound(lua_State* L)
{
	int id = luaL_checkinteger(L, 1);
	const char* sample = luaL_checkstring(L, 2);
	float vol = (float)luaL_optnumber(L, 3, 1.0);
	float attn = (float)luaL_optnumber(L, 4, 0.8); // ATTN_NORM
	int pitch = luaL_optinteger(L, 5, 100); // PITCH_NORM

	edict_t* pEnt = INDEXENT(id);
	if (pEnt && !FNullEnt(pEnt)) {
		// CHAN_AUTO = 0
		g_engfuncs.pfnEmitSound(pEnt, 0, sample, vol, attn, 0, pitch);
	}
	return 0;
}

int CLuaEngine::API_PrecacheSound(lua_State* L)
{
	const char* sample = luaL_checkstring(L, 1);
	g_engfuncs.pfnPrecacheSound((char*)sample);
	return 0;
}

int CLuaEngine::API_PrecacheModel(lua_State* L)
{
	const char* model = luaL_checkstring(L, 1);
	g_engfuncs.pfnPrecacheModel((char*)model);
	return 0;
}

int CLuaEngine::API_GetPlayerButtons(lua_State* L)
{
	int id = luaL_checkinteger(L, 1);
	edict_t* pEnt = INDEXENT(id);
	if (pEnt && !FNullEnt(pEnt) && (pEnt->v.flags & FL_CLIENT)) {
		lua_pushinteger(L, pEnt->v.button);
	}
	else {
		lua_pushinteger(L, 0);
	}
	return 1;
}

int CLuaEngine::API_GetPlayerVelocity(lua_State* L)
{
	int id = luaL_checkinteger(L, 1);
	edict_t* pEnt = INDEXENT(id);
	if (pEnt && !FNullEnt(pEnt) && (pEnt->v.flags & FL_CLIENT)) {
		lua_pushnumber(L, pEnt->v.velocity.x);
		lua_pushnumber(L, pEnt->v.velocity.y);
		lua_pushnumber(L, pEnt->v.velocity.z);
		return 3;
	}
	lua_pushnumber(L, 0.0);
	lua_pushnumber(L, 0.0);
	lua_pushnumber(L, 0.0);
	return 3;
}