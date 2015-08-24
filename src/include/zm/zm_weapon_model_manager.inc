#if defined _zm_weapon_model_manager_included
    #endinput
#endif
#define _zm_weapon_model_manager_included

#include "include/zm/inc/zm_modelmanager_const.inc"

/*******************************************************************************
 * FORWARDS
 ******************************************************************************/

forward zm_onModelRegistered(ZM_MODEL:mdl, model[model_t]);

/*******************************************************************************
 * NATIVES
 ******************************************************************************/

native ZM_MODEL:zm_registerModel(type, const model[]);
native ZM_MODEL:zm_registerPlayerModel(const model[]);
native ZM_MODEL:zm_registerWeaponModel(const model[]);

native zm_setPlayerModel(id, ZM_MODEL:mdl);
native zm_resetPlayerModel(id);

native zm_setWeaponModel(id, CSI:weapon, ZM_MODEL:mdl);
native zm_resetWeaponModel(id);