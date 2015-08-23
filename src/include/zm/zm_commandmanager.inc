#if defined _commandmanager_included
	#endinput
#endif
#define _commandmanager_included

#pragma reqlib zm_commandmanger

#include "inc\\templates\\command_t.inc"

/***************************************************************************************************
Forwards
***************************************************************************************************/

/**
 * Called before a command is processed. Returning ZM_RET_BLOCK will prevent the command from being
 * executed.
 *
 * @note command	This is the value that was returned when the command was registered. It can also
 *					be found by using zm_getCommandByName(command[])
 *
 * @param id		Player index forwarding this event
 * @param command	Command that is being executed
 */
forward zm_onBeforeCommand(id, ZM_CMD:command);

/**
 * Called when a command is being processed.
 * 
 * @note command	This is the value that was returned when the command was registered. It can also
 *					be found by using zm_getCommandByName(command[])
 *
 * @param id		Player index forwarding this event
 * @param command	Command that is being executed
 */
forward zm_onCommand(id, ZM_CMD:command);

/**
 * Called when a command is registered.
 * 
 * @note flags:	a - Execute only on say all
 *				b - Execute only on say_team
 *				c - Execute only if zombie
 *				d - Execute only if human
 *				e - Execute only if alive
 *				f - Execute only if dead
 * 
 * @param cmdId			Command identifier of command
 * @param command		Name of the command, which when typed will call the specified handle
 * @param handle		Name of the PUBLIC function to be executed when the command is entered
 * @param flags			Flags describing the conditions under which the command will be executed
 * @param description	Brief description of the purpose for the command
 * @param adminFlags	AMXX user flags required to use the command
 */
forward zm_onCommandRegistered(ZM_CMD:cmdId, const command[], const handle[], const flags[], const description[], const adminFlags);

/**
 * Called when the set of command prefix symbols has changed.
 * 
 * @param oldValue		Old prefix symbols
 * @param newValue		New prefix symbols
 */
forward zm_onPrefixesChanged(const oldValue[], const newValue[]);

/**
 * Called when commands can be registered. This is not strictly enforced, however it is encouraged
 * that commands/aliases be registered during this event.
 */
forward zm_onRegisterCommands();

/***************************************************************************************************
Natives
***************************************************************************************************/

/**
 * Registers a command into the ZM command manager.  Commands are designed to have a many-to-one
 * relationship to handles, so once a handle is registered, aliases for that command can be created
 * by using the same handle again, and the flags and description will not change.
 *
 * Example:
 * 		To register a new command with 2 aliases
 *			zm_registerCommand("mycommand1", "forwardMyCommand", "abcdef", "An example command");
 *			zm_registerCommand("mycommand2", "forwardMyCommand");
 * 		Additionally, you can also use the zm_registerCommandAlias variant.
 *
 * @note flags:	a - Execute only on say all
 *				b - Execute only on say_team
 *				c - Execute only if zombie
 *				d - Execute only if human
 *				e - Execute only if alive
 *				f - Execute only if dead
 *
 * @param command		Name of the command, which when typed will call the specified handle
 * @param handle		Name of the PUBLIC function to be executed when the command is entered
 * @param flags			Flags describing the conditions under which the command will be executed
 * @param description	Brief description of the purpose for the command
 * @param adminFlags	AMXX user flags required to use the command
 * @return				The command identifier created, or Invalid_Command if there was a problem
 * 							registering
 */
native ZM_CMD:zm_registerCommand(const command[], const handle[], const flags[] = "abcdef", const description[] = "", const adminFlags = ADMIN_ALL);

/**
 * Registers an additional alias for the specified command.
 * 
 * @param command		Command identifier to create an alias for
 * @param alias			Alias to add for the command
 * @return				The handle identifier for the command (will be the same as passed command
 * 							parameter)
 */
native ZM_CMD:zm_registerCommandAlias(ZM_CMD:command, const alias[]);

/**
 * Retrieves the command identifier that the command/alias is tied to.
 *
 * @param command		Command/alias to search for.  This would be a command used in-game, such as
 * 							"cmdlist" or "commands"
 * @return				The command identifier for the command with the specified command/alias, or
 * 							Invalid_Command if one was found
 */
native zm_getCommandByName(const command[]);