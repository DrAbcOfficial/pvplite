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

        g_EntityFuncs.SetModel( self, "models/paranoia/w_grenade.mdl" );
        g_EntityFuncs.SetSize( self.pev, Vector( 0, 0, 0 ), Vector( 0, 0, 0 ) );
        
        self.pev.dmg = 100;
        m_fRegisteredSound = false;
    }
    
    void Precache()
    {
        g_Game.PrecacheModel( "models/paranoia/w_grenade.mdl" );
        
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
    
    //g_EntityFuncs.SetModel( pGrenade, "models/paranoia/w_grenade.mdl" );
    pGrenade.pev.model = string_t( "models/paranoia/w_grenade.mdl" );
    pGrenade.pev.dmg = 100;
    
    return pGrenade;
}


class weapon_f1 : CBaseParanoiaWeapon
{
    float flStartThrow;
    float flReleaseThrow;

    int iPinPullAnimation = 2;
    weapon_f1(){
        szVModel = "models/paranoia/v_grenade.mdl";
        szPModel = "models/paranoia/p_grenade.mdl";
        szWModel = "models/paranoia/w_grenadeammo.mdl";
        szShellModel = "models/paranoia/w_grenade.mdl";
        szHUDModel = "sprites/paranoia/p_hud7.spr";

        szAnimation = "gren";

        flDeploy = 1.0f;

        iDefaultGive = 5;
        iMaxAmmo1 = 3;
        iMaxClip = -1;
        iSlot = 6;
        iPosition = 9;
        iFlag = ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE;
        iWeight = 4;
        
        iDrawAnimation = 7;

        aryFireAnimation = {3, 4, 5};
        aryIdleAnimation = {0, 1};

        aryFireSound = {"weapons/paranoia/grenade-1.wav", "weapons/paranoia/grenade-1.wav"};
        aryOtherSound = {"weapons/paranoia/pinpull.wav", "weapons/paranoia/g_pinpull1.wav", "items/gunpickup2.wav"};
    }

    void Precache() override{
        g_Game.PrecacheOther("hlgrenade");
        CBaseParanoiaWeapon::Precache();
    }

    bool CanHolster(){
        return flStartThrow == 0;
    }

    void DestroyItem(){
        self.DestroyItem();
    }
    void Holster( int skiplocal /* = 0 */ ) override{
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
        if(pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0){
            pPlayer.pev.weapons &= ~(1<<WEAPON_HANDGRENADE);
            SetThink( ThinkFunction(DestroyItem) );
            pev.nextthink = g_Engine.time + 0.1f;
        }
        pPlayer.pev.viewmodel = "";
        BaseClass.Holster();
    }

    void PrimaryAttack() override{
        if( flStartThrow <= 0 and pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 ){
            flStartThrow = g_Engine.time;
            flReleaseThrow = 0;
            self.SendWeaponAnim(2);
            self.m_flTimeWeaponIdle = g_Engine.time + 0.5f;
        }
    }

    void WeaponIdle() override{
        if( flReleaseThrow == 0 and flStartThrow > 0 )
             flReleaseThrow = g_Engine.time;

        if( self.m_flTimeWeaponIdle > g_Engine.time )
            return;

        if( flStartThrow > 0 ){
            Vector angThrow = pPlayer.pev.v_angle + pPlayer.pev.punchangle;
            if( angThrow.x < 0 )
                angThrow.x = -10 + angThrow.x * ((90 - 10) / 90.0f);
            else
                angThrow.x = -10 + angThrow.x * (( 90 + 10) / 90.0f);

            float flVel = (90 - angThrow.x) * 4;
            if( flVel > 500 )
                flVel = 500;

            Math.MakeVectors( angThrow );
            Vector vecSrc = pPlayer.pev.origin + pPlayer.pev.view_ofs + g_Engine.v_forward * 16;
            Vector vecThrow = g_Engine.v_forward * flVel + pPlayer.pev.velocity;
            float time = flStartThrow - g_Engine.time + 3.0f;
            if( time < 0 )
                time = 0;

            HLSDK_CGrenade@ pGrenade = ShootTimed(pPlayer.pev, vecSrc, vecThrow, time);
            g_EntityFuncs.SetModel(pGrenade.self, szShellModel);
            pGrenade.pev.avelocity = Vector(15, 15, 15);

            if( flVel < 500 )
                self.SendWeaponAnim( aryFireAnimation[0] );
            else if( flVel < 1000 )
                self.SendWeaponAnim( aryFireAnimation[1] );
            else
                self.SendWeaponAnim( aryFireAnimation[2] );
            pPlayer.SetAnimation( PLAYER_ATTACK1 );

            flReleaseThrow = 0;
            flStartThrow = 0;
            self.m_flNextPrimaryAttack = g_Engine.time + 0.7f;
            self.m_flTimeWeaponIdle = g_Engine.time + 0.7f;
            pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - 1 );
            if( pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
                self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.5f;// ensure that the animation can finish playing
            return;
        }
        else if( flReleaseThrow > 0 )
        {
            flStartThrow = 0;
            if( pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
                self.SendWeaponAnim( iDrawAnimation );
            else
            {
                self.RetireWeapon();
                return;
            }

            self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( pPlayer.random_seed, 10, 15 );
            flReleaseThrow = -1;
            return;
        }

        if( pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
            self.SendWeaponAnim( aryIdleAnimation[Math.RandomLong(0, aryIdleAnimation.length()-1)] );
    }
    void Materialize(){
        CBaseParanoiaWeapon::Materialize();
        SetTouch (TouchFunction(TheTouch));
    }
    void TheTouch(CBaseEntity@ pOther){
        MyTouch(@pOther);
    }
}