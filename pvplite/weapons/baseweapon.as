mixin class CBasePVPWeapon{
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
            CBasePlayerItem@ pItem = pPlayer.HasNamedPlayerItem(self.pev.classname);
            if(pItem !is null)
            {
                CBasePlayerWeapon@ pWeapon = pItem.GetWeaponPtr();
                if(pWeapon.m_iPrimaryAmmoType >= 0)
                {
                    if(self.iMaxClip() > 0 && pWeapon.m_iClip == 0)
                    {
                        if(pWeapon.pev.classname == "weapon_hlmp5")
                            pWeapon.m_iClip = self.m_iClip;
                        else
                            pWeapon.m_iClip = pWeapon.iMaxClip();
                        pWeapon.m_flNextPrimaryAttack = 0;
                        pWeapon.m_flNextSecondaryAttack = 0;
                        pWeapon.m_flNextTertiaryAttack = 0;
                        pPlayer.m_flNextAttack = 0;
                        int give = self.m_iDefaultAmmo - pWeapon.m_iClip;
                        if(give > 0)
                            pPlayer.GiveAmmo(give, pWeapon.pszAmmo1(), pWeapon.iMaxAmmo1(), true);
                    }
                    else
                        pPlayer.GiveAmmo(self.m_iDefaultAmmo, self.pszAmmo1(), self.iMaxAmmo1(), true);
                }
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
}
