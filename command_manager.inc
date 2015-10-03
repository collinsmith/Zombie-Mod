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

forward cmd_onBeforeCommand(const id, const Command: command);
forward cmd_onCommand(const id, const Command: command);

forward cmd_onCommandRegistered(
        const Command:cmdId,
        const alias[],
        const handle[],
        const flags[],
        const description[],
        const adminFlags);

forward cmd_onPrefixesChanged(const oldValue[], const newValue[]);

/*******************************************************************************
 * NATIVES
 ******************************************************************************/

native cmd_setHandler(const function[]);
native cmd_setHandlerError(const error[]);

/*
1 - Execute only if command executed with say
2 - Execute only if command executed with say_team

a - Execute only if player is alive
d - Execute only if player is dead

u - Execute only if team is UNASSIGNED
t - Execute only if team is TERRORIST
c - Execute only if team is CT
s - Execute only if team is SPECTATOR
*/
native Command: cmd_registerCommand(
        const alias[],
        const handle[],
        const flags[] = "12,ad,utcs",
        const description[] = NULL_STRING,
        const adminFlags = ADMIN_ALL);

native Alias: cmd_registerAlias(
        const Command: command,
        const alias[]);

native Command: cmd_getCommandFromAlias(const alias[]);

native bool: cmd_isValidCommand(const Command: command);
native bool: cmd_isValidAlias(const Alias: alias);

native cmd_getNumCommands();
native cmd_getNumAliases();