#include "wanted/baseweapon"
#include "entity/basemonster"
#include "entity/item_hlbattery"
#include "entity/item_hlmedkit"
#include "entity/item_wagonwheel"
#include "entity/func_healthcharger"
#include "entity/func_recharge"
#include "entity/hlweaponbox"

const dictionary g_ItemMappings =
{
	{ "weapon_9mmhandgun",	HLWanted_Pistol::GetPistolName() },
	{ "weapon_9mmAR",		HLWanted_Colts::GetColtsName() },
	{ "weapon_crowbar",		HLWanted_Knife::GetKnifeName() },
	{ "weapon_crossbow",		HLWanted_Bow::GetBowName() },
	{ "weapon_sniperrifle",	HLWanted_Buffalo::GetBuffaloName() },
	{ "weapon_mp5",			HLWanted_Colts::GetColtsName() },
	{ "weapon_m16",			HLWanted_Winchester::GetWinchesterName() },
	{ "weapon_357",			HLWanted_Colts::GetColtsName() },
	{ "weapon_eagle",		HLWanted_Colts::GetColtsName() },
	{ "weapon_uzi",			HLWanted_Colts::GetColtsName() },
	{ "weapon_uziakimbo",	HLWanted_Colts::GetColtsName() },
	{ "weapon_shotgun",		HLWanted_Shotgun::GetShotgunName() },
	{ "weapon_handgrenade",	HLWanted_Dynamite::GetDynamiteName() },
	{ "weapon_pipewrench",	HLWanted_PickAxe::GetPickName() },
	{ "weapon_satchel",		HLWanted_Beartrap::GetBeartrapName() },
	{ "weapon_tripmine",		HLWanted_Beartrap::GetBeartrapName() },
	{ "weapon_grapple",		HLWanted_Scorpion::GetScorpionName() },
	{ "weapon_snark",		HLWanted_Scorpion::GetScorpionName() },
	{ "weapon_sporelauncher",HLWanted_Scorpion::GetScorpionName() },
	{ "weapon_hornetgun",	HLWanted_Scorpion::GetScorpionName() },
	{ "weapon_shockrifle",	HLWanted_Scorpion::GetScorpionName() },
	{ "weapon_rpg",			HLWanted_Cannon::GetCannonName() },
	{ "weapon_pickaxe",		HLWanted_PickAxe::GetPickName() },
	{ "weapon_saw",			HLWanted_Gattlinggun::GetGattlinggunName() },
	{ "weapon_m249",			HLWanted_Gattlinggun::GetGattlinggunName() },
	{ "weapon_minigun",		HLWanted_Gattlinggun::GetGattlinggunName() },
	{ "weapon_egon",			HLWanted_Gattlinggun::GetGattlinggunName() },
	{ "weapon_gauss",		HLWanted_Cannon::GetCannonName() },
	{ "weapon_displacer",	HLWanted_Cannon::GetCannonName() },
	{ "ammo_9mmclip",		HLWanted_Pistol::GetPistolAmmoName() },
	{ "ammo_9mmuziclip",		HLWanted_Pistol::GetPistolAmmoName() },
	{ "ammo_9mmAR",			HLWanted_Pistol::GetPistolAmmoName() },
	{ "ammo_357",			HLWanted_Winchester::GetWinchesterAmmoName() },
	{ "ammo_762",			HLWanted_Buffalo::GetBuffaloAmmoName() },
	{ "ammo_crossbow",		HLWanted_Bow::GetBowAmmoName() },
	{ "ammo_rpgclip",		HLWanted_Cannon::GetCannonAmmoName() },

    { "func_healthcharger", GetHLHPChargerName() },
    { "func_recharge", GetHLAPChargerName() },
    { "item_battery", "item_hlbattery" },
    { "item_healthkit", "item_hlmedkit"}
};
const array<string> g_RemoveList = {
    "weapon_m16", "weapon_glock", "weapon_9mmhandgun", "weapon_mp5", "weapon_9mmar", "weapon_rpg", "weapon_crowbar",
    "weapon_healthkit", "weapon_shotgun", "weapon_gauss", "weapon_egon", "weapon_tripmine", "weapon_hornetgun", "weapon_357",
    "weapon_eagle", "weapon_handgrenade", "weapon_uzi", "weapon_uzi_akimbo", "weapon_crossbow"
};
const array<string> g_StartEquipments = {
    "weapon_pistol", "ammo_pistol",  "ammo_pistol",  "ammo_pistol", "weapon_knife"
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
    { "sv_maxspeed",  250.0f},
    { "mp_weapon_respawndelay", RESPAWN_DELAY},
    { "mp_ammo_respawndelay", RESPAWN_DELAY},
    { "mp_item_respawndelay", RESPAWN_DELAY}
};
namespace Config{
void Register() {
    HLWanted_WeaponsRegister();

    RegisterHLHPCharger();
    RegisterHLAPCharger();
    g_CustomEntityFuncs.RegisterCustomEntity( "item_hlbattery", "item_hlbattery");
    g_CustomEntityFuncs.RegisterCustomEntity( "item_hlmedkit", "item_hlmedkit");
    g_CustomEntityFuncs.RegisterCustomEntity( "item_wagonwheel", "item_wagonwheel");
    g_CustomEntityFuncs.RegisterCustomEntity( "hlweaponbox", "hlweaponbox");

    g_Game.PrecacheOther("item_hlbattery");
    g_Game.PrecacheOther("item_hlmedkit");
    g_Game.PrecacheOther("item_wagonwheel");
    g_Game.PrecacheOther("hlweaponbox");
}
void PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int bitGib ) {
    HLWanted_Beartrap::DeactivateBeartraps(@pPlayer);
}
}
