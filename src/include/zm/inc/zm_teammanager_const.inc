#if defined _zm_teammanger_const_included
    #endinput
#endif
#define _zm_teammanger_const_included

/*******************************************************************************
Data/Definitions
*******************************************************************************/

/**
 * Represents the states that a player can be in.
 */
enum ZM_CHANGE_STATE {
    /**
     * Implies player is dead or otherwise cannot be changed
     */
    ZM_CHANGE_INVALID = 2000,
    
    /**
     * Implies that the player's state has been changed
     */
    ZM_CHANGED,
    
    /**
     * Implies that the player's state cannot be changed
     */
    ZM_CANNOT_CHANGE
};

/**
 * Constants used to represent the various teams.
 */
enum ZM_TEAM:ZM_TEAM_length {
    /**
     * Represents no team
     */
    ZM_TEAM_UNASSIGNED = 0,
    
    /**
     * Represents the zombie team
     */
    ZM_TEAM_ZOMBIE,
    
    /**
     * Represents the human team
     */
    ZM_TEAM_HUMAN,
    
    /**
     * Represents the spectators
     */
    ZM_TEAM_SPECTATOR
};