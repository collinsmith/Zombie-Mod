#if defined _command_t_included
    #endinput
#endif
#define _command_t_included

/*******************************************************************************
 * command_t template
 ******************************************************************************/

/**
 * Defines the maximum length for the description field of a command
 */
#define command_Desc_length 63

/**
 * Definition to permit the ZM_Cmd tag in place of the ZM_Command tag.
 */
#define ZM_Cmd: ZM_Command:

/**
 * Constant representing the value used for a command which is invalid.
 */
enum ZM_Command {
    Invalid_Command
};

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