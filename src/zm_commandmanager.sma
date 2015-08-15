#define PLUGIN_VERSION "0.0.1"

#include "include\zm\compiler_settings.inc"

#include <amxmodx>
#include <amxmisc>
#include <cvar_util>

#include "include\zm\inc\templates\command_t.inc"
#include "include\zm\inc\zm_colorchat_stocks.inc"
#include "include\zm\zombiemod.inc"
#include "include\zm\zm_teammanger.inc"

#define TEMP_STRING_LENGTH 31

enum _:FORWARDS_length {
	fwReturn = 0,
	onBeforeCommand,
	onCommand,
	onCommandRegistered,
	onRegisterCommands
};

enum (<<=1) {
	SAY_ALL = 1,
	SAY_TEAM,
	ZOMBIE_ONLY,
	HUMAN_ONLY,
	ALIVE_ONLY,
	DEAD_ONLY
}

static g_fw[FORWARDS_length];

static Array:g_handleList;
static Trie:g_handleMap;
static Array:g_handleNames;
static g_numHandles;
static g_tempCommand[command_t];

static Trie:g_prefixMap;
static g_cvar_prefixes;

static g_szTempString[TEMP_STRING_LENGTH+1];

public zm_onInitStructs() {
	g_handleList = ArrayCreate(command_t, 8);
	g_handleNames = ArrayCreate(1);
	for (new i = 0; i < get_pluginsnum(); i++) {
		ArrayPushCell(g_handleNames, TrieCreate());
	}
	
	g_handleMap = TrieCreate();
	g_prefixMap = TrieCreate();
}

public zm_onInit() {
	zm_registerExtension("[ZM] Command Manager", PLUGIN_VERSION, "Manages commands that players can use");
	
	g_cvar_prefixes = CvarRegister("zm_command_prefixes", "/.!", "A list of all symbols that can preceed commands");
	CvarHookChange(g_cvar_prefixes, "onPrefixesAltered", false);
	
	initializeForwards();
	
	register_clcmd("say", "cmdSay");
	register_clcmd("say_team", "cmdSayTeam");
}

public onPrefixesAltered(handleCvar, const oldValue[], const newValue[], const cvarName[]) {
#if defined ZM_DEBUG_MODE
	assert handleCvar == g_cvar_prefixes;
	zm_log(ZM_LOG_LEVEL_DEBUG, "Updating command prefixes table to: %s", newValue);
#endif
	TrieClear(g_prefixMap);
	
	new i;
	while (newValue[i] != EOS) {
		TrieSetCell(g_prefixMap, newValue[i], i);
		i++;
	}
}

initializeForwards() {
#if defined ZM_DEBUG_MODE
	zm_log(ZM_LOG_LEVEL_DEBUG, "Initializing zm_commandmanager forwards");
#endif

	g_fw[onBeforeCommand] = CreateMultiForward("zm_onBeforeCommand", ET_CONTINUE, FP_CELL, FP_CELL);
	g_fw[onCommand] = CreateMultiForward("zm_onCommand", ET_IGNORE, FP_CELL, FP_CELL);
	g_fw[onCommandRegistered] = CreateMultiForward("zm_onCommandRegistered", ET_IGNORE, FP_CELL, FP_STRING, FP_STRING, FP_STRING, FP_STRING, FP_CELL);
	
	fw_registerCommands();
}

fw_registerCommands() {
#if defined ZM_DEBUG_MODE
	zm_log(ZM_LOG_LEVEL_DEBUG, "zm_onRegisterCommands");
#endif

	g_fw[onRegisterCommands] = CreateMultiForward("zm_onRegisterCommands", ET_IGNORE);
	ExecuteForward(g_fw[onRegisterCommands], g_fw[fwReturn]);
	DestroyForward(g_fw[onRegisterCommands]);
	g_fw[onRegisterCommands] = 0;
}

public cmdSay(id) {
	read_args(g_szTempString, TEMP_STRING_LENGTH);
	return checkCommandAndHandled(id, false, g_szTempString);
}

public cmdSayTeam(id) {
	read_args(g_szTempString, TEMP_STRING_LENGTH);
	return checkCommandAndHandled(id, true, g_szTempString);
}

/**
 * Checks if a command is used with a correct prefix and triggers it.
 *
 * @param id			The player index who entered the command
 * @param teamCommand	True if it was sent via team only chat, false otherwise
 * @param message		The message being sent
 * @return				PLUGIN_CONTINUE in the event that this was not a command or did not use a
 * 							valid prefix, otherwise PLUGIN_CONTINUE/PLUGIN_HANDLED depending on
 * 							whether or not the command should be hidden or not from the chat area
 */
checkCommandAndHandled(id, bool:teamCommand, message[]) {
	strtolower(message);
	remove_quotes(message);
	
	new szTemp[2], i;
	szTemp[0] = message[0];
	if (!TrieGetCell(g_prefixMap, szTemp, i)) {
		return PLUGIN_CONTINUE;
	}
	
	// This was from the legacy code. I don't think this is neccessary.
	static szCommand[32];
	argbreak(message, szCommand, 31, message, 31);
	if (TrieGetCell(g_handleMap, szCommand[1], i)) {
		return tryExecutingCommand(ZM_CMD:i, id, teamCommand, message);
	}
	
	return PLUGIN_CONTINUE;
}

/**
 * Attemps to execute the given command for a specified player if their current state meets the
 * criteria that the command definition requires, and the command is not blocked by another
 * extension.
 *
 * @param command		Command identifier to try and execute
 * @param id			Player index who is executing the command
 * @param teamCommand	True if it is a team command, false otherwise
 * @param message		Additional arguments passed with the command (e.g., /kill <player>, where
 * 						the value of <player> would be this parameter)
 */
tryExecutingCommand(ZM_CMD:command, id, bool:teamCommand, message[]) {
#if defined ZM_DEBUG_MODE
	assert command != Invalid_Command;
#endif
	
	ArrayGetArray(g_handleList, any:command, g_tempCommand);
	
	new flags = g_tempCommand[command_Flags];
	if (!(flags&SAY_ALL) && !(flags&SAY_TEAM)) {
		return PLUGIN_CONTINUE;
	} else if ((flags&SAY_TEAM) && !teamCommand && !(flags&SAY_ALL)) {
		zm_printColor(id, "%L", id, "COMMAND_SAYTEAMONLY");
		return PLUGIN_HANDLED;
	} else if ((flags&SAY_ALL) && teamCommand && !(flags&SAY_TEAM)) {
		zm_printColor(id, "%L", id, "COMMAND_SAYALLONLY");
		return PLUGIN_HANDLED;
	}

	new isZombie = zm_isUserZombie(id);
	if (!(flags&ZOMBIE_ONLY) && !(flags&HUMAN_ONLY)) {
		return PLUGIN_CONTINUE;
	} else if ((flags&HUMAN_ONLY) && isZombie && !(flags&ZOMBIE_ONLY)) {
		zm_printColor(id, "%L", id, "COMMAND_HUMANONLY");
		return PLUGIN_HANDLED;
	} else if ((flags&ZOMBIE_ONLY) && !isZombie && !(flags&HUMAN_ONLY)) {
		zm_printColor(id, "%L", id, "COMMAND_ZOMBIEONLY");
		return PLUGIN_HANDLED;
	}

	new isAlive = zm_isUserAlive(id);
	if (!(flags&ALIVE_ONLY) && !(flags&DEAD_ONLY)) {
		return PLUGIN_CONTINUE;
	} else if ((flags&DEAD_ONLY) && isAlive && !(flags&ALIVE_ONLY)) {
		zm_printColor(id, "%L", id, "COMMAND_DEADONLY");
		return PLUGIN_HANDLED;
	} else if ((flags&ALIVE_ONLY) && !isAlive && !(flags&DEAD_ONLY)) {
		zm_printColor(id, "%L", id, "COMMAND_ALIVEONLY");
		return PLUGIN_HANDLED;
	}
	
	new iAdminFlags = g_tempCommand[command_AdminFlags];
	if (!access(id, iAdminFlags)) {
		zm_printColor(id, "%L", id, "COMMAND_ADMINFLAGS");
		return PLUGIN_HANDLED;
	}

	ExecuteForward(g_fw[onBeforeCommand], g_fw[fwReturn], id, command);
	if (g_fw[fwReturn] == any:ZM_RET_BLOCK) {
		zm_printColor(id, "%L", id, "COMMAND_BLOCKED");
		return PLUGIN_HANDLED;
	}
	
	trim(message);
	new player = cmd_target(id, message, CMDTARGET_ALLOW_SELF);
	callfunc_begin_i(g_tempCommand[command_FuncID], g_tempCommand[command_PluginID]); {
		callfunc_push_int(id);
		callfunc_push_int(player);
		callfunc_push_str(message, false);
	} callfunc_end();
	
	ExecuteForward(g_fw[onCommand], g_fw[fwReturn], id, command);
	
	return PLUGIN_HANDLED;
}