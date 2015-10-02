#if defined _zm_stocks_included
    #endinput
#endif
#define _zm_stocks_included

/*******************************************************************************
 * STOCKS
 ******************************************************************************/

/**
 * Registers a console command and logs that the command has been registered.
 * The primary purpose of this stock is to create a macro for creating commands
 * used by admins/developers to debug their plugins. Command names will have
 * zm.* prepended to them.
 * 
 * @param command     Command which when types in console, executes a function
 * @param function    Name of the function to execute
 * @param description Brief description of the purpose for the command
 * @param logger      Logger to log when the command has been registered
 */
stock zm_registerConCmd(const command[], const function[], const description[], const access = ADMIN_CFG, const Logger: logger = Logger:(0)) {
    new temp[32];
    new cmd[16];
    formatex(cmd, charsmax(cmd), "%L", LANG_SERVER, ZM_NAME_SHORT);
    strtolower(cmd);
    formatex(temp, charsmax(temp), "%s.%s", cmd, command);
    register_concmd(
            temp,
            function,
            access,
            description);

    if (logger != Logger:(0)) {
        LoggerLogDebug2(logger, true, "register_concmd \"%s\"", temp);
    }
}