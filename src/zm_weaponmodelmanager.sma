#define PLUGIN_VERSION "0.0.1"

#include "include/zm/compiler_settings.inc"

#include <amxmodx>
#include <cstrike>

#include "include/zm/inc/templates/weaponmodel_t.inc"
#include "include/zm/inc/zm_precache_stocks.inc"
#include "include/zm/zombiemod.inc"
#include "include/zm/zm_teammanager.inc"
#include "include/zm/zm_modelmanager.inc"

#define DEFAULT_MODELS_NUM 8

enum _:FORWARDS_length {
    fwReturn = 0,
    onWeaponModelRegistered
};

static g_fw[FORWARDS_length];

static Array:g_modelList;
static Trie:g_modelTrie;
static g_numModels;

public plugin_natives() {
    register_library("zm_weaponmodelmanager");

    register_native("zm_registerWeaponModel", "_registerWeaponModel", 0);
    register_native("zm_getWeaponModelByName", "_getWeaponModelByName", 0);
    register_native("zm_setWeaponModel", "_setWeaponModel", 0);
    register_native("zm_resetWeaponModel", "_resetWeaponModel", 0);
}

public zm_onInitStructs() {
    g_modelList = ArrayCreate(model_t, DEFAULT_MODELS_NUM);
    g_modelTrie = TrieCreate();
    
    initializeForwards();
}

public zm_onPrecache() {
}

public zm_onInit() {
    zm_registerExtension("[ZM] Weapon Model Manager",
                         PLUGIN_VERSION,
                         "Manages weapon model resources");

#if defined ZM_DEBUG_MODE
    register_concmd("zm.models.weapons",
                    "printModels",
                    ADMIN_CFG,
                    "Prints the list of registered weapon models");
#endif
}

initializeForwards() {
#if defined ZM_DEBUG_MODE
    zm_log(ZM_LOG_LEVEL_DEBUG, "Initializing zm_weaponmodelmanager forwards");
#endif

    g_fw[onWeaponModelRegistered] = CreateMultiForward("zm_onWeaponModelRegistered",
                                                       ET_IGNORE,
                                                       FP_CELL,
                                                       FP_ARRAY);
}

ZM_WEAPON_MODEL:getRegisteredModel(name[]) {
    strtolower(name);
    new ZM_WEAPON_MODEL:mdlId;
    if (TrieGetCell(g_modelTrie, name, mdlId)) {
        return mdlId;
    }
    
    return Invalid_Weapon_Model;
}

/*******************************************************************************
 * Console Commands
 ******************************************************************************/

#if defined ZM_DEBUG_MODE
public printModels(id) {
    console_print(id, "Outputting weapon models list...");
    
    new model[model_t];
    new weaponmodel[weaponmodel_t];
    for (new i = 0; i < g_numModels; i++) {
        ArrayGetArray(g_modelList, i, weaponmodel);
        zm_getModel(weaponmodel[weaponmodel_Model], model);
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

// native ZM_WEAPON_MODEL:zm_registerWeaponModel(ZM_WEAPON:wpn, const name[]);
public ZM_WEAPON_MODEL:_registerWeaponModel(pluginId, numParams) {
    if (numParams != 2) {
        zm_paramError("zm_registerWeaponModel",2,numParams);
        return Invalid_Weapon_Model;
    }
    
    if (g_modelList == Invalid_Array || g_modelTrie == Invalid_Trie) {
        log_error(AMX_ERR_NATIVE, "Cannot register models yet!");
        return Invalid_Weapon_Model;
    }
    
    new model[model_t];
    get_string(2, model[model_Name], model_Name_length);
    zm_formatModelPath(model[model_Name],
                       model[model_Path],
                       model_Path_length);

    new ZM_MODEL:mdlId = zm_registerModel(model[model_Name], model[model_Path]);
    if (mdlId == Invalid_Model) {
        log_error(AMX_ERR_NATIVE, "Failed to register model for weapon model!");
        return Invalid_Weapon_Model;
    }

    new weaponmodel[weaponmodel_t];
    weaponmodel[weaponmodel_Model] = mdlId;
    weaponmodel[weaponmodel_Weapon] = ZM_WEAPON:get_param(1);

    // This check can be performed to copy back the created/existing model
    //zm_getModel(mdlId, model);

    new ZM_WEAPON_MODEL:weaponModelId
            = ZM_WEAPON_MODEL:(ArrayPushArray(g_modelList, weaponmodel)+1);
    TrieSetCell(g_modelTrie, model[model_Name], weaponModelId);
    g_numModels++;
    
#if defined ZM_DEBUG_MODE
    zm_log(ZM_LOG_LEVEL_DEBUG, "Registered weapon model '%s' as %d",
                               model[model_Name],
                               weaponModelId);
#endif
    ExecuteForward(g_fw[onWeaponModelRegistered],
                   g_fw[fwReturn],
                   weaponModelId,
                   PrepareArray(weaponmodel, weaponmodel_t));
    
    return weaponModelId;
}

// native ZM_WEAPON_MODEL:zm_getWeaponModelByName(const name[]);
public ZM_WEAPON_MODEL:_getWeaponModelByName(pluginId, numParams) {
    if (numParams != 1) {
        zm_paramError("zm_getWeaponModelByName",1,numParams);
        return Invalid_Weapon_Model;
    }

    if (g_modelList == Invalid_Array || g_modelTrie == Invalid_Trie) {
        return Invalid_Weapon_Model;
    }

    new name[model_Name_length+1];
    get_string(1, name, model_Name_length);
    if (name[0] == EOS) {
        return Invalid_Weapon_Model;
    }
    
    return getRegisteredModel(name);
}

// native ZM_RETURN:zm_setWeaponModel(id, ZM_WEAPON_MODEL:model);
public ZM_RETURN:_setWeaponModel(pluginId, numParams) {
    if (numParams != 2) {
        zm_paramError("zm_setWeaponModel",2,numParams);
        return ZM_RET_ERROR;
    }

    new id = get_param(1);
    if (!zm_isUserConnected(id)) {
        log_error(AMX_ERR_NATIVE, "Invalid player specified: %d", id);
        return ZM_RET_ERROR;
    }

    new ZM_WEAPON_MODEL:weaponModelId = ZM_WEAPON_MODEL:get_param(2);
    if (weaponModelId == Invalid_Weapon_Model) {
        log_error(AMX_ERR_NATIVE, "Invalid weapon model specified: Invalid_Weapon_Model", weaponModelId);
        return ZM_RET_ERROR;
    } else if (any:weaponModelId < 0 || g_numModels < any:weaponModelId) {
        log_error(AMX_ERR_NATIVE, "Invalid weapon model specified: %d", weaponModelId);
        return ZM_RET_ERROR;
    }

    new weaponmodel[weaponmodel_t];
    ArrayGetArray(g_modelList, any:weaponModelId-1, weaponmodel);
    
    new model[model_t];
    zm_getModel(weaponmodel[weaponmodel_Model], model);
    //...
    return ZM_RET_SUCCESS;
}

// native ZM_RETURN:zm_resetWeaponModel(id, ZM_WEAPON:wpn);
public ZM_RETURN:_resetWeaponModel(pluginId, numParams) {
    if (numParams != 2) {
        zm_paramError("zm_resetWeaponModel",2,numParams);
        return ZM_RET_ERROR;
    }
    
    new id = get_param(1);
    if (!zm_isUserConnected(id)) {
        log_error(AMX_ERR_NATIVE, "Invalid player specified: %d", id);
        return ZM_RET_ERROR;
    }
    
    new ZM_WEAPON:wpn = ZM_WEAPON:get_param(2);
    //...
    return ZM_RET_SUCCESS;
}