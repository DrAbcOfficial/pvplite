/*  
* The original Half-Life version of the mp5
*/

enum Mp5Animation
{
    MP5_LONGIDLE = 0,
    MP5_IDLE1,
    MP5_LAUNCH,
    MP5_RELOAD,
    MP5_DEPLOY,
    MP5_FIRE1,
    MP5_FIRE2,
    MP5_FIRE3,
};

const int MP5_DEFAULT_GIVE     = 50;
const int MP5_MAX_AMMO        = 250;
const int MP5_MAX_AMMO2     = 10;
const int MP5_MAX_CLIP         = 50;
const int MP5_WEIGHT         = 5;

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
        
        g_EntityFuncs.SetModel( self, "models/hlclassic/grenade.mdl" );
        
        self.pev.dmg = 100;
    }
    
    void Precache()
    {
        BaseClass.Precache();
        g_Game.PrecacheModel( "models/hlclassic/grenade.mdl" );
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
    pGrenade.pev.avelocity.x = Math.RandomFloat( -100, -500 );
    pGrenade.pev.dmg = 100;

    g_EntityFuncs.DispatchSpawn(pGrenade.edict());

    return pGrenade;
}

class weapon_hlmp5 : ScriptBasePlayerWeaponEntity, CBasePVPWeapon
{
    private CBasePlayer@ m_pPlayer = null;
    
    float m_flNextAnimTime;
    int m_iShell;
    int    m_iSecondaryAmmo;
    
    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel( self, "models/hlclassic/w_9mmAR.mdl" );

        self.m_iDefaultAmmo = MP5_DEFAULT_GIVE;

        self.m_iSecondaryAmmoType = 0;
        self.m_iClip = 25;
        self.FallInit();
    }

    void Precache()
    {
        self.PrecacheCustomModels();
        g_Game.PrecacheModel( "models/hlclassic/v_9mmAR.mdl" );
        g_Game.PrecacheModel( "models/hlclassic/w_9mmAR.mdl" );
        g_Game.PrecacheModel( "models/hlclassic/p_9mmAR.mdl" );

        m_iShell = g_Game.PrecacheModel( "models/hlclassic/shell.mdl" );

        g_Game.PrecacheOther( "hlargrenade" );

        g_Game.PrecacheModel( "models/w_9mmARclip.mdl" );
        g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );              

        //These are played by the model, needs changing there
        g_SoundSystem.PrecacheSound( "hlclassic/items/clipinsert1.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/items/cliprelease1.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/items/guncock1.wav" );

        g_SoundSystem.PrecacheSound( "hlclassic/weapons/hks1.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/hks2.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/hks3.wav" );

        g_SoundSystem.PrecacheSound( "hlclassic/weapons/glauncher.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/glauncher2.wav" );

        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
    }

    bool GetItemInfo( ItemInfo& out info )
    {
        info.iMaxAmmo1     = MP5_MAX_AMMO;
        info.iMaxAmmo2     = MP5_MAX_AMMO2;
        info.iMaxClip     = MP5_MAX_CLIP;
        info.iSlot         = 2;
        info.iPosition     = 4;
        info.iFlags     = 0;
        info.iWeight     = MP5_WEIGHT;

        return true;
    }

    bool AddToPlayer( CBasePlayer@ pPlayer )
    {
        if( !BaseClass.AddToPlayer( pPlayer ) )
            return false;
            
        @m_pPlayer = pPlayer;
        
        NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
            message.WriteLong( self.m_iId );
        message.End();
        self.SetClassification(CLASS_TEAM1);
        return true;
    }

    bool PlayEmptySound()
    {
        if( self.m_bPlayEmptySound )
        {
            self.m_bPlayEmptySound = false;
            
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
        }
        
        return false;
    }

    bool Deploy()
    {
        return self.DefaultDeploy( self.GetV_Model( "models/hlclassic/v_9mmAR.mdl" ), self.GetP_Model( "models/hlclassic/p_9mmAR.mdl" ), MP5_DEPLOY, "mp5" );
    }
    
    float WeaponTimeBase()
    {
        return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
    }

    void PrimaryAttack()
    {
        // don't fire underwater
        if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
        {
            self.PlayEmptySound( );
            self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
            return;
        }

        if( self.m_iClip <= 0 )
        {
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
            return;
        }

        m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
        m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

        --self.m_iClip;
        
        switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
        {
        case 0: self.SendWeaponAnim( MP5_FIRE1, 0, 0 ); break;
        case 1: self.SendWeaponAnim( MP5_FIRE2, 0, 0 ); break;
        case 2: self.SendWeaponAnim( MP5_FIRE3, 0, 0 ); break;
        }
        
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/hks1.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

        // player "shoot" animation
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

        Vector vecSrc     = m_pPlayer.GetGunPosition();
        Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
        
        // optimized multiplayer. Widened to make it easier to hit a moving player
        m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_6DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2 , 12 , pevAttacker:self.pev);

        if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            // HEV suit - indicate out of ammo condition
            m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
            
        m_pPlayer.pev.punchangle.x = Math.RandomLong( -2, 2 );

        self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.1;
        if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
            self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.1;

        self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );

        Vector vecShellVelocity = m_pPlayer.pev.velocity + g_Engine.v_right * Math.RandomFloat( 50.0, 70.0 ) + g_Engine.v_up * Math.RandomFloat( 100.0, 150.0 ) + g_Engine.v_forward * 25;
        g_EntityFuncs.EjectBrass( self.pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_up * -12 + g_Engine.v_forward * 32 + g_Engine.v_right * 6, vecShellVelocity, self.pev.angles.y, m_iShell, TE_BOUNCE_SHELL );

        TraceResult tr;
        
        float x, y;
        
        g_Utility.GetCircularGaussianSpread( x, y );
        
        Vector vecDir = vecAiming 
                        + x * VECTOR_CONE_6DEGREES.x * g_Engine.v_right 
                        + y * VECTOR_CONE_6DEGREES.y * g_Engine.v_up;

        Vector vecEnd    = vecSrc + vecDir * 4096;

        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
        
        if( tr.flFraction < 1.0 )
        {
            if( tr.pHit !is null )
            {
                CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
                
                if( pHit is null || pHit.IsBSPModel() )
                    g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_MP5 );
            }
        }
    }

    void SecondaryAttack()
    {
        // don't fire underwater
        if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
        {
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
            return;
        }
        
        if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 )
        {
            self.PlayEmptySound();
            return;
        }


        m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
        m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

        m_pPlayer.m_iExtraSoundTypes = bits_SOUND_DANGER;
        m_pPlayer.m_flStopExtraSoundTime = WeaponTimeBase() + 0.2;

        m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) - 1 );

        m_pPlayer.pev.punchangle.x = -10.0;

        self.SendWeaponAnim( MP5_LAUNCH );

        // player "shoot" animation
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

        if ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 ) != 0 )
        {
            // play this sound through BODY channel so we can hear it if player didn't stop firing MP3
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/glauncher.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
        }
        else
        {
            // play this sound through BODY channel so we can hear it if player didn't stop firing MP3
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/glauncher2.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
        }
    
        Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

        // we don't add in player velocity anymore.
        if( ( m_pPlayer.pev.button & IN_DUCK ) != 0 )
        {
            ShootARGrenade( m_pPlayer.pev, 
                                m_pPlayer.pev.origin + g_Engine.v_forward * 16 + g_Engine.v_right * 6, 
                                g_Engine.v_forward * 900 ); //800
        }
        else
        {
            ShootARGrenade( m_pPlayer.pev, 
                                m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs * 0.5 + g_Engine.v_forward * 16 + g_Engine.v_right * 6, 
                                g_Engine.v_forward * 900 ); //800
        }
        self.m_flNextPrimaryAttack = WeaponTimeBase() + 1;
        self.m_flNextSecondaryAttack = WeaponTimeBase() + 1;
        self.m_flTimeWeaponIdle = WeaponTimeBase() + 5;// idle pretty soon after shooting.

        if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 )
            // HEV suit - indicate out of ammo condition
            m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
    }

    void Reload()
    {
        self.DefaultReload( MP5_MAX_CLIP, MP5_RELOAD, 1.5, 0 );

        //Set 3rd person reloading animation -Sniper
        BaseClass.Reload();
    }

    void WeaponIdle()
    {
        self.ResetEmptySound();

        m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

        if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
            return;

        int iAnim;
        switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed,  0, 1 ) )
        {
        case 0:    
            iAnim = MP5_LONGIDLE;    
            break;
        
        case 1:
            iAnim = MP5_IDLE1;
            break;
            
        default:
            iAnim = MP5_IDLE1;
            break;
        }

        self.SendWeaponAnim( iAnim );

        self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );// how long till we do this again.
    }
}

string GetHLMP5Name()
{
    return "weapon_hlmp5";
}

void RegisterHLMP5()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "CMP5Grenade", "hlargrenade" );
    g_CustomEntityFuncs.RegisterCustomEntity( "weapon_hlmp5", GetHLMP5Name() );
    g_ItemRegistry.RegisterWeapon( GetHLMP5Name(), "hl_weapons", "9mm", "ARgrenades" );
}
