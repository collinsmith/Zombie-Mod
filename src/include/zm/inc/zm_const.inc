#if defined _zm_const_included
	#endinput
#endif
#define _zm_const_included

/******************************************************************************************************************************
Data/Definitions
******************************************************************************************************************************/

/**
 * Defines the current version of ZM
 */
#define ZM_VERSION 1.0.0

/**
 * Defines the path of the ZM configs folder through amxmodx/configs/
 */
#define ZM_CONFIGS_DIR "zm"

/**
 * Defines the path of the ZM logs folder through amxmodx/logs/
 */
#define ZM_LOGS_DIR "zm"

/**
 * Defines the name of the ZM cfg file
 */
#define ZM_CFG_FILE "zombiemod.cfg"

/**
 * String representation for the name of ZM
 */
stock const ZM_NAME[] = "Zombie Mod";

/**
 * String representation for the short name of ZM
 */
stock const ZM_NAME_SHORT[] = "ZM";

/**
 * String representation of the version of ZM. This should match the value of the definition.
 */
stock const ZM_VERSION_STRING[] = "1.0.0";

/**
 * Definition to permit the ZM_RETURN tag in place of the ZM_RET tag.
 */
#define ZM_RETURN: ZM_RET:

/**
 * Represents the return values for ZM extensions
 */
enum ZM_RET:ZM_RETURN_length {
	/**
	 * Implies operation should continue
	 */
	ZM_RET_CONTINUE = 1000,
	
	/**
	 * Implies operation should be blocked
	 */
	ZM_RET_BLOCK,
	
	/**
	 * Implies that the operation was a success
	 */
	ZM_RET_SUCCESS,
	
	/**
	 * Implies there was some kind of error
	 */
	ZM_RET_ERROR
};

/**
 * Represents the various log levels used when logging messages.
 */
enum ZM_LOG_LEVEL:ZM_LOG_LEVEL_length {
	/**
	 * Represents the level where no messages are logged. This is not a valid value for logging
	 * messages.
	 */
	ZM_LOG_LEVEL_NONE = 0,
	
	/**
	 * Represents the level where severe messages are logged and the plugin cannot recover.
	 */
	ZM_LOG_LEVEL_SEVERE,
	
	/**
	 * Represents the level where warning messages are logged. These messages should be addressed.
	 */
	ZM_LOG_LEVEL_WARN,
	
	/**
	 * Represents the level where informational messages are logged.
	 */
	ZM_LOG_LEVEL_INFO,
	
	/**
	 * Represents the level where debugging messages are logged. This should not be enabled unless
	 * debugging.
	 */
	ZM_LOG_LEVEL_DEBUG
};