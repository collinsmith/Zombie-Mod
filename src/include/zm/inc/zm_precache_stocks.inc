#if defined _zm_precache_stocks_included
	#endinput
#endif
#define _zm_precache_stocks_included

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

/***************************************************************************************************
Stocks
***************************************************************************************************/

stock bool:zm_precachePlayerModel(model[]) {
	new temp[64];
	formatex(temp, 63, "models/player/%s/%s.mdl", model, model);
	return zm_precache(temp);
}

stock bool:zm_precacheModel(model[]) {
	if (file_exists(model)) {
		engfunc(EngFunc_PrecacheModel, model);
		return true;
	}
	
	return false;
}

stock bool:zm_precacheSound(sound[]) {
	new temp[64];
	formatex(temp, 63, "sound/%s", sound);
	return zm_precache(temp);
}

stock bool:zm_precache(file[]) {
	if (file_exists(file)) {
		engfunc(EngFunc_PrecacheGeneric, file);
		return true;
	}
	
	return false;
}