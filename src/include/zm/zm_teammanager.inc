#if defined _teammanager_included
	#endinput
#endif
#define _teammanager_included

#pragma reqlib zm_teammanager

#include "inc\\zm_teammanager_const.inc"

/***************************************************************************************************
Forwards
***************************************************************************************************/

/**
 * Called when a player's state changes to the following: infected, cured, or spawned
 * 
 * @param id			Player index calling event
 * @param isZombie		True if they are a zombie, otherwise false
 */
forward zm_onRefresh(id, bool:isZombie);

/**
 * Called when a player is about to be infected and change into a zombie. Returning ZM_RET_BLOCK
 * will block the infection if it is blockable.
 * 
 * @param id			Player index being infected
 * @param infector		Player index infecting, -1 if no player (e.g., another extension)
 * @param blockable		True if returning ZM_RET_BLOCK will block this event, otherwise false
 */
forward zm_onBeforeInfected(id, infector, bool:blockable);

/**
 * Called when a player is going to be infected. This call cannot be blocked.
 * 
 * @param id			Player index being infected
 * @param infector		Player index infecting, -1 if no player (e.g., another extension)
 */
forward zm_onInfected(id, infector);

/**
 * Called when a player has been infected and is now a zombie.
 * 
 * @param id			Player index infected
 * @param infector		Player index infecting, -1 if no player (e.g., another extension)
 */
forward zm_onAfterInfected(id, infector);

/**
 * Called when a player is about to be cured and change into a human. Returning ZM_RET_BLOCK will
 * block the cure if it is blockable.
 * 
 * @param id			Player index being cured
 * @param curer			Player index curing, -1 if no player (e.g., another extension)
 * @param blockable		True if returning ZM_RET_BLOCK will block this event, otherwise false
 */
forward zm_onBeforeCured(id, curer, bool:blockable);

/**
 * Called when a player is going to be cured. This call cannot be blocked.
 * 
 * @param id			Player index being cured
 * @param curer			Player index curing, -1 if no player (e.g., another extension)
 */
forward zm_onCured(id, curer);

/**
 * Called when a player has been cured and is now a human.
 * 
 * @param id			Player index cured
 * @param curer			Player index curing, -1 if no player (e.g., another extension)
 */
forward zm_onAfterCured(id, curer);

/**
 * Called when a player spawns.
 * 
 * @param id			Player index spawning
 * @param isZombie		True if the player is a zombie, otherwise false
 */
forward zm_onPlayerSpawn(id, bool:isZombie);

/**
 * Called when a player is killed.
 * 
 * @param killer		Player index who killed the victim
 * @param victim		Player index of dead player
 */
forward zm_onPlayerDeath(killer, victim);

/**
 * Called when a player uses the change team command and is blocked.
 * 
 * @note				This is primarily meant to be used to trigger
 * 						the menu to open.
 * 
 * @param id			Player index who tried to change teams
 */
forward zm_onTeamChangeBlocked(id);

/***************************************************************************************************
Natives
***************************************************************************************************/

/**
 * Respawns a specified player.
 * 
 * @param id			Player index to respawn
 * @param force			True to respawn the user, otherwise only respawn the user only if they are
 * 							dead.
 * 
 * @return				ZM_RET_ERROR when an error has occurred, otherwise ZM_RET_SUCCESS when the
 * 							operation was carried out successfully.
 */
native ZM_RET:zm_respawnUser(id, bool:force = false);

/**
 * Infects a player and attempts to turn them into a zombie.
 * 
 * @param id			Player index to infect
 * @param infector		Player index infecting the above player, -1 for no player
 * @param blockable		True to make this native blockable by other extentions, otherwise false
 * 
 * @return				ZM_CHANGE_INVALID	Implies player is dead or otherwise cannot be changed
 * 						ZM_CHANGED			Implies that the player's state has been changed
 * 						ZM_CANNOT_CHANGE	Implies that the player's state cannot be changed
 */
native ZM_CHANGE_STATE:zm_infectUser(id, infector = -1, bool:blockable = true);

/**
 * Cures a player and attempts to turn them into a human.
 * 
 * @param id			Player index to cure
 * @param curer			Player index curing the above player, -1 for no player
 * @param blockable		True to make this native blockable by other extentions, otherwise false
 * 
 * @return				ZM_CHANGE_INVALID	Implies player is dead or otherwise cannot be changed
 * 						ZM_CHANGED			Implies that the player's state has been changed
 * 						ZM_CANNOT_CHANGE	Implies that the player's state cannot be changed
 */
native ZM_CHANGE_STATE:zm_cureUser(id, curer = -1, bool:blockable = true);

/**
 * Retrieves whether or not a player is currently connected.
 * 
 * @param id			Player index to check
 * 
 * @return				True if the player is connected, otherwise false
 */
native bool:zm_isUserConnected(id);

/**
 * Retrieves whether or not a player is currently alive.
 * 
 * @param id			Player index to check
 * 
 * @return				True if the player is alive, otherwise false
 */
native bool:zm_isUserAlive(id);

/**
 * Retrieves whether or not a player is currently a zombie.
 * 
 * @param id			Player index to check
 * 
 * @return				True if the player is a zombie, otherwise false
 */
native bool:zm_isUserZombie(id);

/**
 * Retrieves whether or not a player is currently a human.
 * 
 * @param id			Player index to check
 * 
 * @return				True if the player is a human, otherwise false
 */
native bool:zm_isUserHuman(id);

/**
 * Checks if a player is on the correct team and then fixes their
 * team if it needs to be changed.
 * 
 * @param id			Player index whose infection to fix
 * 
 * @return				ZM_RET_ERROR when an error has occurred, otherwise ZM_RET_SUCCESS when the
 * 							operation was carried out successfully.
 */
native ZM_RET:zm_fixInfection(id);