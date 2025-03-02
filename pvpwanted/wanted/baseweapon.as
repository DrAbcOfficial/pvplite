#include "weapon_knife"
#include "weapon_pick"
#include "weapon_pistol"
#include "weapon_colts"
#include "weapon_shotgun"
#include "weapon_winchester"
#include "weapon_bow"
#include "weapon_dynamite"
#include "weapon_gattlinggun"
#include "weapon_cannon"
#include "weapon_buffalo"
#include "weapon_beartrap"
#include "weapon_scorpion"

void HLWanted_WeaponsRegister()
{
	HLWanted_Knife::Register();
	HLWanted_PickAxe::Register();
	HLWanted_Pistol::Register();
	HLWanted_Colts::Register();
	HLWanted_Shotgun::Register();
	HLWanted_Winchester::Register();
	HLWanted_Bow::Register();
	HLWanted_Dynamite::Register();
	HLWanted_Gattlinggun::Register();
	HLWanted_Cannon::Register();
	HLWanted_Buffalo::Register();
	HLWanted_Beartrap::Register();
	HLWanted_Scorpion::Register();
}
mixin class CBaseCustomWeapon
{
	// Possible workaround for the SendWeaponAnim() access violation crash.
	// According to R4to0 this seems to provide at least some improvement.
	// GeckoN: TODO: Remove this once the core issue is addressed.
	private CBasePlayer@ m_pPlayer = null;

    void Materialize( void )
    {
        BaseClass.Materialize();
        SetTouch (TouchFunction(MyTouch));
    }
    void MyTouch(CBaseEntity@ pOther)
    {
        if(pOther.IsPlayer())
        {
            CBasePlayer@ pPlayer = cast<CBasePlayer@>(@pOther);
            if(pPlayer.HasNamedPlayerItem(self.pev.classname) !is null)
            {
                if (self.m_iPrimaryAmmoType >= 0)
                    pPlayer.GiveAmmo(self.m_iDefaultAmmo, self.pszAmmo1(), self.iMaxAmmo1(), true);
                if(self.m_iSecondaryAmmoType >= 0 && self.pszAmmo2() != "")
                    pPlayer.GiveAmmo(self.m_iDefaultSecAmmo, self.pszAmmo2(), self.iMaxAmmo2(), true);
                g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
                self.CheckRespawn();
                g_EntityFuncs.Remove( self );
            }
            else if (pPlayer.AddPlayerItem(self) != APIR_NotAdded)
            {
                self.AttachToPlayer( pPlayer );
                g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "items/gunpickup2.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
            }
        }
    }

	protected bool m_fDropped;
	CBasePlayerItem@ DropItem()
	{
		m_fDropped = true;
		return self;
	}

	void GetDefaultShellInfo( CBasePlayer@ pPlayer, Vector& out ShellVelocity,
		Vector& out ShellOrigin, float forwardScale, float rightScale, float upScale )
	{
		Vector vecForward, vecRight, vecUp;

		g_EngineFuncs.AngleVectors( pPlayer.pev.v_angle, vecForward, vecRight, vecUp );

		const float fR = Math.RandomFloat( 50, 70 );
		const float fU = Math.RandomFloat( 100, 150 );

		for( int i = 0; i < 3; ++i )
		{
			ShellVelocity[i] = pPlayer.pev.velocity[i] + vecRight[i] * fR + vecUp[i] * fU + vecForward[i] * 25;
			ShellOrigin[i]   = pPlayer.pev.origin[i] + pPlayer.pev.view_ofs[i] + vecUp[i] * upScale + vecForward[i] * forwardScale + vecRight[i] * rightScale;
		}
	}
}

class CBaseCustomAmmo : ScriptBasePlayerAmmoEntity
{
	protected string m_strModel = "models/error.mdl";
	protected string m_strName;
	protected int m_iAmount = 0;
	protected int m_iMax = 0;

	protected string m_strPickupSound = "items/gunpickup2.wav";

	void Precache()
	{
		g_Game.PrecacheModel( m_strModel );

		g_SoundSystem.PrecacheSound( m_strPickupSound );
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, m_strModel );
		BaseClass.Spawn();
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		if ( pOther.GiveAmmo( m_iAmount, m_strName, m_iMax, false ) == -1 )
			return false;

		g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, m_strPickupSound, 1, ATTN_NORM );

		return true;
	}
}
