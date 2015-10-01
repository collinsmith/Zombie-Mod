#define VERSION_STRING "1.0.0"
#define EXTENSION_NAME "Command Manager"
#define ZM_PLAYERS_PRINT_EMPTY

#include <amxmodx>
#include <logger>

#include "include\\zm\\zm_team_mngr.inc"
#include "include\\zm\\zombiemod.inc"
#include "include\\zm\\template\\command_t.inc"

static Logger: g_Logger = Invalid_Logger;

enum Forwards {
    fwReturn = 0,
    onBeforeCommand,
    onCommand,
    onCommandRegistered,
    onPrefixesChanged,
    onRegisterCommands
}; static g_fw[Forwards] = { 0, INVALID_HANDLE, INVALID_HANDLE, INVALID_HANDLE,
        INVALID_HANDLE, INVALID_HANDLE };

enum (<<=1) {
    SAY_ALL = 1,
    SAY_TEAM,
    ZOMBIE_ONLY,
    HUMAN_ONLY,
    ALIVE_ONLY,
    DEAD_ONLY
}

static Array:g_commandsList;
static Array:g_pluginHandlesList;
static Trie:g_aliasToCommandMap;
static g_numCommands;

static g_tempCommand[command_t];

static Trie:g_prefixesMap;

static g_pCvar_Prefixes;

public plugin_natives() {
    register_library("zm_commandmanager");

    //register_native("zm_registerCommand", "_registerCommand", 0);
    //register_native("zm_registerCommandAlias", "_registerCommandAlias", 0);
    //register_native("zm_getCommandByName", "_getCommandByName", 0);
}

public zm_onExtensionInit() {
    new name[32];
    formatex(name, charsmax(name),
            "[%L] %s",
            LANG_SERVER, ZM_NAME_SHORT,
            EXTENSION_NAME);
    register_plugin(name, VERSION_STRING, "Tirant");
    zm_registerExtension(
            .name = EXTENSION_NAME,
            .version = VERSION_STRING,
            .description = "Manages custom commands");

    g_Logger = LoggerCreate();
#if defined ZM_COMPILE_FOR_DEBUG
    LoggerSetVerbosity(g_Logger, Severity_Lowest);
    LoggerSetVerbosity(All_Loggers, Severity_Lowest);
#endif

    registerConCmds();
    createForwards();
    
    g_pCvar_Prefixes = create_cvar(
            "zm_command_prefixes",
            "/.!",
            FCVAR_SERVER|FCVAR_SPONLY,
            "List of all symbols that can preceed commands");
    hook_cvar_change(g_pCvar_Prefixes, "cvar_onPrefixesAltered");

    new prefixes[8];
    get_pcvar_string(g_pCvar_Prefixes, prefixes, charsmax(prefixes));
    cvar_onPrefixesAltered(g_pCvar_Prefixes, NULL_STRING, prefixes);
}

registerConCmds() {
    zm_registerConCmd(
            .command = "cmds",
            .function = "printCommands",
            .description = "Prints the list of commands with their details",
            .logger = g_Logger);

    zm_registerConCmd(
            .command = "commands",
            .function = "printCommands",
            .description = "Prints the list of commands with their details",
            .logger = g_Logger);

    zm_registerConCmd(
            .command = "aliases",
            .function = "printAliases",
            .description = "Prints the list of commands with their details",
            .logger = g_Logger);
}

createForwards() {
    createOnBeforeCommand();
    createOnCommand();
}

createOnBeforeCommand() {
    LoggerLogDebug(g_Logger, "Creating forward zm_onBeforeCommand");
    g_fw[onBeforeCommand] = CreateMultiForward("zm_onBeforeCommand",
            ET_CONTINUE,
            FP_CELL, 
            FP_CELL);
    LoggerLogDebug(g_Logger,
            "g_fw[onBeforeCommand] = %d",
            g_fw[onBeforeCommand]);
}

createOnCommand() {
    LoggerLogDebug(g_Logger, "Creating forward zm_onCommand");
    g_fw[onCommand] = CreateMultiForward("zm_onCommand",
            ET_IGNORE,
            FP_CELL, 
            FP_CELL);
    LoggerLogDebug(g_Logger,
            "g_fw[onCommand] = %d",
            g_fw[onCommand]);
}

public cvar_onPrefixesAltered(pCvar, const oldValue[], const newValue[]) {
    assert pCvar == g_pCvar_Prefixes;
    LoggerLogDebug(g_Logger,
            "Updating command prefixes table to: \"%s\"",
            newValue);

    if (g_prefixesMap == Invalid_Trie) {
        g_prefixesMap = TrieCreate();
        LoggerLogDebug(g_Logger,
                "Initialized g_prefixesMap as Trie: %d",
                g_prefixesMap);
    } else {
        TrieClear(g_prefixesMap);
        LoggerLogDebug(g_Logger, "Cleared g_prefixesMap");
    }
    
    
    new i = 0;
    new temp[2];
    while (newValue[i] != EOS) {
        temp[0] = newValue[i];
        TrieSetCell(g_prefixesMap, temp, i);
        i++;
    }
    
    if (g_fw[onPrefixesChanged] == INVALID_HANDLE) {
        LoggerLogDebug(g_Logger, "Creating forward zm_onPrefixesChanged");
        g_fw[onPrefixesChanged] = CreateMultiForward(
                "zm_onPrefixesChanged",
                ET_IGNORE,
                FP_STRING,
                FP_STRING);
        LoggerLogDebug(g_Logger,
                "g_fw[onPrefixesChanged] = %d",
                g_fw[onPrefixesChanged]);
    }
    
    ExecuteForward(g_fw[onPrefixesChanged], g_fw[fwReturn], oldValue, newValue);
}

/*******************************************************************************
 * Console Commands
 ******************************************************************************/

public printCommands(id) {
    console_print(id, "Commands:");

    console_print(id, "%d commands found.", g_numCommands);
}

public printAliases(id) {
    console_print(id, "Aliases:");

    console_print(id, "%d aliases found.", 0);
}