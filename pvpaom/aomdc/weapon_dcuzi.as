// Afraid of Monsters: Director's Cut Script
// Weapon Script: Uzi
// Author: Zorbos

const float UZI_MOD_DAMAGE = 15.0;
const float UZI_MOD_FIRERATE = 0.08;

const float UZI_MOD_DAMAGE_SURVIVAL = 11.0; // Reduce damage by 25% on Survival

enum UziAnimation
{
	UZI_LONGIDLE = 0,
	UZI_IDLE1,
	UZI_LAUNCH,
	UZI_RELOAD,
	UZI_DEPLOY,
	UZI_FIRE1,
	UZI_FIRE2,
	UZI_FIRE3,
};

const int UZI_DEFAULT_AMMO 	= 25;
const int UZI_MAX_AMMO		= 120;
const int UZI_MAX_AMMO2 	= -1;
const int UZI_MAX_CLIP 		= 25;
const int UZI_WEIGHT 		= 5;

class weapon_dcuzi : ScriptBasePlayerWeaponEntity, CBaseAOMWeapon
{
	
	private CScheduledFunction@ m_pPostDropItemSched = null;
	private bool bSurvivalEnabled = g_EngineFuncs.CVarGetFloat("mp_survival_starton") == 1 && g_EngineFuncs.CVarGetFloat("mp_survival_supported") == 1;

	float m_flNextAnimTime;
	int m_iShell;
	int iShellModelIndex;
	int	m_iSecondaryAmmo;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/AoMDC/weapons/uzi/w_dcuzi.mdl" );

        self.m_iDefaultAmmo = UZI_DEFAULT_AMMO;

		self.m_iSecondaryAmmoType = 0;
		self.FallInit();

		// Makes it slightly easier to pickup the gun
		g_EntityFuncs.SetSize(self.pev, Vector( -4, -4, -1 ), Vector( 4, 4, 1 ));
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/AoMDC/weapons/uzi/v_dcuzi.mdl" );
		g_Game.PrecacheModel( "models/AoMDC/weapons/uzi/w_dcuzi.mdl" );
		g_Game.PrecacheModel( "models/AoMDC/weapons/uzi/p_dcuzi.mdl" );

		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );

		//These are played by the model, needs changing there
		g_SoundSystem.PrecacheSound( "AoMDC/weapons/uzi/uzi_boltpull.wav" );
		g_SoundSystem.PrecacheSound( "AoMDC/weapons/uzi/uzi_fire.wav" );
		g_SoundSystem.PrecacheSound( "AoMDC/weapons/uzi/uzi_magin.wav" );
		g_SoundSystem.PrecacheSound( "AoMDC/weapons/uzi/uzi_magout.wav" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= UZI_MAX_AMMO;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= UZI_MAX_CLIP;
		info.iSlot 		= 2;
		info.iPosition 	= 8;
		info.iFlags 	= 0;
		info.iWeight 	= UZI_WEIGHT;

		return true;
	}

	void Holster( int skipLocal = 0 )
	{
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
		if(pWeapon.GetClassname() == "weapon_dcuzi")
			plrAngleCompY = m_pPlayer.pev.angles.y;
		else if(pWeapon.GetClassname() == "weapon_dcmp5k")
			plrAngleCompY = m_pPlayer.pev.angles.y + 90.0;
		else
			plrAngleCompY = m_pPlayer.pev.angles.y + 145.0;

		string plrAngles = "" + m_pPlayer.pev.angles.x + " " +
							    plrAngleCompY + " " +
							    m_pPlayer.pev.angles.z;

		// Spawnflags 1280 = USE Only + Never respawn
		dictionary@ pValues = {{"origin", plrOrigin}, {"angles", plrAngles}, {"targetname", "weapon_dropped"}, {"globalname", ""}};

		if(bWasSwapped)
			pValues["globalname"] = g_EngineFuncs.GetPlayerAuthId(m_pPlayer.edict()); // The owner's STEAMID

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
		return self.DefaultDeploy( self.GetV_Model( "models/AoMDC/weapons/uzi/v_dcuzi.mdl" ), self.GetP_Model( "models/AoMDC/weapons/uzi/p_dcuzi.mdl" ), MP5_DEPLOY, "onehanded" );
	}

	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
	}

	void PrimaryAttack()
	{
		int m_iBulletDamage;

		// don't fire underwater
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase();
			return;
		}

		if( self.m_iClip <= 0 )
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase();
			return;
		}

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;

		switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
		{
		case 0: self.SendWeaponAnim( UZI_FIRE1, 0, 0 ); break;
		case 1: self.SendWeaponAnim( UZI_FIRE2, 0, 0 ); break;
		case 2: self.SendWeaponAnim( UZI_FIRE3, 0, 0 ); break;
		}

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "AoMDC/weapons/uzi/uzi_fire.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES );

		if(bSurvivalEnabled)
			m_iBulletDamage = UZI_MOD_DAMAGE_SURVIVAL;
		else
			m_iBulletDamage = UZI_MOD_DAMAGE;

		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_4DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage,  pevAttacker:self.pev);

		//m_pPlayer.pev.punchangle.x = -1;

		self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + UZI_MOD_FIRERATE;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase();

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );

		TraceResult tr;

		float x, y;

		g_Utility.GetCircularGaussianSpread( x, y );

		Vector vecDir = vecAiming
						+ x * VECTOR_CONE_4DEGREES.x * g_Engine.v_right
						+ y * VECTOR_CONE_4DEGREES.y * g_Engine.v_up;

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
		Vector brassOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 15.0 +
							 g_Engine.v_up * -5.0 +
							 g_Engine.v_right * 6.0;
		Vector brassDir = g_Engine.v_right * Math.RandomFloat(65.0, 100.0) +
						  g_Engine.v_up * Math.RandomFloat(10.0, 45.0) +
						  g_Engine.v_forward * Math.RandomFloat(-30.0, 30.0);

		g_EntityFuncs.EjectBrass( brassOrigin, brassDir, 0.0f, iShellModelIndex, TE_BOUNCE_SHELL );
	}

	void Reload()
	{
		self.DefaultReload( UZI_MAX_CLIP, UZI_RELOAD, 2.5, 0 );

		//Set 3rd person reloading animation -Sniper
		BaseClass.Reload();
	}
}

string GetDCUziName()
{
	return "weapon_dcuzi";
}

void RegisterDCUzi()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_dcuzi", GetDCUziName() );
	g_ItemRegistry.RegisterWeapon( GetDCUziName(), "AoMDC", "556" );
}
