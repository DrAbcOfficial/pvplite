namespace HLWanted_PickAxe
{
enum pick_e
{
	PICK_IDLE1 = 0,
	PICK_DRAW,
	PICK_HOLSTER,
	PICK_ATTACK1HIT,
	PICK_ATTACK1MISS,
	PICK_ATTACK2MISS,
	PICK_ATTACK2HIT,
	PICK_ATTACK3MISS,
	PICK_ATTACK3HIT,
	PICK_IDLE2,
	PICK_IDLE3
};

class weapon_pick : ScriptBasePlayerWeaponEntity, CBaseCustomWeapon
{
	int m_iSwing;
	TraceResult m_trHit;
	
	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( "models/wanted/w_pick.mdl") );
		self.m_iClip			= -1;
		self.m_flCustomDmg		= self.pev.dmg;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( "models/wanted/v_pick.mdl" );
		g_Game.PrecacheModel( "models/wanted/w_pick.mdl" );
		g_Game.PrecacheModel( "models/wanted/p_pick.mdl" );

		g_SoundSystem.PrecacheSound( "wanted/weapons/pick_hit1.wav" );
		g_Game.PrecacheGeneric( "sound/" + "wanted/weapons/pick_hit1.wav" );
		g_SoundSystem.PrecacheSound( "wanted/weapons/pick_hit1.wav" );
		g_Game.PrecacheGeneric( "sound/" + "wanted/weapons/pick_hit1.wav" );
		g_SoundSystem.PrecacheSound( "wanted/weapons/pick_hit2.wav" );
		g_Game.PrecacheGeneric( "sound/" + "wanted/weapons/pick_hit2.wav" );
		g_SoundSystem.PrecacheSound( "wanted/weapons/pick_hitbod1.wav" );
		g_Game.PrecacheGeneric( "sound/" + "wanted/weapons/pick_hitbod1.wav" );
		g_SoundSystem.PrecacheSound( "wanted/weapons/pick_hitbod2.wav" );
		g_Game.PrecacheGeneric( "sound/" + "wanted/weapons/pick_hitbod2.wav" );
		g_SoundSystem.PrecacheSound( "wanted/weapons/pick_hitbod3.wav" );
		g_Game.PrecacheGeneric( "sound/" + "wanted/weapons/pick_hitbod3.wav" );
		g_SoundSystem.PrecacheSound( "wanted/weapons/pick_miss1.wav" );
		g_Game.PrecacheGeneric( "sound/" + "wanted/weapons/pick_miss1.wav" );

		g_Game.PrecacheGeneric( "sprites/" + "wanted/320hud1.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "wanted/640hud1.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "wanted/640hud4.spr" );

		g_Game.PrecacheGeneric( "sprites/" + "wanted/weapon_pick.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= WEAPON_NOCLIP;
		info.iSlot	= 0;
		info.iPosition 	= 7;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= 0;
		info.iWeight 	= 0;

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

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( "models/wanted/v_pick.mdl" ), self.GetP_Model( "models/wanted/p_pick.mdl" ), PICK_DRAW, "crowbar" );
			self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat(1.0, 2.0);
			return bResult;
		}
	}

	void Holster( int skiplocal /* = 0 */ )
	{
		self.m_fInReload = false;// cancel any reload in progress.

		m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5; 

		m_pPlayer.pev.viewmodel = "";

		SetThink( null );
	}
	
	void PrimaryAttack()
	{
		if( !Swing( 1 ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}
	
	void Smack()
	{
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}

	void SwingAgain()
	{
		Swing( 0 );
	}

	bool Swing( int fFirst )
	{
		bool fDidHit = false;

		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 32;

		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat(1.0, 2.0);

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if ( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if ( tr.flFraction < 1.0 )
			{
				// Calculate the point of intersection of the line (or hull) and the object we hit
				// This is and approximation of the "best" intersection
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if ( pHit is null || pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
				vecEnd = tr.vecEndPos;	// This is the point on the actual surface (the hull could have hit space)
			}
		}

		if ( tr.flFraction >= 1.0 )
		{
			if( fFirst != 0 )
			{
				// miss
				switch( ( m_iSwing++ ) % 3 )
				{
				case 0: self.SendWeaponAnim( PICK_ATTACK1MISS ); break;
				case 1: self.SendWeaponAnim( PICK_ATTACK2MISS ); break;
				case 2: self.SendWeaponAnim( PICK_ATTACK3MISS ); break;
				}
				self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
				// play wiff or swish sound
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "wanted/weapons/pick_miss1.wav", 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );

				// player "shoot" animation
				m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
			}
		}
		else
		{
			// hit
			fDidHit = true;
			
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			switch( ( ( m_iSwing++ ) % 2 ) + 1 )
			{
			case 0: self.SendWeaponAnim( PICK_ATTACK1HIT ); break;
			case 1: self.SendWeaponAnim( PICK_ATTACK2HIT ); break;
			case 2: self.SendWeaponAnim( PICK_ATTACK3HIT ); break;
			}

			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 

			float flDamage = 30;
			if ( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;

			g_WeaponFuncs.ClearMultiDamage();
			if ( self.m_flNextPrimaryAttack + 1 < g_Engine.time )
			{
				// first swing does full damage
				pEntity.TraceAttack( self.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB );  
			}
			else
			{
				// subsequent swings do 50% (Changed -Sniper) (Half)
				pEntity.TraceAttack( self.pev, flDamage * 0.5, g_Engine.v_forward, tr, DMG_CLUB );  
			}	
			g_WeaponFuncs.ApplyMultiDamage( self.pev, self.pev );

			//m_flNextPrimaryAttack = gpGlobals->time + 0.30; //0.25

			// play thwack, smack, or dong sound
			float flVol = 1.0;
			bool fHitWorld = true;

			if( pEntity !is null )
			{
				self.m_flNextPrimaryAttack = g_Engine.time + 0.30; //0.25

				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{
					if( pEntity.IsPlayer() )
					{
						pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
					}
					// play thwack or smack sound
					switch( Math.RandomLong( 0, 2 ) )
					{
					case 0: g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "wanted/weapons/pick_hitbod1.wav", 1, ATTN_NORM ); break;
					case 1: g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "wanted/weapons/pick_hitbod2.wav", 1, ATTN_NORM ); break;
					case 2: g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "wanted/weapons/pick_hitbod3.wav", 1, ATTN_NORM ); break;
					}
					m_pPlayer.m_iWeaponVolume = 128; 
					if( !pEntity.IsAlive() )
						return true;
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			// play texture hit sound
			// UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

			if( fHitWorld == true )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CROWBAR );
				
				self.m_flNextPrimaryAttack = g_Engine.time + 0.25; //0.25
				
				// override the volume here, cause we don't play texture sounds in multiplayer, 
				// and fvolbar is going to be 0 from the above call.

				fvolbar = 1;

				// also play crowbar strike
				switch( Math.RandomLong( 0, 1 ) )
				{
				case 0: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "wanted/weapons/pick_hit1.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
				case 1: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "wanted/weapons/pick_hit2.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
				}
			}

			// delay the decal a bit
			m_trHit = tr;
			SetThink( ThinkFunction( this.Smack ) );
			self.pev.nextthink = g_Engine.time + 0.2;

			m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
		}
		return fDidHit;
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		int iAnim;
		float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );

		switch( Math.RandomLong(0, 2) )
		{
			case 0:
			{
				iAnim = PICK_IDLE1;
				self.m_flTimeWeaponIdle = g_Engine.time + 3.0f;
			}
			break;
			case 1:
			{
				iAnim = PICK_IDLE2;
				self.m_flTimeWeaponIdle = g_Engine.time + 2.3f;
			}
			break;
			case 2:
			{
				iAnim = PICK_IDLE3;
				self.m_flTimeWeaponIdle = g_Engine.time + 2.3f;
			}
			break;
		}

		self.SendWeaponAnim( iAnim );
	}
}

string GetPickName()
{
	return "weapon_pick";
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "HLWanted_PickAxe::weapon_pick", GetPickName() );
	g_ItemRegistry.RegisterWeapon( GetPickName(), "wanted" );
}

} //namespace HLWanted_PickAxe END