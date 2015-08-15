#if defined _bitflags_included
	#endinput
#endif
#define _bitflags_included

/**
* Gets whether or not a given player has the specified flag set. Note that this implementation
* will return the actual value of the flag, and not a boolean value. If a boolean value is needed,
* use isFlagSet instead.
* 
* @param %1	flag
* @param %2	player index
* 
* @see isFlagSet
*/
#define getFlag(%1,%2)\
	(%1 & (1<<(%2&(cellbits-1))))

/**
* Sets a specified flag to 1 for a given player.
* 
* @param %1	flag
* @param %2	player index
*/
#define setFlag(%1,%2)\
	(%1 |= (1<<(%2&(cellbits-1))))

/**
* Unsets a specified flag to 0 for a given player.
* 
* @param %1	flag
* @param %2	player index
*/
#define unsetFlag(%1,%2)\
	(%1 &= ~(1<<(%2&(cellbits-1))))

/**
* Toggles a specified flag from 1 to 0, or 0 to 1, for a given player.
* 
* @param %1	flag
* @param %2	player index
*/
#define toggleFlag(%1,%2)\
	(%1 ^= (1<<(%2&(cellbits-1))))

/**
* Checks whether or not a given bit is set for any integer variable.
* 
* @param %1	flag
* @param %2	player index
* 
* @see getFlag
*/
#define isFlagSet(%1,%2)\
	(getFlag(%1,%2) != 0)