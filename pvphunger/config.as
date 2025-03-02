#include "hunger/weapon_sawedoff"
#include "hunger/weapon_m16a1"
#include "hunger/weapon_colt1911"
#include "hunger/weapon_tommygun"
#include "hunger/weapon_m14"
#include "hunger/weapon_greasegun"
#include "hunger/weapon_teslagun"
#include "hunger/weapon_spanner"

#include "hunger/weapon_hlcrossbow"
#include "hunger/weapon_hlcrowbar"
#include "hunger/weapon_hlhandgrenade"
#include "hunger/weapon_hl357"

#include "entity/item_hlmedkit"
#include "entity/item_hllongjump"
#include "entity/func_healthcharger"
#include "entity/hlweaponbox"
#include "entity/func_tank_custom"

const dictionary g_ItemMappings ={
    { "weapon_healthkit", "weapon_hlcrowbar"},
    { "weapon_crowbar", "weapon_hlcrowbar"},
    { "weapon_9mmAR", THWeaponThompson::WEAPON_NAME },
    { "weapon_shotgun", THWeaponSawedoff::WEAPON_NAME },
    { "weapon_m16", THWeaponM16A1::WEAPON_NAME },
    { "weapon_crossbow", "weapon_hlcrossbow" },
    { "weapon_9mmhandgun", THWeaponM1911::WEAPON_NAME },
    { "weapon_357", "weapon_hl357" },
    { "weapon_satchel", "weapon_greasegun" },
    { "weapon_snark", THWeaponM16A1::WEAPON_NAME },
    { "weapon_tripmine", "weapon_greasegun" },
    { "weapon_rpg", "weapon_m14" },
    { "weapon_handgrenade", "weapon_hlhandgrenade" },
    { "weapon_gauss", "weapon_teslagun" },
    { "weapon_egon", "weapon_teslagun" },
    { "weapon_hornetgun", "weapon_greasegun" },
    { "weapon_eagle", "weapon_357" },
    { "weapon_pipewrench", "weapon_spanner" },

    { "ammo_rpgclip",  "ammo_762" },
    { "ammo_ARgrenades",  "ammo_556clip" },

    { "func_healthcharger", GetHLHPChargerName() },
    { "func_recharge", GetHLHPChargerName() },
    { "item_battery", "item_hlmedkit" },
    { "item_healthkit", "item_hlmedkit"},
    { "item_longjump", "item_hllongjump"}
};
array<string> g_RemoveList = {
    "weapon_m16", "weapon_glock", "weapon_9mmhandgun", "weapon_mp5", "weapon_9mmar", "weapon_rpg", "weapon_crowbar",
    "weapon_healthkit", "weapon_shotgun", "weapon_gauss", "weapon_egon", "weapon_tripmine", "weapon_hornetgun", "weapon_357",
    "weapon_eagle", "weapon_handgrenade", "weapon_uzi", "weapon_uzi_akimbo", "weapon_crossbow"
};
const array<string> g_StartEquipments = {
    THWeaponM1911::WEAPON_NAME, "ammo_9mmclip",  "ammo_9mmclip",  "ammo_9mmclip", "weapon_hlcrowbar"
};
const float RESPAWN_DELAY = 20;
const dictionary g_CVars = {
    { "mp_respawndelay",  0.0f},
    { "mp_falldamage", 0.0f },
    { "mp_allowmonsterinfo", 0.0f},
    { "mp_allowmonsters", 0.0f},
    { "mp_allowplayerinfo", 0.0f},
    { "mp_weapon_droprules", 0.0f},
    { "mp_ammo_droprules",  0.0f},
    { "mp_hevsuit_voice", 0.0f},
    { "mp_disable_autoclimb",  1.0f},
    { "mp_timelimit",  12.0f},
    { "sv_maxspeed",  250.0f},
    { "mp_weapon_respawndelay", RESPAWN_DELAY},
    { "mp_ammo_respawndelay", RESPAWN_DELAY},
    { "mp_item_respawndelay", RESPAWN_DELAY}
};
namespace Config{
void Register() {
    THWeaponSawedoff::Register();
	THWeaponM16A1::Register();
	THWeaponM1911::Register();
	THWeaponThompson::Register();
	THWeaponM14::Register();
	THWeaponTeslagun::Register();
	THWeaponGreasegun::Register();
	THWeaponSpanner::Register();
	RegisterHL357();
	RegisterHLCrossbow();
	RegisterHLCrowbar();
	RegisterHLHandgrenade();

    RegisterHLHPCharger();
    g_CustomEntityFuncs.RegisterCustomEntity( "item_hlmedkit", "item_hlmedkit");
    g_CustomEntityFuncs.RegisterCustomEntity( "item_hllongjump", "item_hllongjump");
    g_CustomEntityFuncs.RegisterCustomEntity( "hlweaponbox", "hlweaponbox");
    g_CustomEntityFuncs.RegisterCustomEntity( "CustomTank::CFuncTankMortar", "func_tankmortar_custom");

    g_Game.PrecacheOther("item_hlbattery");
    g_Game.PrecacheOther("item_hlmedkit");
    g_Game.PrecacheOther("item_hllongjump");
    g_Game.PrecacheOther("hlweaponbox");
}
void PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int bitGib ) {
}
}
