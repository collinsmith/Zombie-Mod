#if defined _command_manager_const_included
    #endinput
#endif
#define _command_manager_const_included

#include <cstrike>

/*******************************************************************************
 * DEFINITIONS
 ******************************************************************************/

#define FLAG_METHOD_SAY      1
#define FLAG_METHOD_SAY_TEAM 2

#define FLAG_STATE_ALIVE     3
#define FLAG_STATE_DEAD      4

#define FLAG_TEAM_UNASSIGNED 5
#define FLAG_TEAM_T          6
#define FLAG_TEAM_CT         7
#define FLAG_TEAM_SPECTATOR  8

#define FLAG_SEPARATOR          ','

#define FLAG_METHOD_SAY_CH      '1'
#define FLAG_METHOD_SAY_TEAM_CH '2'

#define FLAG_STATE_ALIVE_CH     'a'
#define FLAG_STATE_DEAD_CH      'd'

#define FLAG_TEAM_UNASSIGNED_CH 'u'
#define FLAG_TEAM_T_CH          't'
#define FLAG_TEAM_CT_CH         'c'
#define FLAG_TEAM_SPECTATOR_CH  's'

/*******************************************************************************
 * STOCKS
 ******************************************************************************/

stock readCustomFlags(const flags[], const Logger: logger = Invalid_Logger) {
    new bits = 0;
    for (new i = 0, ch = flags[i]; ch != EOS; ch = flags[++i]) {
        switch (ch) {
            case FLAG_METHOD_SAY_CH:      setFlag(logger, bits, FLAG_METHOD_SAY);
            case FLAG_METHOD_SAY_TEAM_CH: setFlag(logger, bits, FLAG_METHOD_SAY_TEAM);
            
            case FLAG_STATE_ALIVE_CH:     setFlag(logger, bits, FLAG_STATE_ALIVE);
            case FLAG_STATE_DEAD_CH:      setFlag(logger, bits, FLAG_STATE_DEAD);

            case FLAG_TEAM_UNASSIGNED_CH: setFlag(logger, bits, FLAG_TEAM_UNASSIGNED);
            case FLAG_TEAM_T_CH:          setFlag(logger, bits, FLAG_TEAM_T);
            case FLAG_TEAM_CT_CH:         setFlag(logger, bits, FLAG_TEAM_CT);
            case FLAG_TEAM_SPECTATOR_CH:  setFlag(logger, bits, FLAG_TEAM_SPECTATOR);
            
            case FLAG_SEPARATOR:          continue;

            default: continue;
        }
    }

    return bits;
}

stock getCustomFlags(const bits, flags[], const len, const Logger: logger = Invalid_Logger) {
    new copyLen = 0;
    if (isFlagSet(logger, bits, FLAG_METHOD_SAY) && copyLen < len) {
        flags[copyLen++] = FLAG_METHOD_SAY_CH;
    }

    if (isFlagSet(logger, bits, FLAG_METHOD_SAY_TEAM) && copyLen < len) {
        flags[copyLen++] = FLAG_METHOD_SAY_TEAM_CH;
    }

    if (isFlagSet(logger, bits, FLAG_STATE_ALIVE) && copyLen < len) {
        flags[copyLen++] = FLAG_STATE_ALIVE_CH;
    }

    if (isFlagSet(logger, bits, FLAG_STATE_DEAD) && copyLen < len) {
        flags[copyLen++] = FLAG_STATE_DEAD_CH;
    }

    if (isFlagSet(logger, bits, FLAG_TEAM_UNASSIGNED) && copyLen < len) {
        flags[copyLen++] = FLAG_TEAM_UNASSIGNED_CH;
    }

    if (isFlagSet(logger, bits, FLAG_TEAM_T) && copyLen < len) {
        flags[copyLen++] = FLAG_TEAM_T_CH;
    }

    if (isFlagSet(logger, bits, FLAG_TEAM_CT) && copyLen < len) {
        flags[copyLen++] = FLAG_TEAM_CT_CH;
    }

    if (isFlagSet(logger, bits, FLAG_TEAM_SPECTATOR) && copyLen < len) {
        flags[copyLen++] = FLAG_TEAM_SPECTATOR_CH;
    }

    flags[min(len, copyLen-1)+1] = EOS;
    return copyLen;
}

stock CsTeams: getTeamForFlag(const flag) {
    switch (flag) {
        case FLAG_TEAM_UNASSIGNED: return CS_TEAM_UNASSIGNED;
        case FLAG_TEAM_T:          return CS_TEAM_T;
        case FLAG_TEAM_CT:         return CS_TEAM_CT;
        case FLAG_TEAM_SPECTATOR:  return CS_TEAM_SPECTATOR;
    }

    return CS_TEAM_UNASSIGNED;
}

stock getFlagForTeam(const CsTeams: team) {
    switch (team) {
        case CS_TEAM_UNASSIGNED: return FLAG_TEAM_UNASSIGNED;
        case CS_TEAM_T:          return FLAG_TEAM_T;
        case CS_TEAM_CT:         return FLAG_TEAM_CT;
        case CS_TEAM_SPECTATOR:  return FLAG_TEAM_SPECTATOR;
    }

    return 0;
}