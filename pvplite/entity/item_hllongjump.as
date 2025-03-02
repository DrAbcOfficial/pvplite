class item_hllongjump : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    { 
        Precache();
        BaseClass.Spawn();
        g_EntityFuncs.SetSize(self.pev, Vector( -8, -8, -8 ), Vector( 8, 8, 8 ));
        g_EntityFuncs.SetModel( self, "models/hlclassic/w_longjump.mdl" );
    }
    
    void Precache()
    {
        BaseClass.Precache();
        g_Game.PrecacheModel("models/hlclassic/w_longjump.mdl");
        g_Game.PrecacheModel("models/hlclassic/w_longjumpt.mdl");
    }
    
    bool AddAmmo(CBaseEntity@ pOther)
    {
        CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);
        if(pPlayer !is null && !pPlayer.m_fLongJump){
            NetworkMessage message( MSG_ONE, NetworkMessages::ItemPickup, pPlayer.edict() );
                message.WriteString("item_longjump");
            message.End();
            g_SoundSystem.EmitSoundSuit( pPlayer.edict(), "!HEV_A1" );
            pPlayer.m_fLongJump = true;
            KeyValueBuffer@ pInfo = g_EngineFuncs.GetPhysicsKeyBuffer(pPlayer.edict());
            pInfo.SetValue("slj", "1");
            return true;
        }
        return false;
    }
}