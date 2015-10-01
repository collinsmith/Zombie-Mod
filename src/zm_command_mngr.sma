#define VERSION_STRING "1.0.0"
#define EXTENSION_NAME "Command Manager"
#define ZM_PLAYERS_PRINT_EMPTY

#include <amxmodx>
#include <logger>

#include "include\\zm\\zm_team_mngr.inc"
#include "include\\zm\\zombiemod.inc"

static Logger: g_Logger = Invalid_Logger;

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

    
}