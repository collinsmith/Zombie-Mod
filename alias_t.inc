#if defined _alias_t_included
    #endinput
#endif
#define _alias_t_included

#tryinclude <command_t>
#tryinclude "include\\commandmanager\\command_t.inc"
#tryinclude "include\\commandmanager-inc\\command_t.inc"

/*******************************************************************************
 * Command Tag Definition
 ******************************************************************************/

/**
 * Constant representing the value used for an alias which is invalid.
 */
enum Alias {
    Invalid_Alias
};

/*******************************************************************************
 * alias_t template
 ******************************************************************************/

/**
 * Defines the maximum length for the alias field of an alias
 */
#define alias_String_length 31

enum alias_t {
    /**
     * Name of this command
     */
    alias_String[alias_String_length+1],

    /**
     * Command identifier for which this alias belongs
     */
    Command: alias_Command,
};