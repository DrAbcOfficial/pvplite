// Afraid of Monsters: Director's Cut Script
// Weapon Script: Beretta
// Author: Zorbos

const float BERETTA_MOD_DAMAGE = 17.0;
const float BERETTA_MOD_FIRERATE = 0.05;

const float BERETTA_MOD_DAMAGE_SURVIVAL = 13.0; // Reduce damage by 25% on Survival

const int BERETTA_DEFAULT_AMMO 	= 15;
const int BERETTA_MAX_CARRY 	= 130;
const int BERETTA_MAX_CLIP 		= 15;
const int BERETTA_WEIGHT 		= 5;

enum BERETTAAnimation
{
	BERETTA_IDLE1 = 0,
	BERETTA_IDLE2,
	BERETTA_IDLE3,
	BERETTA_SHOOT,
	BERETTA_SHOOT_EMPTY,
	BERETTA_RELOAD,
	BERETTA_RELOAD_NOT_EMPTY,
	BERETTA_DRAW,
	BERETTA_HOLSTER,
	BERETTA_ADD_SILENCER
};

class weapon_dcberetta : ScriptBasePlayerWeaponEntity, CBaseAOMWeapon
{
	
	private CScheduledFunction@ m_pPostDropItemSched = null;
	private bool bSurvivalEnabled = g_EngineFuncs.CVarGetFloat("mp_survival_starton") == 1 && g_EngineFuncs.CVarGetFloat("mp_survival_supported") == 1;
	
	int m_iShell;
	int m_iLastReserveAmmo;
	int iShellModelIndex;
	bool bIsFiring = false; // Used for Semi-Automatic fire

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/AoMDC/weapons/beretta/w_dcberetta.mdl" );
		
        self.m_iDefaultAmmo = BERETTA_DEFAULT_AMMO;

		self.FallInit();// get ready to fall
		
		// Makes it slightly easier to pickup the gun
		g_EntityFuncs.SetSize(self.pev, Vector( -4, -4, -1 ), Vector( 4, 4, 1 ));
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/AoMDC/weapons/beretta/v_dcberetta.mdl" );
		g_Game.PrecacheModel( "models/AoMDC/weapons/beretta/w_dcberetta.mdl" );
		g_Game.PrecacheModel( "models/AoMDC/weapons/beretta/p_dcberetta.mdl" );

		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" ); // brass casing

		g_SoundSystem.PrecacheSound( "AoMDC/weapons/beretta/beretta_magin.wav" ); // reloading sound
		g_SoundSystem.PrecacheSound( "AoMDC/weapons/beretta/beretta_magout.wav" ); // reloading sound
		g_SoundSystem.PrecacheSound( "AoMDC/weapons/beretta/beretta_magplace.wav" ); // reloading sound
		g_SoundSystem.PrecacheSound( "AoMDC/weapons/beretta/beretta_slideforward.wav" ); // reloading sound

		g_SoundSystem.PrecacheSound( "AoMDC/weapons/beretta/beretta_fire.wav" ); // firing sound
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= BERETTA_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= BERETTA_MAX_CLIP;
		info.iSlot 		= 1;
		info.iPosition 	= 6;
		info.iFlags 	= 0;
		info.iWeight 	= BERETTA_WEIGHT;

		return true;
	}

	void Holster( int skipLocal = 0 )
	{
		bIsFiring = false;
		m_pPlayer.m_flNextAttack = WeaponTimeBase() + 0.7f;
		BaseClass.Holster( skipLocal );
		
		if(m_pPostDropItemSched !is null)
			g_Scheduler.RemoveTimer(m_pPostDropItemSched);
		
		@m_pPostDropItemSched = g_Scheduler.SetTimeout(@this, "PostDropItem", 0.1);
	}
	
	// Creates a new weapon of the given type and "throws" it forward
	void ThrowWeapon(CBasePlayerWeapon@ pWeapon, bool bWasSwapped)
	{
		// Get player origin
		string plrOrigin = "" + m_pPlayer.pev.origin.x + " " +
							    m_pPlayer.pev.origin.y + " " +
							    (m_pPlayer.pev.origin.z + 20.0);
								
		// Get player angles
		string plrAngleCompY;
		
		// Different weapons need to be thrown out at different angles so that they face the player.
		if(pWeapon.GetClassname() == "weapon_dcberetta")
			plrAngleCompY = m_pPlayer.pev.angles.y + 180.0;
		else if(pWeapon.GetClassname() == "weapon_dcglock")
			plrAngleCompY = m_pPlayer.pev.angles.y + 165.0;
		else
			plrAngleCompY = m_pPlayer.pev.angles.y - 90.0;
		
		string plrAngles = "" + m_pPlayer.pev.angles.x + " " +
							    plrAngleCompY + " " +
							    m_pPlayer.pev.angles.z;
								
		// Spawnflags 1280 = USE Only + Never respawn
		dictionary@ pValues = {{"origin", plrOrigin}, {"angles", plrAngles}, {"targetname", "weapon_dropped"}, {"message", ""}};
		
		if(bWasSwapped)
			pValues["message"] = g_EngineFuncs.GetPlayerAuthId(m_pPlayer.edict()); // The owner's STEAMID
		
		// Create the new item and "throw" it forward
		CBasePlayerWeapon@ pNew = cast<CBasePlayerWeapon@>(g_EntityFuncs.CreateEntity(pWeapon.GetClassname(), @pValues, true));
		
		if(pWeapon.GetClassname() == self.GetClassname()) // We're dropping THIS weapon
		{
			pNew.m_iClip = self.m_iClip; // Remember how many bullets are in the magazine
			m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) * 2); // Stop ammo stacking
		}
		else // We're dropping a different weapon. Preserve it's current magazine state
			pNew.m_iClip = pWeapon.m_iClip;
			
		pNew.pev.velocity = g_Engine.v_forward * 200 + g_Engine.v_up * 125;
		
		m_pPlayer.SetItemPickupTimes(0);
	}
	
	// Handles the case in which this weapon is thrown VOLUNTARILY by the player or the player dies
	void PostDropItem()
	{
		CBaseEntity@ pWeaponbox = g_EntityFuncs.Instance(self.pev.owner); // The 'actual' thrown weapon
		
		if(pWeaponbox is null) // Failsafe(s)
			return;
		if(!pWeaponbox.pev.ClassNameIs("weaponbox"))
			return;
		
		// Remove the 'actual' dropped weapon..
		g_EntityFuncs.Remove(pWeaponbox);
		
		CBasePlayerWeapon@ pWeapon = self;
		
		// Spawn a new copy and "throw" it forward
		ThrowWeapon(pWeapon, false);
	}   
	
	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( "models/AoMDC/weapons/beretta/v_dcberetta.mdl" ), self.GetP_Model( "models/AoMDC/weapons/beretta/p_dcberetta.mdl" ), BERETTA_DRAW, "onehanded" );
	}

	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
	}

	void PrimaryAttack()
	{
		int m_iBulletDamage;
		
		// Kind of a hack. Forces players to fire in semi-auto (1 click = 1 bullet fired)
		if(bIsFiring)
			return;
			
		if(!bIsFiring)
			bIsFiring = true;
		
		// don't fire underwater
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
			return;
		}
		
		if (self.m_iClip == 0)
		{
			self.m_flNextPrimaryAttack = g_Engine.time + BERETTA_MOD_FIRERATE;
			return;
		}
		else if (self.m_iClip != 0)
		{
			self.SendWeaponAnim( BERETTA_SHOOT, 0, 0 );
		}
		else
		{
			self.SendWeaponAnim( BERETTA_SHOOT_EMPTY, 0, 0 );
		}

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "AoMDC/weapons/beretta/beretta_fire.wav", Math.RandomFloat( 0.92, 1.0 ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( 0 );

		if(bSurvivalEnabled)
			m_iBulletDamage = BERETTA_MOD_DAMAGE_SURVIVAL;
		else
			m_iBulletDamage = BERETTA_MOD_DAMAGE;

		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, g_vecZero, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 0, m_iBulletDamage,  pevAttacker:self.pev );
		self.m_flNextPrimaryAttack = g_Engine.time + BERETTA_MOD_FIRERATE;
		self.m_flTimeWeaponIdle = g_Engine.time + BERETTA_MOD_FIRERATE;

		m_pPlayer.pev.punchangle.x = -2.0;
		
		TraceResult tr;
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming;

		Vector vecEnd	= vecSrc + vecDir * 4096;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		NetworkMessage mFlash(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
			mFlash.WriteByte(TE_DLIGHT);
			mFlash.WriteCoord(m_pPlayer.GetGunPosition().x);
			mFlash.WriteCoord(m_pPlayer.GetGunPosition().y);
			mFlash.WriteCoord(m_pPlayer.GetGunPosition().z);
			mFlash.WriteByte(14); // Radius
			mFlash.WriteByte(255); // R
			mFlash.WriteByte(255); // G
			mFlash.WriteByte(204); // B
			mFlash.WriteByte(1); // Lifetime
			mFlash.WriteByte(1); // Decay
		mFlash.End();
		
		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_9MM );
			}
		}
		
		iShellModelIndex = g_EngineFuncs.ModelIndex("models/shell.mdl");
		Vector brassOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 25.0 +
							 g_Engine.v_up * -9.0 +
							 g_Engine.v_right * 10.0;
		Vector brassDir = g_Engine.v_right * Math.RandomFloat(75.0, 100.0) + 
						  g_Engine.v_up * Math.RandomFloat(5.0, 50.0) + 
						  g_Engine.v_forward * Math.RandomFloat(-15.0, 15.0);
		
		g_EntityFuncs.EjectBrass( brassOrigin, brassDir, 0.0f, iShellModelIndex, TE_BOUNCE_SHELL );
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		// Reset the firing state so we can fire again
		bIsFiring = false;

		self.m_flTimeWeaponIdle = g_Engine.time + BERETTA_MOD_FIRERATE;
	}
	
	void Reload()
	{
		if (self.m_iClip == BERETTA_MAX_CLIP) // Can't reload if we have a full magazine already!
			return;

		if (self.m_iClip == 0)
			self.DefaultReload( BERETTA_MAX_CLIP, BERETTA_RELOAD, 1.85, 0 );
		else
			self.DefaultReload( 16, BERETTA_RELOAD_NOT_EMPTY, 1.65, 0 );
		
		BaseClass.Reload();
		return;
	}
}

string GetDCBerettaName()
{
	return "weapon_dcberetta";
}

void RegisterDCBeretta()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_dcberetta", GetDCBerettaName() );
	g_ItemRegistry.RegisterWeapon( GetDCBerettaName(), "AoMDC", "9mm" );
}















