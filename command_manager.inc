#if defined _command_manager_included
    #endinput
#endif
#define _command_manager_included

#tryinclude <alias_t>
#tryinclude "include\\commandmanager\\alias_t.inc"
#tryinclude "include\\commandmanager-inc\\alias_t.inc"

#tryinclude <command_t>
#tryinclude "include\\commandmanager\\command_t.inc"
#tryinclude "include\\commandmanager-inc\\command_t.inc"

#tryinclude <command_manager_const>
#tryinclude "include\\commandmanager\\command_manager_const.inc"
#tryinclude "include\\commandmanager-inc\\command_manager_const.inc"

#pragma reqlib command_manager

/*******************************************************************************
 * FORWARDS
 ******************************************************************************/

/**
 * Called just before a command is called (i.e., when a command has been found
 * valid and other plugins are given an opportunity to reject it for some
 * outlying reason which can be set with {@link #cmd_setError}).
 *
 * @param id      Player index who entered the command
 * @param prefix  Character which prefixed the command (e.g.,
                      '/' would be the value if "/command" were the command)
 * @param command Unique identifier of the command
 *
 * @return {@literal PLUGIN_HANDLED} to block the command, otherwise {@literal
 *         PLUGIN_CONTINUE}. Note: If command is blocked, a reason should be
 *         specified using {@link #cmd_setError}
 */
forward cmd_onBeforeCommand(const id, const prefix, const Command: command);

/**
 * Called after a command has been processed (i.e., after the command is valid
 * and no plugin blocked it within its {@link #cmd_onBeforeCommand} forward)
 *
 * @param id      Player index who entered the command
 * @param prefix  Character which prefixed the command (e.g.,
                      '/' would be the value if "/command" were the command)
 * @param command Unique identifier of the command
 *
 * @return ignored
 */
forward cmd_onCommand(const id, const prefix, const Command: command);

/**
 * Called after a command has been registered.
 *
 * @param command    Unique identifier of the command
 * @param alias      Alias the command was registered with (i.e., text following
 *                       a prefix, which when typed triggers {@param command}
 * @param flags      Flags which represent which conditions must be met for the
 *                       command to be considered valid (i.e., player states)
 * @param desc       Brief description of the command
 * @param adminFlags Flags representing the admin level required by the command
 *
 * @return ignored
 */
forward cmd_onCommandRegistered(
        const Command: command,
        const alias[],
        const flags[],
        const desc[],
        const adminFlags);

/**
 * Called after command prefixes have been modified.
 *
 * @param oldValue String where each character was previously a prefix
 * @param newValue String where each character is a prefix now
 * 
 * @return ignored
 */
forward cmd_onPrefixesChanged(const oldValue[], const newValue[]);

/*******************************************************************************
 * NATIVES
 ******************************************************************************/

/**
 * Sets the error string for a command if it has been blocked using
 * {@link #cmd_onBeforeCommand}.
 * 
 * @param error Message to give as a reason to the player why the command was
 *              rejected.
 *
 * @error when called outside of {@link #cmd_onBeforeCommand} forward event
 */
native cmd_setError(const error[]);

/**
 * Registers a new command with a default alias. The handle of the command will
 * be called with the following params if specified conditions are met and
 * another plugin doesn't block it:
 *     id     Player index triggering the command 
 *     player Target player index if specified, {@literal 0} if no or multiple
 *                players are found by the name given, e.g.,
 *                    {@code /slay "Player"} will attempt to automatically parse
 *                    the arguments ({@literal "Player"}) and return the index
 *                    of the player named {@literal "Player"} using
 *                    {@link amxmisc.inc::#cmd_target}
 *     args   Message trailing the command alias, e.g.,
 *                {@code /slap "Player" 10} would return {@literal "Player" 10}
 *                with {@param player} set to the player index of the player
 *                named {@literal "Player"} (if found)
 * 
 * @note: Flags are:
 *     1 Execute only if command executed with say
 *     2 Execute only if command executed with say_team
 * 
 *     a Execute only if player is alive
 *     d Execute only if player is dead
 * 
 *     u Execute only if team is UNASSIGNED
 *     t Execute only if team is TERRORIST
 *     c Execute only if team is CT
 *     s Execute only if team is SPECTATOR
 * 
 * @param alias      Default alias for the command
 * @param handle     Local public function name to call when command is executed
 * @param flags      Flags specifying valid states a player must be in to have
 *                       the command executed. Valid flags are listed above,
 *                       additionally,
 *                       {@link command_manager_const.inc::#FLAG_SEPARATOR}
 *                       can be used as a separator (i.e., no actual meaning).
 * @param desc       Brief description of the command (i.e., what it does)
 * @param adminFlags Admin flags ({@code ADMIN_*} constants) which the command
 *                       requires the user must have
 *
 * @return Unique identifier of the created command, otherwise {@literal
 *         Invalid_Command} if there was some problem registering the command
 *         (see logs for detailed information on the specific reason)
 */
native Command: cmd_registerCommand(
        const alias[],
        const handle[],
        const flags[] = "12,ad,utcs",
        const desc[] = NULL_STRING,
        const adminFlags = ADMIN_ALL);

/**
 * Registers an alias for a specified command, or rebinds the alias if it
 * already exists.
 * 
 * @param command Command to register the alias for
 * @param alias   Alias to create (or rebind) to the given command
 *
 * @return Unique identifier of the alias, otherwise {@literal Invalid_Alias}
 *         if there was some problem registering the alias for the command
 *         (see logs for detailed information on the specific reason)
 *      
 */
native Alias: cmd_registerAlias(
        const Command: command,
        const alias[]);

/**
 * Returns the command which a given alias is bound to.
 *
 * @param alias Alias to search for
 * 
 * @return Command which {@param alias} is bound to, otherwise {@literal
 *         Invalid_Command} if it is not yet bound to any command
 */
native Command: cmd_getCommandFromAlias(const alias[]);

/**
 * Returns whether or not the given value is a valid command index (i.e.,
 * is a registered index returned by {@link #cmd_registerCommand}).
 * 
 * @param command value to check
 * 
 * @return {@literal true} if it is a valid command index, otherwise {@literal
 *             false}
 */
native bool: cmd_isValidCommand(const {any,Command}: command);

/**
 * Returns whether or not the given value is a valid alias index (i.e.,
 * is a registered index returned by {@link #cmd_registerAlias}).
 * 
 * @param alias value to check
 * 
 * @return {@literal true} if it is a valid alias index, otherwise {@literal
 *             false}
 */
native bool: cmd_isValidAlias(const {any,Alias}: alias);

/**
 * Returns the number of commands registered.
 * 
 * @return number of commands registered
 */
native cmd_getNumCommands();

/**
 * Returns the number of aliases registered.
 * 
 * @return number of aliases registered
 */
native cmd_getNumAliases();
