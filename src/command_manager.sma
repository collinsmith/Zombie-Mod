#define VERSION_STRING "1.0.0"
#define COMPILE_FOR_DEBUG
#define MAX_NUM_PREFIXES 8
#define INITIAL_COMMANDS_SIZE 8
#define INITIAL_ALIASES_SIZE 16
#define COMMAND_MANAGER_TXT "command_manager.txt"

#include <amxmodx>
#include <logger>

#include "include\\commandmanager\\alias_t.inc"
#include "include\\commandmanager\\command_t.inc"
#include "include\\commandmanager\\command_manager_const.inc"

#include "include\\stocks\\dynamic_param_stocks.inc"
#include "include\\stocks\\flag_stocks.inc"
#include "include\\stocks\\misc_stocks.inc"
#include "include\\stocks\\path_stocks.inc"

stock Command: toCommand(value)                    return Command:(value);
stock Command: operator= (value)                   return toCommand(value);
stock          operator- (Command: command, other) return any:(command) -  other;
stock bool:    operator==(Command: command, other) return any:(command) == other;
stock bool:    operator!=(Command: command, other) return any:(command) != other;
stock bool:    operator< (Command: command, other) return any:(command) <  other;
stock bool:    operator<=(Command: command, other) return any:(command) <= other;
stock bool:    operator> (Command: command, other) return any:(command) >  other;
stock bool:    operator>=(Command: command, other) return any:(command) >= other;

stock Alias: toAlias(value)                  return Alias:(value);
stock Alias: operator= (value)               return toAlias(value);
stock        operator- (Alias: alias, other) return any:(alias) -  other;
stock bool:  operator==(Alias: alias, other) return any:(alias) == other;
stock bool:  operator!=(Alias: alias, other) return any:(alias) != other;
stock bool:  operator< (Alias: alias, other) return any:(alias) <  other;
stock bool:  operator<=(Alias: alias, other) return any:(alias) <= other;
stock bool:  operator> (Alias: alias, other) return any:(alias) >  other;
stock bool:  operator>=(Alias: alias, other) return any:(alias) >= other;

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

static Array: g_commandsList, g_numCommands;
static g_tempCommand[command_t], Command: g_Command = Invalid_Command;

static Array: g_aliasesList, g_numAliases;
static g_tempAlias[alias_t], Alias: g_Alias = Invalid_Alias;

static Trie: g_aliasesMap;
static Trie: g_prefixesMap;

static g_pCvar_Prefixes;

public plugin_precache() {
    g_Logger = LoggerCreate();
#if defined COMPILE_FOR_DEBUG
    LoggerSetVerbosity(g_Logger, Severity_Lowest);
    LoggerSetVerbosity(All_Loggers, Severity_Lowest);
#endif
}

public plugin_natives() {
    register_library("command_manager");

    register_native("cmd_registerCommand", "_registerCommand", 0);
    register_native("cmd_registerAlias", "_registerAlias", 0);

    register_native("cmd_getCommandFromAlias", "_getCommandFromAlias", 0);

    register_native("cmd_isValidCommand", "_isValidCommand", 0);
    register_native("cmd_isValidAlias", "_isValidAlias", 0);

    register_native("cmd_getNumCommands", "_getNumCommands", 0);
    register_native("cmd_getNumAliases", "_getNumAliases", 0);
}

public plugin_init() {
    new buildId[32];
    getBuildId(buildId);
    register_plugin("Command Manager", buildId, "Tirant");

    create_cvar(
            "command_manager_version",
            buildId,
            FCVAR_SPONLY,
            "Current version of Command Manager being used");

    new dictionary[32];
    getPath(dictionary, _, COMMAND_MANAGER_TXT);
    register_dictionary(dictionary);
    LoggerLogDebug(g_Logger, "Registering dictionary file \"%s\"", dictionary);

    registerConCmds();

    g_pCvar_Prefixes = create_cvar(
            "command_prefixes",
            "/.!",
            FCVAR_SERVER|FCVAR_SPONLY,
            "List of all symbols that can preceed commands");
    hook_cvar_change(g_pCvar_Prefixes, "cvar_onPrefixesAltered");

    new prefixes[MAX_NUM_PREFIXES];
    get_pcvar_string(g_pCvar_Prefixes, prefixes, charsmax(prefixes));
    cvar_onPrefixesAltered(g_pCvar_Prefixes, NULL_STRING, prefixes);
}

stock getBuildId(buildId[], len = sizeof buildId) {
#if defined COMPILE_FOR_DEBUG
    return formatex(buildId, len - 1, "%s [%s] [DEBUG]", VERSION_STRING, __DATE__);
#else
    return formatex(buildId, len - 1, "%s [%s]", VERSION_STRING, __DATE__);
#endif
}

registerConCmds() {
    registerConCmd(
            .prefix = "cmd",
            .command = "list",
            .function = "printCommands",
            .description = "Prints the list of commands with their details",
            .logger = g_Logger);

    registerConCmd(
            .prefix = "cmd",
            .command = "cmds",
            .function = "printCommands",
            .description = "Prints the list of commands with their details",
            .logger = g_Logger);

    registerConCmd(
            .prefix = "cmd",
            .command = "commands",
            .function = "printCommands",
            .description = "Prints the list of commands with their details",
            .logger = g_Logger);

    registerConCmd(
            .prefix = "cmd",
            .command = "aliases",
            .function = "printAliases",
            .description = "Prints the list of commands with their details",
            .logger = g_Logger);
}

public cvar_onPrefixesAltered(pCvar, const oldValue[], const newValue[]) {
    assert pCvar == g_pCvar_Prefixes;
    if (g_prefixesMap == Invalid_Trie) {
        g_prefixesMap = TrieCreate();
        LoggerLogDebug(g_Logger,
                "Initialized g_prefixesMap as Trie: %d",
                g_prefixesMap);
    } else {
        TrieClear(g_prefixesMap);
        LoggerLogDebug(g_Logger, "Cleared g_prefixesMap");
    }
    
    LoggerLogDebug(g_Logger,
            "Updating command prefixes table to: \"%s\"",
            newValue);
    
    new i = 0;
    new temp[2];
    while (newValue[i] != EOS) {
        temp[0] = newValue[i];
        TrieSetCell(g_prefixesMap, temp, i);
        i++;
    }
    
    if (g_fw[onPrefixesChanged] == INVALID_HANDLE) {
        LoggerLogDebug(g_Logger, "Creating forward cmd_onPrefixesChanged");
        g_fw[onPrefixesChanged] = CreateMultiForward(
                "cmd_onPrefixesChanged",
                ET_IGNORE,
                FP_STRING,
                FP_STRING);
        LoggerLogDebug(g_Logger,
                "g_fw[onPrefixesChanged] = %d",
                g_fw[onPrefixesChanged]);
    }
    
    ExecuteForward(g_fw[onPrefixesChanged], g_fw[fwReturn], oldValue, newValue);
}

stock bool: isValidCommand({any,Command}: command) {
    return command <= g_numCommands && command > Invalid_Command;
}

stock commandToIndex(Command: command) {
    assert isValidCommand(command);
    return command-1;
}

stock bool: isValidAlias({any,Alias}: alias) {
    return alias <= g_numAliases && alias > Invalid_Alias;
}

stock aliasToIndex(Alias: alias) {
    assert isValidAlias(alias);
    return alias-1;
}

stock bool: isAliasBound(Alias: alias) {
    loadAlias(alias);
    new const Command: command = g_tempAlias[alias_Command];
    LoggerLogDebug(g_Logger,
            "isAliasBound(\"%s\") == %s; g_tempAlias[alias_Command] = %d",
            g_tempAlias[alias_String],
            isValidCommand(command) ? "true" : "false",
            command);
    return isValidCommand(command);
}

stock loadCommand(Command: command) {
    if (command == g_Command) {
        return;
    }

    ArrayGetArray(g_commandsList, commandToIndex(command), g_tempCommand);
    g_Command = command;
    LoggerLogDebug(g_Logger, "Loaded command %d into g_tempCommand", g_Command);
}

stock commitCommand(Command: command) {
    ArrayGetArray(g_commandsList, commandToIndex(command), g_tempCommand);
    g_Command = command;
    LoggerLogDebug(g_Logger, "Committed command %d into g_tempCommand", g_Command);
}

stock invalidateCommand() {
    g_Command = Invalid_Command;
    LoggerLogDebug(g_Logger, "Invalidated g_tempCommand");
}

stock loadAlias(Alias: alias) {
    if (alias == g_Alias) {
        return;
    }

    ArrayGetArray(g_aliasesList, aliasToIndex(alias), g_tempAlias);
    g_Alias = alias;
    LoggerLogDebug(g_Logger, "Loaded alias %d into g_tempAlias", g_Alias);
}

stock commitAlias(Alias: alias) {
    ArrayGetArray(g_aliasesList, aliasToIndex(alias), g_tempAlias);
    g_Alias = alias;
    LoggerLogDebug(g_Logger, "Committed alias %d into g_tempAlias", g_Alias);
}

stock invalidateAlias() {
    g_Alias = Invalid_Alias;
    LoggerLogDebug(g_Logger, "Invalidated g_tempAlias");
}

stock outputArrayContents(Array: array){
    new list[32], len = 0;
    new const size = ArraySize(array);
    for (new i = 0; i < size; i++) {
        len += format(list[len], charsmax(list)-len,
                "%d, ", ArrayGetCell(array, i));
    }

    list[max(0, len-2)] = EOS;
    LoggerLogDebug(g_Logger,
            "Array: %d contents = { %s } (size=%d)",
            array,
            list,
            size);
}

bindAlias(Alias: alias, Command: command) {
    assert isValidCommand(command);
    loadAlias(alias);
    LoggerLogDebug(g_Logger,
            "Binding alias %d (\"%s\") to command %d",
            alias,
            g_tempAlias[alias_String],
            command);

    if (isAliasBound(alias)) {
        unbindAlias(alias);
    }

    loadAlias(alias);
    g_tempAlias[alias_Command] = command;
    loadCommand(command);
    new const Array: aliasesList = g_tempCommand[command_Aliases];
#if defined COMPILE_FOR_DEBUG
    outputArrayContents(aliasesList);
#endif
    LoggerLogDebug(g_Logger,
            "Pushing alias %d (\"%s\") to Array: %d (size=%d)",
            alias,
            g_tempAlias[alias_String],
            aliasesList,
            ArraySize(aliasesList));
            
    ArrayPushCell(aliasesList, alias);
#if defined COMPILE_FOR_DEBUG
    outputArrayContents(aliasesList);
#endif
    commitAlias(alias);
}

unbindAlias(Alias: alias) {
    if (!isAliasBound(alias)) {
        return;
    }

    new const Command: command = g_tempAlias[alias_Command];
    loadCommand(command);

    new const Array: aliasesList = g_tempCommand[command_Aliases];
    assert aliasesList != Invalid_Array;

    new bool: foundAlias = false;
    new const size = ArraySize(aliasesList);
#if defined COMPILE_FOR_DEBUG
    outputArrayContents(aliasesList);
#endif
    LoggerLogDebug(g_Logger,
            "Removing alias %d (\"%s\") from Array: %d (size=%d)",
            alias,
            g_tempAlias[alias_String],
            aliasesList,
            size);

    for (new i = 0; i < size; i++) {
        // @TODO: Binary search could be implemented here
        if (ArrayGetCell(aliasesList, i) == alias) {
            ArrayDeleteItem(aliasesList, i);
            foundAlias = true;
            break;
        }
    }

#if defined COMPILE_FOR_DEBUG
    outputArrayContents(aliasesList);
#endif
    assert foundAlias;
    g_tempAlias[alias_Command] = Invalid_Command;
    commitAlias(alias);
    LoggerLogDebug(g_Logger,
            "Unbound alias %d (\"%s\")",
            alias,
            g_tempAlias[alias_String]);
}

Alias: registerAlias(const Command: command, alias[]) {
    strtolower(alias);
    if (isStringEmpty(alias)) {
        LoggerLogError(g_Logger,
                "Cannot register an empty alias!");
        return Invalid_Alias;
    } else if (!isValidCommand(command)) {
        LoggerLogError(g_Logger,
                "Invalid command specified for alias \"%s\": %d",
                alias,
                command);
        return Invalid_Alias;
    }

    new Alias: aliasId;
    if (g_aliasesMap != Invalid_Trie
            && TrieGetCell(g_aliasesMap, alias, aliasId)) {
        loadAlias(aliasId);
        LoggerLogDebug(g_Logger,
                "Remapping existing alias %d (\"%s\"), from command %d to %d",
                aliasId,
                g_tempAlias[alias_String],
                g_tempAlias[alias_Command],
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

    copy(g_tempAlias[alias_String], alias_String_length, alias);
    g_tempAlias[alias_Command] = Invalid_Command;
    aliasId = ArrayPushArray(g_aliasesList, g_tempAlias)+1;
    TrieSetCell(g_aliasesMap, g_tempAlias[alias_String], aliasId);
    g_Alias = aliasId;

    g_numAliases++;
    assert g_numAliases == ArraySize(g_aliasesList);
    assert g_numAliases == TrieGetSize(g_aliasesMap);

    bindAlias(aliasId, command);
    LoggerLogDebug(g_Logger,
            "Registered alias %d (\"%s\") for command %d",
            aliasId,
            alias,
            command);
    return aliasId;
}

stock readCustomFlags(const flags[]) {
    new bits = 0;
    for (new i = 0, ch = flags[i]; ch != EOS; ch = flags[++i]) {
        switch (ch) {
            case FLAG_METHOD_SAY_CH:      setFlag(bits, FLAG_METHOD_SAY);
            case FLAG_METHOD_SAY_TEAM_CH: setFlag(bits, FLAG_METHOD_SAY_TEAM);
            
            case FLAG_STATE_ALIVE_CH:     setFlag(bits, FLAG_STATE_ALIVE);
            case FLAG_STATE_DEAD_CH:      setFlag(bits, FLAG_STATE_DEAD);

            case FLAG_TEAM_UNASSIGNED_CH: setFlag(bits, FLAG_TEAM_UNASSIGNED);
            case FLAG_TEAM_T_CH:          setFlag(bits, FLAG_TEAM_T);
            case FLAG_TEAM_CT_CH:         setFlag(bits, FLAG_TEAM_CT);
            case FLAG_TEAM_SPECTATOR_CH:  setFlag(bits, FLAG_TEAM_SPECTATOR);
            
            case FLAG_SEPARATOR:          continue;

            default: LoggerLogWarn(g_Logger, "Unknown flag specified: %c", ch);
        }
    }

    return bits;
}

stock getCustomFlags(const bits, flags[], const len) {
    new copyLen = 0;
    if (isFlagSet(bits, FLAG_METHOD_SAY) && copyLen < len) {
        flags[copyLen++] = FLAG_METHOD_SAY_CH;
    }

    if (isFlagSet(bits, FLAG_METHOD_SAY_TEAM) && copyLen < len) {
        flags[copyLen++] = FLAG_METHOD_SAY_TEAM_CH;
    }

    if (isFlagSet(bits, FLAG_STATE_ALIVE) && copyLen < len) {
        flags[copyLen++] = FLAG_STATE_ALIVE_CH;
    }

    if (isFlagSet(bits, FLAG_STATE_DEAD) && copyLen < len) {
        flags[copyLen++] = FLAG_STATE_DEAD_CH;
    }

    if (isFlagSet(bits, FLAG_TEAM_UNASSIGNED) && copyLen < len) {
        flags[copyLen++] = FLAG_TEAM_UNASSIGNED_CH;
    }

    if (isFlagSet(bits, FLAG_TEAM_T) && copyLen < len) {
        flags[copyLen++] = FLAG_TEAM_T_CH;
    }

    if (isFlagSet(bits, FLAG_TEAM_CT) && copyLen < len) {
        flags[copyLen++] = FLAG_TEAM_CT_CH;
    }

    if (isFlagSet(bits, FLAG_TEAM_SPECTATOR) && copyLen < len) {
        flags[copyLen++] = FLAG_TEAM_SPECTATOR_CH;
    }

    flags[min(len, copyLen-1)+1] = EOS;
    return copyLen;
}

stock checkFlags(const bits, const Command: command, const alias[]) {
    if (!isFlagSet(bits, FLAG_METHOD_SAY)
            && !isFlagSet(bits, FLAG_METHOD_SAY_TEAM)) {
        LoggerLogWarn(g_Logger,
                "Command %d with alias \"%s\" does not have a flag specifying \
                a say method which activates it ('%c' for 'say' and/or \
                '%c' for 'say_team')",
                command,
                alias,
                FLAG_METHOD_SAY_CH,
                FLAG_METHOD_SAY_TEAM_CH);
    }

    if (!isFlagSet(bits, FLAG_STATE_ALIVE)
            && !isFlagSet(bits, FLAG_STATE_DEAD)) {
        LoggerLogWarn(g_Logger,
                "Command %d with alias \"%s\" does not have a flag specifying \
                a state which a player must be in order to activate it ('%c' \
                for alive and/or '%c' for dead)",
                command,
                alias,
                FLAG_STATE_ALIVE_CH,
                FLAG_STATE_DEAD_CH);
    }

    if (!isFlagSet(bits, FLAG_TEAM_UNASSIGNED)
            && !isFlagSet(bits, FLAG_TEAM_T)
            && !isFlagSet(bits, FLAG_TEAM_CT)
            && !isFlagSet(bits, FLAG_TEAM_SPECTATOR)) {
        LoggerLogWarn(g_Logger,
                "Command %d with alias \"%s\" does not have a flag specifying \
                a team which a player must be on in order to activate it \
                ('%c' for UNASSIGNED and/or '%c' for TERRORIST and/or '%c' \
                for CT and/or '%c' for SPECTATOR)",
                command,
                alias,
                FLAG_TEAM_UNASSIGNED_CH,
                FLAG_TEAM_T_CH,
                FLAG_TEAM_CT_CH,
                FLAG_TEAM_SPECTATOR_CH);
    }

    if (!isFlagSet(bits, FLAG_STATE_DEAD)
            && isFlagSet(bits, FLAG_TEAM_SPECTATOR)) {
        LoggerLogWarn(g_Logger,
                "Command %d with alias \"%s\" specifies a player must be a \
                spectator ('%c'), however the dead flag ('%c') is not set",
                command,
                alias,
                FLAG_TEAM_SPECTATOR_CH,
                FLAG_STATE_DEAD_CH);
    }
}

/*******************************************************************************
 * Console Commands
 ******************************************************************************/

public printCommands(id) {
    //...
}

public printAliases(id) {
    //...
}

/*******************************************************************************
 * Natives
 ******************************************************************************/

// native Command: cmd_registerCommand(
//         const alias[],
//         const handle[],
//         const flags[] = "12,ad,utcs",
//         const description[] = NULL_STRING,
//         const adminFlags = ADMIN_ALL);
public Command: _registerCommand(pluginId, numParams) {
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

    new const funcId = get_func_id(handle, pluginId);
    if (funcId == -1) {
        new filename[32];
        get_plugin(pluginId, filename, charsmax(filename));
        LoggerLogError(g_Logger,
                "Function \"%s\" does not exist within \"%s\"!",
                handle,
                filename);
        return Invalid_Command;
    }

    new flags[32];
    get_string(3, flags, charsmax(flags));
    new const bits = readCustomFlags(flags);

    new const adminFlags = get_param(5);
    
    get_string(4, g_tempCommand[command_Desc], command_Desc_length);
    g_tempCommand[command_Flags] = bits;
    g_tempCommand[command_AdminFlags] = adminFlags;
    g_tempCommand[command_PluginID] = pluginId;
    g_tempCommand[command_FuncID] = funcId;
    g_tempCommand[command_Aliases] = ArrayCreate(1, 2);
    g_Command = ArrayPushArray(g_commandsList, g_tempCommand)+1;
    g_numCommands++;
    assert g_numCommands == ArraySize(g_commandsList);

    LoggerLogDebug(g_Logger,
            "Initialized command %d[command_Aliases] as Array: %d",
            g_Command,
            g_tempCommand[command_Aliases]);

    LoggerLogDebug(g_Logger,
            "Registered command as Command: %d", g_Command);

    new alias[alias_String_length+1];
    get_string(1, alias, charsmax(alias));
    if (registerAlias(g_Command, alias) == Invalid_Alias) {
        LoggerLogWarn(g_Logger,
                "Command %d registered without an alias!", g_Command);
    }

    checkFlags(bits, g_Command, alias);
    
    if (g_fw[onCommandRegistered] == INVALID_HANDLE) {
        LoggerLogDebug(g_Logger, "Creating forward cmd_onCommandRegistered");
        g_fw[onCommandRegistered] = CreateMultiForward(
                "cmd_onCommandRegistered",
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

    LoggerLogDebug(g_Logger, "Calling cmd_onCommandRegistered");
    ExecuteForward(g_fw[onCommandRegistered], g_fw[fwReturn],
            g_Command,
            alias,
            handle,
            bits,
            g_tempCommand[command_Desc],
            adminFlags);
            
    return g_Command;
}

// native Alias: cmd_registerAlias(
//         const Command: command,
//         const alias[]);
public Alias: _registerAlias(pluginId, numParams) {
    if (!numParamsEqual(g_Logger, 2, numParams)) {
        return Invalid_Alias;
    }

    new alias[alias_String_length+1];
    get_string(2, alias, charsmax(alias));
    return registerAlias(toCommand(get_param(1)), alias);
}

// native Command: cmd_getCommandFromAlias(const alias[]);
public Command: _getCommandFromAlias(pluginId, numParams) {
    if (!numParamsEqual(g_Logger, 1, numParams)) {
        return Invalid_Command;
    }

    if (g_commandsList == Invalid_Array || g_numCommands == 0) {
        return Invalid_Command;
    }

    new alias[alias_String_length+1];
    get_string(1, alias, charsmax(alias));
    
    new Alias: aliasId;
    if (g_aliasesMap == Invalid_Trie
            || !TrieGetCell(g_aliasesMap, alias, aliasId)) {
        return Invalid_Command;
    }

    assert isValidAlias(aliasId);
    loadAlias(aliasId);
    new const Command: command = g_tempAlias[alias_Command];
    LoggerLogDebug(g_Logger,
            "cmd_getCommandFromAlias(\"%s\") == %d",
            alias,
            command);
    return command;
}

// native bool: cmd_isValidCommand(const Command: command);
public bool: _isValidCommand(pluginId, numParams) {
    if (!numParamsEqual(g_Logger, 1, numParams)) {
        return false;
    }

    return isValidCommand(get_param(1));
}

// native bool: cmd_isValidAlias(const Alias: alias);
public bool: _isValidAlias(pluginId, numParams) {
    if (!numParamsEqual(g_Logger, 1, numParams)) {
        return false;
    }

    return isValidAlias(get_param(1));
}

// native cmd_getNumCommands();
public _getNumCommands(pluginId, numParams) {
    if (!hasNoParams(g_Logger, numParams)) {
        return -1;
    }

    return g_numCommands;
}

// native cmd_getNumAliases();
public _getNumAliases(pluginId, numParams) {
    if (!hasNoParams(g_Logger, numParams)) {
        return -1;
    }

    return g_numAliases;
}