#if defined _model_t_included
    #endinput
#endif
#define _model_t_included

/**
 * Definition to permit the ZM_MDL tag in place of the ZM_MODEL tag.
 */
#define ZM_MDL: ZM_MODEL:

/**
 * Defines the maximum length for the name field of a model
 */
#define model_Name_length 31

/**
 * Defines the maximum length for the path field of a model
 */
#define model_Path_length 127

/**
 * Constant representing the value used for a model which is invalid.
 */
enum ZM_MODEL {
    Invalid_Model
};

/**
 * Represents a template for a ZM model.
 */
enum model_t {
    /**
     * Name of this model
     */
    model_Name[model_Name_length+1],

    /**
     * Path of this model
     */
    model_Path[model_Path_length+1],
};