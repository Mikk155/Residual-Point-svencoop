#include "residualpoint/ChapterTittles"
#include "residualpoint/monsters"
#include "Gaftherman/ammo_individual"
#include "residualpoint/weapon_hlsatchel"
#include "residualpoint/weapon_teleporter"
#include "residualpoint/Difficulty"
#include "residualpoint/monster_lasertripmine"
#include "residualpoint/checkpoint_spawner"

#include "rick/trigger_teleport_mp"

#include "beast/teleport_zone"

#include "cubemath/item_airbubble"

bool blSpawnNpcRequired = false; // Change to true = spawn npcs required for the map when they die instead of restart the map NOTE: if enabled, archivemets will be disabled.
bool bSurvivalEnabled = true;	// Change to true = survival mode enabled NOTE: if disabled, archivemets will be disabled.

/*
	Please don't hack/vandalice this script 
	to make archievemets enabled without the bools.
	we want it like this so please. don't.
*/

float flSurvivalStartDelay = g_EngineFuncs.CVarGetFloat( "mp_survival_startdelay" );

void MapInit()
{
	// Take'd from weapon_hlsatchel by JulianR0 IMPORTAN NOTE: This could crash Linux servers. I had problems there
	RegisterHLSatchel(); // https://github.com/JulianR0/TPvP/blob/master/src/map_scripts/hl_weapons/weapon_hlsatchel.as
	
	// buggy as hell but well. have fun :)
	RegisterHLMP5(); 

	// prevent people from getting out the maps. Take'd from Rick
	RegisterTriggerTeleportMp(); // https://github.com/RedSprend/svencoop_plugins/blob/master/svencoop/scripts/maps/triggers/trigger_teleport_mp.as

	// most of this has been remapped. now just xenocrab are script-side
	RegisterAllMonsters(); 
	
	// Ammo for HLSP Campaigns. items that can be taked ONCE per player.
	RegisterAmmoIndividual(); 
	
	// i'm lazy to replace with the new checkpoint. we used this a long ago so zzzzz
	RegisterCheckPointSpawnerEntity(); 

	// Verify the difficulty choosed at lobby
	DiffVerify(); 
	
	// New tripmine for certain maps that should restart the map when explode one of them
	if( string(g_Engine.mapname) == "rps_surface" ){
		RegisterLaserMine();
		g_Game.PrecacheOther( "monster_lasertripmine" );
	}
	
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @SpamTime );
}

void MapActivate()
{
	// Everything are *hardcoded* on the maps but snarks and some items
	AmmoIndividualRemap(); 
	
	// Can be annoying some times but better to let everyone see the chapter title :)
	ChapterTittles(); 
	
	if( blSpawnNpcRequired )
	{
		NpcRequiredStuff();
		UpdateOnRemove(); // >:C
	}
	
	// Custom survival mode without survival count-down messages and fixed the Dupe aka "ammo duplication" when survival is off
	// take'd from https://github.com/Mikk155/angelscript/blob/main/plugins/SurvivalDeluxe.as
	if( bSurvivalEnabled )
	{	
		g_SurvivalMode.Disable();
		g_Scheduler.SetTimeout( "SurvivalModeEnable", flSurvivalStartDelay );
		g_EngineFuncs.CVarSetFloat( "mp_survival_startdelay", 0 );
		g_EngineFuncs.CVarSetFloat( "mp_survival_starton", 0 );
		g_EngineFuncs.CVarSetFloat( "mp_dropweapons", 0 );
	}
	else
	{
		UpdateOnRemove(); // >:C
	}
}

void UpdateOnRemove()
{
    CBaseEntity@ pEntity = null;

    while((@pEntity = g_EntityFuncs.FindEntityByClassname(pEntity, "trigger_save")) !is null)
    {
        g_EntityFuncs.Remove( pEntity );
    }

	g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Archievemets Disabled.\n" );
}

void SurvivalModeEnable()
{
    g_SurvivalMode.Activate( true );
    g_EngineFuncs.CVarSetFloat( "mp_dropweapons", 1 );
	
    NetworkMessage message( MSG_ALL, NetworkMessages::SVC_STUFFTEXT );
    	message.WriteString( "spk buttons/bell1" );
    message.End();
}

HookReturnCode SpamTime(CBasePlayer@ pPlayer)
{
	g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "#=======================================#\n" );
	g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "# http://scmapdb.com/map:residual-point #\n" );
	g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "#=======================================#\n" );
	g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "# Residual Point By Mikk & Gaftherman.  #\n" );
	g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "# Download this Map-Pack from scmapdb   #\n" );
	g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "#    Open console to copy the link      #\n" );
	g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "#=======================================#\n" );
	return HOOK_CONTINUE;
}
