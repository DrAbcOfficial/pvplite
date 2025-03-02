class item_hlbattery : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    { 
        Precache();
        BaseClass.Spawn();
        g_EntityFuncs.SetSize(self.pev, Vector( -4, -4, -4 ), Vector( 4, 4, 4 ));
        g_EntityFuncs.SetModel( self, "models/hlclassic/w_battery.mdl" );
    }
    
    void Precache()
    {
        BaseClass.Precache();
        g_Game.PrecacheModel("models/hlclassic/w_battery.mdl");
        g_Game.PrecacheModel("models/hlclassic/w_batteryt.mdl");
        g_SoundSystem.PrecacheSound("items/gunpickup2.wav");
    }
    
    bool AddAmmo(CBaseEntity@ pOther)
    {
        CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);
        if(pPlayer !is null && pPlayer.pev.armorvalue < pPlayer.pev.armortype){
            NetworkMessage message( MSG_ONE, NetworkMessages::ItemPickup, pPlayer.edict() );
                message.WriteString("item_battery");
            message.End();
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/gunpickup2.wav", 1, ATTN_NORM);
            pPlayer.pev.armorvalue = Math.clamp(0, pPlayer.pev.armortype, pPlayer.pev.armorvalue + 15);
            return true;
        }
        return false;
    }
}