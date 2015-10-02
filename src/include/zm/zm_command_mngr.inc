#if defined _zm_command_mngr_included
    #endinput
#endif
#define _zm_command_mngr_included

#pragma reqlib zm_command_mngr

/*******************************************************************************
 * FORWARDS
 ******************************************************************************/

forward zm_onBeforeCommand(const id, const ZM_Command: command);
forward zm_onCommand(const id, const ZM_Command: command);

forward zm_onCommandRegistered(
        const ZM_Command:cmdId,
        const command[],
        const handle[],
        const flags[],
        const description[],
        const adminFlags);

forward zm_onPrefixesChanged(const oldValue[], const newValue[]);

/*******************************************************************************
 * NATIVES
 ******************************************************************************/

/*
l - Execute only on say all
t - Execute only on say_team
z - Execute only if zombie
h - Execute only if human
a - Execute only if alive
d - Execute only if dead
*/
native ZM_Command: zm_registerCommand(
        const alias[],
        const handle[],
        const flags[] = "abcdef",
        const description[] = NULL_STRING,
        const adminFlags = ADMIN_ALL);

native ZM_Alias: zm_registerAlias(
        const ZM_Command: command,
        const alias[]);

native ZM_Command: zm_getCommandByName(const command[]);