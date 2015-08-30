#if defined _zm_playermodelmanager_included
    #endinput
#endif
#define _zm_playermodelmanager_included

#pragma reqlib zm_playermodelmanager

#include "include/zm/inc/templates/playermodel_t.inc"
#include "include/zm/zm_modelmanager.inc"

/*******************************************************************************
 * FORWARDS
 ******************************************************************************/

/**
 * Called when a player model is registered. This forward cannot be blocked.
 * 
 * @param model         Unique identifier created for the player model
 * @param playermodel   Array of size playermodel_t containing the data representing
 *                          the player model.
 */
forward zm_onPlayerModelRegistered(ZM_PLAYER_MODEL:model,
                                   playermodel[playermodel_t]);

/*******************************************************************************
 * NATIVES
 ******************************************************************************/

/**
 * Registers a model into the player model manager and model manager, and returns
 * the unique identifier for that model. Model names must me unique, i.e., each
 * name must correspond with a single path, and registering a second model using
 * the name of an already registered model will result in this native returning
 * the identifier for the registered model. Models should be registered on
 * {@link #zombiemod.zm_onPrecache()}. The paths for player models are determined
 * using their name, e.g., a model registered with the name "example" is assumed
 * to be located at "models/player/example/example.mdl".
 * 
 * @example     new ZM_PLAYER_MODEL:model = zm_registerPlayerModel("example");
 * 
 * @param name  Name of the model (file)
 * 
 * @return      Unique identifier created for this model or for the model which
 *              is already registered by this name, otherwise {@code Invalid_Player_Model}
 *              if an error occurred when registering.
 * 
 * @error       An error will be thrown if an empty name or path is specified,
 *              or if there was a problem precaching the model at the path e.g.,
 *              when the model does not exist. Errors can also be thrown when
 *              the underlying data structures for managing the models have not
 *              yet been initialized.
 * 
 * @see #zm_modelmanager.zm_registerModel(name[], path[])
 */
native ZM_PLAYER_MODEL:zm_registerPlayerModel(const name[]);

/**
 * Performs a lookup on a particular model name and returns the unique identifier
 * for that model.
 * 
 * @example     new ZM_PLAYER_MODEL:model = zm_getPlayerModelByName("example");
 * @example     if (zm_getPlayerModelByName("example") != Invalid_Player_Model) { ... }
 * 
 * @param name  Name of the model to look up
 * 
 * @return      Unique identifier for the model under the given name, otherwise
 *              {@code Invalid_Player_Model} if none was found.
 * 
 * @see #zm_isPlayerModelRegistered(%1)
 */
native ZM_PLAYER_MODEL:zm_getPlayerModelByName(const name[]);

/**
 * Sets a given player model on a specified player.
 * 
 * @param id    Player index on which to apply the model
 * @param model Unique identifier of the model to apply
 * 
 * @return      {@code ZM_RET_SUCCESS} if the operation was carried out successfully,
 *              otherwise {@code ZM_RET_ERROR}
 * 
 * @error       If an invalid player model is specified (typically {@code Invalid_Player_Model}),
 *              or if an invalid player is specified (e.g., if the user is not
 *              currently connected).
 * 
 * @see #zm_registerPlayerModel(name[])
 * @see #zm_resetPlayerModel(id)
 */
native ZM_RETURN:zm_setPlayerModel(id, ZM_PLAYER_MODEL:model);

/**
 * Resets a player to their default cstrike model.
 * 
 * @param id    Player index whose model to reset
 * 
 * @return      {@code ZM_RET_SUCCESS} if the operation was carried out successfully,
 *              otherwise {@code ZM_RET_ERROR}
 * 
 * @error       If an invalid player is specified (e.g., if the user if not
 *              currently connected).
 * 
 * @see #zm_setPlayerModel(id,model)
 */
native ZM_RETURN:zm_resetPlayerModel(id);

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
 * @see #zm_getPlayerModelByName(name[])
 */
#define zm_isPlayerModelRegistered(%1)\
    (zm_getPlayerModelByName(%1) != Invalid_Player_Model)