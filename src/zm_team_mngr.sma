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
    createOnSpawn();
    createOnKilled();
    createOnApply();
    createInfectedForwards();
    createCuredForwards();
}

createInfectedForwards() {
    createOnBeforeInfected();
    createOnInfected();
    createOnAfterInfected();
}

createCuredForwards() {
    createOnBeforeCured();
    createOnCured();
    createOnAfterCured();
}

createOnSpawn() {
    LoggerLogDebug(g_Logger, "Creating forward zm_onSpawn");
    g_fw[onSpawn] = CreateMultiForward("zm_onSpawn", ET_IGNORE,
            FP_CELL, 
            FP_CELL);
    LoggerLogDebug(g_Logger,
            "g_fw[onSpawn] = %d",
            g_fw[onSpawn]);
}

createOnKilled() {
    LoggerLogDebug(g_Logger, "Creating forward zm_onKilled");
    g_fw[onKilled] = CreateMultiForward("zm_onKilled", ET_IGNORE,
            FP_CELL, 
            FP_CELL);
    LoggerLogDebug(g_Logger,
            "g_fw[onKilled] = %d",
            g_fw[onKilled]);
}

createOnApply() {
    LoggerLogDebug(g_Logger, "Creating forward zm_onApply");
    g_fw[onApply] = CreateMultiForward("zm_onApply", ET_IGNORE,
            FP_CELL, 
            FP_CELL);
    LoggerLogDebug(g_Logger,
            "g_fw[onApply] = %d",
            g_fw[onApply]);
}

createOnBeforeInfected() {
    LoggerLogDebug(g_Logger, "Creating forward zm_onBeforeInfected");
    g_fw[onBeforeInfected] = CreateMultiForward("zm_onBeforeInfected", ET_IGNORE,
            ET_CONTINUE,
            FP_CELL,
            FP_CELL, 
            FP_CELL);
    LoggerLogDebug(g_Logger,
            "g_fw[onBeforeInfected] = %d",
            g_fw[onBeforeInfected]);
}

createOnInfected() {
    LoggerLogDebug(g_Logger, "Creating forward zm_onInfected");
    g_fw[onInfected] = CreateMultiForward("zm_onInfected", ET_IGNORE,
            FP_CELL, 
            FP_CELL);
    LoggerLogDebug(g_Logger,
            "g_fw[onInfected] = %d",
            g_fw[onInfected]);
}

createOnAfterInfected() {
    LoggerLogDebug(g_Logger, "Creating forward zm_onAfterInfected");
    g_fw[onAfterInfected] = CreateMultiForward("zm_onAfterInfected", ET_IGNORE,
            FP_CELL, 
            FP_CELL);
    LoggerLogDebug(g_Logger,
            "g_fw[onAfterInfected] = %d",
            g_fw[onAfterInfected]);
}

createOnBeforeCured() {
    LoggerLogDebug(g_Logger, "Creating forward zm_onBeforeCured");
    g_fw[onBeforeCured] = CreateMultiForward("zm_onBeforeCured", ET_IGNORE,
            ET_CONTINUE,
            FP_CELL,
            FP_CELL, 
            FP_CELL);
    LoggerLogDebug(g_Logger,
            "g_fw[onBeforeCured] = %d",
            g_fw[onBeforeCured]);
}

createOnCured() {
    LoggerLogDebug(g_Logger, "Creating forward zm_onCured");
    g_fw[onCured] = CreateMultiForward("zm_onCured", ET_IGNORE,
            FP_CELL, 
            FP_CELL);
    LoggerLogDebug(g_Logger,
            "g_fw[onCured] = %d",
            g_fw[onCured]);
}

createOnAfterCured() {
    LoggerLogDebug(g_Logger, "Creating forward zm_onAfterCured");
    g_fw[onAfterCured] = CreateMultiForward("zm_onAfterCured", ET_IGNORE,
            FP_CELL, 
            FP_CELL);
    LoggerLogDebug(g_Logger,
            "g_fw[onAfterCured] = %d",
            g_fw[onAfterCured]);
}

public client_putinserver(id) {
    setFlag(g_flagConnected, id);
}

public client_disconnect(id) {
    unsetFlag(g_flagConnected, id);
    unsetFlag(g_flagAlive, id);
}

public ham_onSpawn_Post(id) {
    if (!is_user_alive(id)) {
        unsetFlag(g_flagAlive, id);
        return HAM_IGNORED;
    }
    
    setFlag(g_flagAlive, id);
    new bool: isZombie = isUserZombie(id);
    LoggerLogDebug(g_Logger, "Calling zm_onApply(%d, isZombie=%s) for %N", id, isZombie ? TRUE : FALSE, id);
    ExecuteForward(g_fw[onApply], g_fw[fwReturn], id, isZombie);
    LoggerLogDebug(g_Logger, "Calling zm_onSpawn(%d, isZombie=%s) for %N", id, isZombie ? TRUE : FALSE, id);
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

    new name[32];
    new playersConnected = 0;
    for (new i = 1; i <= MaxClients; i++) {
        if (isUserConnected(i)) {
            playersConnected++;
            get_user_name(i, name, charsmax(name));
            console_print(id,
                    "%2d. %8.8s %5c %5s %s",
                    i,
                    name,
                    isUserZombie(i) ? ZOMBIE[0] : HUMAN[0],
                    isUserAlive(i) ? TRUE : NULL_STRING,
                    TRUE);
        } else {
            name[0] = EOS;
            console_print(id, "%2d.", i);
        }

        
    }
    
    console_print(id, "%d players connected.", playersConnected);
}

public printZombies(id) {
    console_print(id, "Zombies:");

    console_print(id,
        "%3s %8s %5s",
        "ID",
        "NAME",
        "ALIVE");

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
                isUserAlive(i) ? TRUE : NULL_STRING);
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
                isUserAlive(i) ? TRUE : NULL_STRING);
    }
    
    console_print(id, "%d humans found.", players);
}

/*******************************************************************************
 * Natives
 ******************************************************************************/