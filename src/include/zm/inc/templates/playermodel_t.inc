#if defined _playermodel_t_included
    #endinput
#endif
#define _playermodel_t_included

/**
 * Constant representing the value used for a player model which is invalid.
 */
enum ZM_PLAYER_MODEL {
    Invalid_Player_Model
};

/**
 * Represents a template for a ZM player model.
 */
enum playermodel_t {
    /**
     * Base model for this player model
     */
    ZM_MODEL:playermodel_Model,
};