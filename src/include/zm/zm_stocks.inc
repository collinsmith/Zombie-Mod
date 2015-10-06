#if defined _zm_stocks_included
    #endinput
#endif
#define _zm_stocks_included

#include "include\\stocks\\misc_stocks.inc"

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
stock zm_registerConCmd(
        const command[],
        const function[],
        const description[],
        const access = ADMIN_CFG,
        const Logger: logger = Logger:(0)) {
    new temp[32];
    formatex(temp, charsmax(temp), "%L", LANG_SERVER, ZM_NAME_SHORT);
    strtolower(temp);
    registerConCmd(temp, command, function, description, access, logger);
}

/**
 * Defines the length of the buffer used for printing.
 */
#define ZM_PRINT_BUFFER_LENGTH 191

/**
 * Constant value storing the header for the print color messages.
 */
stock const ZM_PRINT_COLOR_HEADER[] = "ZM_PRINT_COLOR_HEADER";//"[%L] ";

/**
 * Copies {@link #ZM_PRINT_COLOR_HEADER} into the specified buffer for a max
 * number of bytes.
 *
 * @param dst Destination buffer to copy into
 * @param len Number of bytes to copy, e.g., {@code sizeof {@param dst} - 1}
 * 
 * @return Number of bytes copied
 */
stock zm_getPrintColorHeader(dst[], len) {
    return copy(dst, len, ZM_PRINT_COLOR_HEADER);
}

/**
 * Returns the usable size of the buffer within a print color message. The value
 * of this function will be equal to {@code {@link #ZM_PRINT_BUFFER_LENGTH} -
 * sizeof {@link #ZM_PRINT_COLOR_HEADER}.
 *
 * @return Usable number of bytes within a print color message.
 */
stock zm_getPrintColorBufferLength() {
    return ZM_PRINT_BUFFER_LENGTH - sizeof ZM_PRINT_COLOR_HEADER;
}

/**
 * Prints a message to the chat using colorchat.
 * 
 * @param id      Player index to send the message to, 0 for all players
 * @param message Message or message format to print
 */
stock zm_printColor(const id, const message[], any: ...) {
    static buffer[ZM_PRINT_BUFFER_LENGTH+1];
    static offset;
    if (buffer[0] == EOS) {
        offset = format(buffer, ZM_PRINT_BUFFER_LENGTH,
                "%L ",
                id, ZM_PRINT_COLOR_HEADER,
                id, ZM_NAME_SHORT);
    }
    
    new length = offset;
    switch (numargs()) {
        case 2: length += copy(
                buffer[offset], ZM_PRINT_BUFFER_LENGTH-offset, message);
        default: length += vformat(
                buffer[offset], ZM_PRINT_BUFFER_LENGTH-offset, message, 3);
    }
    
    buffer[length] = EOS;
    client_print_color(id, print_team_default, buffer);
}