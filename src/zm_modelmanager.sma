#define PLUGIN_VERSION "0.0.1"

#include "include\zm\compiler_settings.inc"

#include <amxmodx>
#include <amxmisc>
#include <cstrike>

#include "include\zm\inc\templates\model_t.inc"
#include "include\zm\inc\zm_precache_stocks.inc"
#include "include\zm\zombiemod.inc"
#include "include\zm\zm_teammanager.inc"

#define command_Prefix_length 1

enum _:FORWARDS_length {
	fwReturn = 0,
	onModelRegistered
};

static g_fw[FORWARDS_length];

static Array:g_modelList;
static Trie:g_modelTrie;
static g_numModels;

static g_tempModel[model_t];

public plugin_natives() {
	register_library("zm_modelmanager");

	register_native("zm_registerModel", "_registerModel", 0);
	register_native("zm_getModelByName", "_getModelByName", 0);
	register_native("zm_setModel", "_setModel", 0);
	register_native("zm_resetModel", "_resetModel", 0);
}

public zm_onInitStructs() {
	g_modelList = ArrayCreate(model_t, 8);
	g_modelTrie = TrieCreate();
	
	initializeForwards();
}

public zm_onPrecache() {
}

public zm_onInit() {
	zm_registerExtension("[ZM] Model Manager", PLUGIN_VERSION, "Manages player model resources");
}

initializeForwards() {
#if defined ZM_DEBUG_MODE
	zm_log(ZM_LOG_LEVEL_DEBUG, "Initializing zm_modelmanager forwards");
#endif

	g_fw[onModelRegistered]	= CreateMultiForward("zm_onModelRegistered", ET_IGNORE, FP_CELL, FP_ARRAY);
}

ZM_MDL:getRegisteredModel(model[]) {
	strtolower(model);
	new ZM_MDL:mdlId;
	if (TrieGetCell(g_modelTrie, model, mdlId)) {
		return mdlId;
	}
	
	return Invalid_Model;
}

/***************************************************************************************************
Natives
***************************************************************************************************/

// native ZM_MDL:zm_registerModel(const model[]);
public ZM_MDL:_registerModel(pluginId, numParams) {
	if (numParams != 1) {
		zm_paramError("zm_registerModel",1,numParams);
		return Invalid_Model;
	}
	
	if (g_modelList == Invalid_Array || g_modelTrie == Invalid_Trie) {
		log_error(AMX_ERR_NATIVE, "Cannot register models yet!");
		return Invalid_Model;
	}
	
	get_string(1, g_tempModel[model_Name], model_Name_length);
	if (g_tempModel[model_Name][0] == EOS) {
		log_error(AMX_ERR_NATIVE, "Cannot register a model with an empty name!");
		return Invalid_Model;
	}
	
	new ZM_MDL:mdlId = getRegisteredModel(g_tempModel[model_Name]);
	if (mdlId != Invalid_Model) {
		return mdlId;
	}
	
	if (!zm_precachePlayerModel(g_tempModel[model_Name])) {
		log_error(AMX_ERR_NATIVE, "Failed to precache model: %s", g_tempModel[model_Name]);
		return Invalid_Model;
	}
	
	mdlId = ZM_MDL:(ArrayPushArray(g_modelList, g_tempModel)+1);
	TrieSetCell(g_modelTrie, g_tempModel[model_Name], mdlId);
	g_numModels++;
	
#if defined ZM_DEBUG_MODE
	zm_log(ZM_LOG_LEVEL_DEBUG, "Registered model '%s' as %d", g_tempModel[model_Name], mdlId);
#endif
	ExecuteForward(g_fw[onModelRegistered], g_fw[fwReturn], mdlId, PrepareArray(g_tempModel, model_t));
	
	return mdlId;
}

// native ZM_MDL:zm_getModelByName(const model[]);
public ZM_MDL:_getModelByName(pluginId, numParams) {
	if (numParams != 1) {
		zm_paramError("zm_getModelByName",1,numParams);
		return Invalid_Model;
	}
	
	if (g_modelList == Invalid_Array || g_modelTrie == Invalid_Trie) {
		return Invalid_Model;
	}
	
	new model[model_Name_length+1];
	get_string(1, model, model_Name_length);
	if (model[0] == EOS) {
		return Invalid_Model;
	}
	
	return getRegisteredModel(model);
}

// native ZM_RET:zm_setModel(id, ZM_MDL:model);
public ZM_RET:_setModel(pluginId, numParams) {
	if (numParams != 2) {
		zm_paramError("zm_setModel",2,numParams);
		return ZM_RET_ERROR;
	}
	
	new id = get_param(1);
	if (!zm_isUserConnected(id)) {
		log_error(AMX_ERR_NATIVE, "Invalid player specified: %d", id);
		return ZM_RET_ERROR;
	}
	
	new ZM_MDL:model = ZM_MDL:get_param(2);
	if (model == Invalid_Model) {
		log_error(AMX_ERR_NATIVE, "Invalid model specified: Invalid_Model", model);
		return ZM_RET_ERROR;
	} else if (g_numModels < any:model) {
		log_error(AMX_ERR_NATIVE, "Invalid model specified: %d", model);
		return ZM_RET_ERROR;
	}
	
	ArrayGetArray(g_modelList, any:model-1, g_tempModel);
	cs_set_user_model(id, g_tempModel[model_Name]);
	return ZM_RET_SUCCESS;
}

// native ZM_RET:zm_resetModel(id);
public ZM_RET:_resetModel(pluginId, numParams) {
	if (numParams != 1) {
		zm_paramError("zm_resetModel",1,numParams);
		return ZM_RET_ERROR;
	}
	
	new id = get_param(1);
	if (!zm_isUserConnected(id)) {
		log_error(AMX_ERR_NATIVE, "Invalid player specified: %d", id);
		return ZM_RET_ERROR;
	}
	
	cs_reset_user_model(id);
	return ZM_RET_SUCCESS;
}