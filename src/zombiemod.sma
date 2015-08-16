#include "include\zm\compiler_settings.inc"

#include <amxmodx>
#include <amxmisc>
#include <cvar_util>
#include <fakemeta>
#include <regex>

#include "include\zm\inc\templates\extension_t.inc"
#include "include\zm\inc\zm_const.inc"
#include "include\zm\inc\zm_stocks.inc"
#include "include\zm\inc\zm_macros.inc"

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

public plugin_natives() {
	register_library("zombiemod");
	
	register_native("zm_log", "_log", 0);
	
	register_native("zm_registerExtension", "_registerExtension", 0);
	register_native("zm_getExtensionsList", "_getExtensionsList", 0);
	register_native("zm_getNumExtensions", "_getNumExtensions", 0);
}

public plugin_precache() {
	register_plugin(ZM_NAME, ZM_VERSION_STRING, "Tirant");
	
	new cvarVersion = CvarRegister("zm_version", ZM_VERSION_STRING, "The current version of Zombie Mod being used", FCVAR_SPONLY);
	CvarLockValue(cvarVersion, ZM_VERSION_STRING);
	
	new szDefaultLogLevel[2];
	num_to_str(any:ZM_LOG_LEVEL_DEBUG, szDefaultLogLevel, 1);
	new cvarLogLevel = CvarRegister(
		.name = "zm_logLevel",
		.string = szDefaultLogLevel,
		.description = "Log level to use, 0-NONE/1-SEVERE/2-WARN/3-INFO/4-DEBUG",
		.flags = FCVAR_SPONLY,
		.hasMin = true,
		.minValue = 0.0,
		.hasMax = true,
		.maxValue = 4.0,
		.forceInterval = true);
	CvarCache(cvarLogLevel, CvarType_Int, g_logLevel);
	
	configureLogFilePath();
	
	log(ZM_LOG_LEVEL_INFO, "================================");
	log(ZM_LOG_LEVEL_INFO, "Launching Zombie Mod v%s...", ZM_VERSION_STRING);
	
#if defined ZM_DEBUG_MODE
	log(ZM_LOG_LEVEL_INFO, "Compiled in DEBUG mode");
#endif
	
	g_extensionsList = ArrayCreate(extension_t, 16);
	g_numExtensions = 0;
	
	register_concmd("zm.version", "printVersion", _, "Prints the version info");
	
#if defined ZM_DEBUG_MODE
	register_concmd("zm.exts", "printExtensions", ADMIN_CFG, "Prints the list of registered extensions");
#endif
	
	new szZMConfigsDir[CONFIGS_DIR_PATH_LENGTH+1];
	szZMConfigsDir = configureZMConfigsDir();
	createZMCfg(szZMConfigsDir);
	executeZMCfg(szZMConfigsDir);	
	configureModName();
		
	initializeForwards();
	
	log(ZM_LOG_LEVEL_INFO, "=============DONE==============");
}

configureLogFilePath() {
	if (g_szLogFilePath[0] != EOS) {
		return;
	}
	
#if defined ZM_DEBUG_MODE
	log(ZM_LOG_LEVEL_DEBUG, "Configuring zm log file");
#endif

	new szTime[16];
	get_time("%Y-%m-%d", szTime, 15);
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
	
	log(ZM_LOG_LEVEL_INFO, "Creating ZM configs directory at '%s'...", szZMConfigsDir);
	switch (mkdir(szZMConfigsDir)) {
		case -1: {
			new szErrorMessage[64];
			formatex(szErrorMessage, 63, "Failed to create ZM configs directory!");
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
	formatex(szFileName, 63, "%s/%s", szZMConfigsDir, ZM_CFG_FILE);
	if (file_exists(szFileName)) {
		return;
	}
	
	log(ZM_LOG_LEVEL_INFO, "Could not find '%s'. Creating '%s'...", ZM_CFG_FILE, szFileName);
	new file = fopen(szFileName, "wt");
	fprintf(file, "; %s\n", ZM_NAME);
	fprintf(file, "; Version : %s\n", ZM_VERSION_STRING);
	fprintf(file, "; Author : Tirant\n");
	// TODO: Write file contents with CVARs and commands list
	fclose(file);
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
	g_fw[onExtensionRegistered] = CreateMultiForward("zm_onExtensionRegistered", ET_IGNORE, FP_CELL, FP_STRING, FP_STRING, FP_STRING);
	fw_initializeStructs();
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
	length += copy(g_szLogBuffer[length], LOG_BUFFER_LENGTH-length, ZM_LOG_LEVEL_NAMES[any:level]);
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

/***************************************************************************************************
Console Commands
***************************************************************************************************/

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
		get_plugin(extension[ext_PluginId], _, _, _, _, _, _, _, _, szStatus, 15);
		console_print(id, "%d. %s %s [%s]", i+1, extension[ext_Name], extension[ext_Version], szStatus);
	}
	
	console_print(id, "%d plugins loaded", g_numExtensions);
}
#endif

/***************************************************************************************************
Natives
***************************************************************************************************/

// native zm_log(ZM_LOG_LEVEL:level, const messageFmt[], any:...);
public _log(pluginId, numParams) {
	if (numParams < 2) {
		zm_paramError("zm_log",2,numParams);
		return;
	}
	
	// I am seeing an issue using this code. In the meantime I am going to just use the code from
	// the method directly instead of introducing another buffer
	/*new length = vdformat(g_szLogBuffer, LOG_BUFFER_LENGTH, 2, 3);
	g_szLogBuffer[length] = EOS;
	log(ZM_LOG_LEVEL:get_param(1), g_szLogBuffer);*/
	new ZM_LOG_LEVEL:level = ZM_LOG_LEVEL:get_param(1);
	if (g_logLevel < level || level <= ZM_LOG_LEVEL_NONE) {
		return;
	}

	new length = 0;
	g_szLogBuffer[length++] = '[';
	length += copy(g_szLogBuffer[length], LOG_BUFFER_LENGTH-length, ZM_LOG_LEVEL_NAMES[any:level]);
	g_szLogBuffer[length++] = ']';
	g_szLogBuffer[length++] = ' ';
	length += vdformat(g_szLogBuffer[length], LOG_BUFFER_LENGTH, 2, 3);
	g_szLogBuffer[length] = EOS;
	log_to_file(g_szLogFilePath, g_szLogBuffer);
}

// native ZM_EXT:zm_registerExtension(const name[], const version[] = "", const description[] = "");
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
	get_string(1, extension[ext_Name], ext_Name_length);
	get_string(2, extension[ext_Version], ext_Version_length);
	get_string(3, extension[ext_Desc], ext_Desc_length);
	
	new ZM_EXT:extId = ZM_EXT:ArrayPushArray(g_extensionsList, extension);
	g_numExtensions++;
	
#if defined ZM_DEBUG_MODE
	log(ZM_LOG_LEVEL_DEBUG, "Registered extension: %s", extension[ext_Name]);
#endif

	ExecuteForward(g_fw[onExtensionRegistered], g_fw[fwReturn], extId, extension[ext_Name], extension[ext_Version], extension[ext_Desc]);
	return extId;
}

// native Array:zm_getExtensionsList();
public Array:_getExtensionsList(pluginId, numParams) {
	if (numParams != 0) {
		zm_paramError("zm_getExtensionsList",0,numParams);
		return Invalid_Array;
	}
	
	if (g_extensionsList == Invalid_Array) {
		return Invalid_Array;
	}
	
	return ArrayClone(g_extensionsList);
}

// native zm_getNumExtensions();
public _getNumExtensions(pluginId, numParams) {
	if (numParams != 0) {
		zm_paramError("zm_getNumExtensions",0,numParams);
		return 0;
	}
	
	return g_numExtensions;
}