#define PLUGIN_VERSION "0.0.1"

#include "include\zm\compiler_settings.inc"

#include <amxmodx>
#include <cs_team_changer>
#include <hamsandwich>

#include "include\zm\inc\zm_teammanger_const.inc"
#include "include\zm\bitflags.inc"
#include "include\zm\zombiemod.inc"

#define AUTO_TEAM_JOIN_DELAY 0.1

enum _:FORWARDS_length {
	fwReturn,
	onPlayerDeath,
	onPlayerSpawn,
	onTeamChangeBlocked,
	onBeforeInfected, onInfected, onAfterInfected,
	onBeforeCured, onCured, onAfterCured,
	onRefresh
};

enum playerFlags_t {
	flag_Connected,
	flag_Alive,
	flag_Zombie,
	flag_FirstTeamSet
};

enum (+= 5039) {
	task_AutoJoin = 514229,
	task_RespawnUser
}

static ZM_TEAM:g_actualTeam[MAX_PLAYERS+1];
static g_playerFlag[playerFlags_t];
static g_fw[FORWARDS_length];

public plugin_natives() {
	register_library("zm_teammanager");
	
	register_native("zm_respawnUser", "_respawnUser", 0);
	register_native("zm_infectUser", "_infectUser", 0);
	register_native("zm_cureUser", "_cureUser", 0);
	register_native("zm_isUserConnected", "_isUserConnected", 0);
	register_native("zm_isUserAlive", "_isUserAlive", 0);
	register_native("zm_isUserZombie", "_isUserZombie", 0);
	register_native("zm_isUserHuman", "_isUserHuman", 0);
	register_native("zm_fixInfection", "_fixInfection", 0);
}

public zm_onInit() {
	zm_registerExtension("[ZM] Team Manager", PLUGIN_VERSION, "Controls who is a zombie and who isn't");
	
#if defined ZM_DEBUG_MODE
	register_concmd("zm.zombies", "printZombies");
#endif
	
	initializeForwards();
	
	blockTeamChangeCommands();
	registerAutoJoinOnConnectMessages();
		
	RegisterHam(Ham_Spawn, "player", "ham_PlayerSpawn_Post", 1);
	RegisterHam(Ham_Killed, "player", "ham_PlayerKilled", 0);
}

public ham_PlayerSpawn_Post(id) {
	if (!is_user_alive(id)) {
		unsetFlag(g_playerFlag[flag_Alive],id);
		return HAM_IGNORED;
	}
	
	setFlag(g_playerFlag[flag_Alive],id);
	new bool:isZombie = isUserZombie(id);
	ExecuteForward(g_fw[onRefresh], g_fw[fwReturn], id, isZombie);
	ExecuteForward(g_fw[onPlayerSpawn], g_fw[fwReturn], id, isZombie);
	return HAM_HANDLED;
}

public ham_PlayerKilled(killer, victim, shouldgib) {
	if (is_user_alive(victim)) {
		return HAM_IGNORED;
	}
	
	hideMenus(victim);
	unsetFlag(g_playerFlag[flag_Alive],victim);
	ExecuteForward(g_fw[onPlayerDeath], g_fw[fwReturn], killer, victim);
	return HAM_HANDLED;
}

initializeForwards() {
#if defined ZM_DEBUG_MODE
	zm_log(ZM_LOG_LEVEL_DEBUG, "Initializing zm_teammanager forwards");
#endif

	g_fw[onRefresh]	= CreateMultiForward("zm_onRefresh", ET_IGNORE, FP_CELL, FP_CELL);
	g_fw[onPlayerSpawn] = CreateMultiForward("zm_onPlayerSpawn", ET_IGNORE, FP_CELL, FP_CELL);
	g_fw[onPlayerDeath] = CreateMultiForward("zm_onPlayerDeath", ET_IGNORE, FP_CELL, FP_CELL);
	g_fw[onTeamChangeBlocked] = CreateMultiForward("zm_onTeamChangeBlocked", ET_IGNORE, FP_CELL);
	initializeInfectForwards();
	initializeCureForwards();
}

initializeInfectForwards() {
	g_fw[onBeforeInfected] = CreateMultiForward("zm_onBeforeInfected", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
	g_fw[onInfected] = CreateMultiForward("zm_onInfected", ET_IGNORE, FP_CELL, FP_CELL);
	g_fw[onAfterInfected] = CreateMultiForward("zm_onAfterInfected", ET_IGNORE, FP_CELL, FP_CELL);
}

initializeCureForwards() {
	g_fw[onBeforeCured] = CreateMultiForward("zm_onBeforeCured", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
	g_fw[onCured] = CreateMultiForward("zm_onCured", ET_IGNORE, FP_CELL, FP_CELL);
	g_fw[onAfterCured] = CreateMultiForward("zm_onAfterCured", ET_IGNORE, FP_CELL, FP_CELL);
}

blockTeamChangeCommands() {
	register_clcmd("chooseteam", "blockTeamChange");
	register_clcmd("jointeam", "blockTeamChange");
}

public blockTeamChange(id) {
	new ZM_TEAM:curTeam = ZM_TEAM:get_user_team(id);
	if (curTeam == ZM_TEAM_SPECTATOR || curTeam == ZM_TEAM_UNASSIGNED) {
		return PLUGIN_CONTINUE;
	}
	
	ExecuteForward(g_fw[onTeamChangeBlocked], g_fw[fwReturn], id);
	return PLUGIN_HANDLED;
}

registerAutoJoinOnConnectMessages() {
	register_message(get_user_msgid("ShowMenu"), "msgShowMenu");
	register_message(get_user_msgid("VGUIMenu"), "msgShowVGUIMenu");
	register_message(get_user_msgid("TeamInfo"), "msgTeamInfo");
}

public client_putinserver(id) {
	setFlag(g_playerFlag[flag_Connected],id);
}

public client_disconnect(id) {
	remove_task(id+task_AutoJoin);
	remove_task(id+task_RespawnUser);
	
	unsetFlag(g_playerFlag[flag_Connected],id);
	unsetFlag(g_playerFlag[flag_Alive],id);
	unsetFlag(g_playerFlag[flag_Zombie],id);
	unsetFlag(g_playerFlag[flag_FirstTeamSet],id);
	g_actualTeam[id] = ZM_TEAM_UNASSIGNED;
}

respawnUser(id, bool:force) {
	if (isFlagSet(g_playerFlag[flag_Alive],id) && !force) {
		return;
	}
	
	ExecuteHamB(Ham_CS_RoundRespawn, id);
}

bool:isUserConnected(id) {
#if defined ZM_DEBUG_MODE
	assert zm_isValidPlayerId(id);
#endif

	return isFlagSet(g_playerFlag[flag_Connected],id);
}

bool:isUserAlive(id) {
#if defined ZM_DEBUG_MODE
	assert zm_isValidPlayerId(id);
#endif

	return isFlagSet(g_playerFlag[flag_Alive],id);
}

bool:isUserZombie(id) {
#if defined ZM_DEBUG_MODE
	assert zm_isValidPlayerId(id);
#endif

	return isFlagSet(g_playerFlag[flag_Zombie],id);
}

bool:isUserHuman(id) {
	return !isUserZombie(id);
}

ZM_CHANGE_STATE:infectUser(id, infector = -1, bool:blockable = true) {
	ExecuteForward(g_fw[onBeforeInfected], g_fw[fwReturn], id, infector, blockable);
	if (blockable && g_fw[fwReturn] == any:ZM_RET_BLOCK) {
		return;
	}
	
	hideMenus(id);
	ExecuteForward(g_fw[onInfected], g_fw[fwReturn], id, infector);
	
	setFlag(g_playerFlag[flag_Zombie],id);
	cs_set_team(id, CSTeam:ZM_TEAM_ZOMBIE);
	//cs_set_player_weap_restrict(id, true, ZOMBIE_ALLOWED_WEAPONS, ZOMBIE_DEFAULT_WEAPON);
	ExecuteForward(g_fw[onRefresh], g_fw[fwReturn], id, true);
	
	ExecuteForward(g_fw[onAfterInfected], g_fw[fwReturn], id, infector);
	
#if defined ZM_DEBUG_MODE
	new szIdName[32];
	get_user_name(id, szIdName, 31);
	if (zm_isValidPlayerId(infector)) {
		new szInfectorName[32];
		get_user_name(infector, szInfectorName, 31);
		zm_log(ZM_LOG_LEVEL_DEBUG, "%s infected %s", szInfectorName, szIdName);
	} else {
		zm_log(ZM_LOG_LEVEL_DEBUG, "%s has been infected", szIdName);
	}
#endif
}

ZM_CHANGE_STATE:cureUser(id, curer = -1, bool:blockable = true) {
	ExecuteForward(g_fw[onBeforeCured], g_fw[fwReturn], id, curer, blockable);
	if (blockable && g_fw[fwReturn] == any:ZM_RET_BLOCK) {
		return;
	}
	
	hideMenus(id);
	ExecuteForward(g_fw[onCured], g_fw[fwReturn], id, curer);
	
	unsetFlag(g_playerFlag[flag_Zombie],id);
	cs_set_team(id, CSTeam:ZM_TEAM_HUMAN);
	//cs_set_player_weap_restrict(id, false, ZOMBIE_ALLOWED_WEAPONS, ZOMBIE_DEFAULT_WEAPON);
	ExecuteForward(g_fw[onRefresh], g_fw[fwReturn], id, false);
	
	ExecuteForward(g_fw[onAfterCured], g_fw[fwReturn], id, curer);
	
#if defined ZM_DEBUG_MODE
	new szIdName[32];
	get_user_name(id, szIdName, 31);
	if (zm_isValidPlayerId(curer)) {
		new szCurerName[32];
		get_user_name(curer, szCurerName, 31);
		zm_log(ZM_LOG_LEVEL_DEBUG, "%s cured %s", szCurerName, szIdName);
	} else {
		zm_log(ZM_LOG_LEVEL_DEBUG, "%s has been cured", szIdName);
	}
#endif
}

hideMenus(id) {
	show_menu(id, 0, "^n", 1);
}

public msgShowMenu(const msgID, const msgDest, const id) {
	if (get_user_team(id)) {
		return PLUGIN_CONTINUE;
	}

	new szMenuTextCode[13];
	get_msg_arg_string(4, szMenuTextCode, 12);
	if (!equal(szMenuTextCode, "#Team_Select")) {
		return PLUGIN_CONTINUE;
	}

	new szParamMenuMsgID[2];
	szParamMenuMsgID[0] = msgID;
	set_task(AUTO_TEAM_JOIN_DELAY, "forceTeamJoin", id+task_AutoJoin, szParamMenuMsgID, 1);
	return PLUGIN_HANDLED;
}

public msgShowVGUIMenu(const msgID, const msgDest, const id) {
	if (get_msg_arg_int(1) != 2 || get_user_team(id)) { 
		return PLUGIN_CONTINUE;
	}
		
	new szParamMenuMsgID[2];
	szParamMenuMsgID[0] = msgID;
	set_task(AUTO_TEAM_JOIN_DELAY, "forceTeamJoin", id+task_AutoJoin, szParamMenuMsgID, 1);
	return PLUGIN_HANDLED;
}

public forceTeamJoin(params[], id) {
	id -= task_AutoJoin;
	if (get_user_team(id)) {
		return;
	}

	new msgBlock = get_msg_block(params[0]);
	set_msg_block(params[0], BLOCK_SET);
	engclient_cmd(id, "jointeam", "5");
	engclient_cmd(id, "joinclass", "5");
	set_msg_block(params[0], msgBlock);
	set_task(1.0, "respawnUserTask", id+task_RespawnUser);
}

public respawnUserTask(taskid) {
	taskid -= task_RespawnUser;
	respawnUser(taskid, false);
	if (!isUserAlive(taskid)) {
		set_task(1.0, "respawnUserTask", taskid+task_RespawnUser);
	}
}

public msgTeamInfo(const msgID, const msgDest) {
	if (msgDest != MSG_ALL && msgDest != MSG_BROADCAST) {
		return;
	}
	
	new team[2];
	get_msg_arg_string(2, team, 1);
	new id = get_msg_arg_int(1);
#if defined ZM_DEBUG_MODE
	new szIdName[32];
	get_user_name(id, szIdName, 31);
#endif
	if (!getFlag(g_playerFlag[flag_FirstTeamSet],id) && (team[0] == 'T' || team[0] == 'C')) {
		setFlag(g_playerFlag[flag_FirstTeamSet],id);
		g_actualTeam[id] = (team[0] == 'T' ? ZM_TEAM_ZOMBIE : ZM_TEAM_HUMAN);
		if (g_actualTeam[id] == ZM_TEAM_ZOMBIE) {
#if defined ZM_DEBUG_MODE
			zm_log(ZM_LOG_LEVEL_DEBUG, "%s has joined the zombie team", szIdName);
#endif
			infectUser(id, -1, false);
		} else {
#if defined ZM_DEBUG_MODE
			zm_log(ZM_LOG_LEVEL_DEBUG, "%s has joined the human team", szIdName);
#endif
			cureUser(id, -1, false);
		}
	} else if (team[0] == 'S') {
#if defined ZM_DEBUG_MODE
		zm_log(ZM_LOG_LEVEL_DEBUG, "%s has joined the spectators", szIdName);
#endif
		user_kill(id);
		g_actualTeam[id] = ZM_TEAM_SPECTATOR;
		unsetFlag(g_playerFlag[flag_FirstTeamSet],id);
	}
}

/***************************************************************************************************
Console Commands
***************************************************************************************************/

#if defined ZM_DEBUG_MODE
public printZombies(id) {
	console_print(id, "Outputting players list...");
	new size = get_playersnum();
	if (size) {
		new szTemp[32];
		for (new i = 1; i <= size; i++) {
			get_user_name(i, szTemp, 31);
			console_print(id, "%d. %c | %s", i, isUserZombie(i) ? 'Z' : 'H', szTemp);
		}
		
		return;
	}
	
	console_print(id, "No players found");
}
#endif

/***************************************************************************************************
Natives
***************************************************************************************************/

// native zm_respawnUser(id, bool:force = false);
public _respawnUser(pluginId, numParams) {
	if (numParams != 2) {
		zm_paramError("zm_respawnUser",2,numParams);
		return;
	}
	
	new id = get_param(1);
	if (!zm_isValidPlayerId(id)) {
		log_error(AMX_ERR_NATIVE, "Player index out of bounds: %d", id);
		return;
	}
	
	respawnUser(get_param(1), bool:get_param(2));
}

// native ZM_CHANGE_STATE:zm_infectUser(id, infector = -1, bool:blockable = true);
public ZM_CHANGE_STATE:_infectUser(pluginId, numParams) {
	if (numParams != 3) {
		zm_paramError("zm_infectUser",3,numParams);
		return ZM_CHANGE_STATE:ZM_RET_ERROR;
	}
	
	new id = get_param(1);
	if (!zm_isValidPlayerId(id)) {
		log_error(AMX_ERR_NATIVE, "Player index out of bounds: %d", id);
		return ZM_CHANGE_STATE:ZM_RET_ERROR;
	}
	
	if (!isUserConnected(id)) {
		return ZM_CHANGE_INVALID;
	}
	
	if (isUserZombie(id)) {
		ExecuteForward(g_fw[onRefresh], g_fw[fwReturn], id, true);
		return ZM_CANNOT_CHANGE;
	}
	
	infectUser(id, get_param(2), bool:get_param(3));
	return ZM_CHANGED;
}

// native ZM_CHANGE_STATE:zm_cureUser(id, curer = -1, bool:blockable = true);
public ZM_CHANGE_STATE:_cureUser(pluginId, numParams) {
	if (numParams != 3) {
		zm_paramError("zm_cureUser",3,numParams);
		return ZM_CHANGE_STATE:ZM_RET_ERROR;
	}
	
	new id = get_param(1);
	if (!zm_isValidPlayerId(id)) {
		log_error(AMX_ERR_NATIVE, "Player index out of bounds: %d", id);
		return ZM_CHANGE_STATE:ZM_RET_ERROR;
	}
	
	if (!isUserConnected(id)) {
		return ZM_CHANGE_INVALID;
	}
	
	if (isUserHuman(id)) {
		ExecuteForward(g_fw[onRefresh], g_fw[fwReturn], id, false);
		return ZM_CANNOT_CHANGE;
	}
	
	cureUser(id, get_param(2), bool:get_param(3));
	return ZM_CHANGED;
}

// native bool:zm_isUserConnected(id);
public bool:_isUserConnected(pluginId, numParams) {
	if (numParams != 1) {
		zm_paramError("zm_isUserConnected",1,numParams);
		return false;
	}
	
	new id = get_param(1);
	if (!zm_isValidPlayerId(id)) {
		log_error(AMX_ERR_NATIVE, "Player index out of bounds: %d", id);
		return false;
	}
	
	return isUserConnected(id);
}

// native bool:zm_isUserAlive(id);
public bool:_isUserAlive(pluginId, numParams) {
	if (numParams != 1) {
		zm_paramError("zm_isUserAlive",1,numParams);
		return false;
	}
	
	new id = get_param(1);
	if (!zm_isValidPlayerId(id)) {
		log_error(AMX_ERR_NATIVE, "Player index out of bounds: %d", id);
		return false;
	}
	
	return isUserAlive(id);
}

// native bool:zm_isUserZombie(id);
public bool:_isUserZombie(pluginId, numParams) {
	if (numParams != 1) {
		zm_paramError("zm_isUserZombie",1,numParams);
		return false;
	}
	
	new id = get_param(1);
	if (!zm_isValidPlayerId(id)) {
		log_error(AMX_ERR_NATIVE, "Player index out of bounds: %d", id);
		return false;
	}
	
	return isUserZombie(id);
}

// native bool:zm_isUserHuman(id);
public bool:_isUserHuman(pluginId, numParams) {
	if (numParams != 1) {
		zm_paramError("zm_isUserHuman",1,numParams);
		return false;
	}
	
	new id = get_param(1);
	if (!zm_isValidPlayerId(id)) {
		log_error(AMX_ERR_NATIVE, "Player index out of bounds: %d", id);
		return false;
	}
	
	return isUserHuman(id);
}

// native zm_fixInfection(id);
public bool:_fixInfection(pluginId, numParams) {
	if (numParams != 1) {
		zm_paramError("zm_fixInfection",1,numParams);
		return;
	}
	
	new id = get_param(1);
	new ZM_TEAM:actualTeam = g_actualTeam[id];
	if (actualTeam == ZM_TEAM_UNASSIGNED || actualTeam == ZM_TEAM_SPECTATOR) {
		return;
	}
	
#if defined ZM_DEBUG_MODE
	new szIdName[32];
	get_user_name(id, szIdName, 31);
#endif
	if (isUserZombie(id) && actualTeam == ZM_TEAM_HUMAN) {
#if defined ZM_DEBUG_MODE
		zm_log(ZM_LOG_LEVEL_DEBUG, "Fixing infection for %s", szIdName);
#endif
		cureUser(id, -1, false);
	} else if (isUserHuman(id) && actualTeam == ZM_TEAM_ZOMBIE) {
#if defined ZM_DEBUG_MODE
		zm_log(ZM_LOG_LEVEL_DEBUG, "Fixing infection for %s", szIdName);
#endif
		infectUser(id, -1, false);
	}
}