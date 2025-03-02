#include "weapons/weapon_hlcrowbar"
#include "weapons/weapon_hlmp5"
#include "weapons/weapon_hlshotgun"
#include "weapons/weapon_hlcrossbow"
#include "weapons/weapon_hl9mmhandgun"
#include "weapons/weapon_hl357"
#include "weapons/weapon_hlsatchel"
#include "weapons/weapon_hlsnark"
#include "weapons/weapon_hltripmine"
#include "weapons/weapon_hlrpg"
#include "weapons/weapon_hlhandgrenade"
#include "weapons/weapon_hlgauss"
#include "weapons/weapon_hlegon"
#include "weapons/weapon_hlhornet"
#include "weapons/weapon_hlshockrifle"
#include "weapons/baseweapon"
#include "entity/item_hlbattery"
#include "entity/item_hlmedkit"
#include "entity/item_hllongjump"
#include "entity/func_healthcharger"
#include "entity/func_recharge"
#include "entity/hlweaponbox"
#include "entity/func_tank_custom"

const dictionary g_ItemMappings ={
    { "weapon_medkit", "weapon_hlcrowbar"},
    { "weapon_crowbar", "weapon_hlcrowbar"},
    { "weapon_9mmAR", "weapon_hlmp5" },
    { "weapon_m16", "weapon_hlmp5" },
    { "weapon_crossbow", GetHLCrossbowName() },
    { "weapon_9mmhandgun", GetHL9mmhandgunName() },
    { "weapon_357", GetHL357Name() },
    { "weapon_satchel", GetHLSatchelName() },
    { "weapon_snark", GetHLSnarkName() },
    { "weapon_tripmine", GetHLTripmineName() },
    { "weapon_rpg", GetHLRpgName() },
    { "weapon_handgrenade", GetHLHandgrenadeName() },
    { "weapon_gauss", GethlgaussName() },
    { "weapon_egon", GetHLEgonName() },
    { "weapon_hornetgun", GetHLHornetName() },
    { "weapon_shotgun", GetHLShotgunName()},
    { "func_healthcharger", GetHLHPChargerName() },
    { "func_recharge", GetHLAPChargerName() },
    { "item_battery", "item_hlbattery" },
    { "item_healthkit", "item_hlmedkit"},
    { "item_longjump", "item_hllongjump"}
};
const array<string> g_RemoveList = {
    "weapon_m16", "weapon_glock", "weapon_9mmhandgun", "weapon_mp5", "weapon_9mmar", "weapon_rpg", "weapon_crowbar",
    "weapon_healthkit", "weapon_shotgun", "weapon_gauss", "weapon_egon", "weapon_tripmine", "weapon_hornetgun", "weapon_357",
    "weapon_eagle", "weapon_handgrenade", "weapon_uzi", "weapon_uzi_akimbo", "weapon_crossbow"
};
const array<string> g_StartEquipments = {
    "weapon_hl9mmhandgun", "ammo_9mmclip",  "ammo_9mmclip",  "ammo_9mmclip", "weapon_hlcrowbar"
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
    { "mp_timelimit",  20.0f},
    { "sv_maxspeed",  320.0f},
    { "mp_weapon_respawndelay", RESPAWN_DELAY},
    { "mp_ammo_respawndelay", RESPAWN_DELAY},
    { "mp_item_respawndelay", RESPAWN_DELAY}
};
namespace Config{
void Register() {
    RegisterHLCrowbar();
    RegisterHLMP5();
    RegisterHLShotgun();
    RegisterHLCrossbow();
    RegisterHL9mmhandgun();
    RegisterHL357();
    RegisterHLSatchel();
    RegisterHLSnark();
    RegisterHLTripmine();
    RegisterHLRpg();
    RegisterHLHandgrenade();
    RegisterHLGauss();
    RegisterHLEgon();
    RegisterHLHPCharger();
    RegisterHLAPCharger();
    RegisterDMShockRifle();
    RegisterHLHornet();

    g_CustomEntityFuncs.RegisterCustomEntity( "item_hlbattery", "item_hlbattery");
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
    DeactivateSatchels( pPlayer );
}
}
