#define VERSION_STRING "1.0.0"
#define COMPILE_FOR_DEBUG

#include <amxmodx>
#include <logger>

#include "include\\commandmanager\\alias_t.inc"
#include "include\\commandmanager\\command_t.inc"
#include "include\\commandmanager\\command_manager_const.inc"

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
}

stock getBuildId(buildId[], len = sizeof buildId) {
#if defined COMPILE_FOR_DEBUG
    return formatex(buildId, len - 1, "%s [%s] [DEBUG]", VERSION_STRING, __DATE__);
#else
    return formatex(buildId, len - 1, "%s [%s]", VERSION_STRING, __DATE__);
#endif
}