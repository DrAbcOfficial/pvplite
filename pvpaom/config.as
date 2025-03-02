#include "aomdc/weapon_dcberetta"
#include "aomdc/weapon_dcp228"
#include "aomdc/weapon_dcglock"
#include "aomdc/weapon_dchammer"
#include "aomdc/weapon_dcknife"
#include "aomdc/weapon_dcmp5k"
#include "aomdc/weapon_dcuzi"
#include "aomdc/weapon_dcshotgun"
#include "aomdc/weapon_dcrevolver"
#include "aomdc/weapon_dcdeagle"
#include "aomdc/weapon_dcaxe"
#include "aomdc/weapon_dcl85a1"
#include "aomdc/ammo_dcglock"
#include "aomdc/ammo_dcdeagle"
#include "aomdc/ammo_dcrevolver"
#include "aomdc/ammo_dcmp5k"
#include "aomdc/ammo_dcshotgun"
#include "aomdc/item_aompills"
#include "aomdc/baseweapon"

#include "entity/item_hlbattery"
#include "entity/item_hllongjump"
#include "entity/func_healthcharger"
#include "entity/func_recharge"
#include "entity/hlweaponbox"
#include "entity/func_tank_custom"

const dictionary g_ItemMappings = {
    { "weapon_medkit", "weapon_dcknife"},
    { "weapon_crowbar", "weapon_dcknife"},
    { "weapon_9mmAR", "weapon_dcmp5k" },
    { "weapon_m16", "weapon_dcmp5k" },
    { "weapon_crossbow", "weapon_dcrevolver" },
    { "weapon_9mmhandgun", "weapon_dcp228" },
    { "weapon_357", "weapon_dcdeagle" },
    { "weapon_satchel", "ammo_dcglock" },
    { "weapon_snark", "weapon_dcglock" },
    { "weapon_tripmine", "weapon_dcberetta" },
    { "weapon_rpg", "weapon_dcuzi" },
    { "weapon_handgrenade", "ammo_dcglock" },
    { "weapon_gauss", "weapon_dcaxe" },
    { "weapon_egon", "weapon_dchammer" },
    { "weapon_hornetgun", "weapon_dcshotgun" },
    { "weapon_shotgun", "weapon_dcshotgun"},
    { "func_healthcharger", GetHLHPChargerName() },
    { "func_recharge", GetHLAPChargerName() },
    { "item_battery", "item_hlbattery" },
    { "item_healthkit", "item_aompills"},
    { "item_longjump", "item_hllongjump"},
    { "ammo_ARgrenade",  "ammo_glockclip" },
    { "ammo_357", "ammo_dcdeagle"},
    { "ammo_556", "ammo_dcmp5k"},
    { "ammo_556clip", "ammo_dcmp5k"},
    { "ammo_9mmAR" ,"ammo_dcmp5k"},
    { "ammo_9mmbox", "ammo_dcglock"},
    { "ammo_buckshot", "ammo_dcshotgun"},
    { "ammo_glockclip", "ammo_dcglock"},
    { "ammo_mp5clip", "ammo_dcmp5k"},
    { "ammo_rpgclip", "ammo_dcmp5k"},
    { "ammo_uziclip", "ammo_dcmp5k"},
    { "ammo_crossbow", "ammo_dcrevolver"},
    { "ammo_gaussclip", "ammo_dcrevolver"}
};
const array<string> g_RemoveList = {
    "weapon_m16", "weapon_glock", "weapon_9mmhandgun", "weapon_mp5", "weapon_9mmar", "weapon_rpg", "weapon_crowbar",
    "weapon_healthkit", "weapon_shotgun", "weapon_gauss", "weapon_egon", "weapon_tripmine", "weapon_hornetgun", "weapon_357",
    "weapon_eagle", "weapon_handgrenade", "weapon_uzi", "weapon_uzi_akimbo", "weapon_crossbow"
};
const array<string> g_StartEquipments = {
    "weapon_dcp228", "ammo_9mmclip",  "ammo_9mmclip",  "ammo_9mmclip", "weapon_dcknife"
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
    { "mp_hevsuit_voice", 0.0f},
    { "mp_disable_autoclimb",  1.0f},
    { "mp_timelimit",  12.0f},
    { "sv_maxspeed",  270.0f},
    { "mp_weapon_respawndelay", RESPAWN_DELAY},
    { "mp_ammo_respawndelay", RESPAWN_DELAY},
    { "mp_item_respawndelay", RESPAWN_DELAY}
};
namespace Config{
void Register() {
    // Register weapons
	RegisterDCBeretta();
	RegisterDCP228();
	RegisterDCGlock();
	RegisterDCHammer();
	RegisterDCKnife();
	RegisterDCMP5K();
	RegisterDCUzi();
	RegisterDCShotgun();
	RegisterDCRevolver();
	RegisterDCDeagle();
	RegisterDCAxe();
	RegisterDCL85A1();

	// Register pills and batteries
	RegisterAOMPills();

	RegisterHLAPCharger();
    RegisterHLHPCharger();

	// Register misc entities
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_dcglock", "ammo_dcglock" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_dcdeagle", "ammo_dcdeagle" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_dcrevolver", "ammo_dcrevolver" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_dcmp5k", "ammo_dcmp5k" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_dcshotgun", "ammo_dcshotgun" );

    g_CustomEntityFuncs.RegisterCustomEntity( "item_hlbattery", "item_hlbattery");
    g_CustomEntityFuncs.RegisterCustomEntity( "item_hllongjump", "item_hllongjump");
    g_CustomEntityFuncs.RegisterCustomEntity( "hlweaponbox", "hlweaponbox");
    g_CustomEntityFuncs.RegisterCustomEntity( "CustomTank::CFuncTankMortar", "func_tankmortar_custom");

    g_Game.PrecacheOther("ammo_dcglock");
    g_Game.PrecacheOther("ammo_dcdeagle");
    g_Game.PrecacheOther("ammo_dcrevolver");
    g_Game.PrecacheOther("ammo_dcmp5k");
    g_Game.PrecacheOther("ammo_dcshotgun");
    g_Game.PrecacheOther("item_hlbattery");
    g_Game.PrecacheOther("item_aompills");
    g_Game.PrecacheOther("item_hllongjump");
    g_Game.PrecacheOther("hlweaponbox");
}

void PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int bitGib ) {
}
}
