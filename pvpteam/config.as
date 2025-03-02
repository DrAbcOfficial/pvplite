const array<CTeamInfo@> g_TeamInfos = {
    CTeamInfo("CT", CLASS_TEAM1, Vector(0, 0, 255), "", {}),
    CTeamInfo("T", CLASS_TEAM2, Vector(255, 0, 0), "", {})
};
const dictionary g_ItemMappings ={
};
const array<string> g_RemoveList = {
    "weapon_m16", "weapon_glock", "weapon_9mmhandgun", "weapon_mp5", "weapon_9mmar", "weapon_rpg", "weapon_crowbar",
    "weapon_healthkit", "weapon_shotgun", "weapon_gauss", "weapon_egon", "weapon_tripmine", "weapon_hornetgun", "weapon_357",
    "weapon_eagle", "weapon_handgrenade", "weapon_uzi", "weapon_uzi_akimbo", "weapon_crossbow"
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
void SpawnPointReCreate() {

}
void Register() {

}

void PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int bitGib ) {

}
}
