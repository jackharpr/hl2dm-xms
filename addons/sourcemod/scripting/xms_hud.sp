#define PLUGIN_VERSION "1.15"
#define UPDATE_URL     "https://raw.githubusercontent.com/jackharpr/hl2dm-xms/master/addons/sourcemod/xms_hud.upd"

public Plugin myinfo=
{
    name        = "XMS - HUD",
    version     = PLUGIN_VERSION,
    description = "Timeleft and spectator HUD for eXtended Match System",
    author      = "harper <www.hl2dm.pro>, Adrianilloo",
    url         = "www.hl2dm.pro"
};

/******************************************************************/

#pragma semicolon 1
#include <sourcemod>

#undef REQUIRE_PLUGIN
 #include <updater>
#define REQUIRE_PLUGIN

#pragma newdecls required
 #include <hl2dm-xms>
 
/******************************************************************/

Handle Hud_Spectator,
       Hud_Time;
        
bool   Selfkeys;

/******************************************************************/

public void OnPluginStart()
{   
    Hud_Spectator = CreateHudSynchronizer();
    Hud_Time      = CreateHudSynchronizer();
    
    if(LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public void OnLibraryAdded(const char[] name)
{
    if(StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public void OnAllPluginsLoaded()
{
    CreateTimer(0.1, T_TimeHud, _, TIMER_REPEAT);
    CreateTimer(0.1, T_SpecHud, _, TIMER_REPEAT);
}

public void OnMapStart()
{
    char buffer[MAX_MODE_LENGTH];

    XMS_GetGamemode(buffer, sizeof(buffer));
    XMS_GetConfigString(buffer, sizeof(buffer), "SelfKeys", "GameModes", buffer);
    Selfkeys = StrEqual(buffer, "1");
}

public Action T_TimeHud(Handle timer)
{   
    char buffer[24];
    bool red;
    int  gamestate = XMS_GetGamestate();
    
    if(gamestate == STATE_MATCHWAIT || gamestate == STATE_CHANGE || gamestate == STATE_PAUSE)
    {
        static int count;
        
        Format(buffer, sizeof(buffer), ". . %s%s%s", count >= 20 ? ". " : NULL_STRING, count >= 15 ? ". " : NULL_STRING, count >= 10 ? "." : NULL_STRING);
        count++;
        if(count == 25) count = 0;
    }
    else if(gamestate == STATE_POST)
    {
        red = true;
        Format(buffer, sizeof(buffer), "– Game Over –");
    }
    else
    {
        if(gamestate == STATE_MATCHEX || gamestate == STATE_DEFAULTEX)
        {
            red = true;
            Format(buffer, sizeof(buffer), "– Overtime –\n");
        }
        
        if(GetConVarBool(FindConVar("mp_timelimit")))
        {
            float tl = XMS_GetTimeRemaining(false);
                
            if(tl < 0) tl = 0.0;
            int h = RoundToNearest(tl) / 3600,
            s = RoundToNearest(tl) % 60,
            m;
                        
            if(h)
            {
                m = RoundToNearest(tl) / 60 - (h * 60);
                Format(buffer, sizeof(buffer), "%s%dh %d:%02d", buffer, h, m, s);
            }
            else
            {
                m = RoundToNearest(tl) / 60;
                        
                if(tl >= 60) Format(buffer, sizeof(buffer), "%s%d:%02d", buffer, m, s);
                else
                {
                    red = true;
                            
                    if(tl >= 10) Format(buffer, sizeof(buffer), "%s%i", buffer, RoundToNearest(tl));
                    else         Format(buffer, sizeof(buffer), "%s%.1f", buffer, tl);
                }
            }
        }
    }
    
    if(red) SetHudTextParams(-1.0, 0.01, 0.2, 220, 10, 10, 255, 0, 0.0, 0.0, 0.0);
    else    SetHudTextParams(-1.0, 0.01, 0.2, 220, 177, 0, 255, 0, 0.0, 0.0, 0.0);
    
    for(int client = 1; client <= MaxClients; client++)
    {
        if(!IsClientConnected(client) || !IsClientInGame(client)) continue;
        
        ShowSyncHudText(client, Hud_Time, "%s", buffer);
    }
}

public Action T_SpecHud(Handle timer)
{
    int gamestate = XMS_GetGamestate();

    if(gamestate != STATE_POST && gamestate != STATE_PAUSE) 
    {
        for(int client = 1; client <= MaxClients; client++)
        {           
            if(!IsClientConnected(client) || !IsClientInGame(client) || IsClientSourceTV(client) || GetClientButtons(client) & IN_SCORE) continue;
            if(!IsClientObserver(client) && !Selfkeys) continue;
            
            int target = (Selfkeys ? client : GetEntPropEnt(client, Prop_Send, "m_hObserverTarget"));
            char hudout[1024];
                        
            // format hud text
            if(GetEntProp(client, Prop_Send, "m_iObserverMode") != 7 && target > 0 && IsClientConnected(target) && IsClientInGame(target))
            {
                int buttons = GetClientButtons(target);
                
                Format(hudout, sizeof(hudout), "health: %d   suit: %d\nvel: %03d  %s    %0.1fº\n%s         %s          %s\n%s     %s     %s",
                    GetClientHealth(target),
                    GetClientArmor(target),
                    GetClientVelocity(target),
                    (buttons & IN_FORWARD)   ? "↑"       : "  ", 
                    GetClientHorizAngle(target),
                    (buttons & IN_MOVELEFT)  ? "←"       : "  ", 
                    (buttons & IN_SPEED)     ? "+SPRINT" : "        ", 
                    (buttons & IN_MOVERIGHT) ? "→"       : "  ",
                    (buttons & IN_DUCK)      ? "+DUCK"   : "    ",
                    (buttons & IN_BACK)      ? "↓"       : "  ",
                    (buttons & IN_JUMP)      ? "+JUMP"   : "    "
                );
            }
            else Format(hudout, sizeof(hudout), "\n[Free-look]");

            SetHudTextParams(-1.0, 0.75, 0.2, 220, 177, 0, 255, 0, 0.0, 0.0, 0.0);
            ShowSyncHudText(client, Hud_Spectator, hudout);
        }
    }
}

/******************************************************************/

stock int GetClientVelocity(int client)
{
    float x = GetEntDataFloat(client, FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]")),
          y = GetEntDataFloat(client, FindSendPropInfo("CBasePlayer", "m_vecVelocity[1]")),
          z = GetEntDataFloat(client, FindSendPropInfo("CBasePlayer", "m_vecVelocity[2]"));
    
    return RoundToNearest(SquareRoot(x * x + y * y + z * z));
}

stock float GetClientHorizAngle(int client)
{
    float angles[3]; 

    GetClientAbsAngles(client, angles);
    return angles[1];
}
