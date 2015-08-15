#if defined _zm_macros_included
	#endinput
#endif
#define _zm_macros_included

/***************************************************************************************************
Macros
***************************************************************************************************/

/**
 * Macro to play a given sound to a specified player (or all players).
 * 
 * @param %1		Player index to play sound to, 0 to play to all players
 * @param %2		Path of the sound file to play
 */
#define zm_playSound(%1,%2)\
	client_cmd(%1,"spk %s",%2)

/**
 * Macro to throw an error stating that %1 parameters were expected, but %d parameters were found.
 * 
 * @param %1		Number of parameters expected
 * @param %2		Number of parameters found
 */
#define zm_paramError(%1,%2)\
	log_error(AMX_ERR_PARAMS,"Expected %d parameters,found %d",%1,%2)
	
/**
 * Macro to test whether or not a given player index is valid (i.e., id elementof [1,32]).
 * 
 * @param %1		Player index to test
 */
#define zm_isValidPlayerId(%1)\
	(1<=%1&&%1<=32)