class item_wagonwheel : ScriptBaseEntity{
    void Spawn()
    { 
        Precache();
        BaseClass.Spawn();
        
        g_EntityFuncs.SetSize(self.pev, Vector( -32, -2, -32 ), Vector( 32, 2, 32 ));
        g_EntityFuncs.SetModel( self, "models/wanted/wagonwheel.mdl" );
        self.pev.solid = SOLID_BBOX;
    }
    void Precache()
    {
        BaseClass.Precache();
        g_Game.PrecacheModel("models/wanted/wagonwheel.mdl");
        g_Game.PrecacheGeneric("models/wanted/wagonwheel.mdl");
    }
}