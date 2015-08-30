#if defined _zm_modelmanager_included
    #endinput
#endif
#define _zm_modelmanager_included

#pragma reqlib zm_modelmanager

#include "include/zm/inc/templates/model_t.inc"

/*******************************************************************************
 * FORWARDS
 ******************************************************************************/

/**
 * Called when a model is registered. This forward cannot be blocked.
 * 
 * @param mdl   Unique identifier created for the model
 * @param model Array of size model_t containing the data representing the model
 */
forward zm_onModelRegistered(ZM_MODEL:mdl, model[model_t]);

/*******************************************************************************
 * NATIVES
 ******************************************************************************/

/**
 * Registers a model into the model manager and returns the unique identifier
 * for that model. Model names must me unique, i.e., each name must correspond
 * with a single path, and registering a second model using the name of an
 * already registered model will result in this native returning the identifier
 * for the registered model. Models should be registered on
 * {@link #zombiemod.zm_onPrecache()}.
 * 
 * @example     new ZM_MODEL:model = zm_registerModel("example",
 *                                                    "models/example.mdl");
 * 
 * @param name  Name of the model
 * @param path  Path to the model
 * 
 * @return      Unique identifier created for this model or for the model which
 *              is already registered by this name, otherwise {@code Invalid_Model}
 *              if an error occurred when registering.
 * 
 * @error       An error will be thrown if an empty name or path is specified,
 *              or if there was a problem precaching the model at the path e.g.,
 *              when the model does not exist. Errors can also be thrown when
 *              the underlying data structures for managing the models have not
 *              yet been initialized.
 */
native ZM_MODEL:zm_registerModel(const name[], const path[]);

/**
 * Performs a lookup on a particular model name and returns the unique identifier
 * for that model.
 * 
 * @example     new ZM_MODEL:model = zm_getModelByName("example");
 * @example     if (zm_getModelByName("example") != Invalid_Model) { ... }
 * 
 * @param name  Name of the model to look up
 * 
 * @return      Unique identifier for the model under the given name, otherwise
 *              {@code Invalid_Model} if none was found.
 * 
 * @see #zm_isModelRegistered(%1)
 */
native ZM_MODEL:zm_getModelByName(const name[]);

/**
 * Copies the data representing the specified model into the specified array of
 * size model_t.
 * 
 * @example     new copy[model_t];
 *              zm_getModel(model, copy);
 * 
 * @param model Unique identifier of the model
 * @param copy  Array of size model_t to copy the model's data into
 * 
 * @return      {@code ZM_RET_SUCCESS} if the operation was carried out successfully,
 *              otherwise {@code ZM_RET_ERROR}
 * 
 * @error       If an invalid model is specified (typically {@code Invalid_Model}).
 */
native ZM_RETURN:zm_getModel(ZM_MODEL:model, copy[model_t]);

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
 * @see #zm_getModelByName(name[])
 */
#define zm_isModelRegistered(%1)\
    (zm_getModelByName(%1) != Invalid_Model)