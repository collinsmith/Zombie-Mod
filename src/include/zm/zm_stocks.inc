#if defined _zm_stocks_included
    #endinput
#endif
#define _zm_stocks_included

#define CONCMD_ACCESS ADMIN_CFG

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
stock zm_registerConCmd(const command[], const function[], const description[], const Logger: logger = Invalid_Logger) {
    new temp[32];
    formatex(temp, charsmax(temp), "zm.%s", command);
    register_concmd(
            command,
            function,
            CONCMD_ACCESS,
            description);

    if (logger != Invalid_Logger) {
        LoggerLogDebug(logger, "register_concmd \"%s\"", zm_players);
    }
}