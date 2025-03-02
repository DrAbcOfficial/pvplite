#include "paranoia/include"
#include "entity/item_hlbattery"
#include "entity/item_hlmedkit"
#include "entity/item_hllongjump"
#include "entity/func_healthcharger"
#include "entity/func_recharge"
#include "entity/hlweaponbox"

const dictionary g_ItemMappings ={
    { "weapon_healthkit", "weapon_paranoia_knife"},
    { "weapon_crowbar", "weapon_paranoia_knife"},
    { "weapon_9mmAR", "weapon_ak74" },
    { "weapon_shotgun", "weapon_spas12" },
    { "weapon_m16", "weapon_aks" },
    { "weapon_crossbow", "weapon_val" },
    { "weapon_9mmhandgun", "weapon_aps" },
    { "weapon_357", "weapon_groza" },
    { "weapon_satchel", "weapon_f1" },
    { "weapon_snark", "weapon_aks" },
    { "weapon_tripmine", "weapon_f1" },
    { "weapon_rpg", "weapon_paranoia_rpg" },
    { "weapon_handgrenade", "weapon_f1" },
    { "weapon_gauss", "weapon_paranoia_mp5" },
    { "weapon_egon", "weapon_rpk" },
    { "weapon_hornetgun", "weapon_paranoia_glock" },
    { "func_healthcharger", GetHLHPChargerName() },
    { "func_recharge", GetHLAPChargerName() },
    { "item_battery", "item_hlbattery" },
    { "item_healthkit", "item_hlmedkit"},
    { "item_longjump", "item_hllongjump"},
    { "ammo_357", "ammo_grozaammobox"},
    { "ammo_556", "ammo_rpkammobox"},
    { "ammo_556clip", "ammo_rpk"},
    { "ammo_9mmAR" ,"ammo_ak74ammobox"},
    { "ammo_9mm", "ammo_apsammobox"},
    { "ammo_9mmbox", "ammo_aksammobox"},
    { "ammo_9mmclip", "ammo_apsammobox"},
    { "ammo_buckshot", "ammo_spas12"},
    { "ammo_glockclip", "ammo_glockammobox"},
    { "ammo_mp5clip", "ammo_paranoia_mp5ammobox"},
    { "ammo_rpgclip", "ammo_paranoia_rpg"},
    { "ammo_uziclip", "ammo_val"},
    { "ammo_crossbow", "ammo_val"},
    { "ammo_gaussclip", "ammo_rpk"}
};
const array<string> g_RemoveList = {
    "weapon_m16", "weapon_glock", "weapon_9mmhandgun", "weapon_mp5", "weapon_9mmar", "weapon_rpg", "weapon_crowbar",
    "weapon_healthkit", "weapon_shotgun", "weapon_gauss", "weapon_egon", "weapon_tripmine", "weapon_hornetgun", "weapon_357",
    "weapon_eagle", "weapon_handgrenade", "weapon_uzi", "weapon_uzi_akimbo", "weapon_crossbow"
};
const array<string> g_StartEquipments = {
    "weapon_aps", "ammo_aps",  "ammo_aps",  "ammo_aps", "weapon_paranoia_knife"
};
const float RESPAWN_DELAY = 20.0f;
const dictionary g_CVars = {
    { "mp_respawndelay",  0.0f},
    { "mp_falldamage", 0.0f },
    { "mp_allowmonsterinfo", 0.0f},
    { "mp_allowmonsters", 0.0f},
    { "mp_allowplayerinfo", 0.0f},
    { "mp_weapon_droprules", 0.0f},
    { "mp_ammo_droprules",  0.0f},
    { "mp_hevsuit_voice", 1.0f},
    { "mp_disable_autoclimb",  1.0f},
    { "mp_timelimit",  12.0f},
    { "sv_maxspeed",  255.0f},
    { "mp_weapon_respawndelay", RESPAWN_DELAY},
    { "mp_ammo_respawndelay", RESPAWN_DELAY},
    { "mp_item_respawndelay", RESPAWN_DELAY}
};
namespace Config{
void Register() {
    WeaponRegister();

    RegisterHLHPCharger();
    RegisterHLAPCharger();
    g_CustomEntityFuncs.RegisterCustomEntity( "item_hlbattery", "item_hlbattery");
    g_CustomEntityFuncs.RegisterCustomEntity( "item_hlmedkit", "item_hlmedkit");
    g_CustomEntityFuncs.RegisterCustomEntity( "item_hllongjump", "item_hllongjump");
    g_CustomEntityFuncs.RegisterCustomEntity( "hlweaponbox", "hlweaponbox");

    g_Game.PrecacheOther("item_hlbattery");
    g_Game.PrecacheOther("item_hlmedkit");
    g_Game.PrecacheOther("item_hllongjump");
    g_Game.PrecacheOther("hlweaponbox");
}
void PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int bitGib ) {
}
}
