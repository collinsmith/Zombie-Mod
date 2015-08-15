#if defined _extension_t_included
	#endinput
#endif
#define _extension_t_included

/**
 * Definition to permit the ZM_EXTENSION tag in place of the ZM_EXT tag.
 */
#define ZM_EXTENSION: ZM_EXT:

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
 * Constant representing the value used for an extension which is invalid.
 */
stock const ZM_EXT:Invalid_Extension = ZM_EXT:0;

/**
 * Represents a template for a ZM extension plugin's metadata.
 */
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
	ext_Version[ext_Version_length+1]
};