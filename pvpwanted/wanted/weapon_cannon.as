// Known bug(s):
// - ShootContact() doesn't damage breakable entities sometimes - deal with it

namespace HLWanted_Cannon
{
const int CANNON_DMG 		= 100;

const string AMMO_TYPE		= "cannon";

const int CANNON_DEFAULT_AMMO 	= 2;
const int CANNON_MAX_CARRY 	= 8;
const int CANNON_MAX_CLIP 	= 1;
const int CANNON_WEIGHT 	= 15;

enum Animation
{
	CANNON_DRAW = 0,
	CANNON_HOLSTER,
	CANNON_IDLE1,
	CANNON_IDLE2,
	CANNON_FIRE,
	CANNON_DRYFIRE,
	CANNON_RELOAD
};

const array<string> pGunSounds =
{
	//"wanted/weapons/cannon_empty.wav",
	"wanted/weapons/cannon_fire1.wav",
	"wanted/weapons/cannon_reload1.wav",
};

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
        
        g_EntityFuncs.SetModel( self, "models/wanted/cannonball.mdl" );
        
        self.pev.dmg = 100;
    }
    
    void Precache()
    {
        BaseClass.Precache();
        g_Game.PrecacheModel( "models/wanted/cannonball.mdl" );
        g_Game.PrecacheGeneric( "models/wanted/cannonball.mdl" );
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

class weapon_cannon : ScriptBasePlayerWeaponEntity, CBaseCustomWeapon
{
	private int m_sModelIndexSmoke;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/wanted/w_cannon.mdl" );
		self.m_iDefaultAmmo = CANNON_DEFAULT_AMMO;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
        g_Game.PrecacheOther( "hlargrenade");
		g_Game.PrecacheModel( "models/wanted/v_cannon.mdl" );
		g_Game.PrecacheModel( "models/wanted/w_cannon.mdl" );
		g_Game.PrecacheModel( "models/wanted/p_cannon.mdl" );
		g_Game.PrecacheModel( "models/wanted/cannonball.mdl" );

		m_sModelIndexSmoke = g_EngineFuncs.ModelIndex( "sprites/steam1.spr" );

		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );

		for( uint i = 0; i < pGunSounds.length(); i++ ) // firing sounds
		{
			g_SoundSystem.PrecacheSound( pGunSounds[i] ); // cache
			g_Game.PrecacheGeneric( "sound/" + pGunSounds[i] ); // client has to download
		}

		g_Game.PrecacheGeneric( "sprites/" + "wanted/320hud1.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "wanted/320hud2.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "wanted/640hud2.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "wanted/640hud5.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "wanted/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "wanted/crosshairs.spr" );

		g_Game.PrecacheGeneric( "sprites/" + "wanted/weapon_cannon.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CANNON_MAX_CARRY;
		info.iAmmo1Drop = CANNON_DEFAULT_AMMO;
		info.iMaxAmmo2 	= -1;
		info.iAmmo2Drop = -1;
		info.iMaxClip 	= CANNON_MAX_CLIP;
		info.iSlot 	= 3;
		info.iPosition 	= 6;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= 0;
		info.iWeight 	= CANNON_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
			
		@m_pPlayer = pPlayer;

		NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			message.WriteLong( g_ItemRegistry.GetIdForName( self.pev.classname ) );
		message.End();

        self.SetClassification(CLASS_TEAM1);
		
		return true;
	}

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "wanted/weapons/pistol_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( "models/wanted/v_cannon.mdl" ), self.GetP_Model( "models/wanted/p_cannon.mdl" ), CANNON_DRAW, "saw" );
			self.m_flNextPrimaryAttack = g_Engine.time + 1.0;
			self.m_flTimeWeaponIdle = g_Engine.time + 1.5;
			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		SetThink( null );
		self.m_fInReload = false;
		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( self.m_iClip <= 0 || m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15;
			return;
		}

		self.SendWeaponAnim( CANNON_FIRE, 0, 0 );

		SetThink( ThinkFunction( this.FireCannon ) );

		self.pev.nextthink = g_Engine.time + 1.8f;
		self.m_flNextPrimaryAttack = g_Engine.time + 3.0;
		self.m_flTimeWeaponIdle = self.pev.nextthink;
	}

	void FireCannon()
	{
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pGunSounds[0], 1.0f, ATTN_NORM, 0, PITCH_NORM );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc = m_pPlayer.GetGunPosition();

		m_pPlayer.pev.velocity = -768 * g_Engine.v_forward; // Knockback!

		Math.MakeVectors( m_pPlayer.pev.v_angle );

		CBaseEntity@ pCannon = ShootARGrenade( m_pPlayer.pev, vecSrc, g_Engine.v_forward * 1400 );
		if( pCannon !is null )
		{
			g_EntityFuncs.SetModel( pCannon, "models/wanted/cannonball.mdl" );
			pCannon.pev.dmg = CANNON_DMG;
			//pCannon.pev.eflags |= EFLAG_PROJECTILE; // for the future when exposed (if ever)
		}

		Vector vecGunPos = vecSrc + (g_Engine.v_forward * 20 + g_Engine.v_right * 5 - g_Engine.v_up * 15);
		NetworkMessage smoke( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecGunPos );
			smoke.WriteByte( TE_SMOKE );
			smoke.WriteCoord( vecGunPos.x );
			smoke.WriteCoord( vecGunPos.y );
			smoke.WriteCoord( vecGunPos.z );
			smoke.WriteShort( m_sModelIndexSmoke );
			smoke.WriteByte( 10 ); // scale * 10
			smoke.WriteByte( 10  ); // framerate
		smoke.End();
	}

	void SecondaryAttack()
	{
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip == CANNON_MAX_CLIP || self.m_flNextPrimaryAttack > g_Engine.time ) // Can't reload if we have a full magazine already!
			return;

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pGunSounds[1], 1.0f, ATTN_NORM, 0, PITCH_NORM );

		self.m_flNextPrimaryAttack = g_Engine.time + 2.5f;

		self.DefaultReload( CANNON_MAX_CLIP, CANNON_RELOAD, 2.5, 0 );

		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );

		//Set 3rd person reloading animation -Sniper
		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		int iAnim;
		float flNextIdle;

		switch( Math.RandomLong(0, 1) )
		{
			case 0:
			{
				iAnim = CANNON_IDLE1;
				flNextIdle = 2.6f;
			}
			break;
			case 1:
			{
				iAnim = CANNON_IDLE2;
				flNextIdle = 2.5f;
			}
			break;
		}

		self.m_flTimeWeaponIdle = g_Engine.time + flNextIdle;
		self.SendWeaponAnim( iAnim );
	}
}

string GetCannonName()
{
	return "weapon_cannon";
}

// Ammo class
class ammo_cannon : CBaseCustomAmmo
{
	string AMMO_MODEL = "models/wanted/w_cannonball.mdl";

	ammo_cannon()
	{
		m_strModel = AMMO_MODEL;
		m_strName = AMMO_TYPE;
		m_iAmount = CANNON_DEFAULT_AMMO;
		m_iMax = CANNON_MAX_CARRY;
	}
}

string GetCannonAmmoName()
{
	return "ammo_cannon";
}

void Register()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "HLWanted_Cannon::CMP5Grenade", "hlargrenade" );
	g_CustomEntityFuncs.RegisterCustomEntity( "HLWanted_Cannon::ammo_cannon", GetCannonAmmoName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "HLWanted_Cannon::weapon_cannon", GetCannonName() );
	g_ItemRegistry.RegisterWeapon( GetCannonName(), "wanted", AMMO_TYPE, "", GetCannonAmmoName(), "" );
}

} //namespace HLWanted_Cannon END