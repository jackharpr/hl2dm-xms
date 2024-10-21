#if (!defined BASE_INC)
#define BASE_INC

#include <dhooks>

#pragma semicolon 1
#pragma newdecls  required

static bool gWasLateLoaded;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int errorMaxLen)
{
	if (GetEngineVersion() != Engine_HL2DM)
	{
		FormatEx(error, errorMaxLen, "[HL2MP] This plugin is intended for Half-Life 2: Deathmatch only.");
		return APLRes_Failure;
	}

	gWasLateLoaded = late;
	return APLRes_Success;
}

stock bool StartHandleLateLoad()
{
	bool wasLateLoaded = gWasLateLoaded;
	gWasLateLoaded = false;
	return wasLateLoaded;
}

stock DynamicHook LoadDHooksOffset(const char[] file, const char[] functionName, bool throwOnError = true)
{
	GameData data = new GameData(file);
	DynamicHook hook = LoadDHooksOffsetEx(data, functionName, throwOnError);
	delete data;
	return hook;
}

stock DynamicHook LoadDHooksOffsetEx(GameData data, const char[] functionName, bool throwOnError = true)
{
	DynamicHook hook = DynamicHook.FromConf(data, functionName);

	if (hook == null && throwOnError)
	{
		ThrowError("Couldn't load %s offset from gamedata", functionName);
	}

	return hook;
}

#endif // BASE_INC