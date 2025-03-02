class hlweaponbox : ScriptBasePlayerAmmoEntity
{
    string szContained;
    string szAmmoName;
    int iAmmo;
    int iAmmoMax;
    void Spawn()
    { 
        Precache();
        BaseClass.Spawn();
        g_EntityFuncs.SetSize(self.pev, Vector( -12, -12, -16 ), Vector( 12, 12, 16 ));
        g_EntityFuncs.SetModel( self, "models/hlclassic/w_weaponbox.mdl" );
        self.pev.solid = SOLID_TRIGGER;
        SetThink(ThinkFunction(Think));
        self.pev.nextthink = g_Engine.time + 60.0f;
    }
    void Think(){
        g_EntityFuncs.Remove(self);
    }
    void Precache()
    {
        BaseClass.Precache();
        g_Game.PrecacheModel("models/hlclassic/w_weaponbox.mdl");
        g_SoundSystem.PrecacheSound("items/gunpickup2.wav");
    }
    
    bool RemoveTrue(){
        g_EntityFuncs.Remove(self);
        return true;
    }
    bool AddAmmo(CBaseEntity@ pOther)
    {
        if(szContained == ""){
            g_EntityFuncs.Remove(self);
            return false;
        }
        CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);
        if(pPlayer !is null){
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/gunpickup2.wav", 1, ATTN_NORM);
            if(pPlayer.HasNamedPlayerItem(szContained) !is null && szAmmoName != "")
                pPlayer.GiveAmmo(iAmmo, szAmmoName, iAmmoMax, true);
            else{
                CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>(g_EntityFuncs.CreateEntity(szContained));
                if(pWeapon is null)
                    return RemoveTrue();
                pWeapon.m_iDefaultAmmo = iAmmo;
                pWeapon.KeyValue("m_flCustomRespawnTime", "-1");
                pWeapon.Touch(pPlayer);
            }
            return RemoveTrue();
        }
        return false;
    }
}

hlweaponbox@ CreateWeaponBox(CBasePlayer@ pPlayer){
    if(!pPlayer.m_hActiveItem.IsValid())
        return null;
    CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>(pPlayer.m_hActiveItem.GetEntity());
    if(pWeapon is null)
        return null;
    hlweaponbox@ pBox = cast<hlweaponbox@>(CastToScriptClass(g_EntityFuncs.Create("hlweaponbox", pPlayer.Center(), pPlayer.pev.angles, false, pPlayer.edict())));
    pBox.self.pev.velocity = pPlayer.pev.velocity;
    pBox.szContained = pWeapon.pev.classname;
    pBox.szAmmoName = pWeapon.pszAmmo1();
    pBox.iAmmo = pWeapon.iMaxClip() > 0 ? pWeapon.m_iClip : pPlayer.m_rgAmmo(pWeapon.m_iPrimaryAmmoType);
    pBox.iAmmoMax = pWeapon.iMaxAmmo1();
    return pBox;
}
