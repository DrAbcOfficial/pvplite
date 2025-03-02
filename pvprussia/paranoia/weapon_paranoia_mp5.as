class CMP5Grenade : ScriptBaseMonsterEntity
{
    void Spawn()
    {
        Precache();
        
        self.pev.movetype = MOVETYPE_BOUNCE;
        self.pev.solid = SOLID_BBOX;
        self.m_bloodColor = DONT_BLEED;
        self.SetClassification(CLASS_TEAM1);

        SetTouch( TouchFunction( ExplodeTouch ) );
        SetThink( ThinkFunction( DangerSoundThink ) );
        
        g_EntityFuncs.SetModel( self, "models/grenade.mdl" );
        
        self.pev.dmg = 100;
    }
    
    void Precache()
    {
        BaseClass.Precache();
        g_Game.PrecacheModel( "models/grenade.mdl" );
        g_Game.PrecacheModel( "sprites/steam1.spr");
        
        g_SoundSystem.PrecacheSound( "weapons/debris1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/debris2.wav" );
        g_SoundSystem.PrecacheSound( "weapons/debris3.wav" );
    }

    void Smoke()
    {
        if (g_EngineFuncs.PointContents ( pev.origin ) == CONTENTS_WATER)
            g_Utility.Bubbles( pev.origin - Vector( 64, 64, 64 ), pev.origin + Vector( 64, 64, 64 ), 100 );
        else{
            NetworkMessage m( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
                m.WriteByte( TE_SMOKE );
                m.WriteCoord( pev.origin.x );
                m.WriteCoord( pev.origin.y );
                m.WriteCoord( pev.origin.z );
                m.WriteShort( g_EngineFuncs.ModelIndex("sprites/steam1.spr") );
                m.WriteByte( int8((pev.dmg - 50) * 0.80) ); // scale * 10
                m.WriteByte( 12  ); // framerate
            m.End();
        }
        g_EntityFuncs.Remove(self);
    }
    
    void Explode( TraceResult pTrace, int bitsDamageType )
    {
        pev.model = "";
        pev.solid = SOLID_NOT;
        pev.takedamage = DAMAGE_NO;
        if ( pTrace.flFraction != 1.0 )
            pev.origin = pTrace.vecEndPos + (pTrace.vecPlaneNormal * (pev.dmg - 24) * 0.6);
        int iContents = g_EngineFuncs.PointContents ( pev.origin );
        g_EntityFuncs.CreateExplosion( pTrace.vecEndPos, Vector( 0, 0, -90 ), self.pev.owner, int( self.pev.dmg ), false );
        entvars_t@ pevOwner = null;
        if ( pev.owner !is null)
            @pevOwner = pev.owner.vars;

        g_WeaponFuncs.RadiusDamage( pTrace.vecEndPos, self.pev, self.pev, self.pev.dmg, ( self.pev.dmg * 3.0 ), CLASS_NONE, bitsDamageType );

        if ( Math.RandomFloat( 0 , 1 ) < 0.5 )
            g_Utility.DecalTrace( pTrace, DECAL_SCORCH1 );
        else
            g_Utility.DecalTrace( pTrace, DECAL_SCORCH2 );
        float flRndSound = Math.RandomFloat( 0 , 1 );
        switch ( Math.RandomLong( 0, 2 ) ){
            case 0:    g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_VOICE, "weapons/debris1.wav", 0.55, ATTN_NORM);break;
            case 1:    g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_VOICE, "weapons/debris2.wav", 0.55, ATTN_NORM);break;
            case 2:    g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_VOICE, "weapons/debris3.wav", 0.55, ATTN_NORM);break;
        }

        pev.effects |= EF_NODRAW;
        SetThink(ThinkFunction(Smoke));
        pev.velocity = g_vecZero;
        pev.nextthink = g_Engine.time + 0.3;
        if (iContents != CONTENTS_WATER){
            int sparkCount = Math.RandomLong(0,3);
            for ( int i = 0; i < sparkCount; i++ ){
                g_EntityFuncs.Create( "spark_shower", pev.origin, pTrace.vecPlaneNormal, false, null );
            } 
        }
    }

    void ExplodeTouch( CBaseEntity@ pOther ){
        TraceResult tr;
        Vector vecSpot;
        @pev.enemy = pOther.edict();
        vecSpot = pev.origin - pev.velocity.Normalize() * 32;
        g_Utility.TraceLine( vecSpot, vecSpot + pev.velocity.Normalize() * 64, ignore_monsters, self.edict(), tr );
        Explode( tr, DMG_BLAST );
    }
    
    void DangerSoundThink(){
        if (!self.IsInWorld()){
             g_EntityFuncs.Remove(self);
            return;
        }
        pev.nextthink = g_Engine.time + 0.2;
        if (pev.waterlevel != 0)
            pev.velocity = pev.velocity * 0.5;
    }
}

CBaseEntity@ ShootARGrenade( entvars_t@ pevOwner, Vector& in vecStart, Vector& in vecVelocity)
{
    CBaseEntity@ pGrenade = g_EntityFuncs.CreateEntity( "hlargrenade", null, false );
    pGrenade.pev.gravity = 0.5;
    pGrenade.pev.origin = vecStart;
    pGrenade.pev.velocity = vecVelocity;
    g_EngineFuncs.VecToAngles( pGrenade.pev.velocity, pGrenade.pev.angles );
    
    CBaseEntity@ pOwner = g_EntityFuncs.Instance( pevOwner );
    @pGrenade.pev.owner = @pOwner.edict();

    pGrenade.pev.nextthink = g_Engine.time;
    pGrenade.pev.avelocity.z = Math.RandomFloat( -100, -500 );
    pGrenade.pev.dmg = 100;

    g_EntityFuncs.DispatchSpawn(pGrenade.edict());

    return pGrenade;
}

class weapon_paranoia_mp5 : CBaseParanoiaWeapon{
    weapon_paranoia_mp5(){
        szVModel = "models/paranoia/v_9mmar.mdl";
        szPModel = "models/paranoia/p_9mmar.mdl";
        szWModel = "models/paranoia/w_9mmar.mdl";
        szShellModel = "models/paranoia/glock_shell.mdl";
        szHUDModel = "sprites/paranoia/p_hud3.spr";

        szAnimation = "mp5";

        flDeploy = 0.77f;
        flReloadTime = 3.5f;
        flIronReloadTime = 3.5f;
        flPrimaryTime = 0.1f;
        flSccenaryTime = 3.1f;
        flIdleTime = 0.52f;

        iDamage = 14;
        iDefaultGive = 90;
        iMaxAmmo1 = 600;
        iMaxAmmo2 = 5;
        iMaxClip = 30;
        iSlot = 4;
        iPosition = 13;
        iFlag = 0;
        iWeight = 4;

        vecEjectOrigin = Vector(6, 18, -6);
        vecIronEjectOrigin = Vector(6, 18, -6);
        vecAccurency = VECTOR_CONE_4DEGREES;
        vecIronAccurency = VECTOR_CONE_2DEGREES;

        vec2XPunch = Vector2D(-2, 2);
        vec2YPunch = Vector2D(-2, 2);

        iDrawAnimation = 3;
        iReloadAnimation = 8;
        iIronReloadAnimation = 8;

        aryFireAnimation = {4};
        aryIronFireAnimation = {5, 6};
        aryIdleAnimation = {0, 1};
        aryIronIdleAnimation = {0, 1};

        aryFireSound = {"weapons/paranoia/hks1.wav", "weapons/paranoia/hks2.wav"};
        aryOtherSound = {"weapons/paranoia/hks_draw.wav", "weapons/paranoia/hks_02.wavv", 
            "weapons/paranoia/hks_pinpull.wav", "weapons/paranoia/hks_m203_in.wav",
            "weapons/paranoia/hks_01.wav", "weapons/paranoia/hks_clipout.wav", 
            "weapons/paranoia/hks_clipin.wav", "weapons/paranoia/hks_boltslap.wav", "weapons/glauncher.wav"};
    }
    void SecondaryAttack(){
        if( pPlayer.pev.waterlevel == WATERLEVEL_HEAD ){
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.15;
            return;
        }
        
        if( pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 ){
            self.PlayEmptySound();
            return;
        }


        pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
        pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

        pPlayer.m_iExtraSoundTypes = bits_SOUND_DANGER;
        pPlayer.m_flStopExtraSoundTime = g_Engine.time + 0.2;

        pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) - 1 );

        pPlayer.pev.punchangle.x = -10.0;
        self.SendWeaponAnim(pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType) <= 0 ? 6 : 5);
        pPlayer.SetAnimation( PLAYER_ATTACK1 );
        g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_WEAPON, "weapons/glauncher.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
        Math.MakeVectors( pPlayer.pev.v_angle + pPlayer.pev.punchangle );

        if( ( pPlayer.pev.button & IN_DUCK ) != 0 ){
            ShootARGrenade( pPlayer.pev, 
                                pPlayer.pev.origin + g_Engine.v_forward * 16 + g_Engine.v_right * 6, 
                                g_Engine.v_forward * 900 ); //800
        }
        else{
            ShootARGrenade( pPlayer.pev, 
                                pPlayer.pev.origin + pPlayer.pev.view_ofs * 0.5 + g_Engine.v_forward * 16 + g_Engine.v_right * 6, 
                                g_Engine.v_forward * 900 ); //800
        }
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + (pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType) <= 0 ? 0.6 : flSccenaryTime);
        self.m_flTimeWeaponIdle = g_Engine.time + flSccenaryTime;
        if( pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 )
            pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
    }
    void Materialize(){
        CBaseParanoiaWeapon::Materialize();
        SetTouch (TouchFunction(TheTouch));
    }
    void TheTouch(CBaseEntity@ pOther){
        MyTouch(@pOther);
    }
}