#define PLUGIN_VERSION "0.0.1"

#include "include/zm/compiler_settings.inc"

#include <amxmodx>

#include "include/zm/inc/templates/model_t.inc"
#include "include/zm/inc/zm_precache_stocks.inc"
#include "include/zm/inc/zm_modelmanager_const.inc"
#include "include/zm/zombiemod.inc"
#include "include/zm/zm_teammanager.inc"

public zm_onInit() {
    zm_registerExtension("[ZM] Model Manager",
                         PLUGIN_VERSION,
                         "Manages model resources");

    //...
}