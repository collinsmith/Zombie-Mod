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

/**
 * Defines the length of the buffer used for printing.
 */
#define BUFFER_LENGTH 191

/**
 * Prints a message to the chat using colorchat.
 * 
 * @param id      Player index to send the message to, 0 for all players
 * @param message Message or message format to print
 */
stock zm_printColor(const id, const message[], any: ...) {
    static buffer[BUFFER_LENGTH+1];
    static offset;
    if (buffer[0] == EOS) {
        offset = formatex(buffer, BUFFER_LENGTH,
                "[%L] ",
                LANG_SERVER, ZM_NAME_SHORT);
    }
    
    new length = offset;
    switch (numargs()) {
        case 2: length += copy(
                buffer[offset], BUFFER_LENGTH-offset, message);
        default: length += vformat(
                buffer[offset], BUFFER_LENGTH-offset, message, 3);
    }
    
    buffer[length] = EOS;
    client_print_color(id, print_team_default, buffer);
}