#include "hl_weapons/weapons"
#include "hl_weapons/mappings"
#include "multi_language/multi_language"
#include "cubemath/item_airbubble"

#include "residualpoint/ammo_individual"
#include "residualpoint/weapon_teleporter"
#include "residualpoint/monster_zombie_hev"
#include "residualpoint/tram_ride_train"
#include "residualpoint/trigger_once_mp"
#include "residualpoint/game_save"

// Modify code bellow for Server operator's choices. -Mikk
bool blSpawnNpcRequired = false;
/*
	Change to true = npcs required for progress Respawn if they die instead of restart the map.
*/

bool blIsAntiRushEnable = true;
/*
	Change to false = antirush is disabled.
*/

bool blClassicModeChoos = true;
/*
	Change to false = Vote for Classic mode is disabled.
*/

bool blWeWantSurvival = true;
/*
	Change to false = Survival mode is disabled.
*/

bool blDifficultyChoose = true;
/*
	Change to false = Vote for difficulty is disabled.
*/

const string str_DiffIs = "easy";
/*
	Change to "easy" "medium" "hard" "hardcore" for default difficulty.
	
	if you're using DinamicDifficulty plugins monster_alien_tor will be kinda strong there.
	custom keyvalue for skippin npcs Health Updates is "$i_dyndiff_skip"
	
	using str_DiffIs with a value that is not specified here will make trigger_save/load do not work.
	so change to anything else and make blDifficultyChoose false to disable this campaign's difficulty system. -Mikk
*/

int DiffMode = 0; //Default DO NOT CHANGE HERE. this will be updated via mapping trigger_save/load. see bool blDifficultyChoose and string str_DiffIs -Mikk

bool ShouldRestartResidualPoint(const string& in szMapName){return szMapName != "rp_c00_lobby";}

void MapInit(){
	MultiLanguageInit();
	RegisterHLMP5(); 
	RegisterAmmoIndividual();
	MonsterZombieHev::Register();
	RegisterSolidityZone();
	
	// For classic mode support
	g_ClassicMode.EnableMapSupport();
	RegisterClassicWeapons();
	g_ClassicMode.SetItemMappings( @g_ClassicWeapons );
	if( !ShouldRestartResidualPoint( g_Engine.mapname ) ) { g_ClassicMode.SetShouldRestartOnChange( false ); }
	g_Scheduler.SetInterval( "ReloadModelsClassicMode", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES );	// Cuz squadmakers x[
	
	if(string(g_Engine.mapname) == "rp_c08_m3" or string(g_Engine.mapname) == "rps_sewer" ){RegisterAirbubbleCustomEntity();}
	
	// We want to check if the map supports survival before registering game_save.
	const bool IsSurvivalEnabled = g_EngineFuncs.CVarGetFloat("mp_survival_supported") == 1;
	
	if( IsSurvivalEnabled and blWeWantSurvival ){
		g_EngineFuncs.CVarSetFloat( "mp_survival_starton", 1 );
		g_EngineFuncs.CVarSetFloat( "mp_survival_startdelay", 10 );
		// Choose a default delay by your choice.
		// BUT game_save actually revives any new players that joins the server
		// So there isn't a reason to update it more than 10 seconds unless you really love everyone rushing maps -Mikk
		RegisterGameSave();
	}
	
	// Just in case...
	g_EngineFuncs.CVarSetFloat( "mp_npckill", 2 );
	g_EngineFuncs.CVarSetFloat( "mp_weapon_droprules", 0 );

	if( blIsAntiRushEnable ) { RegisterAntiRushEntity(); }
	
	if( g_ClassicMode.IsEnabled() ) { Precacheclassic(); }
}

void MapStart()
{
	if( !blIsAntiRushEnable ) { return; }

	const string JsFileLoad = "mikk/antirush/" + string( g_Engine.mapname ) + ".txt";
	
	if(!g_EntityLoader.LoadFromFile(JsFileLoad)){g_EngineFuncs.ServerPrint("Can't open antirush script file "+JsFileLoad+"\n" );}
}

void MapActivate()
{
	if( string(g_Engine.mapname) == "rp_c00_lobby" ){
		CBaseEntity@ pVotes = null;
		if( !blClassicModeChoos ){
			while((@pVotes = g_EntityFuncs.FindEntityByTargetname(pVotes, "classic_mode_button")) !is null){
				edict_t@ pEdict = pVotes.edict();
				g_EntityFuncs.DispatchKeyValue( pEdict, "target", "vote_disabled_msg" );
				g_EntityFuncs.DispatchKeyValue( pEdict, "targetname", "Please.Dont." );
			}
		}

		if( !blDifficultyChoose ){
			while((@pVotes = g_EntityFuncs.FindEntityByTargetname(pVotes, "difficulty_button")) !is null
			or(@pVotes = g_EntityFuncs.FindEntityByTargetname(pVotes, "difficulty_button_med")) !is null
			or(@pVotes = g_EntityFuncs.FindEntityByTargetname(pVotes, "difficulty_button_har")) !is null
			or(@pVotes = g_EntityFuncs.FindEntityByTargetname(pVotes, "difficulty_buttonhardcore")) !is null){
				edict_t@ pEdict = pVotes.edict();
				
				g_EntityFuncs.DispatchKeyValue( pEdict, "target", "vote_disabled_msg" );
				g_EntityFuncs.DispatchKeyValue( pEdict, "targetname", "Please.Dont." );
			}

			while((@pVotes = g_EntityFuncs.FindEntityByTargetname(pVotes, "store_difficulty")) !is null){
				edict_t@ pEdict = pVotes.edict();
				g_EntityFuncs.DispatchKeyValue( pEdict, "$s_difficulty", "" + str_DiffIs );
			}
		}
	}
	
	if( blSpawnNpcRequired ){
		if(string(g_Engine.mapname) == "rp_c08_m1sewer"		)	{ KillThisNpc( "z3f_sci_03"			);										}
		if(string(g_Engine.mapname) == "rp_c08_m2surface"	)	{ KillThisNpc( "p03_scientist_b"	); KillThisNpc( "p03_scientist_a"	);	}
		if(string(g_Engine.mapname) == "rp_c08_m3surface"	)	{ KillThisNpc( "p03_scientist_a"	); KillThisNpc( "spawnsuittted1"	);	}
		if(string(g_Engine.mapname) == "rp_c11"				)	{ KillThisNpc( "suvi_barney"		);										}
		if(string(g_Engine.mapname) == "rp_c12_m1"			)	{ KillThisNpc( "o3n_kelly"			);										}
		if(string(g_Engine.mapname) == "rps_surface"		)	{ KillThisNpc( "bar01_friend"		);										}
	}

	if( !g_EntityLoader.LoadFromFile( EntFileLoad ) )
		g_EngineFuncs.ServerPrint( "Can't open multi-language script file " + EntFileLoad + " No messages will be shown.\n" );
}

void KillThisNpc( const string targetname ){
	CBaseEntity@ pEntity = null;
	g_EntityFuncs.FireTargets( "spawn_npc_required", null, null, USE_TOGGLE );
	while((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, targetname )) !is null )
		g_EntityFuncs.Remove(pEntity);
}

void ReloadModelsClassicMode(){
	// For classic model SetUp models.
	// i know this method is kinda of "Why you do this?"
	// but as long as it works i won't be reworkin the system for 46 maps. -Mikk
	CBaseEntity@ pReplacemets = null;
	while((@pReplacemets = g_EntityFuncs.FindEntityByClassname(pReplacemets, "*")) !is null){
		if( g_ClassicMode.IsEnabled() ){
			if( pReplacemets.pev.model == "models/mikk/residualpoint/w_bloodly_shotgun.mdl" )
				g_EntityFuncs.FireTargets( "ClassicMode_w_bloodly_shotgun", pReplacemets, pReplacemets, USE_TOGGLE );
			if( pReplacemets.pev.model == "models/mikk/residualpoint/w_bloodly_9mmar.mdl" )
				g_EntityFuncs.FireTargets( "ClassicMode_w_bloodly_9mmar", pReplacemets, pReplacemets, USE_TOGGLE );
			if( pReplacemets.pev.model == "models/mikk/residualpoint/zgrunt.mdl" )
				g_EntityFuncs.FireTargets( "ClassicMode_zgrunt", pReplacemets, pReplacemets, USE_TOGGLE );
			if( pReplacemets.pev.model == "models/mikk/residualpoint/xenocrab.mdl" )
				g_EntityFuncs.FireTargets( "ClassicMode_xenocrab", pReplacemets, pReplacemets, USE_TOGGLE );
			if( pReplacemets.pev.model == "models/mikk/residualpoint/ngrunt.mdl" )
				g_EntityFuncs.FireTargets( "ClassicMode_ngrunt", pReplacemets, pReplacemets, USE_TOGGLE );
			if( pReplacemets.pev.model == "models/mikk/residualpoint/civ_scientist.mdl" )
				g_EntityFuncs.FireTargets( "ClassicMode_civ_scientist", pReplacemets, pReplacemets, USE_TOGGLE );
			if( pReplacemets.pev.model == "models/mikk/residualpoint/hgrunt_opfor.mdl" )
				g_EntityFuncs.FireTargets( "ClassicMode_hgrunt_opfor", pReplacemets, pReplacemets, USE_TOGGLE );
			if( pReplacemets.pev.model == "models/mikk/residualpoint/aworker.mdl" )
				g_EntityFuncs.FireTargets( "ClassicMode_aworker", pReplacemets, pReplacemets, USE_TOGGLE );
			if( pReplacemets.pev.classname == "monster_male_assassin" and pReplacemets.pev.model != "models/mikk/hlclassic/massn.mdl" )
				g_EntityFuncs.FireTargets( "ClassicMode_massn", pReplacemets, pReplacemets, USE_TOGGLE );
			if( pReplacemets.pev.classname == "monster_otis" and pReplacemets.pev.model != "models/cm_v3/otis.mdl" )
				g_EntityFuncs.FireTargets( "ClassicMode_otis", pReplacemets, pReplacemets, USE_TOGGLE );
			if( pReplacemets.pev.classname == "monster_zombie_soldier" and pReplacemets.pev.model != "models/cm_v3/zombie_soldier.mdl" )
				g_EntityFuncs.FireTargets( "ClassicMode_zombie_soldier", pReplacemets, pReplacemets, USE_TOGGLE );
			if( pReplacemets.pev.classname == "monster_zombie_barney" and pReplacemets.pev.model != "models/cm_v3/zombie_barney.mdl" )
				g_EntityFuncs.FireTargets( "ClassicMode_zombie_barney", pReplacemets, pReplacemets, USE_TOGGLE );
		}
	}
}

// CallBack for rp_c00_lobby
void ButtonsTargets( CBaseEntity@ pTriggerScript ){
	CBaseEntity@ pButtons = null;
	while((@pButtons = g_EntityFuncs.FindEntityByClassname(pButtons, "func_button")) !is null){
		if( g_Utility.VoteActive() ){
			if( pButtons.GetCustomKeyvalues().HasKeyvalue( "$i_ignore_item" ) or pButtons.pev.target == "vote_disabled_msg")
				continue;

			edict_t@ pEdict = pButtons.edict();
			g_EntityFuncs.DispatchKeyValue( pEdict, "target", "vote_progress_msg" );
		}
		// Now that i think on this i could have use a dictionary instead of changevalues in a raw
		if( pButtons.pev.target == "vote_progress_msg" and !g_Utility.VoteActive() ){
			g_EntityFuncs.FireTargets( "ReturnTargets", null, null, USE_TOGGLE );
		}
	}
}

// CallBack for rp_c00_lobby
void StartClassicModeVote( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue ){
	StartClassicModeVote( false );
}

void StartClassicModeVote( const bool bForce ){
	if( !bForce && g_ClassicMode.IsStateDefined() ){return;}
	float flVoteTime = g_EngineFuncs.CVarGetFloat( "mp_votetimecheck" );
	if( flVoteTime <= 0 ){flVoteTime = 16;}
	float flPercentage = g_EngineFuncs.CVarGetFloat( "mp_voteclassicmoderequired" );
	if( flPercentage <= 0 ){flPercentage = 51;}
	Vote vote( "HLSP Classic Mode vote", ( g_ClassicMode.IsEnabled() ? "Disable" : "Enable" ) + " Classic Mode?", flVoteTime, flPercentage );
	vote.SetVoteBlockedCallback( @ClassicModeVoteBlocked );
	vote.SetVoteEndCallback( @ClassicModeVoteEnd );
	vote.Start();
}

void ClassicModeVoteBlocked( Vote@ pVote, float flTime ){
	g_Scheduler.SetTimeout( "StartClassicModeVote", flTime, false );
}

void ClassicModeVoteEnd( Vote@ pVote, bool bResult, int iVoters ){
	if( !bResult ){
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote for Classic Mode failed" );
		return;
	}
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote to " + ( !g_ClassicMode.IsEnabled() ? "Enable" : "Disable" ) + " Classic mode passed\n" );
	g_ClassicMode.Toggle();
}

// CallBack for rp_c13_m3a
void togglesurvival( CBaseEntity@ pActivator,CBaseEntity@ pCaller, USE_TYPE useType, float flValue ){
	g_SurvivalMode.Disable();
}

// CallBack for rp_c13_m3a
void makezerodamage( CBaseEntity@ pActivator,CBaseEntity@ pCaller, USE_TYPE useType, float flValue ){
	g_EngineFuncs.CVarSetFloat( "sk_kingpin_lightning", 0 );
	g_EngineFuncs.CVarSetFloat( "sk_tor_energybeam", 0 );
}

// CallBack for rp_c13_m3a
/*void BossFight( CBaseEntity@ pTriggerScript )
{
	for( int playerID = 1; playerID <= g_PlayerFuncs.GetNumPlayers(); playerID++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );
            
		if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
			continue;
			
		CBaseEntity@ pBoss = null;
		while( ( @pBoss = g_EntityFuncs.FindEntityByTargetname( pBoss, "thelastboss" )) !is null )
		{
			if( pBoss.takedamage )
				g_EntityFuncs.FireTargets( "IterateTeleport", null, null, USE_TOGGLE );
		}
	}
}*/


/*



	//Damage on players
	while ((@playerInAura = g_EntityFuncs.FindEntityInSphere(playerInAura, controller.pev.origin, 512, "player", "classname")) != null)
	{
		CBaseMonster@ playerInAuraM =  cast<CBaseMonster@>(@playerInAura);
		float psychAuraDmg = 4 * (1 - (controller.pev.origin - playerInAuraM.pev.origin).Length() / 512);
		playerInAuraM.TakeDamage(controller.pev, controller.pev, psychAuraDmg, DMG_FALL);
	}
	
	
				if( m_ilToxicCloud > 1 ) // Make a toxic cloud
				{
					NetworkMessage message( MSG_PVS, NetworkMessages::ToxicCloud );
					message.WriteCoord( self.pev.origin.x );
					message.WriteCoord( self.pev.origin.y );
					message.WriteCoord( self.pev.origin.z );
					message.End();
				}
				
				
				// Return player rendermode.
				if( pPlayer.pev.rendercolor == self.pev.rendercolor && ExistSteamID( pPlayer ) )
				{
					pPlayer.pev.rendermode  = kRenderNormal;
					pPlayer.pev.renderfx    = kRenderFxNone;
					pPlayer.pev.renderamt   = 255;
					pPlayer.pev.rendercolor = Vector(0,0,0); 

					// Stop the sound.
					if( m_slPlaySound != "" )
					{
						g_SoundSystem.StopSound( pPlayer.edict(), CHAN_STATIC, m_slPlaySound ); // it is from the audio remaster
					}

					// Return default speed.
					pPlayer.SetMaxSpeedOverride( -1 );
					
    void VerifyEffects( CBasePlayer@ pPlayer )
    {	
		if( m_ilBeamPointer >= 1 ) // Add beam from this entity's origin to the affected player.
		{
			@pBorderBeam = g_EntityFuncs.CreateBeam( "sprites/laserbeam.spr", 30 );
			pBorderBeam.SetFlags( BEAM_POINTS | SF_BEAM_SHADEIN );
			pBorderBeam.SetStartPos( self.Center() );
			pBorderBeam.SetEndPos( pPlayer.Center() );
			pBorderBeam.SetScrollRate( 100 );
			pBorderBeam.LiveForTime( 0.20 );
			pBorderBeam.pev.rendercolor = self.pev.rendercolor == g_vecZero ? Vector( 255, 0, 0 ) : self.pev.rendercolor;
		}

		if( m_ilFadeScreen >= 1  ) // Fade screen effect.
		{
			g_PlayerFuncs.ScreenFade( pPlayer, self.pev.rendercolor, 1.01f, 1.5f, 52, FFADE_IN );
		}

		if( m_ilGlowPlayers >= 1  ) // Add glow to the player
		{
			if( pPlayer.pev.rendercolor == g_vecZero )
			{
				pPlayer.pev.rendermode  = kRenderNormal;
				pPlayer.pev.renderfx    = kRenderFxGlowShell;
				pPlayer.pev.renderamt   = 4;
				pPlayer.pev.rendercolor = self.pev.rendercolor;
			}
		}
		
		if( m_slPlaySound != "" ) // Play sounds (specify custom sounds too)
		{
			g_SoundSystem.PlaySound( pPlayer.edict(), CHAN_STATIC, m_slPlaySound, 1.0f, 1.0f, 0, PITCH_NORM );
		}

		if( m_ilSpeedModifier >= 1 ) // Add glow to the player
		{
			pPlayer.SetMaxSpeedOverride( m_ilSpeedModifier );
		}

		if( m_ilAttachSpr >= 1 ) // Add Sprites to player
		{
			NetworkMessage firemsg( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );

			firemsg.WriteByte(TE_PLAYERSPRITES);
			firemsg.WriteShort(pPlayer.entindex());
			firemsg.WriteShort(g_EngineFuncs.ModelIndex( m_ilAttachSpr )); // bubble"sprites/mommaspit.spr" 
			firemsg.WriteByte(16);
			firemsg.WriteByte(0);
			firemsg.End();
            return;
		}

		pPlayer.TakeDamage( self.pev, self.pev, 0 * 0.0, m_ilHud | m_ilHudAlt );
*/

// CallBack for rp_c14
void SetOriginPlease( CBaseEntity@ pTriggerScript ){
    CBaseEntity@ pTrain = null;
    while( ( @pTrain = g_EntityFuncs.FindEntityByTargetname( pTrain, "kk01_truck_body" )) !is null ){
        for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
        {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );
        
            if( pPlayer is null or !pPlayer.IsConnected() )
                continue;

            pPlayer.SetOrigin( pTrain.Center() + Vector( 0, -24, 16 ) );
            pPlayer.pev.solid = SOLID_NOT;
            pPlayer.pev.flags |= FL_FROZEN | FL_NOTARGET;
            pPlayer.pev.rendermode = kRenderTransAlpha;
            pPlayer.pev.renderamt = 0;
            pPlayer.BlockWeapons( pTrain );
        }
    }
}

void medium( CBaseEntity@ pActivator,CBaseEntity@ pCaller, USE_TYPE useType, float flValue ){
    DiffMode = 1;
	Register();
}

void hard( CBaseEntity@ pActivator,CBaseEntity@ pCaller, USE_TYPE useType, float flValue ){
    DiffMode = 2;
	Register();
}

void hardcore( CBaseEntity@ pActivator,CBaseEntity@ pCaller, USE_TYPE useType, float flValue ){
    DiffMode = 3;
	Register();
	
	CBaseEntity@ pRepl = null;
	while((@pRepl = g_EntityFuncs.FindEntityByClassname(pRepl, "game_save")) !is null)
		if( pRepl.pev.model == "models/mikk/residualpoint/lambda.mdl" )
			g_EntityFuncs.FireTargets( "limitless_potential", pRepl, pRepl, USE_TOGGLE );
}

void Register(){
	g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PlayerSpawn );
}

HookReturnCode PlayerSpawn(CBasePlayer@ pPlayer){
    if( pPlayer is null or DiffMode == 0)
        return HOOK_CONTINUE;
    
	if(DiffMode == 1 )
    {
        pPlayer.pev.health = 80;
        pPlayer.pev.max_health = 80;
        pPlayer.pev.armortype = 80;
    }
    else if(DiffMode == 2 )
    {
        pPlayer.pev.health = 50;
        pPlayer.pev.max_health = 50;
        pPlayer.pev.armortype = 50;
    }
    else if(DiffMode == 3 )
    {
        pPlayer.pev.health = 1;
        pPlayer.pev.max_health = 1;
        pPlayer.pev.armortype = 1;
    }
    
    return HOOK_CONTINUE;
}

void Precacheclassic(){
	g_Game.PrecacheModel( "models/mikk/misc/limitless_potential.mdl" );
	g_Game.PrecacheModel( "models/mikk/residualpoint/hlclassic/w_bloodly_9mmar.mdl" );
	g_Game.PrecacheModel( "models/mikk/residualpoint/hlclassic/w_bloodly_shotgun.mdl" );
	g_Game.PrecacheModel( "models/mikk/residualpoint/hlclassic/zgrunt.mdl" );
	g_Game.PrecacheModel( "models/mikk/residualpoint/hlclassic/xenocrab.mdl" );
	g_Game.PrecacheModel( "models/mikk/residualpoint/hlclassic/ngrunt.mdl" );
	g_Game.PrecacheModel( "models/mikk/residualpoint/hlclassic/civ_scientist.mdl" );
	g_Game.PrecacheModel( "models/mikk/residualpoint/hlclassic/aworker.mdl" );
	g_Game.PrecacheModel( "models/cm_v3/zombie_soldier.mdl" );
	g_Game.PrecacheModel( "models/mikk/residualpoint/hlclassic/hgrunt_opfor.mdl" );
	g_Game.PrecacheModel( "models/cm_v3/zombie_barney.mdl" );
	g_Game.PrecacheModel( "models/cm_v3/massn.mdl" );
	g_Game.PrecacheModel( "models/cm_v3/otis.mdl" );
}