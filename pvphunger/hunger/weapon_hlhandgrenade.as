/* 
* The original Half-Life version of the hand grenade
*/

const int HANDGRENADE_DEFAULT_GIVE = 5;
const int HANDGRENADE_MAX_CARRY = 10;
const int HANDGRENADE_MAX_CLIP = WEAPON_NOCLIP;
const int HANDGRENADE_WEIGHT = 20;

enum handgrenade_e
{
    HANDGRENADE_IDLE = 0,
    HANDGRENADE_FIDGET,
    HANDGRENADE_PINPULL,
    HANDGRENADE_THROW1,    // toss
    HANDGRENADE_THROW2,    // medium
    HANDGRENADE_THROW3,    // hard
    HANDGRENADE_HOLSTER,
    HANDGRENADE_DRAW
};

class HLSDK_CGrenade : ScriptBaseMonsterEntity
{
    bool m_fRegisteredSound = false;
    
    void Spawn()
    {
        Precache();
        
        self.pev.movetype = MOVETYPE_BOUNCE;
        self.pev.solid = SOLID_BBOX;
        self.m_bloodColor = DONT_BLEED;

        self.SetClassification(CLASS_TEAM1);

        g_EntityFuncs.SetModel( self, "models/hunger/w_hungergrenade.mdl" );
        g_EntityFuncs.SetSize( self.pev, Vector( 0, 0, 0 ), Vector( 0, 0, 0 ) );
        
        self.pev.dmg = 100;
        m_fRegisteredSound = false;
    }
    
    void Precache()
    {
        g_Game.PrecacheModel( "models/hunger/w_hungergrenade.mdl" );
        
        g_SoundSystem.PrecacheSound( "weapons/grenade_hit1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/grenade_hit2.wav" );
        g_SoundSystem.PrecacheSound( "weapons/grenade_hit3.wav" );
    }
    
    void BounceTouch( CBaseEntity@ pOther )
    {
        // don't hit the guy that launched this grenade
        if ( pOther.edict() is self.pev.owner )
            return;
        
        // only do damage if we're moving fairly fast
        if ( self.m_flNextAttack < g_Engine.time && self.pev.velocity.Length() > 100 )
        {
            entvars_t@ pevOwner = self.pev.owner.vars;
            if ( pevOwner !is null )
            {
                TraceResult tr = g_Utility.GetGlobalTrace();
                g_WeaponFuncs.ClearMultiDamage();
                pOther.TraceAttack( self.pev, 1, g_Engine.v_forward, tr, DMG_CLUB );
                g_WeaponFuncs.ApplyMultiDamage( self.pev, self.pev );
            }
            self.m_flNextAttack = g_Engine.time + 1.0; // debounce
        }
        
        Vector vecTestVelocity;
        
        // this is my heuristic for modulating the grenade velocity because grenades dropped purely vertical
        // or thrown very far tend to slow down too quickly for me to always catch just by testing velocity. 
        // trimming the Z velocity a bit seems to help quite a bit.
        vecTestVelocity = self.pev.velocity; 
        vecTestVelocity.z *= 0.45;
        
        if ( !m_fRegisteredSound && vecTestVelocity.Length() <= 60 )
        {
            // grenade is moving really slow. It's probably very close to where it will ultimately stop moving. 
            // go ahead and emit the danger sound.
            
            // register a radius louder than the explosion, so we make sure everyone gets out of the way
            CBaseEntity@ pOwner = g_EntityFuncs.Instance( self.pev.owner );
            CSoundEnt@ soundEnt = GetSoundEntInstance();
            soundEnt.InsertSound( bits_SOUND_DANGER, self.pev.origin, int( self.pev.dmg / 0.4 ), 0.3, pOwner );
            m_fRegisteredSound = true;
        }
        
        int bCheck = self.pev.flags;
        if ( ( bCheck &= FL_ONGROUND ) == FL_ONGROUND )
        {
            // add a bit of static friction
            self.pev.velocity = self.pev.velocity * 0.8;
            
            self.pev.sequence = Math.RandomLong( 1, 1 ); // Really? Why not just use "1" instead? -Giegue
        }
        else
        {
            // play bounce sound
            BounceSound();
        }
        
        self.pev.framerate = self.pev.velocity.Length() / 200.0;
        if ( self.pev.framerate > 1.0 )
            self.pev.framerate = 1;
        else if ( self.pev.framerate < 0.5 )
            self.pev.framerate = 0;
    }

    void TumbleThink()
    {
        if ( !self.IsInWorld() )
        {
            CBaseEntity@ pThis = g_EntityFuncs.Instance( self.edict() );
            g_EntityFuncs.Remove( pThis );
            return;
        }
        
        self.StudioFrameAdvance();
        self.pev.nextthink = g_Engine.time + 0.1;
        
        if ( self.pev.dmgtime - 1 < g_Engine.time )
        {
            CBaseEntity@ pOwner = g_EntityFuncs.Instance( self.pev.owner );
            CSoundEnt@ soundEnt = GetSoundEntInstance();
            soundEnt.InsertSound( bits_SOUND_DANGER, self.pev.origin + self.pev.velocity * ( self.pev.dmgtime - g_Engine.time ), 400, 0.1, pOwner );
        }
        
        if ( self.pev.dmgtime <= g_Engine.time )
        {
            SetThink( ThinkFunction( Detonate ) );
        }
        if ( self.pev.waterlevel != 0 )
        {
            self.pev.velocity = self.pev.velocity * 0.5;
            self.pev.framerate = 0.2;
        }
    }
    
    void Detonate()
    {
        CBaseEntity@ pThis = g_EntityFuncs.Instance( self.edict() );
        
        TraceResult tr;
        Vector vecSpot; // trace starts here!
        
        vecSpot = self.pev.origin + Vector ( 0, 0, 8 );
        g_Utility.TraceLine( vecSpot, vecSpot + Vector ( 0, 0, -40 ), ignore_monsters, self.edict(), tr );
        
        g_EntityFuncs.CreateExplosion( tr.vecEndPos, Vector( 0, 0, -90 ), self.pev.owner, int( self.pev.dmg ), false ); // Effect
        g_WeaponFuncs.RadiusDamage( tr.vecEndPos, self.pev, self.pev, self.pev.dmg, ( self.pev.dmg * 3.0 ), CLASS_NONE, DMG_BLAST );
        
        g_EntityFuncs.Remove( pThis );
    }
    
    void BounceSound()
    {
        switch ( Math.RandomLong( 0, 2 ) )
        {
            case 0:    g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "weapons/grenade_hit1.wav", 0.25, ATTN_NORM ); break;
            case 1:    g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "weapons/grenade_hit2.wav", 0.25, ATTN_NORM ); break;
            case 2:    g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "weapons/grenade_hit3.wav", 0.25, ATTN_NORM ); break;
        }
    }
    
    void cSetTouch()
    {
        SetTouch( TouchFunction( BounceTouch ) );
    }
    
    void cSetThink()
    {
        SetThink( ThinkFunction( TumbleThink ) );
    }
}

HLSDK_CGrenade@ ShootTimed( entvars_t@ pevOwner, Vector& in vecStart, Vector& in vecVelocity, float time )
{
    CBaseEntity@ pre_pGrenade = g_EntityFuncs.CreateEntity( "hlgrenade", null, false );
    HLSDK_CGrenade@ pGrenade = cast<HLSDK_CGrenade@>(CastToScriptClass(pre_pGrenade));
    
    pGrenade.Spawn();
    
    //g_EntityFuncs.SetOrigin( pGrenade, vecStart );
    pGrenade.pev.origin = vecStart;
    pGrenade.pev.velocity = vecVelocity;
    g_EngineFuncs.VecToAngles( pGrenade.pev.velocity, pGrenade.pev.angles );
    
    CBaseEntity@ pOwner = g_EntityFuncs.Instance( pevOwner );
    @pGrenade.pev.owner = @pOwner.edict();
    
    pGrenade.cSetTouch(); // Bounce if touched
    
    // Take one second off of the desired detonation time and set the think to PreDetonate. PreDetonate
    // will insert a DANGER sound into the world sound list and delay detonation for one second so that 
    // the grenade explodes after the exact amount of time specified in the call to ShootTimed(). 
    
    pGrenade.pev.dmgtime = g_Engine.time + time;
    pGrenade.cSetThink();
    pGrenade.pev.nextthink = g_Engine.time + 0.1;
    if ( time < 0.1 )
    {
        pGrenade.pev.nextthink = g_Engine.time;
        pGrenade.pev.velocity = Vector( 0, 0, 0 );
    }
    
    pGrenade.pev.sequence = Math.RandomLong( 3, 6 );
    pGrenade.pev.framerate = 1.0;
    
    pGrenade.pev.gravity = 0.5;
    pGrenade.pev.friction = 0.8;
    
    //g_EntityFuncs.SetModel( pGrenade, "models/hunger/w_hungergrenade.mdl" );
    pGrenade.pev.model = string_t( "models/hunger/w_hungergrenade.mdl" );
    pGrenade.pev.dmg = 100;
    
    return pGrenade;
}

class weapon_hlhandgrenade : ScriptBasePlayerWeaponEntity, CBaseCustomWeapon
{
    float m_flStartThrow;
    float m_flReleaseThrow;
    
    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel( self, "models/hunger/w_hungergrenade.mdl" );
        
        self.m_iDefaultAmmo = HANDGRENADE_DEFAULT_GIVE;

        self.FallInit(); // get ready to fall down.
    }
    
    void Precache()
    {
        g_Game.PrecacheModel( "models/hunger/w_hungergrenade.mdl" );
        g_Game.PrecacheModel( "models/hunger/v_hungergrenade.mdl" );
        g_Game.PrecacheModel( "models/hunger/p_hungergrenade.mdl" );
        
        g_Game.PrecacheOther( "hlgrenade" );
        
        g_Game.PrecacheGeneric( "sprites/hl_weapons/weapon_hlhandgrenade.txt" );
    }
    
    float WeaponTimeBase()
    {
        return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
    }
    
    bool GetItemInfo( ItemInfo& out info )
    {
        info.iMaxAmmo1     = HANDGRENADE_MAX_CARRY;
        info.iMaxAmmo2     = -1;
        info.iMaxClip     = HANDGRENADE_MAX_CLIP;
        info.iSlot         = 4;
        info.iPosition     = 4;
        info.iFlags     = ( ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE );
        info.iWeight     = HANDGRENADE_WEIGHT;
        
        return true;
    }

    bool AddToPlayer( CBasePlayer@ pPlayer )
    {
        if( !BaseClass.AddToPlayer( pPlayer ) )
            return false;
        self.SetClassification(CLASS_TEAM1);
        @m_pPlayer = pPlayer;
        
        return true;
    }
    
    bool Deploy()
    {
        m_flReleaseThrow = -1;
        return self.DefaultDeploy( self.GetV_Model( "models/hunger/v_hungergrenade.mdl" ), self.GetP_Model( "models/hunger/p_hungergrenade.mdl" ), HANDGRENADE_DRAW, "crowbar" );
    }

    void Holster( int skiplocal /* = 0 */ )
    {
        m_pPlayer.m_flNextAttack = WeaponTimeBase() + 0.5;
        self.SendWeaponAnim( HANDGRENADE_HOLSTER );
        
        m_flStartThrow = 0;
        m_flReleaseThrow = -1;
    }
    
    void InactiveItemPostFrame()
    {
        if ( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
        {
            self.DestroyItem();
            self.pev.nextthink = g_Engine.time + 0.1;
        }
    }
    
    void PrimaryAttack()
    {
        if ( m_flStartThrow == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
        {
            m_flStartThrow = g_Engine.time;
            m_flReleaseThrow = 0;
            
            self.SendWeaponAnim( HANDGRENADE_PINPULL );
            self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.5;
        }
    }
    
    void WeaponIdle()
    {
        if ( m_flReleaseThrow == 0 && m_flStartThrow > 0 )
            m_flReleaseThrow = g_Engine.time;
        
        if ( self.m_flTimeWeaponIdle > WeaponTimeBase() )
            return;
        
        if ( m_flStartThrow > 0 )
        {
            Vector angThrow = m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle;
            
            if ( angThrow.x < 0 )
                angThrow.x = -10 + angThrow.x * ( ( 90 - 10 ) / 90.0 );
            else
                angThrow.x = -10 + angThrow.x * ( ( 90 + 10 ) / 90.0 );
            
            float flVel = ( 90 - angThrow.x ) * 4;
            if ( flVel > 500 )
                flVel = 500;
            
            g_EngineFuncs.MakeVectors( angThrow );
            
            Vector vecSrc = m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_forward * 16;
            
            Vector vecThrow = g_Engine.v_forward * flVel + m_pPlayer.pev.velocity;
            
            // explode 3 seconds after launch
            HLSDK_CGrenade@ pGrenade = ShootTimed( m_pPlayer.pev, vecSrc, vecThrow, 3.0 );
            
            if ( flVel < 500 )
            {
                self.SendWeaponAnim( HANDGRENADE_THROW1 );
            }
            else if ( flVel < 1000 )
            {
                self.SendWeaponAnim( HANDGRENADE_THROW2 );
            }
            else
            {
                self.SendWeaponAnim( HANDGRENADE_THROW3 );
            }
            
            // player "shoot" animation
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
            
            m_flReleaseThrow = 0;
            m_flStartThrow = 0;
            self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5;
            self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.5;
            
            int iAmmo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
            m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, --iAmmo );
            
            if ( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
            {
                // just threw last grenade
                // set attack times in the future, and weapon idle in the future so we can see the whole throw
                // animation, weapon idle will automatically retire the weapon for us.
                self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5; // ensure that the animation can finish playing
            }
            return;
        }
        else if ( m_flReleaseThrow > 0 )
        {
            // we've finished the throw, restart.
            m_flStartThrow = 0;
            
            if ( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
            {
                self.SendWeaponAnim( HANDGRENADE_DRAW );
            }
            else
            {
                self.RetireWeapon();
                return;
            }
            
            self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
            m_flReleaseThrow = -1;
            return;
        }
        
        if ( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
        {
            int iAnim;
            float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0, 1 );
            if ( flRand <= 0.75 )
            {
                iAnim = HANDGRENADE_IDLE;
                self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 ); // how long till we do this again.
            }
            else
            {
                iAnim = HANDGRENADE_FIDGET;
                self.m_flTimeWeaponIdle = WeaponTimeBase() + 75.0 / 30.0;
            }
            
            self.SendWeaponAnim( iAnim );
        }
    }
}

string GetHLHandgrenadeName()
{
    return "weapon_hlhandgrenade";
}

void RegisterHLHandgrenade()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "HLSDK_CGrenade", "hlgrenade" );
    g_CustomEntityFuncs.RegisterCustomEntity( "weapon_hlhandgrenade", GetHLHandgrenadeName() );
    g_ItemRegistry.RegisterWeapon( GetHLHandgrenadeName(), "hl_weapons", "Hand Grenade" );
}
