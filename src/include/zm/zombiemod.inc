#if defined _zombiemod_included
    #endinput
#endif
#define _zombiemod_included

#pragma reqlib zombiemod

#include "include\\zm\\zm_cfg.inc"
#include "include\\zm\\zm_debug.inc"
#include "include\\zm\\zm_lang.inc"
#include "include\\zm\\zm_stocks.inc"
#include "include\\zm\\zm_version.inc"
#include "include\\zm\\template\\extension_t.inc"

/*******************************************************************************
 * FORWARDS
 ******************************************************************************/

/**
 * Called when resources are ready to be precached.
 *
 * @return ignored
 */
forward zm_onPrecache();

/**
 * Called after {@link #zm_onPrecache()}, when ZM is initialized. This is
 * intended to be used to register any data structures or variables.
 *
 * @return ignored
 */
forward zm_onInit();

/**
 * Called after {@link #zm_onInit()}. This forward is intended to be used to
 * register plugins which extend the functionality of ZM.
 *
 * @return ignored
 */
forward zm_onExtensionInit();

/**
 * Called when an extension is registered.
 * 
 * @note {@param extension} is the value which was returned when the extension
 *       was registered
 * 
 * @param extension Extension identifier of the extension
 * @param name      Name of the extension
 * @param desc      Brief description of the extension
 * @param version   Version string for the extension
 *
 * @return ignored
 */
forward zm_onExtensionRegistered(
        ZM_Extension: extension,
        const name[],
        const version[],
        const description[]);

/*******************************************************************************
 * NATIVES
 ******************************************************************************/

/**
 * Registers an extension into ZM with the specified name, description and
 * version. Extensions should be registered in an effort to maintain good
 * "house-keeping" of a server to keep track of plugins which rely on ZM.
 * Additionally, any CVars that are registered by these extensions will be
 * automatically added to the ZM CFG file when it is created. Extensions can
 * only be registered during {@link #zm_onExtensionInit()}.
 * 
 * @param name    Name of the extension, {@literal ""} for plugin file name
 * @param desc    Brief description of the extension
 * @param version Version string for the extension
 * 
 * @return ZM_Extension index which is created by the calling of this native
 *         or {@literal Invalid_Extension} if a problem occurred while
 *         registering.
 */
native ZM_Extension: zm_registerExtension(
        const name[] = NULL_STRING,
        const version[] = NULL_STRING,
        const description[] = NULL_STRING);

/**
 * Retrieves the metadata stored on a particular extension.
 * 
 * @param extId     ZM_Extension index of the extension
 * @param extension Array of size extension_t to populate with the metadata
 * 
 * @error if extId is invalid
 */
native zm_getExtension(ZM_Extension: extId, extension[extension_t]);

/**
 * Returns the number of extensions which have been registered with ZM.
 * 
 * @return number of extensions which have been registered
 */
native zm_getNumExtensions();