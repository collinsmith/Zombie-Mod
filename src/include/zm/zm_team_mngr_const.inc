#if defined _zm_team_mngr_const_included
    #endinput
#endif
#define _zm_team_mngr_const_included

/*******************************************************************************
 * CONSTANTS
 ******************************************************************************/

enum ZM_Team {
    ZM_TEAM_UNASSIGNED = CS_TEAM_UNASSIGNED,
    ZM_TEAM_ZOMBIE = CS_TEAM_T,
    ZM_TEAM_HUMAN = CS_TEAM_CT,
    ZM_TEAM_SPECTATOR = CS_TEAM_SPECTATOR,
}

enum ZM_State_Change {
    ZM_STATE_CHANGE_ERROR = -1,
    ZM_STATE_CHANGE_DID_NOT_CHANGE = 0,
    ZM_STATE_CHANGE_BLOCKED,
    ZM_STATE_CHANGE_CHANGED
};