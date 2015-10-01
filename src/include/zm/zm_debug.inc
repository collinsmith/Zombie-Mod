#if defined _zm_debug_included
    #endinput
#endif
#define _zm_debug_included

/**
 * Enables whether or not to compile in debug mode. Compiling in debug mode will
 * enable many additional commands and features that are not required for
 * standard use.
 */
#define ZM_COMPILE_FOR_DEBUG

/*******************************************************************************
 * CONSTANTS
 ******************************************************************************/

stock const TRUE[] = "true";
stock const FALSE[] = "false";
stock const NULL[] = "null";
stock const ZOMBIE[] = "zombie";
stock const HUMAN[] = "human";

/*******************************************************************************
 * STOCKS
 ******************************************************************************/

/**
 * Returns whether or not ZM was compiled in debug mode.
 * 
 * @return {@literal true} if ZM was compiled for debug mode, otherwise
 *         {@literal false}
 */
stock bool: zm_isDebugMode() {
#if defined ZM_COMPILE_FOR_DEBUG
    return true;
#else
    return false;
#endif
}