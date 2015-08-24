#include "include/zm/compiler_settings.inc"

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <regex>

#include "include/zm/inc/templates/extension_t.inc"
#include "include/zm/inc/zm_const.inc"
#include "include/zm/inc/zm_stocks.inc"
#include "include/zm/inc/zm_macros.inc"

#define DEFAULT_EXTENSIONS_NUM 16

#define LOG_BUFFER_LENGTH 255
#define LOG_PATH_LENGTH 63
#define CONFIGS_DIR_PATH_LENGTH 63
#define MOD_NAME_LENGTH 31

static const ZM_LOG_LEVEL_NAMES[ZM_LOG_LEVEL_length][] = {
    "NONE",
    "SEVERE",
    "WARN",
    "INFO",
    "DEBUG"
};

enum _:FORWARDS_length {
    fwReturn,
    onInitStructs,
    onPrecache,
    onInit,
    onExtensionRegistered
};

static g_szLogBuffer[LOG_BUFFER_LENGTH+1];
static g_szLogFilePath[LOG_PATH_LENGTH+1];
static g_szModName[MOD_NAME_LENGTH+1];

static g_fw[FORWARDS_length];

static ZM_LOG_LEVEL:g_logLevel;

static Array:g_extensionsList = Invalid_Array;
static g_numExtensions;

static g_pcvar_version;
static g_pcvar_logLevel;

public plugin_natives() {
    register_library("zombiemod");

    register_native("zm_log", "_log", 0);
    
    register_native("zm_registerExtension", "_registerExtension", 0);
    register_native("zm_getExtension", "_getExtension", 0);
    register_native("zm_getNumExtensions", "_getNumExtensions", 0);
}

public plugin_precache() {
    register_plugin(ZM_NAME, ZM_VERSION_STRING, "Tirant");
    
    g_pcvar_version = create_cvar("zm_version",
                                  ZM_VERSION_STRING,
                                  FCVAR_SPONLY,
                                  "The current version of Zombie Mod being used");
    
    new szDefaultLogLevel[2];
    num_to_str(any:ZM_LOG_LEVEL_DEBUG,
               szDefaultLogLevel,
               charsmax(szDefaultLogLevel));

    g_pcvar_logLevel = create_cvar(
        .name = "zm_log_level",
        .string = szDefaultLogLevel,
        .flags = FCVAR_SPONLY,
        .description = "Log level to use, 0-NONE/1-SEVERE/2-WARN/3-INFO/4-DEBUG",
        .has_min = true,
        .min_val = 0.0,
        .has_max = true,
        .max_val = 4.0);

    bind_pcvar_num(g_pcvar_logLevel, g_logLevel);
    
    configureLogFilePath();
    
    log(ZM_LOG_LEVEL_INFO, "================================");
    log(ZM_LOG_LEVEL_INFO, "Launching Zombie Mod v%s (%s)...",
                           ZM_VERSION_STRING,
                           __DATE__);
    
#if defined ZM_DEBUG_MODE
    log(ZM_LOG_LEVEL_INFO, "Compiled in DEBUG mode");
#endif
    
    g_extensionsList = ArrayCreate(extension_t, DEFAULT_EXTENSIONS_NUM);
    g_numExtensions = 0;
    
    register_concmd("zm.version", "printVersion", _, "Prints the version info");
    
#if defined ZM_DEBUG_MODE
    register_concmd("zm.exts",
                    "printExtensions",
                    ADMIN_CFG,
                    "Prints the list of registered extensions");
#endif
    
    new szZMConfigsDir[CONFIGS_DIR_PATH_LENGTH+1];
    szZMConfigsDir = configureZMConfigsDir();
    
    configureModName();
        
    initializeForwards();
    
    log(ZM_LOG_LEVEL_INFO, "=============DONE==============");
}

public plugin_cfg() {
#if defined ZM_DEBUG_MODE
    log(ZM_LOG_LEVEL_DEBUG, "Configuring plugin cfgs");
#endif
    new szZMConfigsDir[CONFIGS_DIR_PATH_LENGTH+1];
    zm_getConfigsDirPath(szZMConfigsDir, CONFIGS_DIR_PATH_LENGTH);
    createZMCfg(szZMConfigsDir);
    executeZMCfg(szZMConfigsDir);
}

configureLogFilePath() {
    if (g_szLogFilePath[0] != EOS) {
        return;
    }
    
#if defined ZM_DEBUG_MODE
    log(ZM_LOG_LEVEL_DEBUG, "Configuring ZM log file");
#endif

    new szTime[16];
    get_time("%Y-%m-%d", szTime, charsmax(szTime));
    formatex(g_szLogFilePath, LOG_PATH_LENGTH, "zombiemod_%s.log", szTime);
}

configureZMConfigsDir() {
#if defined ZM_DEBUG_MODE
    log(ZM_LOG_LEVEL_DEBUG, "Configuring ZM configs directory");
#endif
    
    new szZMConfigsDir[CONFIGS_DIR_PATH_LENGTH+1];
    zm_getConfigsDirPath(szZMConfigsDir, CONFIGS_DIR_PATH_LENGTH);
    if (dir_exists(szZMConfigsDir)) {
        return szZMConfigsDir;
    }
    
    log(ZM_LOG_LEVEL_INFO, "Creating ZM configs directory at '%s'...",
                           szZMConfigsDir);
    switch (mkdir(szZMConfigsDir)) {
        case -1: {
            new szErrorMessage[64];
            formatex(szErrorMessage,
                     charsmax(szErrorMessage),
                     "Failed to create ZM configs directory!");
            log(ZM_LOG_LEVEL_SEVERE, szErrorMessage);
            set_fail_state(szErrorMessage);
        }
        case 0: {
            log(ZM_LOG_LEVEL_INFO, "ZM configs directory successfully created");
        }
        default: {
            log(ZM_LOG_LEVEL_SEVERE, "Undefined return from mkdir");
            set_fail_state("mkdir has returned a value which is not supported!");
        }
    }
    
    return szZMConfigsDir;
}

createZMCfg(szZMConfigsDir[]) {
#if defined ZM_DEBUG_MODE
    log(ZM_LOG_LEVEL_DEBUG, "Checking for '%s'...", ZM_CFG_FILE);
#endif

    new szFileName[64];
    formatex(szFileName, charsmax(szFileName), "%s/%s",
                                               szZMConfigsDir,
                                               ZM_CFG_FILE);
    if (file_exists(szFileName)) {
        return;
    }
    
    log(ZM_LOG_LEVEL_INFO, "Could not find '%s'. Creating '%s'...",
                           ZM_CFG_FILE,
                           szFileName);
    new file = fopen(szFileName, "wt");
    fprintf(file, "; %s\n", ZM_NAME);
    fprintf(file, "; Version : %s (%s)\n", ZM_VERSION_STRING, __DATE__);
    fprintf(file, "; Author : Tirant\n");
    
    fprintf(file, "\n; Cvars :\n");
#if defined ZM_DEBUG_MODE
        log(ZM_LOG_LEVEL_DEBUG, "Reading cvars from '%s'...", ZM_NAME);
#endif
    fprintCvarsFromPlugin(file, get_plugin(-1));
    
    new extension[extension_t];
    for (new extId = 0; extId < g_numExtensions; extId++) {
        ArrayGetArray(g_extensionsList, extId, extension);
#if defined ZM_DEBUG_MODE
        log(ZM_LOG_LEVEL_DEBUG, "Reading cvars from '%s'...", extension[ext_Name]);
#endif
        fprintCvarsFromPlugin(file, extension[ext_PluginId]);
    }
    
    fclose(file);
}

fprintCvarsFromPlugin(file, forPluginId) {
    // This function call is O(n^2), however there is no easy alternative, and
    // this only needs to execute once, or at most, in the rare cases a CFG
    // needs to be generated.
    new numPluginCvars = get_plugins_cvarsnum();
    new name[32], flags, pluginId, pcvar, description[256];
    for (new i = 0; i < numPluginCvars; i++) {
        if (0 < i) {
            arrayset(name, EOS, charsmax(name));
            arrayset(description, EOS, charsmax(description));
        }
        
        get_plugins_cvar(i,
                         name,
                         charsmax(name),
                         flags,
                         pluginId,
                         pcvar,
                         description,
                         charsmax(description));
        if (pluginId != forPluginId) {
            continue;
        }
        
        if (pcvar == g_pcvar_version) {
            continue;
        }
        
        new value[32];
        get_pcvar_string(pcvar, value, charsmax(value));
#if defined ZM_DEBUG_MODE
        log(ZM_LOG_LEVEL_DEBUG, "Found %s = \"%s\"", name, value);
#endif
        fprintf(file, "%s \"%s\" ; %s\n", name, value, description);
    }
}

executeZMCfg(szZMConfigsDir[]) {
#if defined ZM_DEBUG_MODE
    log(ZM_LOG_LEVEL_DEBUG, "Executing %s/%s", szZMConfigsDir, ZM_CFG_FILE);
#endif
    
    server_cmd("exec %s/%s", szZMConfigsDir, ZM_CFG_FILE);
}

configureModName() {
    if (g_szModName[0] != EOS) {
        return;
    }
    
#if defined ZM_DEBUG_MODE
    log(ZM_LOG_LEVEL_DEBUG, "Configuring mod name");
#endif
        
    new length = copy(g_szModName, MOD_NAME_LENGTH, ZM_NAME);
    g_szModName[length++] = ' ';
    
    new Regex:regex = regex_match(ZM_VERSION_STRING, "^\\d+\\.\\d+");
    regex_substr(regex, 0, g_szModName[length], MOD_NAME_LENGTH-length);
    regex_free(regex);
    
#if defined ZM_DEBUG_MODE
    log(ZM_LOG_LEVEL_DEBUG, "Mod name configured as '%s'", g_szModName);
#endif
    
    register_forward(FM_GetGameDescription, "fw_getGameDescription");
}

initializeForwards() {
    g_fw[onExtensionRegistered] = CreateMultiForward("zm_onExtensionRegistered",
                                                     ET_IGNORE,
                                                     FP_CELL,
                                                     FP_STRING,
                                                     FP_STRING,
                                                     FP_STRING);
    fw_initializeStructs();
    fw_precache();
    fw_initialize();
}

fw_initializeStructs() {
#if defined ZM_DEBUG_MODE
    log(ZM_LOG_LEVEL_DEBUG, "zm_onInitStructs");
#endif
    
    g_fw[onInitStructs] = CreateMultiForward("zm_onInitStructs", ET_IGNORE);
    ExecuteForward(g_fw[onInitStructs], g_fw[fwReturn]);
    DestroyForward(g_fw[onInitStructs]);
    g_fw[onInitStructs] = 0;
}

fw_precache() {
#if defined ZM_DEBUG_MODE
    log(ZM_LOG_LEVEL_DEBUG, "zm_onPrecache");
#endif
    
    g_fw[onPrecache] = CreateMultiForward("zm_onPrecache", ET_IGNORE);
    ExecuteForward(g_fw[onPrecache], g_fw[fwReturn]);
    DestroyForward(g_fw[onPrecache]);
    g_fw[onPrecache] = 0;
}

fw_initialize() {
#if defined ZM_DEBUG_MODE
    log(ZM_LOG_LEVEL_DEBUG, "zm_onInit");
#endif

    g_fw[onInit] = CreateMultiForward("zm_onInit", ET_IGNORE);
    ExecuteForward(g_fw[onInit], g_fw[fwReturn]);
    DestroyForward(g_fw[onInit]);
    g_fw[onInit] = 0;
}

log(ZM_LOG_LEVEL:level, string[], any:...) {
    if (g_logLevel < level || level <= ZM_LOG_LEVEL_NONE) {
        return;
    }

    new length = 0;
    g_szLogBuffer[length++] = '[';
    length += copy(g_szLogBuffer[length],
                   LOG_BUFFER_LENGTH-length,
                   ZM_LOG_LEVEL_NAMES[any:level]);
    g_szLogBuffer[length++] = ']';
    g_szLogBuffer[length++] = ' ';
    length += vformat(g_szLogBuffer[length], LOG_BUFFER_LENGTH-length, string, 3);
    g_szLogBuffer[length] = EOS;
    log_to_file(g_szLogFilePath, g_szLogBuffer);
}

public fw_getGameDescription() {
    forward_return(FMV_STRING, g_szModName);
    return FMRES_SUPERCEDE;
}

/*******************************************************************************
Console Commands
*******************************************************************************/

public printVersion(id) {
    console_print(id, "Zombie Mod v%s", ZM_VERSION_STRING);
}

#if defined ZM_DEBUG_MODE
public printExtensions(id) {
    console_print(id, "Outputting extensions list...");
    
    new extension[extension_t];
    for (new i = 0; i < g_numExtensions; i++) {
        ArrayGetArray(g_extensionsList, i, extension);
        new szStatus[16];
        get_plugin(extension[ext_PluginId],
                   _,
                   _,
                   _,
                   _,
                   _,
                   _,
                   _,
                   _,
                   szStatus,
                   charsmax(szStatus));
        console_print(id, "%d. %s %s [%s]",
                          i+1,
                          extension[ext_Name],
                          extension[ext_Version],
                          szStatus);
    }
    
    console_print(id, "%d plugins loaded", g_numExtensions);
}
#endif

/*******************************************************************************
Natives
*******************************************************************************/

// native zm_log(ZM_LOG_LEVEL:level, const messageFmt[], any:...);
public _log(pluginId, numParams) {
    if (numParams < 2) {
        zm_paramError("zm_log",2,numParams);
        return;
    }
    
    static szBuffer[LOG_BUFFER_LENGTH+1];
    new length = vdformat(szBuffer, LOG_BUFFER_LENGTH, 2, 3);
    szBuffer[length] = EOS;
    log(ZM_LOG_LEVEL:get_param(1), szBuffer);
}

// native ZM_EXT:zm_registerExtension(const name[], const version[] = NULL_STRING, const description[] = NULL_STRING);
public ZM_EXT:_registerExtension(pluginId, numParams) {
    if (numParams != 3) {
        zm_paramError("zm_registerExtension",3,numParams);
        return Invalid_Extension;
    }
    
    if (g_extensionsList == Invalid_Array) {
        log_error(AMX_ERR_NATIVE, "Cannot register extensions yet!");
        return Invalid_Extension;
    }
    
    new extension[extension_t];
    extension[ext_PluginId] = pluginId;
    get_string(1, extension[ext_Name], ext_Name_length);
    if (extension[ext_Name][0] == EOS) {
        log_error(AMX_ERR_NATIVE, "Cannot register an extension with an empty name!");
        return Invalid_Extension;
    }
    
    get_string(2, extension[ext_Version], ext_Version_length);
    get_string(3, extension[ext_Desc], ext_Desc_length);
    
    new ZM_EXT:extId = ZM_EXT:(ArrayPushArray(g_extensionsList, extension)+1);
    g_numExtensions++;
    
#if defined ZM_DEBUG_MODE
    log(ZM_LOG_LEVEL_DEBUG, "Registered extension '%s' as %d",
                            extension[ext_Name],
                            extId);
#endif

    ExecuteForward(g_fw[onExtensionRegistered],
                   g_fw[fwReturn],
                   extId,
                   extension[ext_Name],
                   extension[ext_Version],
                   extension[ext_Desc]);
    return extId;
}

// native zm_getExtension(ZM_EXT:extId, extension[extension_t]);
public ZM_RET:_getExtension(pluginId, numParams) {
    if (numParams != 2) {
        zm_paramError("zm_getExtension",2,numParams);
        return ZM_RET_ERROR;
    }
    
    new ZM_EXT:extId = ZM_EXT:get_param(1);
    if (extId == Invalid_Extension) {
        log_error(AMX_ERR_NATIVE, "Invalid extension specified: Invalid_Extension");
        return ZM_RET_ERROR;
    } else if (g_numExtensions < any:extId) {
        log_error(AMX_ERR_NATIVE, "Invalid extension specified: %d", extId);
        return ZM_RET_ERROR;
    }
    
    new extension[extension_t];
    ArrayGetArray(g_extensionsList, any:extId-1, extension);
    set_array(2, extension, extension_t);
    return ZM_RET_SUCCESS;
}

// native zm_getNumExtensions();
public _getNumExtensions(pluginId, numParams) {
    if (numParams != 0) {
        zm_paramError("zm_getNumExtensions",0,numParams);
        return 0;
    }
    
    return g_numExtensions;
}