#define INITIAL_EXTENSIONS_SIZE 8

#include <amxmodx>
#include <logger>

#include "include\\zm\\zm_cfg.inc"
#include "include\\zm\\zm_lang.inc"
#include "include\\zm\\zm_version.inc"
#include "include\\zm\\template\\extension_t.inc"

#include "include\\stocks\\path_stocks.inc"
#include "include\\stocks\\dynamic_param_stocks.inc"

static Logger: g_Logger = Invalid_Logger;

#pragma unused g_pCvar_Version
static g_pCvar_Version;

static Array:g_extensionsList = Invalid_Array;
static g_numExtensions;

enum Forwards {
    fwReturn,
    onPrecache,
    onInit,
    onExtensionInit,
    onExtensionRegistered
}; static g_fw[Forwards] = { 0, INVALID_HANDLE, INVALID_HANDLE, INVALID_HANDLE, INVALID_HANDLE };

public plugin_natives() {
    register_library("zombiemod");

    register_native("zm_registerExtension", "_registerExtension", 0);
    register_native("zm_getExtension", "_getExtension", 0);
    register_native("zm_getNumExtensions", "_getNumExtensions", 0);
}

public plugin_precache() {
    register_plugin(ZM_NAME, ZM_VERSION_STRING, "Tirant");

    new buildId[32];
    zm_getBuildId(buildId);
    g_pCvar_Version = create_cvar(
            "zm_version",
            buildId,
            FCVAR_SPONLY,
            "The current version of Zombie Mod being used");

    g_Logger = LoggerCreate();
#if defined ZM_COMPILE_FOR_DEBUG
    LoggerSetVerbosity(g_Logger, Severity_Lowest);
    LoggerSetVerbosity(All_Loggers, Severity_Lowest);
#endif
    
    LoggerLogInfo(g_Logger, "Launching Zombie Mod v%s...", buildId);

    new dictionary[32];
    zm_getDictonaryPath(dictionary);
    register_dictionary(dictionary);
    LoggerLogDebug(g_Logger, "Registering dictionary file \"%s\"", dictionary);

    if (LoggerGetVerbosity(g_Logger) >= Severity_Debug) {
        new temp[256];
        zm_getDictonaryPath(temp);
        LoggerLogDebug(g_Logger, "ZOMBIEMOD_TXT=%s", temp);
        zm_getConfigsDirPath(temp);
        LoggerLogDebug(g_Logger, "ZM_CONFIGS_DIR=%s", temp);
        zm_getConfigsFilePath(temp);
        LoggerLogDebug(g_Logger, "ZM_CFG_FILE=%s", temp);
    }

    new zm_version[] = "zm.version";
    register_concmd(
            zm_version,
            "printVersion",
            _,
            "Prints the version info");
    LoggerLogDebug(g_Logger, "register_concmd \"%s\"", zm_version);

    new zm_exts[] = "zm.exts";
    register_concmd(
            zm_exts,
            "printExtensions",
            ADMIN_CFG,
            "Prints the list of registered extensions");
    LoggerLogDebug(g_Logger, "register_concmd \"%s\"", zm_exts);

    zm_onPrecache();
    zm_onInit();
    zm_onExtensionInit();
}

zm_onPrecache() {
    LoggerLogDebug(g_Logger, "Calling zm_onPrecache");
    g_fw[onPrecache] = CreateMultiForward("zm_onPrecache", ET_IGNORE);
    ExecuteForward(g_fw[onPrecache], g_fw[fwReturn]);
    DestroyForward(g_fw[onPrecache]);
    g_fw[onPrecache] = INVALID_HANDLE;
}

zm_onInit() {
    LoggerLogDebug(g_Logger, "Calling zm_onInit");
    g_fw[onInit] = CreateMultiForward("zm_onInit", ET_IGNORE);
    ExecuteForward(g_fw[onInit], g_fw[fwReturn]);
    DestroyForward(g_fw[onInit]);
    g_fw[onInit] = INVALID_HANDLE;
}

zm_onExtensionInit() {
    LoggerLogDebug(g_Logger, "Calling ");
    g_fw[onExtensionInit] = CreateMultiForward("zm_onExtensionInit", ET_IGNORE);
    ExecuteForward(g_fw[onExtensionInit], g_fw[fwReturn]);
    DestroyForward(g_fw[onExtensionInit]);
    g_fw[onExtensionInit] = INVALID_HANDLE;
}

/*******************************************************************************
 * Console Commands
 ******************************************************************************/

public printVersion(id) {
    new buildId[32];
    zm_getBuildId(buildId);
    console_print(id,
            "%L (%L) v%s",
            LANG_PLAYER, ZM_NAME,
            LANG_PLAYER, ZM_NAME_SHORT,
            buildId);
}

public printExtensions(id) {
    console_print(id, "Extensions registered:");
    
    if (g_extensionsList != Invalid_Array) {
        new extension[extension_t];
        for (new i = 0; i < g_numExtensions; i++) {
            ArrayGetArray(g_extensionsList, i, extension);
            new status[16];
            get_plugin(
                    .index = extension[ext_PluginId],
                    .status = status,
                    .len5 = charsmax(status));
            console_print(id,
                    "%d. %8.8s %8.8s %8.8s",
                    i+1,
                    extension[ext_Name],
                    extension[ext_Version],
                    status);
        }
    }
    
    console_print(id, "%d extensions registered.", g_numExtensions);
}

/*******************************************************************************
 * Natives
 ******************************************************************************/

// native ZM_Extension: zm_registerExtension(
//         const name[] = NULL_STRING,
//         const version[] = NULL_STRING,
//         const description[] = NULL_STRING);
public ZM_Extension: _registerExtension(pluginId, numParams) {
    if (!numParamsEqual(g_Logger, 3, numParams)) {
        return Invalid_Extension;
    }

    if (g_extensionsList == Invalid_Array) {
        g_extensionsList = ArrayCreate(extension_t, INITIAL_EXTENSIONS_SIZE);
        g_numExtensions = 0;
        LoggerLogDebug(g_Logger,
                "Initialized g_extensionsList as Array: %d",
                g_extensionsList);
    }

    new extension[extension_t];
    extension[ext_PluginId] = pluginId;
    get_string(1, extension[ext_Name], ext_Name_length);
    if (extension[ext_Name][0] == EOS) {
        get_plugin(
                .index = pluginId,
                .filename = extension[ext_Name],
                .len1 = ext_Name_length);
        extension[ext_Name][strlen(extension[ext_Name])-5] = EOS;
        LoggerLogDebug(g_Logger,
                "Empty extension name specified, using \"%s\"",
                extension[ext_Name]);
    }
    
    get_string(2, extension[ext_Version], ext_Version_length);
    get_string(3, extension[ext_Desc], ext_Desc_length);
    
    new ZM_Extension: extId
            = ZM_Extension:(ArrayPushArray(g_extensionsList, extension)+1);
    g_numExtensions++;
    
    LoggerLogDebug(g_Logger,
            "Registered extension \"%s\" as ZM_Extension: %d",
            extension[ext_Name],
            extId);

    if (g_fw[onExtensionRegistered] == INVALID_HANDLE) {
        LoggerLogDebug(g_Logger, "Creating forward zm_onExtensionRegistered");
        g_fw[onExtensionRegistered] = CreateMultiForward(
                "zm_onExtensionRegistered",
                ET_IGNORE,
                FP_CELL,
                FP_STRING,
                FP_STRING,
                FP_STRING);
        LoggerLogDebug(g_Logger,
                "g_fw[onExtensionRegistered] = %d",
                g_fw[onExtensionRegistered]);
    }

    LoggerLogDebug(g_Logger, "Calling zm_onExtensionRegistered");
    ExecuteForward(g_fw[onExtensionRegistered], g_fw[fwReturn],
            extId,
            extension[ext_Name],
            extension[ext_Version],
            extension[ext_Desc]);
    return extId;
}

// native zm_getExtension(ZM_Extension: extId, extension[extension_t]);
public _getExtension(pluginId, numParams) {
    if (!numParamsEqual(g_Logger, 2, numParams)) {
        return;
    }

    new ZM_Extension: extId = ZM_Extension:(get_param(1));
    if (extId == Invalid_Extension) {
        LoggerLogError(g_Logger,
                "Invalid extension specified: Invalid_Extension");
        return;
    } else if (g_numExtensions < any:(extId)) {
        LoggerLogError(g_Logger, "Invalid extension specified: %d", extId);
        return;
    }

    assert g_extensionsList != Invalid_Array;

    new extension[extension_t];
    ArrayGetArray(g_extensionsList, any:(extId)-1, extension);
    set_array(2, extension, extension_t);
}

// native zm_getNumExtensions();
public _getNumExtensions(pluginId, numParams) {
    if (!numParamsEqual(g_Logger, 1, numParams)) {
        return -1;
    }

    return g_numExtensions;
}