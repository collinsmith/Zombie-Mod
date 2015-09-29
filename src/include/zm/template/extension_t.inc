#if defined _extension_t_included
    #endinput
#endif
#define _extension_t_included

/*******************************************************************************
 * extension_t template
 ******************************************************************************/

/**
 * Defines the max length of an extension's name field.
 */
#define ext_Name_length 31

/**
 * Defines the max length of an extension's description field.
 */
#define ext_Desc_length 127

/**
 * Defines the max length of an extension's version string field.
 */
#define ext_Version_length 15

/**
 * Definition to permit the ZM_Ext tag in place of the ZM_Extension tag.
 */
#define ZM_Ext: ZM_Extension:

/**
 * Constant representing the value used for an extension which is invalid.
 */
enum ZM_Extension {
    Invalid_Extension
};

enum extension_t {
   /**
     * Plugin index which registered this extension
     */
    ext_PluginId,

    /**
     * Name of this extension.
     */
    ext_Name[ext_Name_length+1],
    
    /**
     * Description of this extension.
     */
    ext_Desc[ext_Desc_length+1],
    
    /**
     * String representation for the version of this extension.
     */
    ext_Version[ext_Version_length+1],
};