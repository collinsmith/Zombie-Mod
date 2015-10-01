#if defined _zm_team_mngr_included
    #endinput
#endif
#define _zm_team_mngr_included

#include "include\\zm\\zm_team_mngr_const.inc"

/*******************************************************************************
 * FORWARDS
 ******************************************************************************/

//...

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