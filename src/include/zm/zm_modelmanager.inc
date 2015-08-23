#if defined _modelmanager_included
    #endinput
#endif
#define _modelmanager_included

#pragma reqlib zm_modelmanager

#include "include/zm/inc/templates/model_t.inc"

/*******************************************************************************
Forwards
*******************************************************************************/

/**
 * Called when a model is registered into ZM.
 * 
 * @param mdlId Model index of the model
 * @param model Array of size model_t to populate with model info
 */
forward zm_onModelRegistered(ZM_MDL:mdlId, model[model_t]);

/*******************************************************************************
Natives
*******************************************************************************/

/**
 * Registers and precaches a specified player model into ZM. The player model is
 * asserted to be located at cstrike/models/player/${model}/${model}.mdl and
 * will throw an error if the model cannot be found.
 * 
 * @param model Model to register
 * 
 * @return      Model index created for the model, otherwise Invalid_Model if an
 *                  error occurred
 * 
 * @error       If the model cannot be found, or there was an error loading it.
 */
native ZM_MDL:zm_registerModel(const model[]);

/**
 * Retrieves the model index for the model by the given name.
 * 
 * @param model Model to search for
 * 
 * @return      Model index of the model, otherwise Invalid_Model if the
 *                  model is not registered
 */
native ZM_MDL:zm_getModelByName(const model[]);

/**
 * Applies the specified model index on a given player. Model indexes are
 * created when a model is registered using zm_registerModel, and can be looked
 * up if not cached using zm_getModelByName.
 * 
 * @param id    Player index to apply model on
 * @param model Model to apply
 * 
 * @error       If the model or player index is invalid
 */
native ZM_RET:zm_setModel(id, ZM_MDL:model);

/**
 * Resets the model for a specified player (i.e., changes to their default
 * model).
 * 
 * @param id    Player index to apply model on
 * 
 * @error       If the player index is invalid
 */
native ZM_RET:zm_resetModel(id);