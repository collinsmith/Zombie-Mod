#if defined _zombiemod_included
    #endinput
#endif
#define _zombiemod_included

#pragma reqlib zombiemod

#include "include/zm/inc/templates/extension_t.inc"
#include "include/zm/inc/zm_const.inc"
#include "include/zm/inc/zm_stocks.inc"
#include "include/zm/inc/zm_macros.inc"

/*******************************************************************************
 * Forwards
 ******************************************************************************/

/**
 * Called before the initialization of ZM. This forward is intended to be used
 * to initialize all data structures upon which other extensions may rely.
 */
forward zm_onInitStructs();

/**
 * Called after the data structures have been initialized. This forward is
 * intended to be used for precaching any resources.
 */
forward zm_onPrecache();

/**
 * Called after ZM has been initialized. This forward is intended to be used to
 * register plugins and perform other initializations that were not performed in
 * zm_fw_initStructs.
 */
forward zm_onInit();

/**
 * Called when an extension is registered.
 * 
 * @note extension  This is the value which was returned when the extension was
 *                      registered
 * 
 * @param extension Extension identifier of the extension
 * @param name      Name of the extension
 * @param desc      Brief description of the extension
 * @param version   Version string for the extension        
 */
forward zm_onExtensionRegistered(ZM_EXT:extension,
                                 const name[],
                                 const version[],
                                 const description[]);

/*******************************************************************************
 * Natives
 ******************************************************************************/

/**
 * Logs a message with the specified log level into the ZM log file if that log
 * level is within the scope of the server log level.
 * 
 * @param level         Log level of the message
 * @param messageFmt    The message to log
 * @param ...           params
 */
native zm_log(ZM_LOG_LEVEL:level, const message[], any:...);

/**
 * Registers an extension into ZM with the specified name, description and
 * version. Extensions should be registered in an effort to maintain good
 * "house-keeping" of a server to keep track of plugins which rely on ZM.
 * Additionally, any CVars that are registered by these extensions will be
 * automatically added to the CFG file when it is created. Extensions should be
 * registered within zm_onInit.
 * 
 * @param name      Name of the extension
 * @param desc      Brief description of the extension
 * @param version   Version string for the extension
 * 
 * @return          The ZM_EXT index which is created by the calling of this
 *                      native or ZM_EXT:Invalid_Extension if a problem occurred
 * 
 * @error           Throws an error if extensions cannot be registered at the
 *                      time of calling
 */
native ZM_EXT:zm_registerExtension(const name[],
                                   const version[] = NULL_STRING,
                                   const description[] = NULL_STRING);

/**
 * Retrieves the metadata stored on a particular extension.
 * 
 * @param extId     ZM_EXT index of the extension
 * @param extension Array of size extension_t to populate with the metadata
 * 
 * @return          ZM_RET_ERROR on errors, otherwise ZM_RET_SUCCESS on success
 * 
 * @error           Throws an error when extId is invalid
 */
native ZM_RET:zm_getExtension(ZM_EXT:extId, extension[extension_t]);

/**
 * Returns the number of extensions which have been registered with ZM.
 * 
 * @return The number of extensions which have been registered
 */
native zm_getNumExtensions();