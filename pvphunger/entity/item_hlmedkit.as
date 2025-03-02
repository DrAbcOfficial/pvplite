class item_hlmedkit : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    { 
        Precache();
        BaseClass.Spawn();
        g_EntityFuncs.SetSize(self.pev, Vector( -4, -4, -4 ), Vector( 4, 4, 4 ));
        g_EntityFuncs.SetModel( self, "models/hunger/w_syringebox.mdl" );
    }
    
    void Precache()
    {
        BaseClass.Precache();
        g_Game.PrecacheModel("models/hunger/w_syringebox.mdl");
        g_Game.PrecacheGeneric("models/hunger/w_syringebox.mdl");
        g_SoundSystem.PrecacheSound("items/medshot4.wav");
    }
    
    bool AddAmmo(CBaseEntity@ pOther)
    {
        CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);
        if(pPlayer !is null && pPlayer.pev.health < pPlayer.pev.max_health){
            NetworkMessage message( MSG_ONE, NetworkMessages::ItemPickup, pPlayer.edict() );
                message.WriteString("item_healthkit");
            message.End();
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/medshot4.wav", 1, ATTN_NORM);
            pPlayer.pev.health = Math.clamp(0, pPlayer.pev.max_health, pPlayer.pev.health + 15);
            return true;
        }
        return false;
    }
}
