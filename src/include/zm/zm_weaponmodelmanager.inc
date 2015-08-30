#if defined _zm_weaponmodelmanager_included
    #endinput
#endif
#define _zm_weaponmodelmanager_included

#pragma reqlib zm_weaponmodelmanager

#include "include/zm/inc/templates/weaponmodel_t.inc"
#include "include/zm/inc/zm_weaponmodelmanager_const.inc"
#include "include/zm/zm_modelmanager.inc"

/*******************************************************************************
 * FORWARDS
 ******************************************************************************/

/**
 * Called when a weapon model is registered. This forward cannot be blocked.
 * 
 * @param model         Unique identifier created for the weapon model
 * @param weaponmodel   Array of size weaponmodel_t containing the data representing
 *                          the weapon model.
 */
forward zm_onWeaponModelRegistered(ZM_WEAPON_MODEL:model,
                                   weaponmodel[weaponmodel_t]);

/*******************************************************************************
 * NATIVES
 ******************************************************************************/

/**
 * Registers a model into the weapon model manager and model manager, and returns
 * the unique identifier for that model. Model names must me unique, i.e., each
 * name must correspond with a single path, and registering a second model using
 * the name of an already registered model will result in this native returning
 * the identifier for the registered model. Models should be registered on
 * {@link #zombiemod.zm_onPrecache()}. The paths for weapon models are determined
 * using their name, e.g., a model registered with the name "example" is assumed
 * to be located at "models/example.mdl". Additionally, it is common and valid to
 * specify a path to a model here, e.g., "knives/example" would then imply a model
 * located at "models/knives/example.mdl"
 * 
 * @example     new ZM_WEAPON_MODEL:model = zm_registerWeaponModel(ZM_KNIFE,
 *                                                                 "example");
 * @example     new ZM_WEAPON_MODEL:model = zm_registerWeaponModel(ZM_KNIFE,
 *                                                                 "knives/example");
 * 
 * @param wpn   Constant representing the cstrike weapon that this model applies
 *                  to. When the model is applied via {@link #zm_setWeaponModel(id,model)}
 * @param name  Name of the model (also used to represent path)
 * 
 * @return      Unique identifier created for this model or for the model which
 *              is already registered by this name, otherwise {@code Invalid_Weapon_Model}
 *              if an error occurred when registering.
 * 
 * @error       An error will be thrown if an empty name or path is specified,
 *              or if there was a problem precaching the model at the path e.g.,
 *              when the model does not exist. Errors can also be thrown when
 *              the underlying data structures for managing the models have not
 *              yet been initialized.
 * 
 * @see #zm_modelmanager.zm_registerModel(name[],path[])
 */
native ZM_WEAPON_MODEL:zm_registerWeaponModel(ZM_WEAPON:wpn, const name[]);

/**
 * Performs a lookup on a particular model name and returns the unique identifier
 * for that model.
 * 
 * @example     new ZM_WEAPON_MODEL:model = zm_getWeaponModelByName("example");
 * @example     if (zm_getWeaponModelByName("example") != Invalid_Weapon_Model) { ... }
 * 
 * @param name  Name of the model to look up
 * 
 * @return      Unique identifier for the model under the given name, otherwise
 *              {@code Invalid_Weapon_Model} if none was found.
 * 
 * @see #zm_isWeaponModelRegistered(%1)
 */
native ZM_WEAPON_MODEL:zm_getWeaponModelByName(const name[]);

/**
 * Sets a given weapon model on a specified player. This will automatically apply
 * to the weapon which was specified when the model was registered.
 * 
 * @param id    Player index on which to apply the model
 * @param model Unique identifier of the model to apply
 * 
 * @return      {@code ZM_RET_SUCCESS} if the operation was carried out successfully,
 *              otherwise {@code ZM_RET_ERROR}
 * 
 * @error       If an invalid weapon model is specified (typically {@code Invalid_Weapon_Model}),
 *              or if an invalid player is specified (e.g., if the user is not
 *              currently connected).
 * 
 * @see #zm_registerWeaponModel(wpn,name[])
 * @see #zm_resetWeaponModel(id,wpn)
 */
native ZM_RETURN:zm_setWeaponModel(id, ZM_WEAPON_MODEL:model);

/**
 * Resets a player to their default cstrike weapon model for a specified weapon.
 * 
 * @param id    Player index whose model to reset
 * @param wpn   Weapon constant for the weapon to reset
 * 
 * @return      {@code ZM_RET_SUCCESS} if the operation was carried out successfully,
 *              otherwise {@code ZM_RET_ERROR}
 * 
 * @error       If an invalid player is specified (e.g., if the user if not
 *              currently connected).
 * 
 * @see #zm_setWeaponModel(id,model)
 */
native ZM_RETURN:zm_resetWeaponModel(id, ZM_WEAPON:wpn);

/*******************************************************************************
 * MACROS
 ******************************************************************************/

/**
 * Returns whether or not a model has been registered under a specified name.
 * 
 * @param %1    Name of the model
 * 
 * @return      {@literal true} if it is, otherwise {@literal false}
 * 
 * @see #zm_getWeaponModelByName(name[])
 */
#define zm_isWeaponModelRegistered(%1)\
    (zm_getWeaponModelByName(%1) != Invalid_Weapon_Model)