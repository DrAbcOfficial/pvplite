/***
    Conversion by Dr.Abc
***/


enum gauss_e
{
    GAUSS_IDLE = 0,
    GAUSS_IDLE2,
    GAUSS_FIDGET,
    GAUSS_SPINUP,
    GAUSS_SPIN,
    GAUSS_FIRE,
    GAUSS_FIRE2,
    GAUSS_HOLSTER,
    GAUSS_DRAW
};

const int GAUSS_PRIMARY_CHARGE_VOLUME     = 256;// how loud gauss is while charging
const int GAUSS_PRIMARY_FIRE_VOLUME =    450;// how loud gauss is when discharged
const Vector COLOR_GAUSSL(250, 200, 10);
const Vector COLOR_GAUSSR(250, 250, 250);


class weapon_hlgauss : ScriptBasePlayerWeaponEntity, CBasePVPWeapon
{
    private CBasePlayer@ m_pPlayer = null;
    private float m_flPlayAftershock;
    private float flPlrGauss = 20;
    private bool m_bPrimaryFire;
    private bool g_brunninggausspred;
    private int AMMO_PER_PRIMARY_SHOT = 2;
    private float m_flStartCharge, m_flAmmoStartCharge, m_flNextAmmoBurn;
    private uint8 m_iInAttack;
    private uint8 m_iSoundState;
    private uint8 NOT_ATTACKING = 0;
    private uint8 CHARGING_START = 1;
    private uint8 CHARGING = 2;
    
    bool GetItemInfo( ItemInfo& out info )
    {
        info.iMaxAmmo1     = 100;
        info.iMaxAmmo2    = -1;
        info.iMaxClip     = -1;
        info.iSlot         = 3;
        info.iPosition     = 6;
        info.iFlags     = 0;
        info.iWeight     = 20;
        return true;
    }
    
    float GetFullChargeTime()
    {
        if ( true )
        {
            return 1.5;
        }

        return 4;
    }
    
    float WeaponTimeBase()
    {
        return g_Engine.time;
    }
    
    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel( self, "models/hlclassic/w_gauss.mdl" );
        self.m_iDefaultAmmo = 20;
        self.FallInit();
    }

    void Precache()
    {
        self.PrecacheCustomModels();
        g_Game.PrecacheModel( "models/hlclassic/p_gauss.mdl" );
        g_Game.PrecacheModel( "models/hlclassic/v_gauss.mdl" );
        g_Game.PrecacheModel( "models/hlclassic/w_gauss.mdl" );
        g_Game.PrecacheModel( "sprites/hotglow.spr" );
        g_Game.PrecacheModel( "sprites/smoke.spr" );
        g_SoundSystem.PrecacheSound( "weapons/electro4.wav" );
        g_SoundSystem.PrecacheSound( "weapons/electro5.wav" );
        g_SoundSystem.PrecacheSound( "weapons/electro6.wav" );
        g_SoundSystem.PrecacheSound( "ambience/pulsemachine.wav" );
        g_SoundSystem.PrecacheSound( "weapons/gauss2.wav" );
        g_SoundSystem.PrecacheSound( "weapons/357_cock1.wav" );
        g_Game.PrecacheGeneric( "sprites/hl_weapons/weapon_hlgauss.txt" );
    }
    
    bool AddToPlayer( CBasePlayer@ pPlayer )
    {
        if( BaseClass.AddToPlayer( pPlayer ) == true )
        {
            NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
                message.WriteLong( self.m_iId );
            message.End();
            @m_pPlayer = pPlayer;
            self.SetClassification(CLASS_TEAM1);
            return true;
        }    
        return false;
    }
    
    bool IsUseable()
    {
        return BaseClass.IsUseable() || m_iInAttack != NOT_ATTACKING;
    }

    bool Deploy()
    {
        m_flPlayAftershock = 0.0f;
        return self.DefaultDeploy( "models/hlclassic/v_gauss.mdl", "models/hlclassic/p_gauss.mdl", GAUSS_DRAW, "gauss" );
    }
    
    bool PlayEmptySound()
    {
        if( self.m_bPlayEmptySound )
        {
            self.m_bPlayEmptySound = false;            
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
        }    
        return false;
    }
    void Holster( int skipLocal = 0 )
    {
        g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "ambience/pulsemachine.wav" );
        m_pPlayer.m_flNextAttack = WeaponTimeBase() + 0.5;
        BaseClass.Holster( skipLocal );
        self.SendWeaponAnim( GAUSS_HOLSTER );
        m_iInAttack = NOT_ATTACKING;
        g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "ambience/pulsemachine.wav" );
    }
    
    void PrimaryAttack()
    {
        // don't fire underwater
        if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
        {
            self.PlayEmptySound();
            self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
            return;
        }
        
        if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) < AMMO_PER_PRIMARY_SHOT )
        {
            self.PlayEmptySound();
            self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.5f;
            return;
        }
        
        m_pPlayer.m_iWeaponVolume = GAUSS_PRIMARY_FIRE_VOLUME;
        m_bPrimaryFire = true;

        m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - AMMO_PER_PRIMARY_SHOT );

        StartFire();
        
        m_iInAttack = NOT_ATTACKING;
        self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.2f;
    }
    
    void SecondaryAttack()
    {
        // don't fire underwater
        if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
        {
            if( m_iInAttack != NOT_ATTACKING )
            {
                g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/electro4.wav", 1.0f, ATTN_NORM, 0, 80 + Math.RandomLong( 0,0x3f ) );
                self.SendWeaponAnim( GAUSS_IDLE );
                m_iInAttack = NOT_ATTACKING;
            }
            else
            {
                self.PlayEmptySound();
            }
            self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.5f;
            return;
        }    
        if( m_iInAttack == NOT_ATTACKING )
        {
            if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            {
                self.PlayEmptySound();
                self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
                return;
            }

            m_bPrimaryFire = false;

            m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
            m_flNextAmmoBurn = WeaponTimeBase();
            
            // spin up
            m_pPlayer.m_iWeaponVolume = GAUSS_PRIMARY_CHARGE_VOLUME;
            self.SendWeaponAnim( GAUSS_SPINUP );
            m_iInAttack = CHARGING_START;
            self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.5f;
            m_flStartCharge = g_Engine.time;
            m_flAmmoStartCharge = WeaponTimeBase() + GetFullChargeTime();
            
            g_SoundSystem.PlaySound( m_pPlayer.edict(), CHAN_WEAPON, "ambience/pulsemachine.wav", 1, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
            
            m_iSoundState = SND_CHANGE_PITCH;    
        }    
        else if( m_iInAttack == CHARGING_START )
        {
            if( self.m_flTimeWeaponIdle < WeaponTimeBase() )
            {
                self.SendWeaponAnim( GAUSS_SPIN );
                m_iInAttack = CHARGING;
            }
        }
        else
        {
            //Moved to before the ammo burn.
            //Because we drained 1 in AttackState::NOT_ATTACKING, then 1 again now before checking if we're out of ammo,
            //this resuled in the player having -1 ammo, which in turn caused CanDeploy to think it could be deployed.
            //This will need to be fixed further down the line by preventing negative ammo unless explicitly required (infinite ammo?),
            //But this check will prevent the problem for now. - Solokiller
            //TODO: investigate further.
            if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            {
                // out of ammo! force the gun to fire
                StartFire();
                m_iInAttack = NOT_ATTACKING;
                //Need to set m_flNextPrimaryAttack so the weapon gets a chance to complete its secondary fire animation. - Solokiller
                self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0f;
                return;
            }
            // during the charging process, eat one bit of ammo every once in a while    
            if( WeaponTimeBase() >= m_flNextAmmoBurn && m_flNextAmmoBurn != 1000 )
            {
                m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
                if ( true )
                    m_flNextAmmoBurn = WeaponTimeBase() + 0.1;
                else
                    m_flNextAmmoBurn = WeaponTimeBase() + 0.3;
            }    
            if( WeaponTimeBase() >= m_flAmmoStartCharge )
                // don't eat any more ammo after gun is fully charged.
                m_flNextAmmoBurn = 1000;

            float pitch = ( g_Engine.time - m_flStartCharge ) * ( 150 / GetFullChargeTime() ) + 100;
            if ( pitch > 250 ) 
                 pitch = 250;
            
            // ALERT( at_console, "%d %d %d\n", m_fInAttack, m_iSoundState, pitch );
            if ( m_iSoundState == 0 )
                g_Game.AlertMessage( at_console, "sound state %d\n", m_iSoundState );

            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "ambience/pulsemachine.wav", 1.0f, ATTN_NORM, m_iSoundState,  int8(pitch) );

            m_iSoundState = SND_CHANGE_PITCH; // hack for going through level transitions

            m_pPlayer.m_iWeaponVolume = GAUSS_PRIMARY_CHARGE_VOLUME;
                    
            // m_flTimeWeaponIdle = UTIL_WeaponTimeBase() + 0.1;
            if( m_flStartCharge < g_Engine.time - 10 )
            {
                // Player charged up too long. Zap him.
                g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/electro4.wav", 1.0f, ATTN_NORM, 0, 80 + Math.RandomLong( 0,0x3f ) );
                g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM,   "weapons/electro6.wav", 1.0f, ATTN_NORM, 0, 75 + Math.RandomLong( 0,0x3f ) );
        
                m_iInAttack = NOT_ATTACKING;
                self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0f;

                m_pPlayer.TakeDamage( g_EntityFuncs.Instance( 0 ).pev, g_EntityFuncs.Instance( 0 ).pev, 50, DMG_SHOCK );
                g_PlayerFuncs.ScreenFade( m_pPlayer, Vector( 255,128,0 ), 2, 0.5, 128, FFADE_IN );

                self.SendWeaponAnim( GAUSS_IDLE );
                // Player may have been killed and this weapon dropped, don't execute any more code after this!
                return;
            }
        }
    }

    void StartFire()
    {    
        float flDamage;

        Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
        Vector vecAiming = g_Engine.v_forward;
        Vector vecSrc = m_pPlayer.GetGunPosition();
        
        if( g_Engine.time - m_flStartCharge > GetFullChargeTime() )
            flDamage = flPlrGauss * 10;
        else
            flDamage = ( flPlrGauss * 10 ) * ( ( g_Engine.time - m_flStartCharge ) / GetFullChargeTime() );
        
        if( m_bPrimaryFire )
            // fixed damage on primary attack
            flDamage = flPlrGauss;

        //m_iInAttack is never 3, so this check is always true. - Solokiller
        if ( m_iInAttack != 3)
        {
            //ALERT ( at_console, "Time:%f Damage:%f\n", gpGlobals->time - m_pPlayer->m_flStartCharge, flDamage );
            float flZVel = m_pPlayer.pev.velocity.z;
            if ( !m_bPrimaryFire )
            {
                if ( !true )
                {
                    // in deathmatch, gauss can pop you up into the air. Not in single play.
                    Vector vecVelocity = m_pPlayer.pev.velocity;
                    vecVelocity.z = flZVel;
                    m_pPlayer.pev.velocity = vecVelocity;
                }
                else
                    m_pPlayer.pev.velocity = m_pPlayer.pev.velocity - g_Engine.v_forward * flDamage * 5;
            }
            // player "shoot" animation
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        }

        // time until aftershock 'static discharge' sound
        m_flPlayAftershock = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0.3f, 0.8f );
        Fire( vecSrc, vecAiming, flDamage );
    }

    void Fire( Vector vecOrigSrc, Vector vecDir, float flDamage )
    {
        m_pPlayer.m_iWeaponVolume = GAUSS_PRIMARY_FIRE_VOLUME;
        if ( !m_bPrimaryFire )
            g_brunninggausspred = true;
        // The main firing event is sent unreliably so it won't be delayed.
        g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "ambience/pulsemachine.wav" );

        // This reliable event is used to stop the spinning sound
        // It's delayed by a fraction of second to make sure it is delayed by 1 frame on the client
        // It's sent reliably anyway, which could lead to other delays

        m_pPlayer.pev.punchangle.x = -2.0f;
        g_SoundSystem.PlaySound( m_pPlayer.edict(), CHAN_WEAPON, "weapons/gauss2.wav", 1, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
        self.SendWeaponAnim( GAUSS_FIRE2 );
        
        /*ALERT( at_console, "%f %f %f\n%f %f %f\n", 
            vecSrc.x, vecSrc.y, vecSrc.z, 
            vecDest.x, vecDest.y, vecDest.z );*/
        

    //    ALERT( at_console, "%f %f\n", tr.flFraction, flMaxFrac );    
        Vector vecSrc = vecOrigSrc;
        Vector vecDest = vecSrc + vecDir * 8192;

        TraceResult tr, beam_tr;

        edict_t@ pentIgnore = m_pPlayer.edict();

        float flMaxFrac = 1.0f;

        int    nTotal = 0;
        bool fHasPunched = false;
        bool fFirstBeam = true;
        int    nMaxHits = 10;

        while (flDamage > 10 && nMaxHits > 0)
        {
            //减一次反射次数
            nMaxHits--;

            //做忽略玩家的射线
            // ALERT( at_console, "." );
            g_Utility.TraceLine( vecSrc, vecDest, dont_ignore_monsters, pentIgnore, tr );

            //高斯直击
            if( tr.fAllSolid != 0 )
                break;

            CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
            //你打到了虚空
            if( pEntity is null )
                break;        
            
            //初始入射
            if ( fFirstBeam )
            {
                m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
                fFirstBeam = false;
                TEEntBeam( tr, m_pPlayer, m_bPrimaryFire ? 10 : 25, m_bPrimaryFire );
                nTotal += 26;
            }
            else
                TEBeam( tr, vecSrc, m_bPrimaryFire ? 10 : 25, m_bPrimaryFire );

            if( pEntity.pev.takedamage != DAMAGE_NO )
            {
                g_WeaponFuncs.ClearMultiDamage();
                pEntity.TraceAttack( self.pev, flDamage, vecDir, tr, DMG_BULLET );
                g_WeaponFuncs.ApplyMultiDamage( self.pev, self.pev );
            }

            //可反射高斯
            if ( pEntity.ReflectGauss() )
            {
                //清空无视实体
                @pentIgnore = null;

                //与击中面法线做点乘，取负数，判断入射角
                float n = -DotProduct(tr.vecPlaneNormal, vecDir);

                //角度小于60°
                if (n < 0.5) // 60 degrees
                {
                    // ALERT( at_console, "reflect %f\n", n );
                    // reflect
                    Vector r;

                    //向量和相加乘二取得终点坐标
                    r = 2.0 * tr.vecPlaneNormal * n + vecDir;

                    flMaxFrac = flMaxFrac - tr.flFraction;

                    //取得新的射线坐标和方向
                    vecDir = r;
                    vecSrc = tr.vecEndPos + vecDir * 8;
                    vecDest = vecSrc + vecDir * 8192;

                    //反射点造成一个小爆炸，蹭伤害
                    // explode a bit
                    g_WeaponFuncs.RadiusDamage( tr.vecEndPos, self.pev, self.pev, flDamage * n, (flDamage * n) * 2.5f, CLASS_NONE, DMG_BLAST );

                    TEBeam(tr, tr.vecEndPos, 25, true);

                    
                    TEGlow( tr, 0.2f, flDamage * n, flDamage * n * 0.5f * 0.1f );
                    TEBall( tr, ( tr.vecEndPos + tr.vecPlaneNormal ), 3, 0.1, 100, 100 );
                    
                    nTotal += 34;
                    
                    // lose energy
                    if (n == 0)
                        n = 0.1;
                    flDamage = flDamage * (1 - n);
                }
                else
                {
                    //不可反射高斯
                    //反射光打到人了
                    nTotal += 13;

                    //已经挨了一拳了，不要反射了
                    //即穿透直击
                    // limit it to one hole punch
                    if (fHasPunched)
                        break;
                    fHasPunched = true;

                    //如果右键没法直击到，那就尝试穿墙（左键没法穿墙的）
                    // try punching through wall if secondary attack (primary is incapable of breaking through)
                    if ( !m_bPrimaryFire )
                    {
                        //以第一次直击的入射点为起点，向玩家的前方8单位做穿透激光起点，以玩家的鼠标所指方向为终点
                        g_Utility.TraceLine( tr.vecEndPos + vecDir * 8, vecDest, dont_ignore_monsters, pentIgnore, beam_tr);

                        //反射激光落点是固体
                        if (beam_tr.fAllSolid == 0)
                        {
                            //以第一次穿透的入口点为重点重置穿透激光
                            // trace backwards to find exit point
                            g_Utility.TraceLine( beam_tr.vecEndPos, tr.vecEndPos, dont_ignore_monsters, pentIgnore, beam_tr);
                            
                            //求该射线长度为n
                            n = ( beam_tr.vecEndPos - tr.vecEndPos ).Length();

                            //如果长度比伤害小
                            if (n < flDamage)
                            {
                                //不能为0的，长度永远为1
                                if (n == 0)
                                    n = 1;

                                //每折射一次伤害少n
                                flDamage -= n;

                                // ALERT( at_console, "punch %f\n", n );
                                nTotal += 21;
                                //射线的后面一点做球
                                TEBall( tr, ( tr.vecEndPos - vecDir ), 3, 0.1f, 100, 100 );
                                // exit blast damage
                                //m_pPlayer->RadiusDamage( beam_tr.vecEndPos + vecDir * 8, pev, m_pPlayer->pev, flDamage, EntityClassifications().GetNoneId(), DMG_BLAST );
                                float damage_radius;
                                
                                //折射点造成一个爆炸伤害
                                //多人模式爆炸半径为直击伤害的1.75倍
                                //单人模式为2.5倍
                                if ( true )
                                    damage_radius = flDamage * 1.75;  // Old code == 2.5
                                else
                                    damage_radius = flDamage * 2.5;

                                g_WeaponFuncs.RadiusDamage( beam_tr.vecEndPos + vecDir * 8, self.pev, self.pev, flDamage, damage_radius, CLASS_NONE, DMG_BLAST );

                                TEGlow( tr, 0.2f, 200.0f, 6.0f );
                                TEBall( beam_tr, ( beam_tr.vecEndPos - vecDir ), int( flDamage * 0.02f ), 0.1f, 200, 40 );
                                
                                nTotal += 53;

                                //下一次主激光点为折射激光点终点，法线重置为向前
                                vecSrc = beam_tr.vecEndPos + vecDir;
                            }
                        }
                        else
                             //ALERT( at_console, "blocked %f\n", n );
                             //被生物阻挡，停止循环
                            flDamage = 0;
                    }
                    else
                    {
                        //大于60°，不穿透，折射一次后停止循环
                        if( m_bPrimaryFire )
                        {
                            TEGlow( tr, 0.2f, 200.0f, 0.3f ); 
                            TEBall( tr, ( tr.vecEndPos + tr.vecPlaneNormal ), 8, 0.6f, 100, 200 ); 
                        }
                        //ALERT( at_console, "blocked solid\n" );
                        flDamage = 0;
                    }
                }
            }
            else
            {
                //不可反射表面
                //以终点向前尝试一次穿透后停止
                vecSrc = tr.vecEndPos + vecDir;
                @pentIgnore = pEntity.edict();
            }
        }
        // ALERT( at_console, "%d bytes\n", nTotal );
    }
    
    void WeaponIdle()
    {
        self.ResetEmptySound();

        // play aftershock static discharge
        if(  m_flPlayAftershock > 0 && m_flPlayAftershock < g_Engine.time  )
        {
            switch (Math.RandomLong(0,3))
            {
                case 0:    g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "weapons/electro4.wav", Math.RandomFloat( 0.7f, 0.8f ), ATTN_NORM ); break;
                case 1:    g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "weapons/electro5.wav", Math.RandomFloat( 0.7f, 0.8f ), ATTN_NORM ); break;
                case 2:    g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "weapons/electro6.wav", Math.RandomFloat( 0.7f, 0.8f ), ATTN_NORM ); break;
                case 3:    break; // no sound
            }
            m_flPlayAftershock = 0.0f;
        }

        if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
            return;

        if ( m_iInAttack != NOT_ATTACKING )
        {
            StartFire();
            m_iInAttack = NOT_ATTACKING;
            self.m_flTimeWeaponIdle = WeaponTimeBase() + 2.0f;

            //Need to set m_flNextPrimaryAttack so the weapon gets a chance to complete its secondary fire animation. - Solokiller
            if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
                self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5;
        }
        
        else
        {
            int iAnim;
            float flRand = Math.RandomFloat( 0, 1 );
            if (flRand <= 0.5)
            {
                iAnim = GAUSS_IDLE;
                self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
            }
            else if (flRand <= 0.75)
            {
                iAnim = GAUSS_IDLE2;
                self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
            }
            else
            {
                iAnim = GAUSS_FIDGET;
                self.m_flTimeWeaponIdle = WeaponTimeBase() + 3;
            }
            
            self.SendWeaponAnim( iAnim );
            return;    
        }
    }
    
    void TEEntBeam( TraceResult tr , CBasePlayer@ pPlayer , uint8 Width , bool color )
    {
        Vector tempVec = color ? COLOR_GAUSSL : COLOR_GAUSSR;
        NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
            message.WriteByte( TE_BEAMENTPOINT );
            message.WriteShort( pPlayer.entindex() + 4096 ); 
            message.WriteCoord( tr.vecEndPos.x );
            message.WriteCoord( tr.vecEndPos.y );
            message.WriteCoord( tr.vecEndPos.z );
            message.WriteShort( g_EngineFuncs.ModelIndex( "sprites/smoke.spr" ) );
            message.WriteByte( 0 );
            message.WriteByte( 0 );
            message.WriteByte( 1 );
            message.WriteByte( Width ); 
            message.WriteByte( 0 );
            message.WriteByte( uint8(tempVec.x) );
            message.WriteByte( uint8(tempVec.y) );
            message.WriteByte( uint8(tempVec.z) ); 
            message.WriteByte( 200 );
            message.WriteByte( 0 );
        message.End();
    }
    
    void TEBeam( TraceResult tr , Vector vecSrc, uint8 Width , bool color )
    {
        Vector tempVec = color ? COLOR_GAUSSL : COLOR_GAUSSR;
        NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
            message.WriteByte( TE_BEAMPOINTS );
            message.WriteCoord( vecSrc.x );
            message.WriteCoord( vecSrc.y ); 
            message.WriteCoord( vecSrc.z );
            message.WriteCoord( tr.vecEndPos.x );
            message.WriteCoord( tr.vecEndPos.y ); 
            message.WriteCoord( tr.vecEndPos.z );
            message.WriteShort( g_EngineFuncs.ModelIndex( "sprites/smoke.spr" ) ); 
            message.WriteByte( 0 ); 
            message.WriteByte( 0 );
            message.WriteByte( 1 ); 
            message.WriteByte( Width ); 
            message.WriteByte( 0 );
            message.WriteByte( uint8(tempVec.x) );
            message.WriteByte( uint8(tempVec.y) );
            message.WriteByte( uint8(tempVec.z) );
            message.WriteByte( 200 );
            message.WriteByte( 0 );
        message.End();
    }
    
    void TEGlow( TraceResult tr, float flScale, float flDamage, float flLife )
    {
        NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
            message.WriteByte( TE_GLOWSPRITE );
            message.WriteCoord( tr.vecEndPos.x );
            message.WriteCoord( tr.vecEndPos.y );
            message.WriteCoord( tr.vecEndPos.z );
            message.WriteShort( g_EngineFuncs.ModelIndex( "sprites/hotglow.spr" ) );
            message.WriteByte( int( flLife * 10 ) );
            message.WriteByte( int( flScale ) );
            message.WriteByte( Math.min (int( flDamage ), 200) );
        message.End();
    }
    
    void TEBall( TraceResult tr, Vector vecEnd, uint iCount, float flLife, uint iAmplitude, uint iSpeed )
    {
        NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
            message.WriteByte( TE_SPRITETRAIL );
            message.WriteCoord( tr.vecEndPos.x );
            message.WriteCoord( tr.vecEndPos.y ); 
            message.WriteCoord( tr.vecEndPos.z );
            message.WriteCoord( vecEnd.x );
            message.WriteCoord( vecEnd.y );
            message.WriteCoord( vecEnd.z );
            message.WriteShort( g_EngineFuncs.ModelIndex( "sprites/hotglow.spr" ) );
            message.WriteByte( iCount );
            message.WriteByte( int( flLife * 100 ) );
            message.WriteByte( Math.RandomLong( 1, 2 ) );
            message.WriteByte( iSpeed/10 );
            message.WriteByte( iAmplitude/10 );
        message.End();
    }
}
    
string GethlgaussName()
{
    return "weapon_hlgauss";
}

void RegisterHLGauss()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "weapon_hlgauss", GethlgaussName() );
    g_ItemRegistry.RegisterWeapon( GethlgaussName(), "hl_weapons", "uranium" );
}