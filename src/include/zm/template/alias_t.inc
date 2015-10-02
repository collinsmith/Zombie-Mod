#if defined _alias_t_included
    #endinput
#endif
#define _alias_t_included

/*******************************************************************************
 * alias_t template
 ******************************************************************************/

/**
 * Defines the maximum length for the alias field of an alias
 */
#define alias_Alias_length 31

/**
 * Constant representing the value used for an alias which is invalid.
 */
enum ZM_Alias {
    Invalid_Alias
};

enum alias_t {
    /**
     * Name of this command
     */
    alias_Alias[alias_Alias_length+1],

    /**
     * Command identifier for which this alias belongs
     */
    ZM_Command: alias_Command,
};