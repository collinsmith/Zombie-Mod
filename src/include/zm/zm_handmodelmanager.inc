#if defined _zm_handmodelmanager_included
    #endinput
#endif
#define _zm_handmodelmanager_included

#include "include/zm/inc/templates/model_t.inc"

/*******************************************************************************
Forwards
*******************************************************************************/

/**
 * Called when a hand model is registered into ZM.
 * 
 * @param mdlId Model index of the hand model
 * @param model Array of size model_t to populate with hand model info
 */
forward zm_onHandModelRegistered(ZM_MDL:mdlId, model[model_t]);

/*******************************************************************************
Natives
*******************************************************************************/

/**
 * Registers and precaches a specified hand model into ZM. The hand model is
 * asserted to be located at cstrike/models/${hands}/${model}.mdl and will throw
 * an error if the model cannot be found.
 * 
 * @param model Hand model to register
 * 
 * @return      Hand model index created for the model, otherwise Invalid_Model
 *                  if an error occurred
 * 
 * @error       If the model cannot be found, or there was an error loading it.
 */
native ZM_MDL:zm_registerHandModel(const model[]);

/**
 * Retrieves the hand model index for the model by the given name.
 * 
 * @param model Hand model to search for
 * 
 * @return      Hand model index of the model, otherwise Invalid_Model if the
 *                  model is not registered
 */
native ZM_MDL:zm_getHandModelByName(const model[]);

/**
 * Applies the specified hand model index on a given player. Model indexes are
 * created when a model is registered using zm_registerHandModel, and can be
 * looked up if not cached using zm_getHandModelByName.
 * 
 * @param id    Player index to apply model on
 * @param model Hand model to apply
 * 
 * @error       If the model or player index is invalid
 */
native ZM_RET:zm_setHandModel(id, ZM_MDL:model);

/**
 * Resets the hand model for a specified player (i.e., changes to their default
 * knife model).
 * 
 * @param id    Player index to apply hand model on
 * 
 * @error       If the player index is invalid
 */
native ZM_RET:zm_resetHandModel(id);