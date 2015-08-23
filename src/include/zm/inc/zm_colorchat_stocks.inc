#if defined _zm_colorchat_stocks_included
    #endinput
#endif
#define _zm_colorchat_stocks_included

#include <colorchat>

#include "zm_const.inc"

/*******************************************************************************
Stocks
*******************************************************************************/

/**
 * Defines the length of the buffer used for printing.
 */
#define BUFFER_LENGTH 191

/**
 * Prints a message to the chat using colorchat.
 * 
 * @param id        Player index to send the message to, 0 for all players
 * @param message   Message or message format to print
 * @param ...       Arguments if a message format is used
 */
stock zm_printColor(id, message[], any:...) {
    static buffer[BUFFER_LENGTH+1];
    static offset;
    if (buffer[0] == EOS) {
        offset = formatex(buffer, BUFFER_LENGTH, "[%s] ", ZM_NAME_SHORT);
    }
    
    new length = offset;
    switch (numargs()) {
        case 2: {
            length += copy(buffer[offset], BUFFER_LENGTH-offset, message);
        }
        default: {
            length += vformat(buffer[offset], BUFFER_LENGTH-offset, message, 3);
        }
    }
    
    buffer[length] = EOS;
    client_print_color(id, DontChange, buffer);
}