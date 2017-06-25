//you should checkout http://downloadtzz.firewall-gateway.com/ for free programs and basicpawn autocomplete func ect

#include <sourcemod>
#include <sdkhooks>
 
#pragma semicolon 1
 
#define PLUGIN_VERSION "1.2"

#define ENABLE_AUTOEXEC true

public Plugin:myinfo =
{
    name = "[L4D/L4D2]TankDamageModifier",
    author = "Lux",
    description = "Lets you Choose your own custom damage for Tanks",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2421778#post2421778"
};

new Handle:hCvar_DmgEnable = INVALID_HANDLE;
new Handle:hCvar_Damage = INVALID_HANDLE;
new Handle:hCvar_IncapMulti = INVALID_HANDLE;
new Handle:hCvar_ThirdParty = INVALID_HANDLE;

new bool:g_DmgEnable;
new bool:g_ThirdParty;
new Float:g_iDamage;
new Float:g_iImultiplyer;

new bool:g_bDisable = false;
new ZOMBIECLASS_TANK;

public OnPluginStart()
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if(StrEqual(sGameName, "left4dead"))
		ZOMBIECLASS_TANK = 5;
	else if(StrEqual(sGameName, "left4dead2"))
		ZOMBIECLASS_TANK = 8;
	else
		SetFailState("This plugin only runs on Left 4 Dead and Left 4 Dead 2!");
	
	CreateConVar("TankDamageModifier_Version", PLUGIN_VERSION, "TankDamageModifier Plugin Version", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	hCvar_DmgEnable = CreateConVar("tank_damage_enable", "1", "Should We Enable Tank Damage Modifing", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_Damage = CreateConVar("tank_damage", "20.0", "Damage Modifier Value", FCVAR_NOTIFY, true, 0.0, true, 9999.0);
	hCvar_IncapMulti = CreateConVar("tank_damage_modifier", "10.0", "Incapped Damage Multiplyer Value", FCVAR_NOTIFY, true, 0.0, true, 9999.0);
	hCvar_ThirdParty = CreateConVar("tank_third_party", "1", "Disable plugin for thirdparty tank support e.g. supertanks, this will only trigger if the enable cvar is enable. (Example cvar if st_on 1 disable damage modifier damage because of supertanks", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	HookConVarChange(hCvar_DmgEnable, eConvarChanged);
	HookConVarChange(hCvar_Damage, eConvarChanged);
	HookConVarChange(hCvar_IncapMulti, eConvarChanged);
	HookConVarChange(hCvar_ThirdParty, eConvarChanged);
	
	HookEvent("tank_spawn", eTankSpawn);
	
	#if ENABLE_AUTOEXEC
	AutoExecConfig(true, "TankDamageModifier");
	#endif
}

public OnMapStart()
{
	CvarsChanged();
}

public eConvarChanged(Handle:hCvar, const String:sOldVal[], const String:sNewVal[])
{
	CvarsChanged();
}

CvarsChanged()
{
	g_DmgEnable = GetConVarInt(hCvar_DmgEnable) > 0;
	g_ThirdParty = GetConVarInt(hCvar_ThirdParty) > 0;
	g_iDamage = GetConVarFloat(hCvar_Damage);
	g_iImultiplyer = GetConVarFloat(hCvar_IncapMulti);
}

public OnClientPutInServer(iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, eOnTakeDamage);
}

public Action:eOnTakeDamage(iVictim, &iAttacker, &iInflictor, &Float:fDamage, &iDamagetype)
{
	if(!g_DmgEnable || g_bDisable)
		return Plugin_Continue;
   
	if(!IsClientInGame(iVictim) || GetClientTeam(iVictim) != 2)
		return Plugin_Continue;
       
	if(iAttacker < 1 || iAttacker > MaxClients)
		return Plugin_Continue;
		
	if(GetClientTeam(iAttacker) != 3 || GetEntProp(iAttacker, Prop_Send, "m_zombieClass") != ZOMBIECLASS_TANK)
		return Plugin_Continue;
	
	if(IsSurvivorIncapacitated(iVictim))
	{
		fDamage = (g_iDamage * g_iImultiplyer);
		return Plugin_Changed;
	}
	else
	{
		fDamage = g_iDamage;
		return Plugin_Changed;
	}
}

public eTankSpawn(Handle:hEvent, const String:sname[], bool:bDontBroadcast)// timo's idea instead of doing it OnMap start
{
	if(!g_ThirdParty)
	{
		g_bDisable = false;
		return;
	}
	
	if(FindConVar("st_on") != INVALID_HANDLE)
	{
		if(GetConVarInt(FindConVar("st_on")) != 0)
			g_bDisable = true;
		else
			g_bDisable = false;
	}
	else
		g_bDisable = false;
}

bool:IsSurvivorIncapacitated(iClient)
{
	return GetEntProp(iClient, Prop_Send, "m_isIncapacitated", 1) > 0;
}
