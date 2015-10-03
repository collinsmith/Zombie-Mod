#define VERSION_STRING "1.0.0"
#define COMMAND_MANAGER_TXT "command_handler.txt"
#define COMPILE_FOR_DEBUG
#define PRINT_BUFFER_LENGTH 191

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <logger>

#include "include\\commandmanager\\command_manager.inc"

#include "include\\stocks\\flag_stocks.inc"
#include "include\\stocks\\path_stocks.inc"
#include "include\\stocks\\string_stocks.inc"

static Logger: g_Logger = Invalid_Logger;

public plugin_init() {
    new buildId[32];
    getBuildId(buildId);
    register_plugin("Command Handler", buildId, "Tirant");

    g_Logger = LoggerCreate();
#if defined COMPILE_FOR_DEBUG
    LoggerSetVerbosity(g_Logger, Severity_Lowest);
    LoggerSetVerbosity(All_Loggers, Severity_Lowest);
#endif

    new dictionary[32];
    getPath(dictionary, _, COMMAND_MANAGER_TXT);
    register_dictionary(dictionary);
    LoggerLogDebug(g_Logger, "Registering dictionary file \"%s\"", dictionary);

    cmd_setHandler("cmd_onHandleCommand");
}

stock getBuildId(buildId[], len = sizeof buildId) {
    return formatex(buildId, len - 1, "%s [%s]", VERSION_STRING, __DATE__);
}

stock cmd_printColor(const id, const message[], any: ...) {
    static buffer[PRINT_BUFFER_LENGTH+1];
    static offset;
    if (buffer[0] == EOS) {
        offset = formatex(buffer, PRINT_BUFFER_LENGTH,
                "[\4CMD\1] ");
    }
    
    new length = offset;
    switch (numargs()) {
        case 2: length += copy(
                buffer[offset], PRINT_BUFFER_LENGTH-offset, message);
        default: length += vformat(
                buffer[offset], PRINT_BUFFER_LENGTH-offset, message, 3);
    }
    
    buffer[length] = EOS;
    client_print_color(id, print_team_default, buffer);
}

public cmd_onHandleCommand(
        const id,
        const error[],
        const flags,
        const bool: isTeamCommand,
        const bool: isAlive,
        const CsTeams: team,
        const bool: hasAccess) {
    if (!isStringEmpty(error)) {
        cmd_printColor(id, error);
        return PLUGIN_HANDLED;
    }

    if (!isFlagSet(flags, FLAG_METHOD_SAY)
            && !isFlagSet(flags, FLAG_METHOD_SAY_TEAM)) {
        return PLUGIN_CONTINUE;
    } else if (isFlagSet(flags, FLAG_METHOD_SAY_TEAM) && !isTeamCommand
            && !isFlagSet(flags, FLAG_METHOD_SAY)) {
        cmd_printColor(id, "%L", id, "COMMAND_SAYTEAM_ONLY");
        return PLUGIN_HANDLED;
    } else if (isFlagSet(flags, FLAG_METHOD_SAY) && isTeamCommand
            && !isFlagSet(flags, FLAG_METHOD_SAY_TEAM)) {
        cmd_printColor(id, "%L", id, "COMMAND_SAYALL_ONLY");
        return PLUGIN_HANDLED;
    }

    /*new const bool: isZombie = zm_isUserZombie(id);
    if (!isFlagSet(flags, IS_ZOMBIE) && !isFlagSet(flags, IS_HUMAN)) {
        return PLUGIN_CONTINUE;
    } else if (isFlagSet(flags, IS_HUMAN) && isZombie
            && !isFlagSet(flags, IS_ZOMBIE)) {
        return HANDLE_COMMAND(g_fw[fwReturn]);
    } else if (isFlagSet(flags, IS_ZOMBIE) && !isZombie
            && !isFlagSet(flags, IS_HUMAN)) {
        return HANDLE_COMMAND(g_fw[fwReturn]);
    }*/

    if (!isFlagSet(flags, FLAG_STATE_ALIVE)
            && !isFlagSet(flags, FLAG_STATE_DEAD)) {
        return PLUGIN_CONTINUE;
    } else if (isFlagSet(flags, FLAG_STATE_DEAD) && isAlive
            && !isFlagSet(flags, FLAG_STATE_ALIVE)) {
        cmd_printColor(id, "%L", id, "COMMAND_DEAD_ONLY");
        return PLUGIN_HANDLED;
    } else if (isFlagSet(flags, FLAG_STATE_ALIVE) && !isAlive
            && !isFlagSet(flags, FLAG_STATE_DEAD)) {
        cmd_printColor(id, "%L", id, "COMMAND_ALIVE_ONLY");
        return PLUGIN_HANDLED;
    }
    
    if (!hasAccess) {
        cmd_printColor(id, "%L", id, "COMMAND_NO_ACCESS");
        return PLUGIN_HANDLED;
    }

    return PLUGIN_CONTINUE;
}