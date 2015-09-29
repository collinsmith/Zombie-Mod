#if defined _zm_lang_included
    #endinput
#endif
#define _zm_lang_included

/**
 * Name of the zombiemod dictionary file
 */
#define ZOMBIEMOD_TXT "zombiemod.txt"

/**
 * Long name of ZM (def: Zombie Mod)
 */
stock const ZM_NAME[] = "ZM_NAME";

/**
 * Short name of ZM (def: ZM)
 */
stock const ZM_NAME_SHORT[] = "ZM_NAME_SHORT";

/**
 * Copies the path to the zombie mod dictionary into the specified buffer.
 * 
 * @param dst Destination buffer
 * @param len Maximum number of bytes to copy (copies to {@code {@param len}-1})
 * 
 * @return number of bytes copied
 */
stock zm_getDictonaryPath(dst[], len = sizeof dst) {
    return getPath(dst, len, ZOMBIEMOD_TXT);
}