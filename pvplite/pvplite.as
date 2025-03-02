#include "config"
#include "mlg"

array<int> g_KillingCounter(33);
array<string> g_DeathMsg;
array<array<float>> g_PrevPlayerStats(33);
HUDTextParams pHudParams;

CScheduledFunction@ pRemoveOldMsgScheduler;

void PluginInit(){
    g_Module.ScriptInfo.SetAuthor( "drabc" );
    g_Module.ScriptInfo.SetContactInfo( "lite lite lite" );
}
void MapInit(){
    g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServer );
    g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PlayerSpawn );
    g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @PlayerTakeDamage );
    g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @PlayerKilled );
    g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @PlayerPostThink );
    g_Hooks.RegisterHook( Hooks::Game::EntityCreated, @EntityCreated );
    g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );

    pHudParams.x = 0.90;
    pHudParams.y = 0.05;
    pHudParams.effect = 0;
    pHudParams.r1 = pHudParams.r2 = RGBA_SVENCOOP.r;
    pHudParams.g1 = pHudParams.g2 = RGBA_SVENCOOP.g;
    pHudParams.b1 = pHudParams.b2 = RGBA_SVENCOOP.b;
    pHudParams.a1 = pHudParams.a2 = RGBA_SVENCOOP.a;
    pHudParams.holdTime = 1.5;
    pHudParams.fxTime = 0.005;
    pHudParams.channel = 4;

    Config::Register();

    MLGFeedBack::MapInit();

    g_SoundSystem.PrecacheSound("items/gunpickup2.wav");
    g_SoundSystem.PrecacheSound("hlclassic/items/9mmclip1.wav");
    for(uint i = 0; i < g_KillingCounter.length(); i++){
        g_KillingCounter[i] = 0;
    }
    for(uint i = 0; i < g_PrevPlayerStats.length(); i++){
        g_PrevPlayerStats[i] = {0, 0, 0, 0};
    }
    g_DeathMsg.resize(0);
}
void SpawnNewItem(CBaseEntity@ pEntity){
    CBaseEntity@ pTarget = g_EntityFuncs.Create(string(g_ItemMappings[pEntity.pev.classname]), pEntity.pev.origin, pEntity.pev.angles, true);
    pTarget.pev.targetname = pEntity.pev.targetname;
    pTarget.pev.maxs = pEntity.pev.maxs;
    pTarget.pev.mins = pEntity.pev.mins;
    pTarget.pev.origin = pEntity.pev.origin;
    pTarget.pev.angles = pEntity.pev.angles;
    pTarget.pev.target = pEntity.pev.target;
    pTarget.pev.scale = pEntity.pev.scale;
    pTarget.KeyValue("IsNotAmmoItem", "0");
    pTarget.KeyValue("m_flCustomRespawnTime", string(RESPAWN_DELAY));
    pTarget.pev.spawnflags = 128; //TOUCH ONLY
    if(pEntity.IsBSPModel())
        g_EntityFuncs.SetModel( pTarget, pEntity.pev.model );
    g_EntityFuncs.DispatchSpawn(pTarget.edict());
    g_EntityFuncs.Remove( pEntity );
}
void MapActivate(){
    array<string>@ arykeys = g_ItemMappings.getKeys();
    for(uint i = 0; i < arykeys.length(); i++){
        CBaseEntity@ ent = null;
        while( ( @ent = g_EntityFuncs.FindEntityByClassname( ent, arykeys[i] ) ) !is null ){
            SpawnNewItem(ent);
        }
    }
    CBaseEntity@ ent = null;
    while( ( @ent = g_EntityFuncs.FindEntityByClassname( ent, "ammo_*" ) ) !is null ){
        ent.pev.spawnflags = 128; //TOUCH ONLY
    }
    while( ( @ent = g_EntityFuncs.FindEntityByClassname( ent, "monster_*" ) ) !is null ){
        g_EntityFuncs.Remove(ent);
    }
    while( ( @ent = g_EntityFuncs.FindEntityByClassname( ent, "weapon_*" ) ) !is null ){
        ent.KeyValue("m_flCustomRespawnTime", string(RESPAWN_DELAY));
        ent.pev.spawnflags = 128; //TOUCH ONLY
    }
    array<string>@ aryCVarKeys = g_CVars.getKeys();
    for (uint i = 0; i < aryCVarKeys.length(); i++) {
        g_EngineFuncs.CVarSetFloat(aryCVarKeys[i], float(g_CVars[aryCVarKeys[i]]));
    }
    @pRemoveOldMsgScheduler = g_Scheduler.SetInterval("RemoveOldDeathMsg", 7.0f, g_Scheduler.REPEAT_INFINITE_TIMES);
}
void RemoveOldDeathMsg(){
    if(g_DeathMsg.length() > 0)
        g_DeathMsg.removeAt(0);
}
void SendDeathMsg(string szIn){
    g_DeathMsg.insertLast(szIn);
    if(g_DeathMsg.length() > 4)
        g_DeathMsg.removeAt(0);
    string szTemp = "";
    for(uint i = 0; i < g_DeathMsg.length(); i++){
        szTemp += g_DeathMsg[i] + "\n";
    }
    g_PlayerFuncs.HudMessageAll(pHudParams, szTemp);
}
void SuitNoise(CBasePlayer@ pPlayer, int bitsDamageType, float flHealthPrev){
    bool ftrivial = (pPlayer.pev.health > 75 || pPlayer.m_lastDamageAmount < 5);
	bool fmajor = (pPlayer.m_lastDamageAmount > 25);
	bool fcritical = (pPlayer.pev.health < 30);
    bool ffound = true;
    int bitsDamage = bitsDamageType;
	while ((!ftrivial || (bitsDamage & DMG_TIMEBASED != 0)) && ffound && bitsDamage != 0)
	{
		ffound = false;
		if (bitsDamage & DMG_CLUB != 0)
		{
			if (fmajor)
				pPlayer.SetSuitUpdate("!HEV_DMG4", false, 30);	// minor fracture
			bitsDamage &= ~DMG_CLUB;
			ffound = true;
		}
		if (bitsDamage & (DMG_FALL | DMG_CRUSH) != 0)
		{
			if (fmajor)
				pPlayer.SetSuitUpdate("!HEV_DMG5", false, 30);	// major fracture
			else
				pPlayer.SetSuitUpdate("!HEV_DMG4", false, 30);	// minor fracture
	
			bitsDamage &= ~(DMG_FALL | DMG_CRUSH);
			ffound = true;
		}
		if (bitsDamage & DMG_BULLET != 0)
		{
			if (pPlayer.m_lastDamageAmount > 5)
				pPlayer.SetSuitUpdate("!HEV_DMG6", false, 30);	// blood loss detected
			bitsDamage &= ~DMG_BULLET;
			ffound = true;
		}
		if (bitsDamage & DMG_SLASH != 0)
		{
			if (fmajor)
				pPlayer.SetSuitUpdate("!HEV_DMG1", false, 30);	// major laceration
			else
				pPlayer.SetSuitUpdate("!HEV_DMG0", false, 30);	// minor laceration

			bitsDamage &= ~DMG_SLASH;
			ffound = true;
		}
		if (bitsDamage & DMG_SONIC != 0)
		{
			if (fmajor)
				pPlayer.SetSuitUpdate("!HEV_DMG2", false, 60);	// internal bleeding
			bitsDamage &= ~DMG_SONIC;
			ffound = true;
		}
		if (bitsDamage & (DMG_POISON | DMG_PARALYZE) != 0)
		{
			pPlayer.SetSuitUpdate("!HEV_DMG3", false, 60);	// blood toxins detected
			bitsDamage &= ~(DMG_POISON | DMG_PARALYZE);
			ffound = true;
		}
		if (bitsDamage & DMG_ACID != 0)
		{
			pPlayer.SetSuitUpdate("!HEV_DET1", false, 60);	// hazardous chemicals detected
			bitsDamage &= ~DMG_ACID;
			ffound = true;
		}
		if (bitsDamage & DMG_NERVEGAS != 0)
		{
			pPlayer.SetSuitUpdate("!HEV_DET0", false, 60);	// biohazard detected
			bitsDamage &= ~DMG_NERVEGAS;
			ffound = true;
		}
		if (bitsDamage & DMG_RADIATION != 0)
		{
			pPlayer.SetSuitUpdate("!HEV_DET2", false, 60);	// radiation detected
			bitsDamage &= ~DMG_RADIATION;
			ffound = true;
		}
		if (bitsDamage & DMG_SHOCK != 0)
		{
			bitsDamage &= ~DMG_SHOCK;
			ffound = true;
		}
	}
	if (!ftrivial && fmajor && flHealthPrev >= 75) 
	{
		// first time we take major damage...
		// turn automedic on if not on
		pPlayer.SetSuitUpdate("!HEV_MED1", false, 30);	// automedic on

		// give morphine shot if not given recently
		pPlayer.SetSuitUpdate("!HEV_HEAL7", false, 30);	// morphine shot
	}
	
	if (!ftrivial && fcritical && flHealthPrev < 75)
	{

		// already took major damage, now it's critical...
		if (pPlayer.pev.health < 6)
			pPlayer.SetSuitUpdate("!HEV_HLTH3", false, 10);	// near death
		else if (pPlayer.pev.health < 20)
			pPlayer.SetSuitUpdate("!HEV_HLTH2", false, 10);	// health critical
	
		// give critical health warnings
		if (Math.RandomLong(0,3) == 0 && flHealthPrev < 50)
			pPlayer.SetSuitUpdate("!HEV_DMG7", false, 5); //seek medical attention
	}

	// if we're taking time based damage, warn about its continuing effects
	if ((bitsDamageType & DMG_TIMEBASED != 0) && flHealthPrev < 75)
	{
		if (flHealthPrev < 50)
		{
			if (Math.RandomLong(0,3) == 0)
				pPlayer.SetSuitUpdate("!HEV_DMG7", false, 5); //seek medical attention
		}
		else
			pPlayer.SetSuitUpdate("!HEV_HLTH1", false, 10);	// health dropping
	}
}
HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer ){
    for (int i = 1; i <= 33;i++) {
        CBasePlayer@ tPlayer = cast<CBasePlayer@>(g_EntityFuncs.Instance(g_EntityFuncs.IndexEnt(i)));
        if (tPlayer !is null) {
            NetworkMessage message( MSG_ONE, NetworkMessages::Spectator, pPlayer.edict());
                //Spectator
                message.WriteByte(tPlayer.entindex());
                //Be spectator
                message.WriteByte(tPlayer.entindex());
            message.End();
        }
    }
    return HOOK_CONTINUE;
}
HookReturnCode PlayerSpawn( CBasePlayer@ pPlayer ){
    pPlayer.RemoveAllItems(false);
    for (uint i = 0; i < g_StartEquipments.length();i++) {
        pPlayer.GiveNamedItem( g_StartEquipments[i]);
    }
    g_KillingCounter[pPlayer.entindex()] = 0;
    NetworkMessage message( MSG_ALL, NetworkMessages::Spectator );
        //Spectator
        message.WriteByte(pPlayer.entindex());
        //Be spectator
        message.WriteByte(pPlayer.entindex());
    message.End();
    for (uint i = 0; i < g_StartEquipments.length();i++) {
        g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_AUTO, "items/gunpickup2.wav", 1.0f, ATTN_NORM, 0, PITCH_NORM );
    }
    return HOOK_CONTINUE;
}
HookReturnCode PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int bitGib ){
    if (pAttacker.IsPlayer())
        g_KillingCounter[pAttacker.entindex()]++;
    Config::PlayerKilled(@pPlayer, @pAttacker, bitGib);
    return HOOK_CONTINUE;
}
HookReturnCode EntityCreated(CBaseEntity@ pEntity){
    if(g_RemoveList.find(pEntity.pev.classname) >= 0){
        g_EntityFuncs.Remove(@pEntity);
        return HOOK_CONTINUE;
    }
    return HOOK_CONTINUE;
}
HookReturnCode PlayerTakeDamage(DamageInfo@ info){
    CBasePlayer@ pPlayer = cast<CBasePlayer@>(info.pVictim);
    CBaseEntity@ pAttacker = info.pAttacker;
    CBaseEntity@ pInflictor = info.pInflictor;
    int bitsDamageType = info.bitsDamageType;
    if(pAttacker is null || pInflictor is null || pPlayer is null)
        return HOOK_CONTINUE;
    if(!pPlayer.IsAlive())
        return HOOK_CONTINUE;
    if(bitsDamageType & DMG_FALL != 0 && pAttacker.IsBSPModel()){
        pPlayer.pev.health -= 10;
    }
    else{
        float flDamage = info.flDamage;
        info.flDamage = 0;
        float flRatio = 0.2;
        float flBonus = 0.5;
        if( pPlayer.m_LastHitGroup == HITGROUP_HEAD)
            flDamage *= 3;
        if ( bitsDamageType & DMG_BLAST != 0)
            flBonus *= 2;
        pPlayer.m_lastDamageAmount = flDamage;
        if (pPlayer.pev.armorvalue > 0 && pAttacker.entindex() != 0 && (bitsDamageType & (DMG_FALL | DMG_DROWN) == 0) ){
            float flNew = flDamage * flRatio;
            float flArmor;
            flArmor = (flDamage - flNew) * flBonus;
            if (flArmor > pPlayer.pev.armorvalue){
                flArmor = pPlayer.pev.armorvalue;
                flArmor *= (1/flBonus);
                flNew = flDamage - flArmor;
                pPlayer.pev.armorvalue = 0;
            }
            else
                pPlayer.pev.armorvalue -= flArmor;
            flDamage = flNew;
        }
        Vector vecDir = Vector( 0, 0, 0 );
        pPlayer.m_bitsDamageType |= bitsDamageType;
        if (pInflictor !is null)
            vecDir = ( pInflictor.Center() - Vector ( 0, 0, 10 ) - pPlayer.Center() ).Normalize();
        @pPlayer.pev.dmg_inflictor = pInflictor.edict();
        pPlayer.pev.dmg_take += flDamage;
        
        TraceResult tr = g_Utility.GetGlobalTrace();
        if(tr.pHit is pPlayer.edict())
            g_Utility.BloodDrips(tr.vecEndPos, g_Utility.RandomBloodVector(), pPlayer.BloodColor(), int(flDamage));

        if ( (pPlayer.pev.movetype == MOVETYPE_WALK) && (pAttacker !is null || pAttacker.pev.solid != SOLID_TRIGGER) )
            pPlayer.pev.velocity = pPlayer.pev.velocity + vecDir * - pPlayer.DamageForce( flDamage );
        if( pPlayer.pev.health - flDamage <= 0 )
            CreateWeaponBox( pPlayer );
        float flPrveHealth = pPlayer.pev.health;
        pPlayer.pev.health -= flDamage;

        if(pPlayer.pev.health < 1 && pPlayer.pev.health > 60 && bitsDamageType & DMG_NEVERGIB == 0)
            SuitNoise(pPlayer, bitsDamageType, flPrveHealth);

        CBasePlayer@ pKiller = cast<CBasePlayer@>(g_EntityFuncs.Instance(pAttacker.pev.owner));
        MLGFeedBack::TakeDamage(@pPlayer, pKiller);
    }
    if ( pPlayer.pev.health < 1 ){
        entvars_t@ pevVars = pAttacker.pev.owner !is null ? @pAttacker.pev.owner.vars : @pAttacker.pev;
        if ( bitsDamageType & DMG_ALWAYSGIB != 0)
            pPlayer.Killed( pevVars, GIB_ALWAYS );
        else if ( bitsDamageType & DMG_NEVERGIB != 0)
            pPlayer.Killed( pevVars, GIB_NEVER );
        else
            pPlayer.Killed( pevVars, GIB_NORMAL );
        if (@pPlayer !is pAttacker)
            pPlayer.m_iDeaths++;
        SendDeathMsg(string(pevVars.netname) + " [" + pAttacker.pev.classname + "] " + pPlayer.pev.netname);
    }
    return HOOK_CONTINUE;
}
HookReturnCode PlayerPostThink( CBasePlayer@ pPlayer ){
    pPlayer.SetItemPickupTimes(0);
    pPlayer.SetViewMode(ViewMode_FirstPerson);
    return HOOK_CONTINUE;
}
HookReturnCode MapChange(){
    g_Scheduler.RemoveTimer(@pRemoveOldMsgScheduler);
    return HOOK_CONTINUE;
}
