#define PLUGIN_VERSION "0.0.1"

#include "include\\zm\\compiler_settings.inc"

#include <amxmodx>
#include <amxmisc>

#include "include\\zm\\inc\\templates\\command_t.inc"
#include "include\\zm\\inc\\zm_colorchat_stocks.inc"
#include "include\\zm\\zombiemod.inc"
#include "include\\zm\\zm_teammanager.inc"

#define DEFAULT_COMMANDS_NUM 16

#define command_Prefix_length 1

enum _:FORWARDS_length {
    fwReturn = 0,
    onBeforeCommand,
    onCommand,
    onCommandRegistered,
    onPrefixesChanged,
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
static g_pcvar_prefixes;

static g_szTemp[command_Prefix_length+command_Name_length+1];

public plugin_natives() {
    register_library("zm_commandmanager");

    register_native("zm_registerCommand", "_registerCommand", 0);
    register_native("zm_registerCommandAlias", "_registerCommandAlias", 0);
    register_native("zm_getCommandByName", "_getCommandByName", 0);
}

public zm_onInitStructs() {
    g_handleList = ArrayCreate(command_t, DEFAULT_COMMANDS_NUM);
    g_handleNames = ArrayCreate(1);
    for (new i = 0; i < get_pluginsnum(); i++) {
        ArrayPushCell(g_handleNames, TrieCreate());
    }
    
    g_handleMap = TrieCreate();
    g_prefixMap = TrieCreate();
}

public zm_onInit() {
    zm_registerExtension("[ZM] Command Manager",
                         PLUGIN_VERSION,
                         "Manages commands that players can use");
    register_dictionary("zombiemod.txt");
    
    initializeForwards();
    
    g_pcvar_prefixes = create_cvar("zm_command_prefixes",
                                   "/.!",
                                   FCVAR_SERVER|FCVAR_SPONLY,
                                   "A list of all symbols that can preceed commands");
    hook_cvar_change(g_pcvar_prefixes, "onPrefixesAltered");
    
    new szPrefixes[8];
    get_pcvar_string(g_pcvar_prefixes, szPrefixes, 7);
    onPrefixesAltered(g_pcvar_prefixes, "", szPrefixes);
    
    register_clcmd("say", "cmdSay");
    register_clcmd("say_team", "cmdSayTeam");
}

public onPrefixesAltered(pcvar, const oldValue[], const newValue[]) {
#if defined ZM_DEBUG_MODE
    assert pcvar == g_pcvar_prefixes;
    zm_log(ZM_LOG_LEVEL_DEBUG, "Updating command prefixes table to: %s",
                               newValue);
#endif
    TrieClear(g_prefixMap);
    
    new i = 0;
    new szTemp[2];
    while (newValue[i] != EOS) {
        szTemp[0] = newValue[i];
        TrieSetCell(g_prefixMap, szTemp, i);
        i++;
    }
    
#if defined ZM_DEBUG_MODE
    zm_log(ZM_LOG_LEVEL_DEBUG, "zm_onPrefixesChanged");
#endif
    ExecuteForward(g_fw[onPrefixesChanged], g_fw[fwReturn], oldValue, newValue);
}

initializeForwards() {
#if defined ZM_DEBUG_MODE
    zm_log(ZM_LOG_LEVEL_DEBUG, "Initializing zm_commandmanager forwards");
#endif

    g_fw[onBeforeCommand]     = CreateMultiForward("zm_onBeforeCommand",
                                                   ET_CONTINUE,
                                                   FP_CELL,
                                                   FP_CELL);
    g_fw[onCommand]           = CreateMultiForward("zm_onCommand",
                                                   ET_IGNORE,
                                                   FP_CELL,
                                                   FP_CELL);
    g_fw[onCommandRegistered] = CreateMultiForward("zm_onCommandRegistered",
                                                   ET_IGNORE,
                                                   FP_CELL,
                                                   FP_STRING,
                                                   FP_STRING,
                                                   FP_STRING,
                                                   FP_STRING,
                                                   FP_CELL);
    g_fw[onPrefixesChanged]   = CreateMultiForward("zm_onPrefixesChanged",
                                                   ET_IGNORE,
                                                   FP_STRING,
                                                   FP_STRING);
    
    fw_registerCommands();
}

fw_registerCommands() {
#if defined ZM_DEBUG_MODE
    zm_log(ZM_LOG_LEVEL_DEBUG, "zm_onRegisterCommands");
#endif

    g_fw[onRegisterCommands] = CreateMultiForward("zm_onRegisterCommands",
                                                  ET_IGNORE);
    ExecuteForward(g_fw[onRegisterCommands], g_fw[fwReturn]);
    DestroyForward(g_fw[onRegisterCommands]);
    g_fw[onRegisterCommands] = 0;
}

public cmdSay(id) {
    read_args(g_szTemp, command_Prefix_length+command_Name_length);
    return checkCommandAndHandled(id, false, g_szTemp);
}

public cmdSayTeam(id) {
    read_args(g_szTemp, command_Prefix_length+command_Name_length);
    return checkCommandAndHandled(id, true, g_szTemp);
}

/**
 * Checks if a command is used with a correct prefix and triggers it.
 *
 * @param id            The player index who entered the command
 * @param teamCommand   True if it was sent via team only chat, false otherwise
 * @param message       The message being sent
 * @return              PLUGIN_CONTINUE in the event that this was not a
 *                          command or did not use a valid prefix, otherwise
 *                          PLUGIN_CONTINUE/PLUGIN_HANDLED depending on whether
 *                          or not the command should be hidden or not from the
 *                          chat area
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
    static szCommand[command_Name_length+1];
    argbreak(message[1],
             szCommand,
             command_Name_length,
             message,
             command_Prefix_length+command_Name_length);
    if (TrieGetCell(g_handleMap, szCommand, i)) {
        return tryExecutingCommand(ZM_CMD:i, id, teamCommand, message);
    }
    
    return PLUGIN_CONTINUE;
}

/**
 * Attemps to execute the given command for a specified player if their current
 * state meets the criteria that the command definition requires, and the
 * command is not blocked by another extension.
 *
 * @param command       Command identifier to try and execute
 * @param id            Player index who is executing the command
 * @param teamCommand   True if it is a team command, false otherwise
 * @param message       Additional arguments passed with the command (e.g.,
 *                          /kill <player>, where the value of <player> would be
 *                          this parameter)
 */
tryExecutingCommand(ZM_CMD:command, id, bool:teamCommand, message[]) {
#if defined ZM_DEBUG_MODE
    assert command != Invalid_Command;
#endif
    
    ArrayGetArray(g_handleList, any:command-1, g_tempCommand);
    
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

/*******************************************************************************
Natives
*******************************************************************************/

// native ZM_CMD:zm_registerCommand(const command[], const handle[], const flags[] = "abcdef", const description[] = "", const adminFlags = ADMIN_ALL);
public ZM_CMD:_registerCommand(pluginId, numParams) {
    if (numParams != 5) {
        zm_paramError("zm_registerCommand",5,numParams);
        return Invalid_Command;
    }
    
    if (g_handleList == Invalid_Array || g_handleNames == Invalid_Array
            || g_handleMap == Invalid_Trie) {
        log_error(AMX_ERR_NATIVE, "Cannot register commands yet!");
        return Invalid_Command;
    }

    new i;
    get_string(1, g_tempCommand[command_Name], command_Name_length);
    if (g_tempCommand[command_Name][0] == EOS) {
        log_error(AMX_ERR_NATIVE, "Cannot register a command with an empty command/alias!");
        return Invalid_Command;
    }
    
    strtolower(g_tempCommand[command_Name]);
    if (TrieGetCell(g_handleMap, g_tempCommand[command_Name], i)) {
        return Invalid_Command;
    }
    
    new szHandle[32];
    get_string(2, szHandle, 31);
    if (szHandle[0] == EOS) {
        log_error(AMX_ERR_NATIVE, "Cannot register a command with an empty handle!");
        return Invalid_Command;
    }

    new Trie:tempTrie;
    tempTrie = ArrayGetCell(g_handleNames, pluginId);
    if (TrieGetCell(tempTrie, szHandle, i)) {
        TrieSetCell(g_handleMap, g_tempCommand[command_Name], i);
        return ZM_CMD:i;
    } else {
        new szPluginName[32];
        get_plugin(pluginId, szPluginName, 31);
        g_tempCommand[command_FuncID] = get_func_id(szHandle, pluginId);
        if (g_tempCommand[command_FuncID] < 0) {
            log_error(AMX_ERR_NATIVE, "Function handle '%s' does not exist within plugin '%s'",
                                      szHandle,
                                      szPluginName);
            return Invalid_Command;
        }
        
        ArraySetCell(g_handleNames, pluginId, tempTrie);

        g_tempCommand[command_PluginID] = pluginId;
        
        new szFlags[8];
        get_string(3, szFlags, 7);
        if (szFlags[0] == EOS) {
            log_error(AMX_ERR_NATIVE, "Cannot register a command with empty flags!");
            return Invalid_Command;
        }
        
        g_tempCommand[command_Flags] = read_flags(szFlags);
        get_string(4, g_tempCommand[command_Desc], command_Desc_length);
        g_tempCommand[command_AdminFlags] = get_param(5);
        
        new ZM_CMD:cmdId = ZM_CMD:(ArrayPushArray(g_handleList, g_tempCommand)+1);
        TrieSetCell(tempTrie, szHandle, cmdId);
        TrieSetCell(g_handleMap, g_tempCommand[command_Name], cmdId);
        g_numHandles++;
        
#if defined ZM_DEBUG_MODE
        zm_log(ZM_LOG_LEVEL_DEBUG, "Registered command '%s' as %d",
                                   g_tempCommand[command_Name],
                                   cmdId);
#endif
        ExecuteForward(g_fw[onCommandRegistered],
                       g_fw[fwReturn],
                       cmdId,
                       g_tempCommand[command_Name],
                       szPluginName,
                       szFlags,
                       g_tempCommand[command_Desc],
                       g_tempCommand[command_AdminFlags]);
        
        return cmdId;
    }
}

// native ZM_CMD:zm_registerCommandAlias(ZM_CMD:command, const alias[]);
public ZM_CMD:_registerCommandAlias(pluginId, numParams) {
    if (numParams != 2) {
        zm_paramError("zm_registerCommandAlias",2,numParams);
        return Invalid_Command;
    }
    
    new ZM_CMD:command = ZM_CMD:get_param(1);
    if (command == Invalid_Command) {
        log_error(AMX_ERR_NATIVE, "Invalid command handle specified: Invalid_Command");
        return Invalid_Command;
    } else if (g_numHandles < any:command) {
        log_error(AMX_ERR_NATIVE, "Invalid command handle specified: %d", command);
        return Invalid_Command;
    }
    
    new szTemp[command_Name_length+1];
    get_string(2, szTemp, command_Name_length);
    if (szTemp[0] == EOS) {
        return Invalid_Command;
    }
    
    TrieSetCell(g_handleMap, szTemp, command);
    return command;
}

// native zm_getCommandByName(const command[]);
public ZM_CMD:_getCommandByName(pluginId, numParams) {
    if (numParams != 1) {
        zm_paramError("zm_getCommandByName",1,numParams);
        return Invalid_Command;
    }
    
    new i;
    new szTemp[command_Name_length+1];
    get_string(1, szTemp, command_Name_length);
    if (szTemp[0] == EOS) {
        return Invalid_Command;
    }
    
    if (TrieGetCell(g_handleMap, szTemp, i)) {
        return ZM_CMD:i;
    }
    
    return Invalid_Command;
}