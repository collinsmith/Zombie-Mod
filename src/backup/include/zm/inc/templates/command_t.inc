#if defined _command_t_included
    #endinput
#endif
#define _command_t_included

/**
 * Definition to permit the ZM_COMMAND tag in place of the ZM_CMD tag.
 */
#define ZM_COMMAND: ZM_CMD:

/**
 * Defines the maximum length for the name field of a command
 */
#define command_Name_length 31

/**
 * Defines the maximum length for the description field of a command
 */
#define command_Desc_length 63

/**
 * Constant representing the value used for a command which is invalid.
 */
enum ZM_CMD {
    Invalid_Command
};

/**
 * Represents a template for a ZM command.
 */
enum command_t {
    /**
     * Name of this command
     */
    command_Name[command_Name_length+1],
    
    /**
     * Description of this command
     */
    command_Desc[command_Desc_length+1],
    
    /**
     * Plugin index which owns the handle to be called
     */
    command_PluginID,
    
    /**
     * Function index of the handle to be called
     */
    command_FuncID,
    
    /**
     * Flags for activation
     */
    command_Flags,
    
    /**
     * Admin flags needed
     */
    command_AdminFlags,
};