#pragma once

#include <extdll.h>
#include <meta_api.h>

void Hook_ClientCommand(edict_t* pEntity);
qboolean Hook_ClientConnect(edict_t* pEntity, const char* pszName, const char* pszAddress, char szRejectReason[128]);
void Hook_StartFrame();
