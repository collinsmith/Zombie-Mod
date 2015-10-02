#define VERSION_STRING "1.0.0"
#define EXTENSION_NAME "Command Manager"
#define ZM_PLAYERS_PRINT_EMPTY
#define INITIAL_COMMANDS_SIZE 8
#define INITIAL_ALIASES_SIZE 16

#include <amxmodx>
#include <logger>

#include "include\\zm\\zm_team_mngr.inc"
#include "include\\zm\\zombiemod.inc"
#include "include\\zm\\template\\alias_t.inc"
#include "include\\zm\\template\\command_t.inc"

#include "include\\stocks\\string_stocks.inc"
#include "include\\stocks\\dynamic_param_stocks.inc"

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

static Array: g_commandsList;
static g_numCommands;
static g_tempCommand[command_t];

static Array: g_aliasesList;
static Trie: g_aliasesMap;
static g_numAliases;
static g_tempAlias[alias_t];

static Trie:g_prefixesMap;

static g_pCvar_Prefixes;

public plugin_natives() {
    register_library("zm_command_mngr");

    register_native("zm_registerCommand", "zm_registerCommand", 0);
    //register_native("zm_registerCommandAlias", "_registerCommandAlias", 0);
    //register_native("zm_getCommandByName", "_getCommandByName", 0);
}

public zm_onInit() {
    g_Logger = LoggerCreate();
#if defined ZM_COMPILE_FOR_DEBUG
    LoggerSetVerbosity(g_Logger, Severity_Lowest);
    LoggerSetVerbosity(All_Loggers, Severity_Lowest);
#endif
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

bool: isValidCommand(ZM_Command: command) {
    return command > Invalid_Command;
}

commandToIndex(ZM_Command: command) {
    assert isValidCommand(command);
    return any:(command)-1;
}

bool: isValidAlias(ZM_Alias: alias) {
    return alias > Invalid_Alias;
}

aliasToIndex(ZM_Alias: alias) {
    assert isValidAlias(alias);
    return any:(alias)-1;
}

bool: isAliasBound(ZM_Alias: alias) {
    assert isValidAlias(alias);
    ArrayGetArray(g_aliasesList, aliasToIndex(alias), g_tempAlias);
    return isValidCommand(g_tempAlias[alias_Command]);
}

bindAlias(ZM_Alias: alias, ZM_Command: command) {
    assert isValidAlias(alias);
    assert isValidCommand(command);
    LoggerLogDebug(g_Logger,
            "Binding alias %d to command %d", alias, command);
    new const aliasIndex = aliasToIndex(alias);
    //g_tempAlias will be loaded by unbindAlias
    //ArrayGetArray(g_aliasesList, aliasIndex, g_tempAlias);
    unbindAlias(alias);

    g_tempAlias[alias_Command] = command;
    ArrayGetArray(g_commandsList, commandToIndex(command), g_tempCommand);
    new const Array: aliasesList = g_tempCommand[command_Aliases];
    if (zm_isDebugMode()) {
        new list[32], len = 0;
        new const size = ArraySize(aliasesList);
        for (new i = 0; i < size; i++) {
            len += format(list[len], charsmax(list)-len, "%d ", ArrayGetCell(aliasesList, i));
        }

        LoggerLogDebug(g_Logger,
                "Array: %d contents = { %s} (size=%d)",
                aliasesList,
                list,
                size);
    }

    LoggerLogDebug(g_Logger,
            "Pushing alias %d to Array: %d (size=%d)",
            alias,
            aliasesList,
            ArraySize(aliasesList));
    ArrayPushCell(aliasesList, alias);
    // Don't have to set g_commandsList again, as we modified an Array: element
    
    if (zm_isDebugMode()) {
        new list[32], len = 0;
        new const size = ArraySize(aliasesList);
        for (new i = 0; i < size; i++) {
            len += format(list[len], charsmax(list)-len, "%d ", ArrayGetCell(aliasesList, i));
        }

        LoggerLogDebug(g_Logger,
                "Array: %d contents = { %s} (size=%d)",
                aliasesList,
                list,
                size);
    }
    
    ArraySetArray(g_aliasesList, aliasIndex, g_tempAlias);
}

unbindAlias(ZM_Alias: alias) {
    assert isValidAlias(alias);
    if (!isAliasBound(alias)) {
        return;
    }

    //g_tempAlias was already loaded by above call
    //new const aliasIndex = aliasToIndex(alias);
    //ArrayGetArray(g_aliasesList, aliasIndex, g_tempAlias);
    new const ZM_Command: command = g_tempAlias[alias_Command];

    ArrayGetArray(g_commandsList, commandToIndex(command), g_tempCommand);
    new const Array: aliasesList = g_tempCommand[command_Aliases];
    assert aliasesList != Invalid_Array;

    new bool: foundAlias = false;
    new const size = ArraySize(aliasesList);
    LoggerLogDebug(g_Logger,
            "Removing alias %d from Array: %d (size=%d)", alias, aliasesList, size);
    if (zm_isDebugMode()) {
        new list[32], len = 0;
        new const assertSize = ArraySize(aliasesList);
        for (new i = 0; i < assertSize; i++) {
            len += format(list[len], charsmax(list)-len, "%d ", ArrayGetCell(aliasesList, i));
        }

        LoggerLogDebug(g_Logger,
                "Array: %d contents = { %s} (size=%d)",
                aliasesList,
                list,
                assertSize);
    }

    for (new i = 0; i < size; i++) {
        // @TODO: Binary search could be implemented here
        if (ArrayGetCell(aliasesList, i) == alias) {
            ArrayDeleteItem(aliasesList, i);
            foundAlias = true;
            break;
        }
    }

    if (zm_isDebugMode()) {
        new list[32], len = 0;
        new const assertSize = ArraySize(aliasesList);
        for (new i = 0; i < assertSize; i++) {
            len += format(list[len], charsmax(list)-len, "%d ", ArrayGetCell(aliasesList, i));
        }

        LoggerLogDebug(g_Logger,
                "Array: %d contents = { %s} (size=%d)",
                aliasesList,
                list,
                assertSize);
    }

    // Don't have to set g_commandsList again, as we modified an Array: element
    g_tempAlias[alias_Command] = Invalid_Command;
    ArraySetArray(g_aliasesList, aliasToIndex(alias), g_tempAlias);
    assert foundAlias;
    LoggerLogDebug(g_Logger, "Unbound alias %d", alias);
}

ZM_Alias: registerAlias(
        const ZM_Command: command,
        alias[]) {
    assert isValidCommand(command);
    if (isStringEmpty(alias)) {
        LoggerLogError(g_Logger,
                "Cannot register a command with an empty alias!");
        return Invalid_Alias;
    }

    strtolower(alias);
    new ZM_Alias: aliasId;
    if (g_aliasesMap != Invalid_Trie && TrieGetCell(g_aliasesMap, alias, aliasId)) {
        bindAlias(aliasId, command);
        return aliasId;
    }

    if (g_aliasesList == Invalid_Array) {
        g_aliasesList = ArrayCreate(alias_t, INITIAL_ALIASES_SIZE);
        g_numAliases = 0;
        LoggerLogDebug(g_Logger,
                "Initialized g_aliasesList as Array: %d",
                g_aliasesList);
    }

    if (g_aliasesMap == Invalid_Trie) {
        g_aliasesMap = TrieCreate();
        LoggerLogDebug(g_Logger,
                "Initialized g_aliasesMap as Trie: %d",
                g_aliasesMap);
    }

    copy(g_tempAlias[alias_Alias], alias_Alias_length, alias);
    aliasId = ZM_Alias:(ArrayPushArray(g_aliasesList, g_tempAlias)+1);
    TrieSetCell(g_aliasesMap, alias, aliasId);
    g_numAliases++;
    assert g_numAliases == ArraySize(g_aliasesList);
    assert g_numAliases == TrieGetSize(g_aliasesMap);
    bindAlias(aliasId, command);
    LoggerLogDebug(g_Logger,
            "Registered alias \"%s\" for command %d", alias, command);
    return aliasId;
}

/*******************************************************************************
 * Console Commands
 ******************************************************************************/

public printCommands(id) {
    console_print(id, "Commands:");
    console_print(id,
            "%3s %32s %6s %11s %6s %8s %s",
            "ID",
            "DESCRIPTION",
            "FLAGS",
            "ADMIN_LEVEL",
            "PLUGIN",
            "FUNCTION",
            "ALIASES");

    new Array: aliasesList;
    new flags[7];
    for (new i = 0; i < g_numCommands; i++) {
        ArrayGetArray(g_commandsList, i, g_tempCommand);
        get_flags(g_tempCommand[command_Flags], flags, charsmax(flags));

        aliasesList = g_tempCommand[command_Aliases];
        new list[256], len = 0;
        new const assertSize = ArraySize(aliasesList);
        for (new j = 0; j < assertSize; j++) {
            new alias[32];
            ArrayGetArray(g_aliasesList, ArrayGetCell(aliasesList, j)-1, g_tempAlias);
            len += format(list[len], charsmax(list)-len, "%s, ", g_tempAlias[alias_Alias]);
        }

        list[max(0, len-2)] = EOS;

        console_print(id,
            "%2d. %-32.32s %6s %-11d %-6d %-8d %s",
            i+1,
            g_tempCommand[command_Desc],
            flags,
            g_tempCommand[command_AdminFlags],
            g_tempCommand[command_PluginID],
            g_tempCommand[command_FuncID],
            list);
    }

    console_print(id, "%d commands found.", g_numCommands);
}

public printAliases(id) {
    console_print(id, "Aliases:");

    console_print(id, "%d aliases found.", 0);
}

/*******************************************************************************
 * Natives
 ******************************************************************************/

// native ZM_Command: zm_registerCommand(
//         const alias[],
//         const handle[],
//         const flags[] = "abcdef",
//         const description[] = NULL_STRING,
//         const adminFlags = ADMIN_ALL);
public ZM_Command: zm_registerCommand(pluginId, numParams) {
    if (!numParamsEqual(g_Logger, 5, numParams)) {
        return Invalid_Command;
    }

    if (g_commandsList == Invalid_Array) {
        g_commandsList = ArrayCreate(command_t, INITIAL_COMMANDS_SIZE);
        g_numCommands = 0;
        LoggerLogDebug(g_Logger,
                "Initialized g_commandsList as Array: %d",
                g_commandsList);
    }
    
    new handle[32];
    get_string(2, handle, charsmax(handle));
    if (isStringEmpty(handle)) {
        LoggerLogError(g_Logger,
                "Cannot register a command with an empty handle!");
        return Invalid_Command;
    }

    new funcId = get_func_id(handle, pluginId);
    if (funcId < 0) {
        new plugin[32];
        get_plugin(pluginId, plugin, charsmax(plugin));
        LoggerLogError(g_Logger,
                "Function \"%s\" does not exist within plugin \"%s\"!",
                handle,
                plugin);
        return Invalid_Command;
    }

    new flags[27];
    get_string(3, flags, charsmax(flags));
    
    new command[command_t];
    command[command_Flags] = read_flags(flags);
    get_string(4, command[command_Desc], command_Desc_length);
    command[command_AdminFlags] = get_param(5);
    command[command_PluginID] = pluginId;
    command[command_FuncID] = funcId;
    command[command_Aliases] = ArrayCreate(1, 2);
    new const ZM_Command: cmdId
            = ZM_Command:(ArrayPushArray(g_commandsList, command)+1);
    g_numCommands++;
    assert g_numCommands == ArraySize(g_commandsList);
    LoggerLogDebug(g_Logger,
            "Registered command as ZM_Command: %d", cmdId);

    new alias[alias_Alias_length+1];
    get_string(1, alias, alias_Alias_length);
    new const ZM_Alias: aliasId = registerAlias(cmdId, alias);
    if (aliasId == Invalid_Alias) {
        LoggerLogWarn(g_Logger,
                "Command %d registered without an alias!", cmdId);
    }

    return cmdId;
}

// native ZM_Alias: zm_registerAlias(
//         const ZM_Command: command,
//         const alias[]);


// native ZM_Command: zm_getCommandByName(const command[]);