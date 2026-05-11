#include "LuaHooks.h"
#include "LuaEngine.h"

extern enginefuncs_t g_engfuncs;

void Hook_ClientCommand(edict_t* pEntity)
{
	int playerId = ENTINDEX(pEntity);
	const char* cmd = g_engfuncs.pfnCmd_Argv(0);
	const char* args = g_engfuncs.pfnCmd_Args();

	if (CLuaEngine::Get().CallClientCommand(playerId, cmd, args))
	{
		RETURN_META(MRES_SUPERCEDE);
	}

	RETURN_META(MRES_IGNORED);
}

qboolean Hook_ClientConnect(edict_t* pEntity, const char* pszName, const char* pszAddress, char szRejectReason[128])
{
	int playerId = ENTINDEX(pEntity);

	if (!CLuaEngine::Get().CallClientConnect(playerId, pszName, pszAddress, szRejectReason))
	{
		RETURN_META_VALUE(MRES_SUPERCEDE, FALSE);
	}

	RETURN_META_VALUE(MRES_IGNORED, TRUE);
}

void Hook_StartFrame()
{
	CLuaEngine::Get().Think();
	RETURN_META(MRES_IGNORED);
}
