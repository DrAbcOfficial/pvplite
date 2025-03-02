namespace MLGFeedBack{
HUDSpriteParams pHud;
HUDSpriteParams pHudEmpty;
const string szSpr = "misc/mlg.spr";
const string szSound = "misc/hitmarker.wav";
void MapInit() {
    pHud.channel = 11;
	pHud.flags =  HUD_ELEM_SCR_CENTER_Y | HUD_ELEM_SCR_CENTER_X | HUD_SPR_MASKED | HUD_ELEM_DEFAULT_ALPHA;
	pHud.spritename = szSpr;
	pHud.x = 0;
	pHud.y = 0;
	pHud.fxTime = 0.03;
	pHud.effect = HUD_EFFECT_RAMP_UP;
	pHud.fadeinTime = 0.03;
	pHud.fadeoutTime = 0.03;
	pHud.holdTime = 0.2;
	pHud.color1 = RGBA_SVENCOOP;
	pHud.color2 = RGBA_WHITE;

	pHudEmpty.channel = 11;

    g_Game.PrecacheModel("sprites/" + szSpr);
    g_Game.PrecacheGeneric("sprites/" + szSpr);
    g_SoundSystem.PrecacheSound( szSound );
    g_Game.PrecacheGeneric("sound/" + szSound);
}
void TakeDamage(CBasePlayer@ pVictim, CBasePlayer@ pAttacker){
    if (pVictim is null || pAttacker is null)
        return;
    if (!pAttacker.IsPlayer())
        return;
    if ( @pVictim !is @pAttacker) {
        g_PlayerFuncs.HudCustomSprite(@pAttacker, pHud);
        NetworkMessage message( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, pAttacker.edict());
            message.WriteString("spk \"" + szSound + "\"\n");
        message.End();
    }
    return;
}
}
