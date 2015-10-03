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

#include "include\\stocks\\flag_stocks.inc"
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

enum any: Flags {
    IS_ALIVE = 1,
    IS_DEAD,
    IS_SAY_ALL,
    IS_SAY_TEAM,
    IS_HUMAN,
    IS_ZOMBIE,
}

#define IS_ALIVE_CH    'a'
#define IS_DEAD_CH     'd'
#define IS_SAY_ALL_CH  's'
#define IS_SAY_TEAM_CH 't'
#define IS_HUMAN_CH    'h'
#define IS_ZOMBIE_CH   'z'

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

    register_native("zm_registerCommand", "_registerCommand", 0);
    register_native("zm_registerAlias", "_registerAlias", 0);
    register_native("zm_getCommandFromAlias", "_getCommandFromAlias", 0);
    register_native("zm_isValidCommand", "_isValidCommand", 0);
    register_native("zm_isValidAlias", "_isValidAlias", 0);
    register_native("zm_getNumCommands", "_getNumCommands", 0);
    register_native("zm_getNumAliases", "_getNumAliases", 0);
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
    return any:(command) <= g_numCommands && command > Invalid_Command;
}

commandToIndex(ZM_Command: command) {
    assert isValidCommand(command);
    return any:(command)-1;
}

bool: isValidAlias(ZM_Alias: alias) {
    return any:(alias) <= g_numAliases && alias > Invalid_Alias;
}

aliasToIndex(ZM_Alias: alias) {
    assert isValidAlias(alias);
    return any:(alias)-1;
}

bool: isAliasBound(ZM_Alias: alias) {
    assert isValidAlias(alias);
    ArrayGetArray(g_aliasesList, aliasToIndex(alias), g_tempAlias);
    LoggerLogDebug(g_Logger,
            "isAliasBound(%d) == %d", alias, g_tempAlias[alias_Command]);
    return isValidCommand(g_tempAlias[alias_Command]);
}

stock outputArrayContents(Array: array) {
    new list[32], len = 0;
    new const size = ArraySize(array);
    for (new i = 0; i < size; i++) {
        len += format(list[len], charsmax(list)-len, "%d, ", ArrayGetCell(array, i));
    }

    list[max(0, len-2)] = EOS;
    LoggerLogDebug(g_Logger,
            "Array: %d contents = { %s } (size=%d)",
            array,
            list,
            size);
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
#if defined ZM_COMPILE_FOR_DEBUG
    outputArrayContents(aliasesList);
#endif

    LoggerLogDebug(g_Logger,
            "Pushing alias %d to Array: %d (size=%d)",
            alias,
            aliasesList,
            ArraySize(aliasesList));
    ArrayPushCell(aliasesList, alias);
    // Don't have to set g_commandsList again, as we modified an Array: element
    
#if defined ZM_COMPILE_FOR_DEBUG
    outputArrayContents(aliasesList);
#endif
    
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
#if defined ZM_COMPILE_FOR_DEBUG
    outputArrayContents(aliasesList);
#endif

    for (new i = 0; i < size; i++) {
        // @TODO: Binary search could be implemented here
        if (ArrayGetCell(aliasesList, i) == alias) {
            ArrayDeleteItem(aliasesList, i);
            foundAlias = true;
            break;
        }
    }

#if defined ZM_COMPILE_FOR_DEBUG
    outputArrayContents(aliasesList);
#endif

    // Don't have to set g_commandsList again, as we modified an Array: element
    g_tempAlias[alias_Command] = Invalid_Command;
    ArraySetArray(g_aliasesList, aliasToIndex(alias), g_tempAlias);
    assert foundAlias;
    LoggerLogDebug(g_Logger, "Unbound alias %d", alias);
}

ZM_Alias: registerAlias(
        const ZM_Command: command,
        alias[]) {
    if (isStringEmpty(alias)) {
        LoggerLogError(g_Logger,
                "Cannot register a command with an empty alias!");
        return Invalid_Alias;
    } else if (!isValidCommand(command)) {
        LoggerLogError(g_Logger, "Invalid command specified for alias \"%s\" \
                (%d)",
                alias,
                command);
        return Invalid_Alias;
    }

    strtolower(alias);
    new ZM_Alias: aliasId;
    if (g_aliasesMap != Invalid_Trie && TrieGetCell(g_aliasesMap, alias, aliasId)) {
        LoggerLogDebug(g_Logger,
                "Alias already mapped (alias=%d), remapping to command %d",
                aliasId,
                command);
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
    g_tempAlias[alias_Command] = Invalid_Command;
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

stock readCustomFlags(const flags[]) {
    new bits = 0;
    for (new i = 0, ch = flags[i]; ch != EOS; ch = flags[++i]) {
        switch (ch) {
            case IS_ALIVE_CH:    setFlag(bits, IS_ALIVE);
            case IS_DEAD_CH:     setFlag(bits, IS_DEAD);
            case IS_HUMAN_CH:    setFlag(bits, IS_HUMAN);
            case IS_SAY_ALL_CH:  setFlag(bits, IS_SAY_ALL);
            case IS_SAY_TEAM_CH: setFlag(bits, IS_SAY_TEAM);
            case IS_ZOMBIE_CH:   setFlag(bits, IS_ZOMBIE);
            default: LoggerLogWarn(g_Logger, "Unknown flag specified: %c", ch);
        }
    }

    return bits;
}

stock getCustomFlags(const bits, flags[], const len) {
    new copyLen = 0;
    if (isFlagSet(bits, IS_ALIVE) && copyLen < len) {
        flags[copyLen++] = IS_ALIVE_CH;
    }

    if (isFlagSet(bits, IS_DEAD) && copyLen < len) {
        flags[copyLen++] = IS_DEAD_CH;
    }

    if (isFlagSet(bits, IS_HUMAN) && copyLen < len) {
        flags[copyLen++] = IS_HUMAN_CH;
    }

    if (isFlagSet(bits, IS_SAY_ALL) && copyLen < len) {
        flags[copyLen++] = IS_SAY_ALL_CH;
    }

    if (isFlagSet(bits, IS_SAY_TEAM) && copyLen < len) {
        flags[copyLen++] = IS_SAY_TEAM_CH;
    }

    if (isFlagSet(bits, IS_ZOMBIE) && copyLen < len) {
        flags[copyLen++] = IS_ZOMBIE_CH;
    }

    flags[min(len+1, copyLen-1)] = EOS;
    return bits;
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
    new flags[Flags+1];
    for (new i = 0; i < g_numCommands; i++) {
        ArrayGetArray(g_commandsList, i, g_tempCommand);
        getCustomFlags(g_tempCommand[command_Flags], flags, charsmax(flags));

        aliasesList = g_tempCommand[command_Aliases];
        new list[256], len = 0;
        new const assertSize = ArraySize(aliasesList);
        for (new j = 0; j < assertSize; j++) {
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
    console_print(id,
            "%3s %16s %7s %32s %s",
            "ID",
            "ALIAS",
            "COMMAND",
            "PLUGIN",
            "FUNCTION_ID");

    new filename[32];
    new ZM_Command: command;
    for (new i = 0; i < g_numAliases; i++) {
        ArrayGetArray(g_aliasesList, i, g_tempAlias);
        command = g_tempAlias[alias_Command];
        if (isValidCommand(command)) {
            get_plugin(
                    g_tempCommand[command_PluginID],
                    .filename = filename,
                    .len1 = charsmax(filename));
            ArrayGetArray(g_commandsList, commandToIndex(command), g_tempCommand);
            console_print(id,
                    "%2d. %-16.16s %-7d %-32.32s %d",
                    i+1,
                    g_tempAlias[alias_Alias],
                    command,
                    filename,
                    g_tempCommand[command_FuncID]);
        } else {
            console_print(id,
                    "%2d. %-16.16s %-7d %-32.32s %d",
                    i+1,
                    g_tempAlias[alias_Alias],
                    command,
                    NULL_STRING,
                    -1);
        }
    }

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
public ZM_Command: _registerCommand(pluginId, numParams) {
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

    new flags[Flags+1];
    get_string(3, flags, charsmax(flags));
    
    new command[command_t];
    command[command_Flags] = readCustomFlags(flags);
    get_string(4, command[command_Desc], command_Desc_length);
    command[command_AdminFlags] = get_param(5);
    command[command_PluginID] = pluginId;
    command[command_FuncID] = funcId;
    command[command_Aliases] = ArrayCreate(1, 2);
    LoggerLogDebug(g_Logger,
            "Initialized command[command_Aliases] as Array: %d",
            command[command_Aliases]);
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

    if (g_fw[onCommandRegistered] == INVALID_HANDLE) {
        LoggerLogDebug(g_Logger, "Creating forward zm_onCommandRegistered");
        g_fw[onCommandRegistered] = CreateMultiForward(
                "zm_onCommandRegistered",
                ET_IGNORE,
                FP_CELL,
                FP_STRING,
                FP_STRING,
                FP_CELL,
                FP_STRING,
                FP_CELL);
        LoggerLogDebug(g_Logger,
                "g_fw[onCommandRegistered] = %d",
                g_fw[onCommandRegistered]);
    }

    LoggerLogDebug(g_Logger, "Calling zm_onCommandRegistered");
    ExecuteForward(g_fw[onCommandRegistered], g_fw[fwReturn],
            cmdId,
            alias,
            handle,
            command[command_Flags],
            command[command_Desc],
            command[command_AdminFlags]);
    return cmdId;
}

// native ZM_Alias: zm_registerAlias(
//         const ZM_Command: command,
//         const alias[]);
public ZM_Alias: _registerAlias(pluginId, numParams) {
    if (!numParamsEqual(g_Logger, 2, numParams)) {
        return Invalid_Alias;
    }

    new const ZM_Command: command = ZM_Command:(get_param(1));
    new alias[alias_Alias_length+1];
    get_string(2, alias, alias_Alias_length);
    return registerAlias(command, alias);
}

// native ZM_Command: zm_getCommandFromAlias(const command[]);
public ZM_Command: _getCommandFromAlias(pluginId, numParams) {
    if (!numParamsEqual(g_Logger, 1, numParams)) {
        return Invalid_Command;
    }

    if (g_commandsList == Invalid_Array || g_numCommands == 0) {
        return Invalid_Command;
    }

    new alias[alias_Alias_length+1];
    get_string(1, alias, alias_Alias_length);
    
    new ZM_Alias: aliasId;
    if (g_aliasesMap == Invalid_Trie || !TrieGetCell(g_aliasesMap, alias, aliasId)) {
        return Invalid_Command;
    }

    assert isValidAlias(aliasId);
    ArrayGetArray(g_aliasesList, aliasToIndex(aliasId), g_tempAlias);
    LoggerLogDebug(g_Logger,
            "zm_getCommandFromAlias(\"%s\") == %d",
            alias,
            g_tempAlias[alias_Command]);
    return g_tempAlias[alias_Command];
}

// native bool: zm_isValidCommand(const ZM_Command: command);
public bool: _isValidCommand(pluginId, numParams) {
    if (!numParamsEqual(g_Logger, 1, numParams)) {
        return false;
    }

    new ZM_Command: command = ZM_Command:(get_param(1));
    return isValidCommand(command);
}

// native bool: zm_isValidAlias(const ZM_Alias: alias);
public bool: _isValidAlias(pluginId, numParams) {
    if (!numParamsEqual(g_Logger, 1, numParams)) {
        return false;
    }

    new ZM_Alias: alias = ZM_Alias:(get_param(1));
    return isValidAlias(alias);
}

// native zm_getNumCommands();
public _getNumCommands(pluginId, numParams) {
    if (!hasNoParams(g_Logger, numParams)) {
        return false;
    }

    return g_numCommands;
}

// native zm_getNumAliases();
public _getNumAliases(pluginId, numParams) {
    if (!hasNoParams(g_Logger, numParams)) {
        return false;
    }

    return g_numAliases;
}