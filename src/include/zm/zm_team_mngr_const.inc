#if defined _zm_team_mngr_const_included
    #endinput
#endif
#define _zm_team_mngr_const_included

/*******************************************************************************
 * CONSTANTS
 ******************************************************************************/

enum ZM_Team {
    ZM_TEAM_UNASSIGNED = 0,
    ZM_TEAM_ZOMBIE = 1,
    ZM_TEAM_HUMAN = 2,
    ZM_TEAM_SPECTATOR = 3,
}

enum ZM_State_Change {
    ZM_STATE_CHANGE_ERROR = -1,
    ZM_STATE_CHANGE_DID_NOT_CHANGE = 0,
    ZM_STATE_CHANGE_BLOCKED,
    ZM_STATE_CHANGE_CHANGED
};