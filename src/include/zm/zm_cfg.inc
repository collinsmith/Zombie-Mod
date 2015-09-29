#if defined _zm_cfg_included
    #endinput
#endif
#define _zm_cfg_included

#include <amxmisc>
#include "include\\stocks\\path_stocks.inc"

/**
 * Defines the name of ZM. This value is used in places before the lang is
 * registered. Typically, only {@link zm_cfg::#ZM_NAME} need be used.
 */
#define ZM_MOD_NAME "Zombie Mod"

/**
 * Defines the path of the ZM configs folder through amxmodx/configs/
 */
#define ZM_CONFIGS_DIR "zm"

/**
 * Defines the name of the ZM cfg file
 */
#define ZM_CFG_FILE "zombiemod.cfg"

/**
 * Copies the ZM configs directory into the specified array.
 * 
 * @param dst Destination array to copy into
 * @param len Maximum number of bytes to copy (will zero-terminate
 *                {@code len-1})
 * 
 * @return number of bytes copied
 */
stock zm_getConfigsDirPath(dst[], len = sizeof dst) {
    new tempLen = get_localinfo("amxx_configsdir", dst, len);
    tempLen += formatex(dst[tempLen], len-tempLen-1, "%c", PATH_SEPARATOR);
    tempLen += getPath(dst[tempLen], len-tempLen, ZM_CONFIGS_DIR);
    fixPathAndMkdir(dst, tempLen);
    return tempLen;
}

/**
 * Copies the ZM configs file path into the specified array.
 * 
 * @param dst Destination array to copy into
 * @param len Maximum number of bytes to copy (will zero-terminate
 *                {@code len-1})
 * 
 * @return number of bytes copied
 */
stock zm_getConfigsFilePath(dst[], len = sizeof dst) {
    new tempLen = zm_getConfigsDirPath(dst, len);
    tempLen += formatex(dst[tempLen], len-tempLen-1, "%c", PATH_SEPARATOR);
    tempLen += getPath(dst[tempLen], len-tempLen, ZM_CFG_FILE);
    fixPathAndMkdir(dst, tempLen);
    return tempLen;
}