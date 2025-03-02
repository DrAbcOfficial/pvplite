#include "config"
#include "mlg"

array<string> g_DeathMsg;
HUDTextParams pHudParams;
CScheduledFunction@ pRemoveOldMsgScheduler;
CScheduledFunction@ pNoTeamBitchScheduler;
CTextMenu@ pTeamMenu;
final class CTeamInfo{
    array<CBasePlayer@> aryPlayers;
    array<string>@ aryStartEquipment;
    string szName;
    string szModel;
    int iClass;
    Vector vecColor;
    CTeamInfo(string _s, int _c, Vector _co, string _m, array<string> _e) {
        szName = _s;
        iClass = _c;
        vecColor = _co;
        @aryStartEquipment = _e;
        szModel = _m;
    }
    void SendTeamScore() {
        int16 frags = 0;
        int16 death = 0;
        for (uint i = 0; i < aryPlayers.length(); i++) {
            frags += int16(aryPlayers[i].pev.frags);
            death += int16(aryPlayers[i].m_iDeaths);
        }
        NetworkMessage message( MSG_ALL, NetworkMessages::TeamScore );
            message.WriteString(this.szName);
            message.WriteShort(frags);                // frags
            message.WriteShort(death);                // death
        message.End();
    }
}
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

    g_SoundSystem.PrecacheSound("hlclassic/items/9mmclip1.wav");
    g_DeathMsg.resize(0);

    @pTeamMenu = CTextMenu(@TeamMenuCallback);
    pTeamMenu.SetTitle("[Select Team]");
    for (uint i = 0;i < g_TeamInfos.length();i++) {
        pTeamMenu.AddItem(g_TeamInfos[i].szName);
    }
    pTeamMenu.Register();
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
    @pNoTeamBitchScheduler = g_Scheduler.SetInterval("SearchNoTeam", 5.0f, g_Scheduler.REPEAT_INFINITE_TIMES);

    Config::SpawnPointReCreate();
}
void SearchNoTeam() {
    for (int i = 0;i <= 33;i++) {
        CBasePlayer@ pPlayer = cast<CBasePlayer@>(g_EntityFuncs.Instance(g_EntityFuncs.IndexEnt(i)));
        if (pPlayer !is null && pPlayer.pev.targetname == "")
            pTeamMenu.Open(5, 0, @pPlayer);
    }
}
void RemoveOldDeathMsg(){
    if(g_DeathMsg.length() > 0)
        g_DeathMsg.removeAt(0);
}
void TeamMenuCallback(CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem) {
    if (@pItem is null || @pPlayer is null || @menu is null)
        return;
    CTeamInfo@ pTeamInfo = null;
    for (uint i = 0;i < g_TeamInfos.length();i++) {
        if (pItem.m_szName == g_TeamInfos[i].szName ) {
            @pTeamInfo = g_TeamInfos[i];
            break;
        }
    }
    if (pTeamInfo !is null) {
        pTeamInfo.aryPlayers.insertLast(@pPlayer);
        pPlayer.SetClassification(pTeamInfo.iClass);
        pPlayer.pev.targetname = "__TEAMPLAYER" + pTeamInfo.szName;
        if (pTeamInfo.szModel != "")
            pPlayer.SetOverriddenPlayerModel(pTeamInfo.szModel);
        NetworkMessage message( MSG_ALL, NetworkMessages::TeamInfo );
            message.WriteByte(g_EntityFuncs.EntIndex(pPlayer.edict()));
            message.WriteString(pTeamInfo.szName);
        message.End();
        pPlayer.SendScoreInfo();
    }
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
    NetworkMessage m1( MSG_ONE, NetworkMessages::GameMode, pPlayer.edict());
		m1.WriteByte(1);
	m1.End();
	NetworkMessage m2( MSG_ONE, NetworkMessages::TeamNames, pPlayer.edict());
		m2.WriteByte(g_TeamInfos.length());
		for (uint i = 0; i < g_TeamInfos.length(); i++) {
            m2.WriteString(g_TeamInfos[i].szName);
            m2.WriteCoord(g_TeamInfos[i].vecColor.x);
            m2.WriteCoord(g_TeamInfos[i].vecColor.y);
            m2.WriteCoord(g_TeamInfos[i].vecColor.z);
        }
	m2.End();
    return HOOK_CONTINUE;
}
HookReturnCode PlayerSpawn( CBasePlayer@ pPlayer ){
    pPlayer.RemoveAllItems(false);
    CTeamInfo@ pTeamInfo = null;
    for (uint i = 0;i < g_TeamInfos.length();i++) {
        if (pPlayer.Classify() == g_TeamInfos[i].iClass ) {
            @pTeamInfo = g_TeamInfos[i];
            break;
        }
    }
    if (pTeamInfo !is null) {
        for (uint i = 0;i < pTeamInfo.aryStartEquipment.length();i++) {
            pPlayer.GiveNamedItem(pTeamInfo.aryStartEquipment[i]);
        }
    }
    return HOOK_CONTINUE;
}
HookReturnCode PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int bitGib ){
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
    float flDamage = info.flDamage;
    info.flDamage = 0;
    if(pAttacker is null || pInflictor is null || pPlayer is null)
        return HOOK_CONTINUE;
    if(pAttacker is null || pInflictor is null || pPlayer is null)
        return HOOK_CONTINUE;
    if(!pPlayer.IsAlive())
        return HOOK_CONTINUE;
    int bitsDamageType = info.bitsDamageType;
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
    float flPrveHealth = pPlayer.pev.health;
    pPlayer.pev.health -= flDamage;
    SuitNoise(pPlayer, bitsDamageType, flPrveHealth);
    MLGFeedBack::TakeDamage(@pPlayer, cast<CBasePlayer@>(g_EntityFuncs.Instance(pAttacker.pev.owner)));
    if ( pPlayer.pev.health <= 0 ){
        entvars_t@ pevVars = @pAttacker.pev;
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
    g_Scheduler.RemoveTimer(@pNoTeamBitchScheduler);
    return HOOK_CONTINUE;
}
