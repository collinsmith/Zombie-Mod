#define PLUGIN_VERSION "0.0.1"

#include "include/zm/compiler_settings.inc"

#include <amxmodx>
#include <cstrike>

#include "include/zm/inc/templates/playermodel_t.inc"
#include "include/zm/inc/zm_precache_stocks.inc"
#include "include/zm/zombiemod.inc"
#include "include/zm/zm_teammanager.inc"
#include "include/zm/zm_modelmanager.inc"

#define DEFAULT_MODELS_NUM 8

enum _:FORWARDS_length {
    fwReturn = 0,
    onPlayerModelRegistered
};

static g_fw[FORWARDS_length];

static Array:g_modelList;
static Trie:g_modelTrie;
static g_numModels;

public plugin_natives() {
    register_library("zm_playermodelmanager");

    register_native("zm_registerPlayerModel", "_registerPlayerModel", 0);
    register_native("zm_getPlayerModelByName", "_getPlayerModelByName", 0);
    register_native("zm_setPlayerModel", "_setPlayerModel", 0);
    register_native("zm_resetPlayerModel", "_resetPlayerModel", 0);
}

public zm_onInitStructs() {
    g_modelList = ArrayCreate(model_t, DEFAULT_MODELS_NUM);
    g_modelTrie = TrieCreate();
    
    initializeForwards();
}

public zm_onPrecache() {
}

public zm_onInit() {
    zm_registerExtension("[ZM] Player Model Manager",
                         PLUGIN_VERSION,
                         "Manages player model resources");

#if defined ZM_DEBUG_MODE
    register_concmd("zm.models.player",
                    "printModels",
                    ADMIN_CFG,
                    "Prints the list of registered player models");
#endif
}

initializeForwards() {
#if defined ZM_DEBUG_MODE
    zm_log(ZM_LOG_LEVEL_DEBUG, "Initializing zm_playermodelmanager forwards");
#endif

    g_fw[onPlayerModelRegistered] = CreateMultiForward("zm_onPlayerModelRegistered",
                                                       ET_IGNORE,
                                                       FP_CELL,
                                                       FP_ARRAY);
}

ZM_PLAYER_MODEL:getRegisteredModel(name[]) {
    strtolower(name);
    new ZM_PLAYER_MODEL:mdlId;
    if (TrieGetCell(g_modelTrie, name, mdlId)) {
        return mdlId;
    }
    
    return Invalid_Player_Model;
}

/*******************************************************************************
 * Console Commands
 ******************************************************************************/

#if defined ZM_DEBUG_MODE
public printModels(id) {
    console_print(id, "Outputting player models list...");
    
    new model[model_t];
    new playermodel[playermodel_t];
    for (new i = 0; i < g_numModels; i++) {
        ArrayGetArray(g_modelList, i, playermodel);
        zm_getModel(playermodel[playermodel_Model], model);
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

// native ZM_PLAYER_MODEL:zm_registerPlayerModel(const name[]);
public ZM_PLAYER_MODEL:_registerPlayerModel(pluginId, numParams) {
    if (numParams != 2) {
        zm_paramError("zm_registerPlayerModel",1,numParams);
        return Invalid_Player_Model;
    }
    
    if (g_modelList == Invalid_Array || g_modelTrie == Invalid_Trie) {
        log_error(AMX_ERR_NATIVE, "Cannot register models yet!");
        return Invalid_Player_Model;
    }
    
    new model[model_t];
    get_string(1, model[model_Name], model_Name_length);
    zm_formatPlayerModelPath(model[model_Name],
                             model[model_Path],
                             model_Path_length);

    new ZM_MODEL:mdlId = zm_registerModel(model[model_Name], model[model_Path]);
    if (mdlId == Invalid_Model) {
        log_error(AMX_ERR_NATIVE, "Failed to register model for player model!");
        return Invalid_Player_Model;
    }

    new playermodel[playermodel_t];
    playermodel[playermodel_Model] = mdlId;

    // This check can be performed to copy back the created/existing model
    //zm_getModel(mdlId, model);

    new ZM_PLAYER_MODEL:playerModelId
            = ZM_PLAYER_MODEL:(ArrayPushArray(g_modelList, playermodel)+1);
    TrieSetCell(g_modelTrie, model[model_Name], playerModelId);
    g_numModels++;
    
#if defined ZM_DEBUG_MODE
    zm_log(ZM_LOG_LEVEL_DEBUG, "Registered player model '%s' as %d",
                               model[model_Name],
                               playerModelId);
#endif
    ExecuteForward(g_fw[onPlayerModelRegistered],
                   g_fw[fwReturn],
                   playerModelId,
                   PrepareArray(playermodel, playermodel_t));
    
    return playerModelId;
}

// native ZM_PLAYER_MODEL:zm_getPlayerModelByName(const name[]);
public ZM_PLAYER_MODEL:_getPlayerModelByName(pluginId, numParams) {
    if (numParams != 1) {
        zm_paramError("zm_getPlayerModelByName",1,numParams);
        return Invalid_Player_Model;
    }

    if (g_modelList == Invalid_Array || g_modelTrie == Invalid_Trie) {
        return Invalid_Player_Model;
    }

    new name[model_Name_length+1];
    get_string(1, name, model_Name_length);
    if (name[0] == EOS) {
        return Invalid_Player_Model;
    }
    
    return getRegisteredModel(name);
}

// native ZM_RETURN:zm_setPlayerModel(id, ZM_PLAYER_MODEL:model);
public ZM_RETURN:_setPlayerModel(pluginId, numParams) {
    if (numParams != 2) {
        zm_paramError("zm_setPlayerModel",2,numParams);
        return ZM_RET_ERROR;
    }

    new id = get_param(1);
    if (!zm_isUserConnected(id)) {
        log_error(AMX_ERR_NATIVE, "Invalid player specified: %d", id);
        return ZM_RET_ERROR;
    }

    new ZM_PLAYER_MODEL:playerModelId = ZM_PLAYER_MODEL:get_param(2);
    if (playerModelId == Invalid_Player_Model) {
        log_error(AMX_ERR_NATIVE, "Invalid player model specified: Invalid_Player_Model", playerModelId);
        return ZM_RET_ERROR;
    } else if (any:playerModelId < 0 || g_numModels < any:playerModelId) {
        log_error(AMX_ERR_NATIVE, "Invalid player model specified: %d", playerModelId);
        return ZM_RET_ERROR;
    }

    new playermodel[playermodel_t];
    ArrayGetArray(g_modelList, any:playerModelId-1, playermodel);
    
    new model[model_t];
    zm_getModel(playermodel[playermodel_Model], model);
    cs_set_user_model(id, model[model_Name]);
    return ZM_RET_SUCCESS;
}

// native ZM_RETURN:zm_resetPlayerModel(id);
public ZM_RETURN:_resetPlayerModel(pluginId, numParams) {
    if (numParams != 1) {
        zm_paramError("zm_resetPlayerModel",1,numParams);
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