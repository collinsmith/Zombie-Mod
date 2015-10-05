#define VERSION_STRING "1.0.0"

#include <amxmodx>
#include <logger>

#include "include\\commandmanager\\command_manager.inc"

static const TEST[][] = {
    "FAILED",
    "PASSED"
};

static tests, passed;
static bool: isEqual;

public plugin_init() {
    register_plugin("Command Manager Tests", VERSION_STRING, "Tirant");
    
    log_amx("Testing %s", name);
    tests = passed = 0;

    test_registerCommand();

    log_amx("Finished Stocks tests: %s (%d/%d)", TEST[tests == passed], passed, tests);
}

public handle1(id) {
    zm_printColor(id, "handle1");
}

public handle2(id) {
    zm_printColor(id, "handle2");
}

test(bool: b) {
    isEqual = b;
    tests++;
    if (isEqual) passed++;
}

test_registerCommand() {
    new numCommands;
    new ZM_Command: command;
    new alias[32];
    new handle[32];
    log_amx("Testing zm_registerCommand");

    alias = "alias1";
    handle = "handle1";
    numCommands = zm_getNumCommands();
    command = zm_registerCommand(alias, handle);
    log_amx("\tzm_registerCommand(\"%s\", \"%s\") = %d", alias, handle, command);
    test(numCommands+1 == zm_getNumCommands());
    log_amx("\t\t%s - numCommands incremented; actual => %d -> %d", TEST[isEqual], numCommands, zm_getNumCommands());
    test(command > Invalid_Command);
    log_amx("\t\t%s - command > Invalid_Command; actual => %d > %d", TEST[isEqual], command, Invalid_Command);
    test(command == zm_getCommandFromAlias(alias));
    log_amx("\t\t%s - command == zm_getCommandFromAlias(alias); actual => %d == %d", TEST[isEqual], command, zm_getCommandFromAlias(alias));
    
    alias = "alias2";
    handle = "handle2";
    numCommands = zm_getNumCommands();
    command = zm_registerCommand(alias, handle);
    log_amx("\tzm_registerCommand(\"%s\", \"%s\") = %d", alias, handle, command);
    test(numCommands+1 == zm_getNumCommands());
    log_amx("\t\t%s - numCommands incremented; actual => %d -> %d", TEST[isEqual], numCommands, zm_getNumCommands());
    test(command > Invalid_Command);
    log_amx("\t\t%s - command > Invalid_Command; actual => %d > %d", TEST[isEqual], command, Invalid_Command);
    test(command == zm_getCommandFromAlias(alias));
    log_amx("\t\t%s - command == zm_getCommandFromAlias(alias); actual => %d == %d", TEST[isEqual], command, zm_getCommandFromAlias(alias));
    
    test_registerAlias();
}

test_registerAlias() {
    new numAliases;
    new ZM_Alias: alias;
    new ZM_Command: command;
    new ZM_Command: command2;
    new alias1[32];
    new alias2[32];
    new alias3[32];
    log_amx("Testing zm_registerAlias");

    alias1 = "alias1";
    alias2 = "alias2";
    test(zm_getCommandFromAlias(alias1) != (command2 = zm_getCommandFromAlias(alias2)));
    log_amx("\t%s - zm_getCommandFromAlias(\"%s\") != zm_getCommandFromAlias(\"%s\"); \
            actual => %d != %d", TEST[isEqual],
            alias1, alias2,
            zm_getCommandFromAlias(alias1), zm_getCommandFromAlias(alias2));
    command = zm_getCommandFromAlias(alias1);
    alias = zm_registerAlias(command, alias2);
    log_amx("\t%s - zm_registerAlias(%d, \"%s\") = %d;", TEST[isEqual],
            command, alias2, alias);
    test(zm_getCommandFromAlias(alias1) == zm_getCommandFromAlias(alias2));
    log_amx("\t%s - zm_getCommandFromAlias(\"%s\") == zm_getCommandFromAlias(\"%s\"); \
            actual => %d == %d", TEST[isEqual],
            alias1, alias2,
            zm_getCommandFromAlias(alias1), zm_getCommandFromAlias(alias2));
    new ZM_Alias: t1 = zm_registerAlias(command, alias1);
    new ZM_Alias: t2 = zm_registerAlias(command, alias1);
    test(t1 == t2);
    log_amx("\t%s - zm_registerAlias(%d, \"%s\") == zm_registerAlias(%d, \"%s\"); \
            actual => %d == %d", TEST[isEqual],
            command, alias1,
            command, alias1,
            t1, t2);

    alias3 = "alias3";
    numAliases = zm_getNumAliases();
    alias = zm_registerAlias(command2, alias3);
    log_amx("\tzm_registerAlias(%d, \"%s\") = %d;",
            command2, alias3, alias);
    test(numAliases+1 == zm_getNumAliases());
    log_amx("\t\t%s - numAliases incremented; actual => %d -> %d", TEST[isEqual], numAliases, zm_getNumAliases());
    test(alias > Invalid_Alias);
    log_amx("\t\t%s - alias > Invalid_Alias; actual => %d > %d", TEST[isEqual], alias, Invalid_Alias);
    test(zm_getCommandFromAlias(alias3) == command2);
    log_amx("\t\t%s - zm_getCommandFromAlias(\"%s\") == %d; \
            actual => %d == %d", TEST[isEqual],
            alias3, command2,
            zm_getCommandFromAlias(alias3), command2);
}