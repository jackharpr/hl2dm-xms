/******************************
COMPILE OPTIONS
******************************/
#pragma semicolon 1
#pragma newdecls required

/******************************
NECESSARY INCLUDES
******************************/
#include <sourcemod>
#include <base>
#include <clientprefs>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>
#include <smlib>
#include <basecomm>
#include <jhl2dm>
#include <vphysics>

/******************************
PLUGIN DEFINES
******************************/
#define DEVENABLE	0

/*Team Colors*/
#define PLAYERCOLOR "\x07d8bfd8"
#define TEAMCOLOR	"\x07d2b48c"
#define CHATCOLOR	"\x07ffffff"
#define REBELS		"\x07ff3d42"
#define COMBINE		"\x079fcaf2"
#define SPEC		"\x07ff811c"
#define UNASSIGNED	"\x07f7ff7f"
#define ZOOM_NONE	0
#define ZOOM_XBOW	1
#define ZOOM_SUIT	2
#define ZOOM_TOGL	3
#define FIRSTPERSON 4

/*Setting static strings*/
static const char
	/*Plugin Info*/
	PL_NAME[]		 = "HL2MP - Fixes & Enhancements",
	PL_AUTHOR[]		 = "HL2MP Sourcemodders",
	PL_DESCRIPTION[] = "Half-Life 2: Deathmatch Fixes & Enhancements",
	PL_VERSION[]	 = "1.6.11";

/******************************
PLUGIN HANDLES
******************************/

Handle g_hTeam[MAXPLAYERS + 1],
	hHUD,
	gcFov,
	g_hCookiePlModel,
	g_hCookieFootsteps,
	g_hCookieSndFix,

	g_hWeapon_ShootPosition = INVALID_HANDLE;

/******************************
PLUGIN FLOATS
******************************/
float gfVolume				= 1.0,
	  g_vecOldWeaponShootPos[MAXPLAYERS + 1][3];

/******************************
PLUGIN BOOLEANS
******************************/
bool gbLate,
	g_bPlayerModel[MAXPLAYERS + 1]								 = { true, ... },
								g_bFlipFlopSpeed[MAXPLAYERS + 1] = { true, ... },
								g_bFootsteps[MAXPLAYERS + 1]	 = { true, ... },
								g_bSndFix[MAXPLAYERS + 1]		 = { true, ... },
								g_bTchat,
								gbRoundEnd,
								gbMOTDExists,
								gbTeamplay,

								g_bAuthenticated[MAXPLAYERS + 1] = { false, ... },

								g_bRocketFired[MAXPLAYERS + 1]	 = { false, ... },
								g_bAr2AltFire[MAXPLAYERS + 1]	 = { false, ... };

/******************************
PLUGIN CONVARS
******************************/

ConVar gCvar;

enum struct _gConVar
{
	ConVar g_cTimeleftEnable;
	ConVar g_cTimeleftX;
	ConVar g_cTimeleftY;
	ConVar g_cTimeleftR;
	ConVar g_cTimeleftG;
	ConVar g_cTimeleftB;
	ConVar g_cTimeleftI;
	ConVar sk_auto_reload_time;
	ConVar g_cplayermodelmsg;
	ConVar g_cTeamHook;
	ConVar g_cEnable;
	ConVar g_cChatEnabled;
	ConVar g_cTeamplay;
	ConVar fov_minfov;
	ConVar fov_defaultfov;
	ConVar fov_maxfov;
	ConVar sv_gravity;
	ConVar mp_falldamage;
	ConVar mp_falldamage_multiplier;
	ConVar sm_pluginmessages_check;
	ConVar sm_missing_sounds_fix;
	ConVar sm_hl2_footsteps;
	ConVar mp_forcerespawn;
	ConVar mp_restartgame;
	ConVar fps_max_check;
	ConVar sm_rpg_allow_wep_switch;
	ConVar sm_ar2_allow_wep_switch;
	ConVar fps_max_min_required;
	ConVar fps_max_max_required;
	ConVar sm_hud_stats;
}

_gConVar gConVar;

/******************************
PLUGIN INTEGERS
******************************/
int		 giZoom[MAXPLAYERS + 1],
	iRocket[MAXPLAYERS + 1],
	iOrb[MAXPLAYERS + 1],
	iDeploy[MAXPLAYERS + 1];

/******************************
PLUGIN STRINGMAPS
******************************/
StringMap gmKills,
	gmDeaths,
	gmTeams;

/******************************
PLUGIN STRINGS
******************************/
char g_sFootstepSnds[68][75] = {
	"player/footsteps/concrete1.wav",
	"player/footsteps/concrete2.wav",
	"player/footsteps/concrete3.wav",
	"player/footsteps/concrete4.wav",
	"player/footsteps/chainlink1.wav",
	"player/footsteps/chainlink2.wav",
	"player/footsteps/chainlink3.wav",
	"player/footsteps/chainlink4.wav",
	"player/footsteps/dirt1.wav",
	"player/footsteps/dirt2.wav",
	"player/footsteps/dirt3.wav",
	"player/footsteps/dirt4.wav",
	"player/footsteps/duct1.wav",
	"player/footsteps/duct2.wav",
	"player/footsteps/duct3.wav",
	"player/footsteps/duct4.wav",
	"player/footsteps/grass1.wav",
	"player/footsteps/grass2.wav",
	"player/footsteps/grass3.wav",
	"player/footsteps/grass4.wav",
	"player/footsteps/gravel1.wav",
	"player/footsteps/gravel2.wav",
	"player/footsteps/gravel3.wav",
	"player/footsteps/gravel4.wav",
	"player/footsteps/ladder1.wav",
	"player/footsteps/ladder2.wav",
	"player/footsteps/ladder3.wav",
	"player/footsteps/ladder4.wav",
	"player/footsteps/metal1.wav",
	"player/footsteps/metal2.wav",
	"player/footsteps/metal3.wav",
	"player/footsteps/metal4.wav",
	"player/footsteps/metalgrate1.wav",
	"player/footsteps/metalgrate2.wav",
	"player/footsteps/metalgrate3.wav",
	"player/footsteps/metalgrate4.wav",
	//"player/footsteps/mud1.wav",
	//"player/footsteps/mud2.wav",
	//"player/footsteps/mud3.wav",
	//"player/footsteps/mud4.wav",
	"player/footsteps/sand1.wav",
	"player/footsteps/sand2.wav",
	"player/footsteps/sand3.wav",
	"player/footsteps/sand4.wav",
	//"player/footsteps/slosh1.wav",
	//"player/footsteps/slosh2.wav",
	//"player/footsteps/slosh3.wav",
	//"player/footsteps/slosh4.wav",
	"player/footsteps/tile1.wav",
	"player/footsteps/tile2.wav",
	"player/footsteps/tile3.wav",
	"player/footsteps/tile4.wav",
	//"player/footsteps/wade1.wav",
	//"player/footsteps/wade2.wav",
	//"player/footsteps/wade3.wav",
	//"player/footsteps/wade4.wav",
	"player/footsteps/wood1.wav",
	"player/footsteps/wood2.wav",
	"player/footsteps/wood3.wav",
	"player/footsteps/wood4.wav",
	"player/footsteps/woodpanel1.wav",
	"player/footsteps/woodpanel2.wav",
	"player/footsteps/woodpanel3.wav",
	"player/footsteps/woodpanel4.wav",
	//"physics/body/body_medium_impact_soft3.wav",
	//"physics/body/body_medium_impact_soft4.wav",
	//"physics/cardboard/cardboard_box_impact_soft1.wav",
	//"physics/cardboard/cardboard_box_impact_soft2.wav",
	//"physics/cardboard/cardboard_box_impact_soft3.wav",
	//"physics/cardboard/cardboard_box_impact_soft4.wav",
	//"physics/flesh/flesh_impact_hard1.wav",
	//"physics/flesh/flesh_impact_hard2.wav",
	//"physics/glass/glass_impact_soft1.wav",
	//"physics/glass/glass_impact_soft2.wav",
	//"physics/glass/glass_impact_soft3.wav",
	"physics/glass/glass_sheet_step1.wav",
	"physics/glass/glass_sheet_step2.wav",
	"physics/glass/glass_sheet_step3.wav",
	"physics/glass/glass_sheet_step4.wav",
	"physics/metal/metal_box_footstep1.wav",
	"physics/metal/metal_box_footstep2.wav",
	"physics/metal/metal_box_footstep3.wav",
	"physics/metal/metal_box_footstep4.wav",
	//"physics/metal/metal_grenade_impact_soft1.wav",
	//"physics/metal/metal_grenade_impact_soft2.wav",
	//"physics/metal/metal_grenade_impact_soft3.wav",
	"physics/plaster/ceiling_tile_step1.wav",
	"physics/plaster/ceiling_tile_step2.wav",
	"physics/plaster/ceiling_tile_step3.wav",
	"physics/plaster/ceiling_tile_step4.wav",
	//"physics/plaster/drywall_footstep1.wav",
	//"physics/plaster/drywall_footstep2.wav",
	//"physics/plaster/drywall_footstep3.wav",
	//"physics/plaster/drywall_footstep4.wav",
	//"physics/plastic/plastic_barrel_impact_soft1.wav",
	//"physics/plastic/plastic_barrel_impact_soft2.wav",
	//"physics/plastic/plastic_barrel_impact_soft3.wav",
	//"physics/plastic/plastic_barrel_impact_soft4.wav",
	//"physics/plastic/plastic_box_impact_soft1.wav",
	//"physics/plastic/plastic_box_impact_soft2.wav",
	//"physics/plastic/plastic_box_impact_soft3.wav",
	//"physics/plastic/plastic_box_impact_soft4.wav",
	//"physics/rubber/rubber_tire_impact_soft1.wav",
	"physics/wood/wood_box_footstep1.wav",
	"physics/wood/wood_box_footstep2.wav",
	"physics/wood/wood_box_footstep3.wav",
	"physics/wood/wood_box_footstep4.wav"
};

static const char g_sWepSnds[8][75] = {
	"weapons/crossbow/bolt_load1.wav",
	"weapons/crossbow/bolt_load2.wav",
	"weapons/physcannon/physcannon_claws_close.wav",
	"weapons/physcannon/physcannon_claws_open.wav",
	"weapons/physcannon/physcannon_tooheavy.wav",
	"weapons/physcannon/physcannon_pickup.wav",
	"weapons/physcannon/physcannon_drop.wav",
	"weapons/physcannon/hold_loop.wav"
};

static const char g_sChatSnd[1][25] = {
	"common/talk.wav"
};

static char g_sModels[19][75] = {
	"models/combine_soldier.mdl",
	"models/combine_soldier_prisonguard.mdl",
	"models/combine_super_soldier.mdl",
	"models/police.mdl",
	"models/humans/group03/female_01.mdl",
	"models/humans/group03/female_02.mdl",
	"models/humans/group03/female_03.mdl",
	"models/humans/group03/female_04.mdl",
	"models/humans/group03/female_06.mdl",
	"models/humans/group03/female_07.mdl",
	"models/humans/group03/male_01.mdl",
	"models/humans/group03/male_02.mdl",
	"models/humans/group03/male_03.mdl",
	"models/humans/group03/male_04.mdl",
	"models/humans/group03/male_05.mdl",
	"models/humans/group03/male_06.mdl",
	"models/humans/group03/male_07.mdl",
	"models/humans/group03/male_08.mdl",
	"models/humans/group03/male_09.mdl"
};

static char g_sDisconnectReason[64];

/******************************
DHOOKS
******************************/
DynamicHook gExplosionDamageHook;

/******************************
PLUGIN INFO
******************************/
public Plugin myinfo =
{
	name		= PL_NAME,
	author		= PL_AUTHOR,
	description = PL_DESCRIPTION,
	version		= PL_VERSION
};

/******************************
INITIATE THE PLUGIN
******************************/
public void OnPluginStart()
{
	gExplosionDamageHook = LoadDHooksOffset("dhooks.hl2mp_tinnitus_fix", "OnDamagedByExplosion");

	AddNormalSoundHook(OnSound);

	/*PRECACHE SOUNDS*/
	for (int i = 1; i < sizeof(g_sWepSnds); i++)
	{
		PrecacheSound(g_sWepSnds[i]);
	}

	for (int i = 1; i < sizeof(g_sFootstepSnds); i++)
	{
		PrecacheSound(g_sFootstepSnds[i]);
	}

	for (int i = 1; i < sizeof(g_sChatSnd); i++)
	{
		PrecacheSound(g_sChatSnd[i]);
	}

	/*PRECACHE MODELS*/
	for (int i; i < sizeof(g_sModels); i++)
	{
		PrecacheModel(g_sModels[i]);
	}

	if (gbLate)
	{
		ReplicateToAll("0");
	}

	gmKills			   = CreateTrie();
	gmDeaths		   = CreateTrie();
	gmTeams			   = CreateTrie();

	/*COOKIES*/
	gcFov			   = RegClientCookie("hl2dm_fov", "Field-of-view value", CookieAccess_Public);
	g_hCookiePlModel   = RegClientCookie("hl2dm_playermodel", "Player model client messages", CookieAccess_Public);
	g_hCookieFootsteps = RegClientCookie("hl2dm_footsteps", "Footstep sounds", CookieAccess_Public);
	g_hCookieSndFix	   = RegClientCookie("hl2dm_sndfix", "Sounds fix", CookieAccess_Public);

	/*CONVARS*/
	CreateConVar("sm_hl2mp_fixes_version", PL_VERSION, "Version", FCVAR_DONTRECORD | FCVAR_SPONLY | FCVAR_ARCHIVE);

	gConVar.g_cplayermodelmsg		 = CreateConVar("sm_show_playermodel_msg_global", "1", "Shows message that player model was adjusted based on team", 0, true, 0.0, true, 1.0);
	gConVar.g_cTeamHook				 = CreateConVar("sm_playermodel_fix", "1", "Enable/Disable plugin fix", 0, true, 0.0, true, 1.0);
	gConVar.g_cEnable				 = CreateConVar("sm_connect_status_enable", "1", "Determines if the plugin is enabled", 0, true, 0.0, true, 1.0);
	gConVar.g_cChatEnabled			 = CreateConVar("sm_chat_fix", "1", "Enable/Disable Plugin", 0, true, 0.0, true, 1.0);

	gConVar.g_cTimeleftEnable		 = CreateConVar("sm_timeleft_hud_enable", "1", "Enable timeleft to show on HUD", 0, true, 0.0, true, 1.0);
	gConVar.g_cTimeleftX			 = CreateConVar("sm_timeleft_x", "-1.0", "Position the HUD's timeleft on the X axis");
	gConVar.g_cTimeleftY			 = CreateConVar("sm_timeleft_y", "0.01", "Position the HUD's timeleft on the y axis");
	gConVar.g_cTimeleftR			 = CreateConVar("sm_timeleft_r", "255", "Red color intensity of the HUD's timeleft", 0, true, 0.0, true, 255.0);
	gConVar.g_cTimeleftG			 = CreateConVar("sm_timeleft_g", "220", "Green color intensity of the HUD's timeleft", 0, true, 0.0, true, 255.0);
	gConVar.g_cTimeleftB			 = CreateConVar("sm_timeleft_b", "0", "Blue color intensity of the HUD's timeleft", 0, true, 0.0, true, 255.0);
	gConVar.g_cTimeleftI			 = CreateConVar("sm_timeleft_i", "255", "Amount of transparency of the HUD's timeleft", 0, true, 0.0, true, 255.0);

	gConVar.fov_minfov				 = CreateConVar("fov_minfov", "70", "Minimum FOV allowed on server");
	gConVar.fov_defaultfov			 = CreateConVar("fov_defaultfov", "90", "Default FOV of players on server");
	gConVar.fov_maxfov				 = CreateConVar("fov_maxfov", "110", "Maximum FOV allowed on server");
	gConVar.mp_falldamage_multiplier = CreateConVar("mp_falldamage_multiplier", "1.0", "Multiplier value for the fall damage", _, true, 0.0);
	gConVar.sm_pluginmessages_check	 = CreateConVar("sm_pluginmessages_check", "1", "Check if a client's \"cl_showpluginmessages\" is set to 0 and displays a message to set it to 1", _, true, 0.0, true, 1.0);
	gConVar.sm_missing_sounds_fix	 = CreateConVar("sm_missing_sounds_fix", "1", "Enable/Disable missing sounds fix", 0, true, 0.0, true, 1.0);
	gConVar.sm_hl2_footsteps		 = CreateConVar("sm_hl2_footsteps", "1", "Enable/Disable HL2 footstep sounds", 0, true, 0.0, true, 1.0);

	gConVar.fps_max_check			 = CreateConVar("sm_fps_max_check", "1", "Enable/Disable the checking of client's fps_max value", 0, true, 0.0, true, 1.0);
	gConVar.fps_max_min_required	 = CreateConVar("sm_fps_min", "60", "Minimum value that a client needs to set their fps_max at", 0, true, 10.0);
	gConVar.fps_max_max_required	 = CreateConVar("sm_fps_max", "1000", "Maximum value that a client needs to set their fps_max at", 0, true, 60.0);

	gConVar.sm_rpg_allow_wep_switch	 = CreateConVar("sm_rpg_allow_wep_switch", "0", "Whether players can switch guns after an active rocket has been fired", 0, true, 0.0, true, 1.0);
	gConVar.sm_ar2_allow_wep_switch	 = CreateConVar("sm_ar2_allow_wep_switch", "0", "Whether players can switch guns after an active orb has been fired", 0, true, 0.0, true, 1.0);

	// gConVar.sm_hud_stats			 = CreateConVar("sm_hud_stats", "1", "Shows observed player's information on HUD", 0, true, 0.0, true, 1.0); // TODO: Show observed player's HUD elements

	gConVar.g_cTeamplay				 = FindConVar("mp_teamplay");
	gConVar.mp_falldamage			 = FindConVar("mp_falldamage");
	gConVar.sv_gravity				 = FindConVar("sv_gravity");
	gConVar.mp_forcerespawn			 = FindConVar("mp_forcerespawn");
	gConVar.sk_auto_reload_time		 = FindConVar("sk_auto_reload_time");	 // Tie the relaod time to this ConVar
	gConVar.mp_restartgame			 = FindConVar("mp_restartgame");
	gCvar							 = FindConVar("sv_footsteps");

	/*HOOKING*/
	HookUserMessage(GetUserMessageId("TextMsg"), dfltmsg, true);					 // To get rid of default engine messages
	HookEvent("player_team", playerteam_callback, EventHookMode_Pre);				 // To fix death when names get changed through SM commands
	HookEvent("player_disconnect", playerdisconnect_callback, EventHookMode_Pre);	 // Connect messages
	HookEvent("player_connect_client", Event_PlayerConnect, EventHookMode_Pre);		 // Connect messages
	HookEvent("player_death", event_death, EventHookMode_Pre);
	HookEvent("server_cvar", Event_GameMessage, EventHookMode_Pre);
	HookEvent("round_start", Event_RoundBegin, EventHookMode_Pre);
	HookConVarChange(gConVar.g_cTeamHook, OnConVarChanged_pModelFix);
	HookConVarChange(gConVar.g_cTeamplay, OnConVarChanged_Teamplay);
	HookConVarChange(gConVar.g_cTimeleftEnable, OnConVarChanged_HudTimeleft);

	HookUserMessage(GetUserMessageId("VGUIMenu"), UserMsg_VGUIMenu, false);
	gConVar.sv_gravity.AddChangeHook(OnGravityChanged);

	AddCommandListener(cmd_say, "say");
	AddCommandListener(cmd_tsay, "say_team");
	AddCommandListener(OnClientChangeFOV, "fov");
	AddCommandListener(OnClientToggleZoom, "toggle_zoom");
	AddCommandListener(HandleUse, "phys_swap");
	AddCommandListener(HandleUse, "use");

	/*PUBLIC COMMANDS*/
	RegConsoleCmd("sm_plmdl_msg", Command_playermdlmsg, "Display message that player model was adjusted when switching teams");
	RegConsoleCmd("sm_fov", Command_FOV, "Set your desired field-of-view value");
	RegConsoleCmd("sm_footsteps", Command_footsteps, "Toggle between default or HL2 footstep sounds");
	RegConsoleCmd("sm_sndfix", Command_Sndfix, "Enable/Disable sound fixes");
	RegConsoleCmd("xfix", xfix_credits, "Credits listing");

	BulletFix();

	AutoExecConfig(true, "hl2mp_fix_config");

	for (int i = MaxClients; i > 0; --i)	// Late load for client pref
	{
		if (!AreClientCookiesCached(i))
			continue;

		OnClientCookiesCached(i);
	}

	if (gbLate)
	{
		for (int client = 1; client < MaxClients; client++)
		{
			OnClientPutInServer(client);
		}
	}
}

void BulletFix()
{
	Handle gameData = LoadGameConfigFile("dhooks.weapon_shootposition");	// Bullet position fix by xutaxkamay

	if (gameData == INVALID_HANDLE)
	{
		SetFailState("[SM] FireBullets Fix cannot load: Missing gamedata.");
	}

	else PrintToServer("[SM] FireBullets Fix has successfully loaded.");

	int offset = GameConfGetOffset(gameData, "Weapon_ShootPosition");

	if (offset == -1)
	{
		SetFailState("[FireBullets Fix] failed to find offset");
	}

	LogMessage("Found offset for Weapon_ShootPosition %d", offset);

	g_hWeapon_ShootPosition = DHookCreate(offset, HookType_Entity, ReturnType_Vector, ThisPointer_CBaseEntity);

	if (g_hWeapon_ShootPosition == INVALID_HANDLE)
	{
		SetFailState("[FireBullets Fix] couldn't hook Weapon_ShootPosition");
	}

	CloseHandle(gameData);
}

public Action xfix_credits(int client, int args)
{
	if (!client)
	{
		PrintToServer("===================================\nHL2MP - Fixes & Enhancements\n        Version: %s\n===================================\n\n\
	This plugin is a collection of fixes for Half-Life 2: Deathmatch made possible thanks to:\n \
	1) Adrian - Tinnitus Dhooks fix\n\n \
	2) Benni - Gravity Gun prop hold fix\n \
	3) Chanz - Sprint delay fix\n \
	4) Grey83 - Set local angles fix\n \
	5) Harper - Creator of xFix and fixing a myriad of HL2MP issues!\n \
	6) Peter Brev - Additional HL2MP fixes\n \
	7) Sidez - Grenade glow edict fix\n \
	8) Toizy - Jesus/T-Pose animation fix\n \
	9) V952 - Shotgun lag compensation fix\n \
	10) Xutaxkamay - Bullet fix\n\n \
	xFix is a continuously updated plugin featuring more fixes as they become available!",
					  PL_VERSION);

		return Plugin_Handled;
	}

	if (GetCmdReplySource() == SM_REPLY_TO_CHAT) ReplyToCommand(client, "[SM] Check your console for output");

	PrintToConsole(client, "===================================\nHL2MP - Fixes & Enhancements\n        Version: %s\n===================================\n\n\
	This plugin is a collection of fixes for Half-Life 2: Deathmatch made possible thanks to:\n \
	1) Adrian - Tinnitus Dhooks fix\n\n \
	2) Benni - Gravity Gun prop hold fix\n \
	3) Chanz - Sprint delay fix\n \
	4) Grey83 - Set local angles fix\n \
	5) Harper - Creator of xFix and fixing a myriad of HL2MP issues!\n \
	6) Peter Brev - Additional HL2MP fixes\n \
	7) Sidez - Grenade glow edict fix\n \
	8) Toizy - Jesus/T-Pose animation fix\n \
	9) V952 - Shotgun lag compensation fix\n \
	10) Xutaxkamay - Bullet fix\n\n \
	xFix is a continuously updated plugin featuring more fixes as they become available!",
					  PL_VERSION);

	return Plugin_Handled;
}

public void OnClientCookiesCached(int client)
{
	char sPlMdl[8], sFootsteps[8], SndFix[8];

	GetClientCookie(client, g_hCookiePlModel, sPlMdl, sizeof(sPlMdl));
	GetClientCookie(client, g_hCookieFootsteps, sFootsteps, sizeof(sFootsteps));
	GetClientCookie(client, g_hCookieSndFix, SndFix, sizeof(SndFix));
	g_bPlayerModel[client] = (sPlMdl[0] != '\0' && StringToInt(sPlMdl));
	g_bFootsteps[client]   = (sFootsteps[0] != '\0' && StringToInt(sFootsteps));
	g_bSndFix[client]	   = (SndFix[0] != '\0' && StringToInt(SndFix));
}

void q_PluginMessages(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	if (result != ConVarQuery_Okay)
		return;

	if (strcmp(cvarValue, "0") == 0)	// Help player turn on plugin messages
	{
		PrintToChat(client, "\x01[SM] It looks like menu panels cannot be displayed for you. Please type \x04cl_showpluginmessages 1\x01 in your console.");
		return;
	}
}

void q_fpsmax(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	if (!IsClientInGame(client) || IsFakeClient(client))
		return;

	if (result != ConVarQuery_Okay)
	{
		KickClient(client, "Client command query \"fps_max\" failed. Reconnect.");
		return;
	}

	int cvar = StringToInt(cvarValue);

	if (cvar < GetConVarInt(gConVar.fps_max_min_required) || cvar > GetConVarInt(gConVar.fps_max_max_required))
		KickClient(client, "This server requires your \"fps_max\" value to be set between %d and %d. Your value: %d",
				   GetConVarInt(gConVar.fps_max_min_required), GetConVarInt(gConVar.fps_max_max_required), cvar);

	return;
}

public void OnMapStart()
{
	for (int i = 1; i < sizeof(g_sWepSnds); i++)
	{
		PrecacheSound(g_sWepSnds[i]);
	}

	if (GetConVarInt(gConVar.fps_max_check) == 1)
		if (GetConVarInt(gConVar.fps_max_min_required) > GetConVarInt(gConVar.fps_max_max_required))	// in theory, this shouldn't be required, but this is just a safety net
		{
			// set back to default
			SetConVarInt(gConVar.fps_max_min_required, 10);
			SetConVarInt(gConVar.fps_max_max_required, 60);
		}

	CreateTimer(30.0, CheckAngles, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	if (GetConVarInt(gConVar.g_cTimeleftEnable) == 1)
		CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	gbMOTDExists = (FileExists("cfg/motd.txt") && FileSize("cfg/motd.txt") > 2);
	gbTeamplay	 = gConVar.g_cTeamplay.BoolValue;
	gbRoundEnd	 = false;

	CreateTimer(0.1, T_CheckPlayerStates, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapEnd()
{
	gmKills.Clear();
	gmDeaths.Clear();
}

public Action Event_RoundBegin(Event event, const char[] name, bool dontBroadcast)
{
	gmTeams.Clear();
	gmKills.Clear();
	gmDeaths.Clear();

	for (int client = 1; client <= MaxClients; client++)
	{
		if (client < 1 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
			continue;

		if (IsClientObserver(client))
		{
			Client_SetHideHud(client, HIDEHUD_HEALTH);
		}
	}

	return Plugin_Continue;
}

Action event_death(Event event, const char[] name, bool dontBroadcast)
{
	int client			   = GetClientOfUserId(GetEventInt(event, "userid"));

	g_bAr2AltFire[client]  = false;
	g_bRocketFired[client] = false;

	if (GetConVarInt(gConVar.mp_forcerespawn) > 0)
		CreateTimer(3.0, t_forcerespawn, client, TIMER_FLAG_NO_MAPCHANGE);	  // mp_forcerespawn bypass fix

	return Plugin_Continue;
}

Action t_forcerespawn(Handle timer, int client)
{
	if (IsClientInGame(client) && !IsPlayerAlive(client))
		DispatchSpawn(client);

	return Plugin_Stop;
}

public void OnClientPutInServer(int iClient)
{
	if (GetConVarBool(gConVar.sm_pluginmessages_check))
		QueryClientConVar(iClient, "cl_showpluginmessages", q_PluginMessages);

	if (GetConVarBool(gConVar.fps_max_check))
		QueryClientConVar(iClient, "fps_max", q_fpsmax);

	if (!IsFakeClient(iClient))
		gExplosionDamageHook.HookEntity(Hook_Pre, iClient, OnClientDamagedByExplosion);

	iRocket[iClient] = 0;
	iOrb[iClient]	 = 0;

	CreateTimer(60.0, t_AuthCheck, iClient, TIMER_FLAG_NO_MAPCHANGE);

	SDKHook(iClient, SDKHook_WeaponSwitchPost, OnClientSwitchWeapon);

	DHookEntity(g_hWeapon_ShootPosition, true, iClient, _, Weapon_ShootPosition_Post);

	ReplicateTo(iClient, "0");

	if (GetConVarBool(gConVar.g_cEnable))
	{
		int c_Teamplay;
		c_Teamplay = GetConVarInt(FindConVar("mp_teamplay"));
		if (c_Teamplay == 0)
		{
			PrintToChatAll("\x04%N \x01is connected.", iClient);
		}
	}

	if (!IsClientSourceTV(iClient))
	{
		SDKHook(iClient, SDKHook_WeaponCanSwitchTo, Hook_WeaponCanSwitchTo);
		SDKHook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);

		if (!gbMOTDExists)
		{
			// disable showing the MOTD panel if there's nothing to show
			CreateTimer(0.5, T_BlockConnectMOTD, iClient, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

MRESReturn OnClientDamagedByExplosion(DHookParam params)
{
	return MRES_Supercede; // Prevent ear ringing sound, which may play infinitely (engine DSP bug)
}

public void OnClientPostAdminCheck(int client)
{
	g_bAuthenticated[client] = true;

	if (IsFakeClient(client)) return;

	char id[32];
	GetClientAuthId(client, AuthId_Steam2, id, sizeof(id));

	for (int i = 1; i <= MaxClients; i++)
	{
		if (client == i || !IsClientConnected(i))
			continue;

		char targetid[32];
		GetClientAuthId(i, AuthId_Steam2, id, sizeof(id));

		// if (StrEqual(id, targetid, false))
		if (strcmp(id, targetid, false) == 0)
		{
			KickClient(i, "SteamID Hijack detected.");
			LogMessage("Kicked \"%L\" for hijacking the SteamID of \"%L\".", i, client);
		}
	}
}

Action t_AuthCheck(Handle timer, int client)
{
	if (!IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Stop;

	if (!g_bAuthenticated[client])
	{
		KickClient(client, "Steam authentication ticket failed. Reconnect.");
		LogMessage("[SM] \"%L\" kicked. Unverified SteamID.");
	}

	return Plugin_Stop;
}

/******************************
SOUNDS
******************************/
public Action Command_footsteps(int client, int args)
{
	if (GetConVarInt(gConVar.sm_hl2_footsteps) == 0)
	{
		ReplyToCommand(client, "[SM] This server uses only the default footsteps.");
		return Plugin_Handled;
	}

	char sFootsteps[8];

	if (g_bFootsteps[client])
	{
		g_bFootsteps[client] = false;
		ReplyToCommand(client, "[SM] HL2 footstep sounds are now enabled.");
		IntToString(g_bFootsteps[client], sFootsteps, sizeof(sFootsteps));
		SetClientCookie(client, g_hCookieFootsteps, sFootsteps);
		return Plugin_Handled;
	}

	else if (!g_bFootsteps[client])
	{
		g_bFootsteps[client] = true;
		ReplyToCommand(client, "[SM] Default footstep sounds are now enabled.");
		IntToString(g_bFootsteps[client], sFootsteps, sizeof(sFootsteps));
		SetClientCookie(client, g_hCookieFootsteps, sFootsteps);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_Sndfix(int client, int args)
{
	if (GetConVarInt(gConVar.sm_missing_sounds_fix) == 0)
	{
		ReplyToCommand(client, "[SM] This server has deactivated the missing sounds fix.");
		return Plugin_Handled;
	}

	char SndFix[8];

	if (g_bSndFix[client])
	{
		g_bSndFix[client] = false;
		ReplyToCommand(client, "[SM] Sound fix is now turned on.");
		IntToString(g_bSndFix[client], SndFix, sizeof(SndFix));
		SetClientCookie(client, g_hCookieSndFix, SndFix);
		return Plugin_Handled;
	}

	else if (!g_bSndFix[client])
	{
		g_bSndFix[client] = true;
		ReplyToCommand(client, "[SM] Sound fix is now turned off.");
		IntToString(g_bSndFix[client], SndFix, sizeof(SndFix));
		SetClientCookie(client, g_hCookieSndFix, SndFix);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action OnSound(int iClients[MAXPLAYERS], int &iNumClients, char sSample[PLATFORM_MAX_PATH], int &iEntity, int &iChannel, float &fVolume, int &iLevel, int &iPitch, int &iFlags, char sEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (iEntity < 1 || iEntity > MaxClients || !IsClientInGame(iEntity))
		return Plugin_Continue;

	if (StrContains(sSample, "npc/metropolice/gear", false) != -1 || StrContains(sSample, "npc/combine_soldier/gear", false) != -1 || StrContains(sSample, "npc/footsteps/hardboot_generic", false) != -1)
	{
		float pos[3];
		float ang[3];
		GetClientAbsOrigin(iEntity, pos);
		ang[0] = 90.0;
		ang[1] = 0.0;
		ang[2] = 0.0;

		char   surfname[128];

		Handle trace = TR_TraceRayFilterEx(pos, ang, MASK_SHOT | MASK_SHOT_HULL | MASK_WATER, RayType_Infinite, TraceEntityFilter, iEntity);
		// int	   surfflags = TR_GetSurfaceFlags(trace);
		TR_GetSurfaceName(trace, surfname, sizeof(surfname));
		int surfprops = TR_GetSurfaceProps(trace);
		// int surfdisp  = TR_GetDisplacementFlags(trace);
		CloseHandle(trace);
		// PrintToChat(iEntity, "TRMaterial Flags %i Props %i Name %s Disp: %i", surfflags, surfprops, surfname, surfdisp);

		if (GetConVarInt(gConVar.sm_hl2_footsteps) == 1)
		{
			if (!g_bFootsteps[iEntity])
			{
				if (GetEntityMoveType(iEntity) == MOVETYPE_LADDER)
				{
					Format(sSample, sizeof(sSample), "player/footsteps/ladder%i.wav", GetRandomInt(1, 4));
				}

				//else if (StrContains(surfname, "cardboard", false) != -1)
				//{
				//	Format(sSample, sizeof(sSample), "physics/cardboard/cardboard_box_impact_soft%i.wav", GetRandomInt(1, 4));
				//}

				else if (StrContains(surfname, "ceiling_tile", false) != -1)
				{
					Format(sSample, sizeof(sSample), "physics/plaster/ceiling_tile_step%i.wav", GetRandomInt(1, 4));
				}

				else if (StrContains(surfname, "chainlink", false) != -1 || surfprops == 37)
				{
					Format(sSample, sizeof(sSample), "player/footsteps/chainlink%i.wav", GetRandomInt(1, 4));
				}

				else if (StrContains(surfname, "dirt", false) != -1 || StrContains(surfname, "mud", false) != -1 || surfprops == 9 || surfprops == 10 || surfprops == 44)
				{
					Format(sSample, sizeof(sSample), "player/footsteps/dirt%i.wav", GetRandomInt(1, 4));
				}

				else if (StrContains(surfname, "glass", false) != -1)
				{
					Format(sSample, sizeof(sSample), "physics/glass/glass_sheet_step%i.wav", GetRandomInt(1, 4));
				}

				else if (StrContains(surfname, "grass", false) != -1)
				{
					Format(sSample, sizeof(sSample), "player/footsteps/grass%i.wav", GetRandomInt(1, 4));
				}

				else if (StrContains(surfname, "gravel", false) != -1 || StrContains(surfname, "plaster", false) != -1)
				{
					Format(sSample, sizeof(sSample), "player/footsteps/gravel%i.wav", GetRandomInt(1, 4));
				}

				else if (StrContains(surfname, "metal_box", false) != -1)
				{
					Format(sSample, sizeof(sSample), "physics/metal/metal_box_footstep%i.wav", GetRandomInt(1, 4));
				}

				else if (StrContains(surfname, "metalgrate", false) != -1)
				{
					Format(sSample, sizeof(sSample), "player/footsteps/metalgrate%i.wav", GetRandomInt(1, 4));
				}

				else if (StrContains(surfname, "metalvent", false) != -1)
				{
					Format(sSample, sizeof(sSample), "player/footsteps/duct%i.wav", GetRandomInt(1, 4));
				}

				else if (StrContains(surfname, "sand", false) != -1)
				{
					Format(sSample, sizeof(sSample), "player/footsteps/sand%i.wav", GetRandomInt(1, 4));
				}

				else if (StrContains(surfname, "solidmetal", false) != -1 || surfprops == 3 || surfprops == 8)
				{
					Format(sSample, sizeof(sSample), "player/footsteps/metal%i.wav", GetRandomInt(1, 4));
				}

				else if (StrContains(surfname, "tile", false) != -1)
				{
					Format(sSample, sizeof(sSample), "player/footsteps/tile%i.wav", GetRandomInt(1, 4));
				}

				else if (StrContains(surfname, "wood_box", false) != -1 || StrContains(surfname, "wood_crate", false) != -1)
				{
					Format(sSample, sizeof(sSample), "physics/wood/wood_box_footstep%i.wav", GetRandomInt(1, 4));
				}

				else if (StrContains(surfname, "wood_panel", false) != -1)
				{
					Format(sSample, sizeof(sSample), "player/footsteps/woodpanel%i.wav", GetRandomInt(1, 4));
				}

				else if (StrContains(surfname, "wood", false) != -1 || surfprops == 14 || surfprops == 19)
				{
					Format(sSample, sizeof(sSample), "player/footsteps/wood%i.wav", GetRandomInt(1, 4));
				}

				else
				{
					Format(sSample, sizeof(sSample), "player/footsteps/concrete%i.wav", GetRandomInt(1, 4));
				}
			}
		}
	}

	else if (StrContains(sSample, "npc/footsteps/hardboot_generic", false) == -1)
	{
		if (GetConVarInt(gConVar.sm_missing_sounds_fix) == 1)
		{
			if (!g_bSndFix[iEntity])
			{
				if (strcmp(sSample, "weapons/slam/throw.wav", false) == 0)
				{
					Format(sSample, sizeof(sSample), "weapons/slam/throw.wav");
				}

				else if (strcmp(sSample, "weapons/physcannon/physcannon_tooheavy.wav", false) == 0)
				{
					Format(sSample, sizeof(sSample), "weapons/physcannon/physcannon_tooheavy.wav");
				}

				else if (strcmp(sSample, ")weapons/physcannon/physcannon_claws_close.wav", false) == 0)	   // No idea why it needs a closed bracket here.
				{
					Format(sSample, sizeof(sSample), "weapons/physcannon/physcannon_claws_close.wav");
				}

				else if (strcmp(sSample, ")weapons/physcannon/physcannon_claws_open.wav", false) == 0)	  // Same thing here.
				{
					Format(sSample, sizeof(sSample), "weapons/physcannon/physcannon_claws_close.wav");
				}

				else if (strcmp(sSample, ")weapons/physcannon/physcannon_pickup.wav", false) == 0)	  // Same thing here.
				{
					Format(sSample, sizeof(sSample), "weapons/physcannon/physcannon_pickup.wav");
				}

				else if (StrContains(sSample, ")weapons/physcannon/physcannon_drop.wav", false) != -1)
				{
					Format(sSample, sizeof(sSample), "weapons/physcannon/physcannon_drop.wav");
				}

				else if (strcmp(sSample, "weapons/physcannon/hold_loop.wav", false) == 0)	 // This one seems broken or not included in the sound hook. I will leave it in there in case Sourcemod gets updated with it working.
				{
					Format(sSample, sizeof(sSample), "weapons/physcannon/hold_loop.wav");
				}

				else if (strcmp(sSample, "weapons/crossbow/bolt_load1.wav", false) == 0 || strcmp(sSample, "weapons/crossbow/bolt_load2.wav", false) == 0)
				{
					Format(sSample, sizeof(sSample), "weapons/crossbow/bolt_load%i.wav", GetRandomInt(1, 2));
				}
				else return Plugin_Continue;
			}
			else return Plugin_Continue;
		}
		else return Plugin_Continue;
	}

	if (iEntity > 1 && iEntity <= MaxClients && IsClientInGame(iEntity))
	{
		if (StrContains(sSample, "npc/metropolice/die", false) != -1)
		{
			Format(sSample, sizeof(sSample), "npc/combine_soldier/die%i.wav", GetRandomInt(1, 3));
			return Plugin_Changed;
		}
	}

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientConnected(iClient) || !IsClientInGame(iClient))
			continue;

		EmitSoundToClient(iClient, sSample, iEntity, iChannel, iLevel, iFlags, fVolume * gfVolume, iPitch);
	}

	return Plugin_Changed;
}

void ReplicateTo(int iClient, const char[] sValue)
{
	if (IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		gCvar.ReplicateToClient(iClient, sValue);
	}
}

void ReplicateToAll(const char[] sValue)
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		ReplicateTo(iClient, sValue);
	}
}

bool TraceEntityFilter(int entity, int contentsMask, any data)
{
	if (entity == data)
	{
		return true;
	}
	if (entity > 0 && entity <= MaxClients)
	{
		return false;
	}
	return false;
}

/******************************
PLAYER MODEL FIX
******************************/
public Action playerteam_callback(Event event, const char[] name, bool dontBroadcast)	  // HL2DM: Fixes death when name gets changed through a command
{
	if (GetConVarBool(gConVar.g_cTeamHook))
	{
		SetEventBroadcast(event, true);
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		int team   = GetEventInt(event, "team");

		if (!client || IsFakeClient(client) || !IsClientInGame(client))
			return Plugin_Handled;
		DataPack pack;
		g_hTeam[client] = CreateDataTimer(0.1, changeteamtimer, pack);	  // Using a timer because team == 0 causes team change message to show on client disconnect
		pack.WriteCell(client);
		pack.WriteCell(team);
		return Plugin_Handled;
	}
	else return Plugin_Continue;
}

public Action changeteamtimer(Handle timer, DataPack pack)
{
	int client;
	int team;

	pack.Reset();
	client = pack.ReadCell();
	team   = pack.ReadCell();

	if (team == 3)
	{
		if (!IsClientInGame(client))
			return Plugin_Stop;

		ClientCommand(client, "cl_playermodel %s", g_sModels[GetRandomInt(4, 18)]);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		if (GetConVarBool(gConVar.g_cplayermodelmsg))
		{
			if (g_bPlayerModel[client])
			{
				PrintToChat(client, "Adjusting your player model to match your team.");
			}
		}
		PrintToChatAll("%s%N \x01has joined team: %sRebels", REBELS, client, REBELS);

		return Plugin_Stop;
	}

	if (team == 2)
	{
		if (!IsClientInGame(client))
			return Plugin_Stop;

		ClientCommand(client, "cl_playermodel %s", g_sModels[GetRandomInt(0, 3)]);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		if (GetConVarBool(gConVar.g_cplayermodelmsg))
		{
			if (g_bPlayerModel[client])
			{
				PrintToChat(client, "Adjusting your cl_playermodel setting to match your team.");
			}
		}
		PrintToChatAll("%s%N \x01has joined team: %sCombine", COMBINE, client, COMBINE);

		return Plugin_Stop;
	}

	if (team == 1)
	{
		if (!IsClientInGame(client))
			return Plugin_Stop;

		PrintToChatAll("%s%N \x01has joined team: %sSpectators", SPEC, client, SPEC);

		return Plugin_Stop;
	}

	if (team == 0)
	{
		if (!IsClientInGame(client))
			return Plugin_Stop;

		PrintToChatAll("%s%N \x01has joined team: %sPlayers", UNASSIGNED, client, UNASSIGNED);

		return Plugin_Stop;
	}
	return Plugin_Stop;
}

public Action Command_playermdlmsg(int client, int args)
{
	if (!client || IsFakeClient(client))
		return Plugin_Handled;

	if (GetConVarBool(gConVar.g_cTeamHook))
	{
		if (GetConVarBool(gConVar.g_cplayermodelmsg))
		{
			char sPlMdl[8];

			if (g_bPlayerModel[client])
			{
				g_bPlayerModel[client] = false;
				ReplyToCommand(client, "[SM] Player model update messages will no longer show.");
				IntToString(g_bPlayerModel[client], sPlMdl, sizeof(sPlMdl));
				SetClientCookie(client, g_hCookiePlModel, sPlMdl);
				return Plugin_Handled;
			}

			else if (!g_bPlayerModel[client])
			{
				g_bPlayerModel[client] = true;
				ReplyToCommand(client, "[SM] Now showing player model update messages.");
				IntToString(g_bPlayerModel[client], sPlMdl, sizeof(sPlMdl));
				SetClientCookie(client, g_hCookiePlModel, sPlMdl);
				return Plugin_Handled;
			}
		}

		else
		{
			PrintToChat(client, "[SM] This server has disabled the displaying of adjusted player model messages.");
			return Plugin_Handled;
		}
	}

	else
	{
		PrintToChat(client, "[SM] This plugin is currently disabled.");
		return Plugin_Handled;
	}

	return Plugin_Handled;
}

public Action dfltmsg(UserMsg msg, Handle hMsg, const int[] iPlayers, int iNumPlayers, bool bReliable, bool bInit)
{
	char sMessage[70];

	BfReadString(hMsg, sMessage, sizeof(sMessage), true);
	if (StrContains(sMessage, "more seconds before trying to switch") != -1 || StrContains(sMessage, "Your player model is") != -1 || StrContains(sMessage, "You are on team") != -1)
	{
		return Plugin_Handled;	  // Get rid of those crap messages
	}

	return Plugin_Continue;
}

public void OnConVarChanged_pModelFix(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (strcmp(newValue, "1") == 0)
	{
		PrintToServer("[HL2MP] Player will know that their player model is being updated on team change.");
		LogMessage("Players know player model is being updated on team change.");
	}
	else if (strcmp(newValue, "0") == 0)
	{
		PrintToServer("[HL2MP] Player will no longer know that their player model is being updated on team change.");
		LogMessage("Players no longer know that their player model is being updated on team change.");
	}
}

public void OnConVarChanged_Teamplay(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (FindPluginByFile("xms.smx"))
		return;

	// Reload the map if teamplay is enabled
	for (int i; i <= MaxClients; i++)
	{
		if (i == 0)
		{
			int c_Teamplay;
			c_Teamplay = GetConVarInt(FindConVar("mp_teamplay"));
			if (c_Teamplay == 1)
			{
				PrintToServer("Teamplay has been enabled. Reloading map...");
				PrintToChatAll("Teamplay is now enabled.");
			}

			else if (c_Teamplay == 0)
			{
				PrintToServer("Teamplay has been disabled. Reloading map...");
				PrintToChatAll("Teamplay is now disabled.");
			}
		}
	}
	CreateTimer(0.1, TeamplayChanged_Timer);
	return;
}

public void OnConVarChanged_HudTimeleft(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (GetConVarInt(gConVar.g_cTimeleftEnable) == 1)
		CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action TeamplayChanged_Timer(Handle Timer, any data)
{
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	ForceChangeLevel(sMap, "mp_teamplay changed");
	return Plugin_Stop;
}

/******************************
CONNECT STATUS
******************************/
public Action Event_PlayerConnect(Event event, const char[] name, bool dontBroadcast)
{
	event.BroadcastDisabled = true;
	return Plugin_Continue;
}

public Action playerdisconnect_callback(Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarBool(gConVar.g_cEnable))
	{
		SetEventBroadcast(event, true);
		GetEventString(event, "reason", g_sDisconnectReason, sizeof(g_sDisconnectReason));
		return Plugin_Handled;
	}
	else return Plugin_Continue;
}

public Action playerconnect_callback(Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarBool(gConVar.g_cEnable))
	{
		SetEventBroadcast(event, true);
		return Plugin_Handled;
	}
	else return Plugin_Continue;
}

public bool OnClientConnect(int client)
{
	g_bAuthenticated[client] = false;

	if (GetConVarBool(gConVar.g_cEnable))
	{
		PrintToChatAll("\x04%N \x01is connecting...", client);
	}
	return true;
}

public void OnClientDisconnect(int client)
{
	g_bAuthenticated[client] = false;
	g_bAr2AltFire[client]	 = false;
	g_bRocketFired[client]	 = false;

	if (GetConVarBool(gConVar.g_cEnable))
	{
		if (!IsClientInGame(client))
		{
			PrintToChatAll("%s%N \x01has disconnected [\x04%s\x01]", UNASSIGNED, client, g_sDisconnectReason);
			return;
		}

		int team;
		team = GetClientTeam(client);

		if (!GetClientTeam(client))
		{
			PrintToChatAll("\x04%N \x01has disconnected - [\x04%s\x01]", client, g_sDisconnectReason);
			return;
		}

		if (team == 3)
		{
			PrintToChatAll("%s%N \x01has disconnected - [\x04%s\x01]", REBELS, client, g_sDisconnectReason);
			return;
		}

		else if (team == 2)
		{
			PrintToChatAll("%s%N \x01has disconnected - [\x04%s\x01]", COMBINE, client, g_sDisconnectReason);
			return;
		}

		else if (team == 1)
		{
			PrintToChatAll("%s%N \x01has disconnected [\x04%s\x01]", SPEC, client, g_sDisconnectReason);
			return;
		}

		else if (team == 0)
		{
			PrintToChatAll("%s%N \x01has disconnected [\x04%s\x01]", UNASSIGNED, client, g_sDisconnectReason);
			return;
		}
	}
}

/******************************
CHAT ENHANCEMENT
******************************/
public Action cmd_say(int client, const char[] cmd, int argc)
{
	if (GetConVarInt(gConVar.g_cChatEnabled) == 0) return Plugin_Continue;

	if (!client)
		return Plugin_Continue;

	if (g_bTchat) return Plugin_Handled;

	char s_Text[127];
	int	 iteam;

	iteam = GetClientTeam(client);
	GetCmdArgString(s_Text, sizeof(s_Text));
	StripQuotes(s_Text);

	if (s_Text[0] == '/') return Plugin_Handled;

	if (iteam == 1)
	{
		EmitSoundToAll(g_sChatSnd[0]);
		PrintToChatAll("%s[SPEC] %s%N: \x01%s", SPEC, PLAYERCOLOR, client, s_Text);
		return Plugin_Handled;
	}

	if (iteam == 2)
	{
		EmitSoundToAll(g_sChatSnd[0]);
		PrintToChatAll("%s%N: \x01%s", COMBINE, client, s_Text);
		return Plugin_Handled;
	}

	if (iteam == 3)
	{
		EmitSoundToAll(g_sChatSnd[0]);
		PrintToChatAll("%s%N: \x01%s", REBELS, client, s_Text);
		return Plugin_Handled;
	}

	EmitSoundToAll(g_sChatSnd[0]);
	PrintToChatAll("%s%N: \x01%s", REBELS, client, s_Text);

	return Plugin_Handled;
}

public Action cmd_tsay(int client, const char[] cmd, int argc)
{
	if (GetConVarInt(gConVar.g_cChatEnabled) == 0) return Plugin_Continue;

	bool gag = BaseComm_IsClientGagged(client);

	if (gag) return Plugin_Handled;

	if (GetConVarInt(gConVar.g_cTeamplay) <= 0)
	{
		g_bTchat = true;
		PrintToChat(client, "[SM] Team play must be enabled to use team chat.");
		CreateTimer(0.1, t_reset, _, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Handled;
	}

	char s_Text[127];
	int	 iteam;

	iteam = GetClientTeam(client);
	GetCmdArgString(s_Text, sizeof(s_Text));
	StripQuotes(s_Text);

	if (s_Text[0] == '/') return Plugin_Handled;

	if (iteam == 1)
	{
		EmitSoundToTeam(iteam);
		PrintToChatAll("%s[Spectators] %s%N: \x01%s", SPEC, PLAYERCOLOR, client, s_Text);
		return Plugin_Handled;
	}

	if (iteam == 2)
	{
		EmitSoundToTeam(iteam);
		PrintToChatAll("%s[Combine] %s%N: \x01%s", TEAMCOLOR, COMBINE, client, s_Text);
		return Plugin_Handled;
	}

	if (iteam == 3)
	{
		EmitSoundToTeam(iteam);
		PrintToChatAll("%s[Rebels] %s%N: \x01%s", TEAMCOLOR, REBELS, client, s_Text);
		return Plugin_Handled;
	}

	return Plugin_Handled;
}

public Action t_reset(Handle timer, any data)
{
	g_bTchat = false;
	return Plugin_Stop;
}

/******************************
TIMELEFT ON HUD
******************************/
public Action Timer_Countdown(Handle timer, any data)
{
	if (GetConVarInt(gConVar.g_cTimeleftEnable) == 0)
		return Plugin_Stop;

	static int time;
	GetMapTimeLeft(time);
	if (time < 1)
		return Plugin_Continue;

	static char left[32];
	if (time > 3599)
		FormatEx(left, sizeof(left), "%ih %02im", time / 3600, (time / 60) % 60);
	else if (time > 59)
		FormatEx(left, sizeof(left), "%i%c%02i", time / 60, time % 2 ? '.' : ':', time % 60);
	else FormatEx(left, sizeof(left), "%02i", time);

	if (!hHUD) hHUD = CreateHudSynchronizer();

	float x		  = GetConVarFloat(gConVar.g_cTimeleftX),
		  y		  = GetConVarFloat(gConVar.g_cTimeleftY);
	int red		  = GetConVarInt(gConVar.g_cTimeleftR),
		green	  = GetConVarInt(gConVar.g_cTimeleftG),
		blue	  = GetConVarInt(gConVar.g_cTimeleftB),
		intensity = GetConVarInt(gConVar.g_cTimeleftI);

	SetHudTextParams(x, y, 1.10, red, green, blue, intensity, 0, 0.0, 0.0, 0.0);
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i)) ShowSyncHudText(i, hHUD, left);

	return Plugin_Continue;
}

/******************************
FOV
******************************/
public Action Command_FOV(int iClient, int iArgs)
{
	RequestFOV(iClient, GetCmdArgInt(1));

	return Plugin_Handled;
}

public Action OnClientChangeFOV(int iClient, const char[] sCommand, int iArgs)
{
	RequestFOV(iClient, GetCmdArgInt(1));

	return Plugin_Handled;
}

void RequestFOV(int iClient, int iFov)
{
	if (iFov < GetConVarInt(gConVar.fov_minfov) || iFov > GetConVarInt(gConVar.fov_maxfov))
	{
		PrintToChat(iClient, "%sYour FOV can only be set between %s%d %sand %s%d.", CHATCOLOR, SPEC, GetConVarInt(gConVar.fov_minfov), CHATCOLOR, SPEC, GetConVarInt(gConVar.fov_maxfov));
	}
	else
	{
		SetClientCookieInt(iClient, gcFov, iFov);
		PrintToChat(iClient, "%sFOV set: %s%d", CHATCOLOR, SPEC, iFov);
	}
}

/******************************
SPEC & WEP FIX
******************************/
public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon)
{
	if (!IsClientConnected(iClient) || !IsClientInGame(iClient) || IsFakeClient(iClient))
	{
		return Plugin_Continue;
	}

	int m_hActiveWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");

	if (IsValidEntity(m_hActiveWeapon))
	{
		char activeweaponclsname[32];

		GetEdictClassname(m_hActiveWeapon, activeweaponclsname, sizeof(activeweaponclsname));
		if (StrEqual(activeweaponclsname, "weapon_ar2"))
		{
			int curtime;
			if (GetConVarInt(gConVar.sm_ar2_allow_wep_switch) == 0)
			{
				if (curtime < iDeploy[iClient])
					return Plugin_Continue;

				if (iButtons & IN_ATTACK2)	  // m_flNextSecondaryAttack
				{
					g_bAr2AltFire[iClient] = true;
					CreateTimer(0.51, t_CheckAltFire, iClient, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}

	GetClientEyePosition(iClient, g_vecOldWeaponShootPos[iClient]);

	if (IsClientObserver(iClient))
	{
		int iMode	 = GetEntProp(iClient, Prop_Send, "m_iObserverMode"),
			iTarget	 = GetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget");
		Handle hMenu = StartMessageOne("VGUIMenu", iClient);

		// disable broken spectator menu >
		if (hMenu != INVALID_HANDLE)
		{
			BfWriteString(hMenu, "specmenu");
			BfWriteByte(hMenu, 0);
			EndMessage();
		}

		// force free-look where appropriate - this removes the extra (pointless) third person spec mode >
		if (iMode == SPECMODE_ENEMYVIEW || iTarget <= 0 || !IsClientInGame(iTarget))
		{
			SetEntProp(iClient, Prop_Data, "m_iObserverMode", SPECMODE_FREELOOK);
			Client_SetHideHud(iClient, HIDEHUD_CROSSHAIR);	  // if not spectating someone, hide the crosshair
		}

		// fix bug where spectator can't move while free-looking >
		if (iMode == SPECMODE_FREELOOK)
		{
			SetEntityMoveType(iClient, MOVETYPE_OBSERVER);
			Client_SetHideHud(iClient, HIDEHUD_CROSSHAIR);	  // Crosshair is useless if not in first person
		}

		if (iMode == SPECMODE_FIRSTPERSON)
		{
			Client_SetHideHud(iClient, 2056);	 // Make sure the HUD does not show up when going back first person
		}

		// block spectator sprinting >
		iButtons &= ~IN_SPEED;

		// also fixes 1hp bug > (only works if no mp_restartgame, fixed above)
		return Plugin_Changed;
	}

	if (!IsPlayerAlive(iClient))
	{
		// no use when dead >
		iButtons &= ~IN_USE;
		return Plugin_Changed;
	}

	if ((iButtons & IN_SPEED) && !IsPlayerAlive(iClient))	 // No need to sprint if dead
	{
		iButtons ^= IN_SPEED;
	}

	// shotgun altfire lagcomp fix by V952 >
	int	 iActiveWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	char sWeapon[32];

	if (IsValidEdict(iActiveWeapon))
	{
		GetEdictClassname(iActiveWeapon, sWeapon, sizeof(sWeapon));

		if (StrEqual(sWeapon, "weapon_shotgun") && (iButtons & IN_ATTACK2) == IN_ATTACK2)
		{
			iButtons |= IN_ATTACK;
			return Plugin_Changed;
		}
	}

	// Block crouch standing-view exploit >
	if ((iButtons & IN_DUCK) && GetEntProp(iClient, Prop_Send, "m_bDucked", 1) && GetEntProp(iClient, Prop_Send, "m_bDucking", 1))
	{
		iButtons ^= IN_DUCK;
		return Plugin_Changed;
	}

	if (AreClientCookiesCached(iClient))
	{
		static int iLastButtons[MAXPLAYERS + 1];

		int		   iFov = GetClientCookieInt(iClient, gcFov);

		if (iFov < GetConVarInt(gConVar.fov_minfov) || iFov > GetConVarInt(gConVar.fov_maxfov))
		{
			// fov is out of bounds, reset
			iFov = GetConVarInt(gConVar.fov_defaultfov);
		}

		if (!IsClientObserver(iClient) && IsPlayerAlive(iClient))
		{
			char sCurrentWeapon[32];

			GetClientWeapon(iClient, sCurrentWeapon, sizeof(sCurrentWeapon));

			if (giZoom[iClient] == ZOOM_XBOW || giZoom[iClient] == ZOOM_TOGL)
			{
				// block suit zoom while xbow/toggle-zoomed
				iButtons &= ~IN_ZOOM;
			}

			if (giZoom[iClient] == ZOOM_TOGL)
			{
				if (StrEqual(sCurrentWeapon, "weapon_crossbow"))
				{
					// block xbow zoom while toggle zoomed
					iButtons &= ~IN_ATTACK2;
				}

				SetEntProp(iClient, Prop_Send, "m_iDefaultFOV", 90);
				return Plugin_Continue;
			}

			if (iButtons & IN_ZOOM)
			{
				if (!(iLastButtons[iClient] & IN_ZOOM) && !giZoom[iClient])
				{
					// suit zooming
					giZoom[iClient] = ZOOM_SUIT;
				}
			}
			else if (giZoom[iClient] == ZOOM_SUIT) {
				// no longer suit zooming
				giZoom[iClient] = ZOOM_NONE;
			}

			if ((StrEqual(sCurrentWeapon, "weapon_crossbow") && (iButtons & IN_ATTACK2) && !(iLastButtons[iClient] & IN_ATTACK2)) || (!StrEqual(sCurrentWeapon, "weapon_crossbow") && giZoom[iClient] == ZOOM_XBOW))
			{
				// xbow zoom cycle
				giZoom[iClient] = (giZoom[iClient] == ZOOM_XBOW ? ZOOM_NONE : ZOOM_XBOW);
			}
		}
		else {
			giZoom[iClient] = ZOOM_NONE;
		}

		// set values
		if (giZoom[iClient] || (IsClientObserver(iClient) && GetEntProp(iClient, Prop_Send, "m_iObserverMode") == FIRSTPERSON))
		{
			SetEntProp(iClient, Prop_Send, "m_iDefaultFOV", 90);
		}
		else if (giZoom[iClient] == ZOOM_NONE) {
			SetEntProp(iClient, Prop_Send, "m_iFOV", iFov);
			SetEntProp(iClient, Prop_Send, "m_iDefaultFOV", iFov);
		}

		iLastButtons[iClient] = iButtons;
	}

	if (iButtons == 0)
	{
		return Plugin_Continue;
	}

	int m_fIsSprinting = GetEntProp(iClient, Prop_Data, "m_fIsSprinting", 1);

	if ((iButtons & IN_SPEED) && (m_fIsSprinting == 0))
	{
		if (g_bFlipFlopSpeed[iClient])
		{
			iButtons &= ~IN_SPEED;
			g_bFlipFlopSpeed[iClient] = false;
		}
		else {
			g_bFlipFlopSpeed[iClient] = true;
		}
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

Action t_CheckAltFire(Handle timer, int client)
{
	if (g_bAr2AltFire[client])
	{
		g_bAr2AltFire[client] = false;
	}

	return Plugin_Stop;
}

public Action OnClientToggleZoom(int iClient, const char[] sCommand, int iArgs)
{
	if (giZoom[iClient] != ZOOM_NONE)
	{
		if (giZoom[iClient] == ZOOM_TOGL || giZoom[iClient] == ZOOM_SUIT)
		{
			giZoom[iClient] = ZOOM_NONE;
		}
	}
	else {
		giZoom[iClient] = ZOOM_TOGL;
	}

	return Plugin_Continue;
}

public Action OnClientSwitchWeapon(int iClient, int iWeapon)
{
	if (giZoom[iClient] == ZOOM_TOGL)
	{
		giZoom[iClient] = ZOOM_NONE;
	}

	return Plugin_Continue;
}

public void OnGravityChanged(Handle hConvar, const char[] sOldValue, const char[] sNewValue)
{
	float fGravity[3];

	fGravity[2] -= StringToFloat(sNewValue);

	// force sv_gravity change to take effect immediately (by default, props retain the previous map's gravity) >
	Phys_SetEnvironmentGravity(fGravity);
}

public Action Hook_OnTakeDamage(int iClient, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType)
{	
	if (iDamageType & DMG_FALL)
	{
		if (GetConVarInt(gConVar.mp_falldamage) == -1)
			return Plugin_Handled;

		else if (GetConVarInt(gConVar.mp_falldamage) == 0)
			return Plugin_Continue;

		else if (GetConVarInt(gConVar.mp_falldamage) == 1 && GetConVarFloat(gConVar.mp_falldamage_multiplier) != 0.0)
		{
			fDamage *= gConVar.mp_falldamage_multiplier.FloatValue;
		}

		else if (GetConVarInt(gConVar.mp_falldamage) == 1)
			return Plugin_Continue;

		else
			fDamage = gConVar.mp_falldamage.FloatValue;	   // Fix mp_falldamage value not having any effect >
	}

	else {
		return Plugin_Continue;
	}

	return Plugin_Changed;
}

public Action Hook_WeaponCanSwitchTo(int iClient, int iWeapon)
{
	if (g_bRocketFired[iClient] || g_bAr2AltFire[iClient])
		return Plugin_Handled;

	// Hands animation fix by toizy >
	SetEntityFlags(iClient, GetEntityFlags(iClient) | FL_ONGROUND);

	return Plugin_Changed;
}

public void OnEntityCreated(int iEntity, const char[] sEntity)
{
	// env_sprite fix by sidezz >
	if (StrEqual(sEntity, "env_sprite", false) || StrEqual(sEntity, "env_spritetrail", false))
	{
		RequestFrame(GetSpriteData, EntIndexToEntRef(iEntity));
	}

	if (GetConVarInt(gConVar.sm_rpg_allow_wep_switch) == 0)
	{
		if (StrEqual(sEntity, "rpg_missile"))
		{
			SDKHook(iEntity, SDKHook_Spawn, SDK_OnEntitySpawn);
		}
	}

	if (StrEqual(sEntity, "prop_combine_ball"))
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			g_bAr2AltFire[client] = false;
		}
	}

	return;
}

public Action SDK_OnEntitySpawn(int iEntity)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (client < 1 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
			continue;

		iRocket[client]		   = iEntity;
		g_bRocketFired[client] = true;
	}

	return Plugin_Continue;
}

public void OnEntityDestroyed(int iEntity)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (client < 1 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
			continue;

		if (iRocket[client] == iEntity)
		{
			g_bRocketFired[client] = false;
			SDKUnhook(iEntity, SDKHook_Spawn, SDK_OnEntitySpawn);
		}
	}
}

void GetSpriteData(int iRef)
{
	int iSprite = EntRefToEntIndex(iRef);

	if (IsValidEntity(iSprite))
	{
		int	 iNade = GetEntPropEnt(iSprite, Prop_Data, "m_hAttachedToEntity");
		char sClass[32];

		if (iNade == -1)
		{
			return;
		}

		GetEdictClassname(iNade, sClass, sizeof(sClass));

		if (StrEqual(sClass, "npc_grenade_frag", false))
		{
			for (int i = MaxClients + 1; i < 2048; i++)
			{
				char sOtherClass[32];

				if (!IsValidEntity(i))
				{
					continue;
				}

				GetEdictClassname(i, sOtherClass, sizeof(sOtherClass));

				if (StrEqual(sOtherClass, "env_spritetrail", false) || StrEqual(sOtherClass, "env_sprite", false))
				{
					if (GetEntPropEnt(i, Prop_Data, "m_hAttachedToEntity") == iNade)
					{
						int iGlow  = GetEntPropEnt(iNade, Prop_Data, "m_pMainGlow"),
							iTrail = GetEntPropEnt(iNade, Prop_Data, "m_pGlowTrail");

						if (i != iGlow && i != iTrail)
						{
							AcceptEntityInput(i, "Kill");
						}
					}
				}
			}
		}
	}
}

public Action T_CheckPlayerStates(Handle hTimer)
{
	static bool bWasAlive[MAXPLAYERS + 1] = { false };
	static int	iWasTeam[MAXPLAYERS + 1]  = { -1 };

	int			iTeamScore[4];

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient))
		{
			iWasTeam[iClient]  = -1;
			bWasAlive[iClient] = false;
			continue;
		}

		if (IsClientSourceTV(iClient))
		{
			continue;
		}

		int	 iTeam	= GetClientTeam(iClient);
		bool bAlive = IsPlayerAlive(iClient);

		if (iWasTeam[iClient] == -1)
		{
			int iKills,
				iDeaths;

			gmKills.GetValue(AuthId(iClient), iKills);
			gmDeaths.GetValue(AuthId(iClient), iDeaths);

			Client_SetScore(iClient, iKills);
			Client_SetDeaths(iClient, iDeaths);
		}
		else if (iTeam != iWasTeam[iClient]) {
			OnPlayerPostTeamChange(iClient, iTeam, bWasAlive[iClient], bAlive);
		}

		iWasTeam[iClient]  = iTeam;
		bWasAlive[iClient] = bAlive;
		iTeamScore[iTeam] += Client_GetScore(iClient);

		if (!gbRoundEnd)
		{
			SavePlayerState(iClient);
		}
	}

	// team scores should reflect current team members
	for (int i = 1; i < 4; i++)
	{
		Team_SetScore(i, iTeamScore[i]);
	}

	return Plugin_Continue;
}

void SavePlayerStates()
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient) && !IsClientSourceTV(iClient))
		{
			SavePlayerState(iClient);
		}
	}
}

void SavePlayerState(int iClient)
{
	int	 iTeam;
	char sId[32];

	GetClientAuthId(iClient, AuthId_Engine, sId, sizeof(sId));
	iTeam = (gbTeamplay					 ? GetClientTeam(iClient)
			 : IsClientObserver(iClient) ? TEAM_SPECTATORS
										 : TEAM_REBELS);

	gmKills.SetValue(sId, Client_GetScore(iClient));
	gmDeaths.SetValue(sId, Client_GetDeaths(iClient));
	gmTeams.SetValue(sId, iTeam);
}

void OnPlayerPostTeamChange(int iClient, int iTeam, bool bWasAlive, bool bIsAlive)
{
	if (!bIsAlive)
	{
		if (iTeam == TEAM_SPECTATORS)
		{
			if (gbTeamplay)
			{
				if (!bWasAlive)
				{
					// player was dead and joined spec, the game will record a kill, fix:
					Client_SetScore(iClient, Client_GetScore(iClient) - 1);
				}
				else {
					// player was alive and joined spec, the game will record a death, fix:
					Client_SetDeaths(iClient, Client_GetDeaths(iClient) - 1);
				}
			}
		}
		else if (bWasAlive) {
			// player was alive and changed team, the game will record a suicide, fix:
			Client_SetScore(iClient, Client_GetScore(iClient) + 1);
			Client_SetDeaths(iClient, Client_GetDeaths(iClient) - 1);
		}
	}
}

public Action T_BlockConnectMOTD(Handle hTimer, int iClient)
{
	if (IsClientConnected(iClient) && IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		Handle hMsg = StartMessageOne("VGUIMenu", iClient);

		if (hMsg != INVALID_HANDLE)
		{
			BfWriteString(hMsg, "info");
			BfWriteByte(hMsg, 0);
			EndMessage();
		}
	}

	return Plugin_Handled;
}

public Action UserMsg_VGUIMenu(UserMsg msg, Handle hMsg, const int[] iPlayers, int iNumPlayers, bool bReliable, bool bInit)
{
	char sMsg[10];

	BfReadString(hMsg, sMsg, sizeof(sMsg));
	if (StrEqual(sMsg, "scores"))
	{
		gbRoundEnd = true;
		RequestFrame(SavePlayerStates);
	}

	return Plugin_Continue;
}

public Action Event_GameMessage(Event hEvent, const char[] sEvent, bool bDontBroadcast)
{
	// block Server cvar spam
	hEvent.BroadcastDisabled = true;

	return Plugin_Changed;
}

public Action HandleUse(int client, const char[] cmd, int argc)
{
	if (!IsClientInGame(client))
		return Plugin_Continue;

	char WeaponName[32];
	GetClientWeapon(client, WeaponName, sizeof(WeaponName));

	if (StrEqual(WeaponName, "weapon_physcannon"))
	{
		if (GetEntityOpen(HasClientWeapon(client, "weapon_physcannon")) && GetEffectState(HasClientWeapon(client, "weapon_physcannon")) == 3)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

/******************************
BAD SETLOCALANGLES FIX by Grey83
******************************/
public Action CheckAngles(Handle timer)
{
	static int MaxEnt;
	MaxEnt = GetMaxEntities();
	for (int i = MaxClients + 1; i <= MaxEnt; i++)
	{
		if (IsValidEntity(i) && HasEntProp(i, Prop_Send, "m_angRotation"))
		{
			static bool	 wrongAngle;
			static float ang[3];
#if DEVENABLE
			static float old_ang[3];
#endif
			GetEntPropVector(i, Prop_Send, "m_angRotation", ang);
#if DEVENABLE
			old_ang = ang;
#endif
			wrongAngle = false;
			for (int j; j < 3; j++)
			{
				if (FloatAbs(ang[j]) > 360)
				{
					wrongAngle = true;
					ang[j]	   = FloatFraction(ang[j]) + RoundToZero(ang[j]) % 360;
				}
			}
			if (wrongAngle)
			{
				SetEntPropVector(i, Prop_Send, "m_angRotation", ang);

				static char class[64], name[64];
				class[0] = name[0] = 0;
				GetEdictClassname(i, class, 64);
				GetEntPropString(i, Prop_Data, "m_iName", name, 64);
#if DEVENABLE
				PrintToServer(">	Wrong angles of the prop '%s' (#%d, '%s'):\n	%.2f, %.2f, %.2f (fixed to: %.2f, %.2f, %.2f)", class, i, name, old_ang[0], old_ang[1], old_ang[2], ang[0], ang[1], ang[2]);
#endif
			}
		}
	}
	return Plugin_Continue;
}

public MRESReturn Weapon_ShootPosition_Post(int client, Handle hReturn)
{
	// At this point we always want to use our old origin.
	DHookSetReturnVector(hReturn, g_vecOldWeaponShootPos[client]);
	return MRES_Supercede;
}

/******************************
PLUGIN STOCKS
******************************/
stock int  GetEffectState(int Ent) { return GetEntProp(Ent, Prop_Send, "m_EffectState"); }

stock bool GetEntityOpen(int Ent) { return GetEntProp(Ent, Prop_Send, "m_bOpen", 1) ? true : false; }

stock int  HasClientWeapon(int Client, const char[] WeaponName)
{
	// Initialize:
	int Offset	= FindSendPropInfo("CHL2MP_Player", "m_hMyWeapons");

	int MaxGuns = 256;

	// Loop:
	for (int X = 0; X < MaxGuns; X = (X + 4))
	{
		// Initialize:
		int WeaponId = GetEntDataEnt2(Client, Offset + X);

		// Valid:
		if (WeaponId > 0)
		{
			char ClassName[32];
			GetEdictClassname(WeaponId, ClassName, sizeof(ClassName));
			if (StrEqual(ClassName, WeaponName))
			{
				return WeaponId;
			}
		}
	}
	return -1;
}

void EmitSoundToTeam(int team)
{
	for (int client = 1; client < MaxClients; client++)
	{
		if (client < 1 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
			continue;

		int iCurrentTeam;
		iCurrentTeam = GetClientTeam(client);

		if (iCurrentTeam == team)
		{
			EmitSoundToClient(client, g_sChatSnd[0]);
		}
	}
}