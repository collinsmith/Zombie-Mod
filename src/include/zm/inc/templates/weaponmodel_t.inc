#if defined _weaponmodel_t_included
    #endinput
#endif
#define _weaponmodel_t_included

#include "include/zm/inc/zm_weaponmodelmanager_const.inc"

/**
 * Constant representing the value used for a weapon model which is invalid.
 */
enum ZM_WEAPON_MODEL {
    Invalid_Weapon_Model
};

/**
 * Represents a template for a ZM weapon model.
 */
enum weaponmodel_t {
    /**
     * Base model for this weapon model
     */
    ZM_MODEL:weaponmodel_Model,

    /**
     * ZM_* (or corresponding CSI_*) constant representing which weapon this
     * model applies to.
     */
    ZM_WEAPON:weaponmodel_Weapon,
};