#if defined _zm_team_mngr_included
    #endinput
#endif
#define _zm_team_mngr_included

#pragma reqlib zm_team_mngr

#include "include\\zm\\zm_team_mngr_const.inc"

/*******************************************************************************
 * FORWARDS
 ******************************************************************************/

forward zm_onSpawn(const id, const bool: isZombie);
forward zm_onKilled(const killer, const victim);
forward zm_onBeforeInfected(const id, const infector, const bool: blockable);
forward zm_onInfected(const id, const infector);
forward zm_onAfterInfected(const id, const infector);
forward zm_onBeforeCured(const id, const curor, const bool: blockable);
forward zm_onCured(const id, const curor);
forward zm_onAfterCured(const id, const curor);
forward zm_onApply(const id, const bool: isZombie);

/*******************************************************************************
 * NATIVES
 ******************************************************************************/

native bool: zm_isUserConnected(const id);
native bool: zm_isUserAlive(const id);
native bool: zm_isUserZombie(const id);

native bool: zm_respawn(const id, const bool: force = false);

native ZM_State_Change: zm_infect(
        const id,
        const infector = -1,
        const bool: blockable = true);

native ZM_State_Change: zm_cure(
        const id,
        const curor = -1,
        const bool: blockable = true);

/*******************************************************************************
 * STOCKS
 ******************************************************************************/

stock bool: zm_isUserHuman(const id) {
    return !zm_isUserZombie(id);
}