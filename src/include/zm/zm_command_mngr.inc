#if defined _zm_command_mngr_included
    #endinput
#endif
#define _zm_command_mngr_included

#include "include\\zm\\template\\alias_t.inc"
#include "include\\zm\\template\\command_t.inc"

#pragma reqlib zm_command_mngr

/*******************************************************************************
 * FORWARDS
 ******************************************************************************/

forward zm_onBeforeCommand(const id, const ZM_Command: command);
forward zm_onCommand(const id, const ZM_Command: command);

forward zm_onCommandRegistered(
        const ZM_Command:cmdId,
        const alias[],
        const handle[],
        const flags[],
        const description[],
        const adminFlags);

forward zm_onPrefixesChanged(const oldValue[], const newValue[]);

/*******************************************************************************
 * NATIVES
 ******************************************************************************/

/*
a - Execute only if alive
d - Execute only if dead
s - Execute only on say all
t - Execute only on say_team
h - Execute only if human
z - Execute only if zombie
*/
native ZM_Command: zm_registerCommand(
        const alias[],
        const handle[],
        const flags[] = "adsthz",
        const description[] = NULL_STRING,
        const adminFlags = ADMIN_ALL);

native ZM_Alias: zm_registerAlias(
        const ZM_Command: command,
        const alias[]);

native ZM_Command: zm_getCommandFromAlias(const alias[]);

native bool: zm_isValidCommand(const ZM_Command: command);

native bool: zm_isValidAlias(const ZM_Alias: alias);

native zm_getNumCommands();
native zm_getNumAliases();