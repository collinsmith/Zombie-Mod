#if defined _zm_version_included
    #endinput
#endif
#define _zm_version_included

/**
 * Defines the current version of ZM represented as an integer.
 */
#define ZM_VERSION 1

/**
 * Defines the string representation of the version of ZM.
 */
#define ZM_VERSION_STRING "1.0.0"

/**
 * Returns the current version id (integer representation).
 * 
 * @return current version id of ZM.
 */
stock zm_getVersionId() {
    return ZM_VERSION;
}

/**
 * Populates a given array with the string representation for the version of
 * ZM.
 * 
 * @param buildId String to populate
 * @param len     Maximum number of bytes to copy (will copy up to len-1)
 * 
 * @return number of bytes copied
 */
stock zm_getVersion(version[], len = sizeof version) {
    return copy(version, len - 1, ZM_VERSION_STRING);
}

/**
 * Populates a given array with the string representation for the build id for
 * the current build of ZM.
 * 
 * @param buildId String to populate
 * @param len     Maximum number of bytes to copy (will copy up to len-1)
 * 
 * @return number of bytes copied
 */
stock zm_getBuildId(buildId[], len = sizeof buildId) {
#if defined ZM_COMPILE_FOR_DEBUG
    return formatex(buildId, len - 1, "%s [%s] [DEBUG]", ZM_VERSION_STRING, __DATE__);
#else
    return formatex(buildId, len - 1, "%s [%s]", ZM_VERSION_STRING, __DATE__);
#endif
}