#define PLUGIN_VERSION "0.0.1"

#include "include/zm/compiler_settings.inc"

#include <amxmodx>

#include "include/zm/inc/templates/model_t.inc"
#include "include/zm/inc/zm_precache_stocks.inc"
#include "include/zm/zombiemod.inc"

#define DEFAULT_MODELS_NUM 16

enum _:FORWARDS_length {
    fwReturn = 0,
    onModelRegistered
};

static g_fw[FORWARDS_length];

static Array:g_modelList;
static Trie:g_modelTrie;
static g_numModels;

public plugin_natives() {
    register_library("zm_modelmanager");

    register_native("zm_registerModel", "_registerModel", 0);
    register_native("zm_getModelByName", "_getModelByName", 0);
    register_native("zm_getModel", "_getModel", 0);
}

public zm_onInitStructs() {
    g_modelList = ArrayCreate(model_t, DEFAULT_MODELS_NUM);
    g_modelTrie = TrieCreate();
    
    initializeForwards();
}

public zm_onPrecache() {
}

public zm_onInit() {
    zm_registerExtension("[ZM] Model Manager",
                         PLUGIN_VERSION,
                         "Manages model resources");

#if defined ZM_DEBUG_MODE
    register_concmd("zm.models",
                    "printModels",
                    ADMIN_CFG,
                    "Prints the list of registered models");
#endif
}

initializeForwards() {
#if defined ZM_DEBUG_MODE
    zm_log(ZM_LOG_LEVEL_DEBUG, "Initializing zm_modelmanager forwards");
#endif

    g_fw[onModelRegistered] = CreateMultiForward("zm_onModelRegistered",
                                                 ET_IGNORE,
                                                 FP_CELL,
                                                 FP_ARRAY);
}

ZM_MODEL:getRegisteredModel(name[]) {
    strtolower(name);
    new ZM_MODEL:mdlId;
    if (TrieGetCell(g_modelTrie, name, mdlId)) {
        return mdlId;
    }
    
    return Invalid_Model;
}

/*******************************************************************************
 * Console Commands
 ******************************************************************************/

#if defined ZM_DEBUG_MODE
public printModels(id) {
    console_print(id, "Outputting models list...");
    
    new model[model_t];
    for (new i = 0; i < g_numModels; i++) {
        ArrayGetArray(g_modelList, i, model);
        console_print(id, "%d. %s [%s]",
                          i+1,
                          model[model_Name],
                          model[model_Path]);
    }
    
    console_print(id, "%d models registered", g_numModels);
}
#endif

/*******************************************************************************
 * Natives
 ******************************************************************************/

// native ZM_MODEL:zm_registerModel(const name[], const path[]);
public ZM_MODEL:_registerModel(pluginId, numParams) {
    if (numParams != 2) {
        zm_paramError("zm_registerModel",2,numParams);
        return Invalid_Model;
    }
    
    if (g_modelList == Invalid_Array || g_modelTrie == Invalid_Trie) {
        log_error(AMX_ERR_NATIVE, "Cannot register models yet!");
        return Invalid_Model;
    }
    
    new model[model_t];
    get_string(1, model[model_Name], model_Name_length);
    if (model[model_Name][0] == EOS) {
        log_error(AMX_ERR_NATIVE, "Cannot register a model with an empty name!");
        return Invalid_Model;
    }
    
    new ZM_MODEL:mdlId = getRegisteredModel(model[model_Name]);
    if (mdlId != Invalid_Model) {
        return mdlId;
    }
    
    get_string(2, model[model_Path], model_Path_length);
    if (!zm_precache(model[model_Path])) {
        log_error(AMX_ERR_NATIVE, "Failed to precache model: %s",
                                  model[model_Path]);
        return Invalid_Model;
    }
    
    mdlId = ZM_MODEL:(ArrayPushArray(g_modelList, model)+1);
    TrieSetCell(g_modelTrie, model[model_Name], mdlId);
    g_numModels++;
    
#if defined ZM_DEBUG_MODE
    zm_log(ZM_LOG_LEVEL_DEBUG, "Registered model '%s' as %d",
                               model[model_Name],
                               mdlId);
#endif
    ExecuteForward(g_fw[onModelRegistered],
                   g_fw[fwReturn],
                   mdlId,
                   PrepareArray(model, model_t));
    
    return mdlId;
}

// native ZM_MODEL:zm_getModelByName(const name[]);
public ZM_MODEL:_getModelByName(pluginId, numParams) {
    if (numParams != 1) {
        zm_paramError("zm_getModelByName",1,numParams);
        return Invalid_Model;
    }
    
    if (g_modelList == Invalid_Array || g_modelTrie == Invalid_Trie) {
        return Invalid_Model;
    }
    
    new name[model_Name_length+1];
    get_string(1, name, model_Name_length);
    if (name[0] == EOS) {
        return Invalid_Model;
    }
    
    return getRegisteredModel(name);
}

// native ZM_RETURN:zm_getModel(ZM_MODEL:model, copy[model_t]);
public ZM_RETURN:_getModel(pluginId, numParams) {
    if (numParams != 2) {
        zm_paramError("zm_getModel",2,numParams);
        return ZM_RET_ERROR;
    }

    new ZM_MODEL:model = ZM_MODEL:get_param(1);
    if (model == Invalid_Model) {
        log_error(AMX_ERR_NATIVE, "Invalid model specified: Invalid_Model", model);
        return ZM_RET_ERROR;
    } else if (any:model < 0 || g_numModels < any:model) {
        log_error(AMX_ERR_NATIVE, "Invalid model specified: %d", model);
        return ZM_RET_ERROR;
    }

    new copy[model_t];
    ArrayGetArray(g_modelList, any:model-1, copy);
    set_array(2, copy, model_t);
    return ZM_RET_SUCCESS;
}