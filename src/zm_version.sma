#define VERSION_STRING "1.0.0"
#define EXTENSION_NAME "Version"

#define MOD_NAME_LENGTH 31

#include <logger>
#include <fakemeta>
#include <regex>

#include "include\\zm\\zombiemod.inc"

static Logger: g_Logger = Invalid_Logger;
static g_ModName[MOD_NAME_LENGTH+1];

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
            .description = "Sets the game description string");

    g_Logger = LoggerCreate();
#if defined ZM_COMPILE_FOR_DEBUG
    LoggerSetVerbosity(g_Logger, Severity_Lowest);
    LoggerSetVerbosity(All_Loggers, Severity_Lowest);
#endif

    configureModName();
    register_forward(FM_GetGameDescription, "fw_onGetGameDescription");
    LoggerDestroy(g_Logger);
}

configureModName() {
    assert g_ModName[0] == EOS;
    LoggerLogDebug(g_Logger, "Configuring mod name (FM_GetGameDescription)");

    new length = formatex(g_ModName, MOD_NAME_LENGTH,
            "%L",
            LANG_SERVER, ZM_NAME);
    g_ModName[length++] = ' ';
    
    new Regex: regex = regex_match(ZM_VERSION_STRING, "^\\d+\\.\\d+");
    regex_substr(regex, 0, g_ModName[length], MOD_NAME_LENGTH-length);
    regex_free(regex);
    
    LoggerLogDebug(g_Logger, "Mod name configured as \"%s\"", g_ModName);
}

public fw_onGetGameDescription() {
    forward_return(FMV_STRING, g_ModName);
    return FMRES_SUPERCEDE;
}