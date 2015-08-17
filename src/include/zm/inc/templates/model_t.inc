#if defined _model_t_included
	#endinput
#endif
#define _model_t_included

/**
 * Definition to permit the ZM_MODEL tag in place of the ZM_MDL tag.
 */
#define ZM_MODEL: ZM_MDL:

/**
 * Defines the maximum length for the name field of a model
 */
#define model_Name_length 31

/**
 * Constant representing the value used for a model which is invalid.
 */
stock const ZM_MDL:Invalid_Model = ZM_MDL:0;

/**
 * Represents a template for a ZM model.
 */
enum model_t {
	/**
	 * Name of this model
	 */
	model_Name[model_Name_length+1],
};