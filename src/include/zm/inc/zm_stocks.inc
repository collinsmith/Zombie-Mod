#if defined _zm_stocks_included
	#endinput
#endif
#define _zm_stocks_included

#include "include/zm/inc/zm_const.inc"

/*******************************************************************************
Stocks
*******************************************************************************/

/**
 * Copies the string representation for the path to configs directory of ZM.
 * 
 * @param string		String to copy the path into
 * @param length		Maximum length of the string
 * @return				Total number of characters copied
 */
stock zm_getConfigsDirPath(string[], length) {
	new curLength = get_configsdir(string, length);
	if (curLength < length) {
		string[curLength++] = '/';
	}
	
	return curLength+copy(string[curLength], length-curLength, ZM_CONFIGS_DIR);
}