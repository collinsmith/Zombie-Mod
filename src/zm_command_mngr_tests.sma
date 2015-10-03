#define VERSION_STRING "1.0.0"
#define EXTENSION_NAME "Command Manager Tests"

#include <amxmodx>

#include "include\\zm\\zm_command_mngr.inc"
#include "include\\zm\\zombiemod.inc"

public zm_onExtensionInit() {
    new name[32];
    formatex(name, charsmax(name),
            "[%L] %s",
            LANG_SERVER, ZM_NAME_SHORT,
            EXTENSION_NAME);
    register_plugin(name, VERSION_STRING, "Tirant");
    zm_registerExtension(
            .name = EXTENSION_NAME,
            .version = VERSION_STRING,
            .description = "Tests customer commands registered in zm_command_mngr");

    new ZM_Command: command;
    zm_registerCommand("alias1", "handle1", _, "Calls handle1");
    zm_registerCommand("alias1", "handle2", "a", "Calls handle2");
    zm_registerCommand("alias1", "handle1", "ad");
    command = zm_registerCommand("alias1", "handle1", "ads");
    zm_registerCommand("alias2", "handle2", "adst");
    zm_registerCommand("alias2", "handle2", "adsth");
    zm_registerCommand("alias2", "handle2", "adsthz");
    zm_registerAlias(command, "alias3");
    zm_getCommandFromAlias("alias1");
    zm_getCommandFromAlias("alias2");
    zm_getCommandFromAlias("alias3");
}

public handle1() {
}

public handle2() {
}