#if defined _zm_precache_stocks_included
	#endinput
#endif
#define _zm_precache_stocks_included

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#include "include/zm/inc/templates/model_t.inc"

/*******************************************************************************
 * Stocks
 ******************************************************************************/

/**
 * Formats the path for a player model.
 * 
 * @param model     Name of the player model file without the extension. This
 *                      file is assumed to be located at:
 *                      "models/player/${model}/${model}.mdl"
 * @param copy      Array to populate with the path of the model (see above
 *                      path)
 * @param length    Number of cells in the copy array that the path can fill
 * 
 * @return          The number of cells copied.
 */
stock zm_formatPlayerModelPath(model[], path[], length) {
    return formatex(path, length, "models/player/%s/%s.mdl", model, model);
}

/**
 * Formats the path for a model.
 * 
 * @param model     Name of the model file without the extension. This file is
 *                      assumed to be located at "models/${model}.mdl". Model
 *                      can be specified as a subpath, e.g.,
 *                      "zm/hands/v_classic" would equate to the file named
 *                      "models/zm/hands/v_classic.mdl"
 * @param copy      Array to populate with the path of the model (see above
 *                      path)
 * @param length    Number of cells in the copy array that the path can fill
 * 
 * @return          The number of cells copied.
 */
stock zm_formatModelPath(model[], path[], length) {
    return formatex(path, length, "models/%s.mdl", model);
}

/**
 * Precaches a given model. Models should begin with "models/", and typical
 * names can be formatted using zm_formatPlayerModelPath and zm_formatModelPath
 * for player and other models respectively.
 * 
 * @param model     Path of the model
 * 
 * @return          True if the model exists and was precached, otherwise false
 */
stock bool:zm_precacheModel(model[]) {
	if (file_exists(model)) {
		engfunc(EngFunc_PrecacheModel, model);
		return true;
	}
	
	return false;
}

/**
 * Precaches a given sound file. Sounds are assumed to be located within the
 * sound directory (i.e., "sound/${sound}").
 * 
 * @param sound     Path of the sound
 * 
 * @return          True if the sound was precached, otherwise false
 */
stock bool:zm_precacheSound(sound[]) {
	new temp[64];
	formatex(temp, 63, "sound/%s", sound);
	return zm_precache(temp);
}

/**
 * Precaches a given file.
 * 
 * @param file      Path of the file
 * 
 * @return          True if the file exists and was precached, otherwise false
 */
stock bool:zm_precache(file[]) {
	if (file_exists(file)) {
		engfunc(EngFunc_PrecacheGeneric, file);
		return true;
	}
	
	return false;
}