#if defined _compiler_settings_included
	#endinput
#endif
#define _compiler_settings_included

#pragma semicolon 1
#pragma ctrlchar '\'

/**
 * Enables whether or not to compile in debug mode. Compiling in debug mode will enable many
 * additional commands and log messages that are not needed for standard use.
 */
#define ZM_DEBUG_MODE

/**
 * Defines the number of players to compile for. Smaller server can decrease this value as they see
 * fit to try and save some memory, but the internal implementation is already highly optimized in
 * most cases.
 */
#define MAX_PLAYERS 32