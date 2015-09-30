#if defined _zm_stocks_included
    #endinput
#endif
#define _zm_stocks_included

#define CONCMD_ACCESS ADMIN_CFG

/*******************************************************************************
 * STOCKS
 ******************************************************************************/

stock zm_registerConCmd(const command[], const function[], const description[], const Logger: logger = Invalid_Logger) {
    register_concmd(
            command,
            function,
            CONCMD_ACCESS,
            description);

    if (logger != Invalid_Logger) {
        LoggerLogDebug(logger, "register_concmd \"%s\"", zm_players);
    }
}