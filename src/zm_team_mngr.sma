#define VERSION_STRING "1.0.0"
#define EXTENSION_NAME "Team Manager"

#include <amxmodx>
#include <logger>
#include <hamsandwich>

#include "include\\zm\\zombiemod.inc"

#include "include\\stocks\\flag_stocks.inc"
#include "include\\stocks\\param_test_stocks.inc"
#include "include\\stocks\\dynamic_param_stocks.inc"

static Logger: g_Logger = Invalid_Logger;

enum Forwards {
    fwReturn,
    onSpawn,
    onKilled,
    onBeforeInfected, onInfected, onAfterInfected,
    onBeforeCured, onCured, onAfterCured,
    onApply
}; static g_fw[Forwards] = { 0, INVALID_HANDLE, INVALID_HANDLE, INVALID_HANDLE,
        INVALID_HANDLE, INVALID_HANDLE, INVALID_HANDLE, INVALID_HANDLE,
        INVALID_HANDLE, INVALID_HANDLE };

static g_flagConnected;
static g_flagAlive;
static g_flagZombie;

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
            .description = "Manages the teams and infection events");

    g_Logger = LoggerCreate();
#if defined ZM_COMPILE_FOR_DEBUG
    LoggerSetVerbosity(g_Logger, Severity_Lowest);
    LoggerSetVerbosity(All_Loggers, Severity_Lowest);
#endif

    registerConCmds();
    createForwards();

    RegisterHam(Ham_Spawn, "player", "ham_onSpawn_Post", 1);
    RegisterHam(Ham_Killed, "player", "ham_onKilled", 0);
}

registerConCmds() {
    zm_registerConCmd(
            .command = "players",
            .function = "printPlayers",
            .description = "Prints the list of players with their statuses",
            .logger = g_Logger);

    zm_registerConCmd(
            .command = "zombies",
            .function = "printZombies",
            .description = "Prints the list of players who are a zombie",
            .logger = g_Logger);

    zm_registerConCmd(
            .command = "humans",
            .function = "printHumans",
            .description = "Prints the list of players who are a human",
            .logger = g_Logger);
}

createForwards() {
    LoggerLogDebug(g_Logger, "Creating forward zm_onSpawn");
    g_fw[onSpawn] = CreateMultiForward("zm_onSpawn", ET_IGNORE,
            FP_CELL, 
            FP_CELL);
    LoggerLogDebug(g_Logger,
            "g_fw[onSpawn] = %d",
            g_fw[onSpawn]);

    LoggerLogDebug(g_Logger, "Creating forward zm_onKilled");
    g_fw[onKilled] = CreateMultiForward("zm_onKilled", ET_IGNORE,
            FP_CELL, 
            FP_CELL);
    LoggerLogDebug(g_Logger,
            "g_fw[onKilled] = %d",
            g_fw[onKilled]);
}

public ham_onSpawn_Post(id) {
    if (!is_user_alive(id)) {
        unsetFlag(g_flagAlive, id);
        return HAM_IGNORED;
    }
    
    setFlag(g_flagAlive, id);
    new bool: isZombie = isUserZombie(id);
    //ExecuteForward(g_fw[onRefresh], g_fw[fwReturn], id, isZombie);
    LoggerLogDebug(g_Logger, "Calling zm_onSpawn(%d, isZombie=%s) for %N", id, isZombie ? "true" : "false", id);
    ExecuteForward(g_fw[onSpawn], g_fw[fwReturn], id, isZombie);
    return HAM_HANDLED;
}

public ham_onKilled(killer, victim, shouldgib) {
    if (is_user_alive(victim)) {
        return HAM_IGNORED;
    }
    
    //hideMenus(victim);
    unsetFlag(g_flagAlive, victim);
    LoggerLogDebug(g_Logger, "Calling zm_onKilled(killer=%d, victim=%d) for %N", killer, victim, victim);
    ExecuteForward(g_fw[onKilled], g_fw[fwReturn], killer, victim);
    return HAM_HANDLED;
}

bool: isUserConnected(const id) {
    assert isValidId(id);
    return isFlagSet(g_flagConnected, id);
}

bool: isUserAlive(const id) {
    assert isValidId(id);
    return isFlagSet(g_flagAlive, id);
}

bool: isUserZombie(const id) {
    assert isValidId(id);
    return isFlagSet(g_flagZombie, id);
}

bool: isUserHuman(const id) {
    return !isUserZombie(id);
}

/*******************************************************************************
 * Console Commands
 ******************************************************************************/

public printPlayers(id) {
    console_print(id, "Players:");

    console_print(id,
        "%3s %8s %5s %5s %s",
        "ID",
        "NAME",
        "STATE",
        "ALIVE",
        "CONNECTED");

    new const ALIVE[] = "Y";
    new const CONNECTED[] = "Y";

    new name[32];
    new players = get_playersnum(.flag = 1);
    for (new i = 1; i <= players; i++) {
        get_user_name(i, name, charsmax(name));
        console_print(id,
                "%2d. %8.8s %5c %5s %s",
                i,
                name,
                isUserZombie(i) ? 'Z' : 'H',
                isUserAlive(i) ? ALIVE : NULL_STRING,
                isUserConnected(i) ? CONNECTED : NULL_STRING);
    }
    
    console_print(id, "%d players found.", players);
}

public printZombies(id) {
    console_print(id, "Zombies:");

    console_print(id,
        "%3s %8s %5s",
        "ID",
        "NAME",
        "ALIVE");

    new const ALIVE[] = "Y";

    new name[32];
    new players = get_playersnum(.flag = 0);
    for (new i = 1; i <= players; i++) {
        if (!isUserZombie(i)) {
            continue;
        }

        get_user_name(i, name, charsmax(name));
        console_print(id,
                "%2d. %8.8s %5s",
                i,
                name,
                isUserAlive(i) ? ALIVE : NULL_STRING);
    }
    
    console_print(id, "%d zombies found.", players);
}

public printHumans(id) {
    console_print(id, "Humans:");

    console_print(id,
        "%3s %8s %5s",
        "ID",
        "NAME",
        "ALIVE");

    new const ALIVE[] = "Y";

    new name[32];
    new players = get_playersnum(.flag = 0);
    for (new i = 1; i <= players; i++) {
        if (!isUserHuman(i)) {
            continue;
        }

        get_user_name(i, name, charsmax(name));
        console_print(id,
                "%2d. %8.8s %5s",
                i,
                name,
                isUserAlive(i) ? ALIVE : NULL_STRING);
    }
    
    console_print(id, "%d humans found.", players);
}

/*******************************************************************************
 * Natives
 ******************************************************************************/