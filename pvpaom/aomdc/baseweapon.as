mixin class CBaseAOMWeapon{
    private CBasePlayer@ m_pPlayer;
    bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
		self.SetClassification(CLASS_TEAM1);
		@m_pPlayer = pPlayer;
		NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			message.WriteLong( self.m_iId );
		message.End();
		return true;
	}
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
}
