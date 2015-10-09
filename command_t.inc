#if defined _command_t_included
    #endinput
#endif
#define _command_t_included

/*******************************************************************************
 * Command Tag Definition
 ******************************************************************************/

/**
 * Definition to permit the Cmd tag in place of the Command tag.
 */
#define Cmd: Command:

/**
 * Constant representing the value used for a command which is invalid.
 */
enum Command {
    Invalid_Command
};

/*******************************************************************************
 * command_t template
 ******************************************************************************/

/**
 * Defines the maximum length for the description field of a command
 */
#define command_Desc_length 63

enum command_t {
    /**
     * Description of this command
     */
    command_Desc[command_Desc_length+1],
    
    /**
     * Flags for activation
     */
    command_Flags,
    
    /**
     * Admin flags needed
     */
    command_AdminFlags,

    /**
     * Plugin index which owns the function to be called
     */
    command_PluginID,
    
    /**
     * Function index to be called
     */
    command_FuncID,

    /**
     * List of aliases for this command
     */
    Array: command_Aliases,
};