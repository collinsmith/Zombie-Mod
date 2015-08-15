#include <amxmodx>
#include <amxmisc>
#include <cvar_util>

public plugin_init()
{
    register_plugin("CU: amx_cvar Fix", "1.1", "Arkshine" );

    register_dictionary( "admincmd.txt" );
    register_dictionary( "common.txt" );
    register_dictionary( "adminhelp.txt" )
    
    register_concmd( "amx_cvar", "ClientCommand_Cvar", ADMIN_CVAR, "<cvar> [value]" );
}

public ClientCommand_Cvar( const id, const level, const cid )
{
    if( !cmd_access( id, level, cid, 2 ) )
    {
        return PLUGIN_HANDLED;
    }    

    new arg[ 32 ], arg2[ 64 ];
    
    read_argv( 1, arg, charsmax( arg ) );
    read_argv( 2, arg2, charsmax( arg2 ) );
    
    new pointer;
    
    if( equal( arg, "add" ) && ( get_user_flags( id ) & ADMIN_RCON ) )
    {
        if( ( pointer=get_cvar_pointer( arg2 ) ) != 0 )
        {
            new flags = get_pcvar_flags( pointer );
            
            if( !( flags & FCVAR_PROTECTED ) )
            {
                set_pcvar_flags( pointer, flags | FCVAR_PROTECTED );
            }
        }
        
        return PLUGIN_HANDLED;
    }
    
    if( ( pointer = get_cvar_pointer( arg ) ) == 0 )
    {
        console_print( id, "[AMXX] %L", id, "UNKNOWN_CVAR", arg );
        return PLUGIN_HANDLED;
    }
    
    if( onlyRcon( arg ) && !( get_user_flags( id ) & ADMIN_RCON ) )
    {
        // Exception for the new onlyRcon rules:
        // sv_password is allowed to be modified by ADMIN_PASSWORD
        if( !( equali( arg, "sv_password" ) && ( get_user_flags( id ) & ADMIN_PASSWORD ) ) )
        {
            console_print( id, "[AMXX] %L", id, "CVAR_NO_ACC" );
            return PLUGIN_HANDLED;
        }
    }
    
    if( read_argc() < 3 )
    {
        get_pcvar_string( pointer, arg2, 63 );
        console_print( id, "[AMXX] %L", id, "CVAR_IS", arg, arg2 );
        return PLUGIN_HANDLED;
    }

    /* START : Cvar Utilities Fix */
    
    if( CvarGetStatus( pointer ) & CvarStatus_LockActive )
    {
        new pluginId, value[ 256 ];
        CvarLockInfo( pointer, pluginId, value, charsmax( value ) );

        console_print( id, "[AMXX] The cvar is locked with ^"%s^"", value );
        return PLUGIN_HANDLED;
    }
    
    /* END : Cvar Utilities Fix */
    
    new authid[ 32 ], name[ 32 ];
    
    get_user_authid( id, authid, charsmax( authid ) );
    get_user_name( id, name, charsmax( name ) );
    
    /* START : Cvar Utilities Fix */
    
    set_pcvar_string( pointer, arg2 );
    get_pcvar_string( pointer, arg2, charsmax( arg2 ) );
    
    if( CvarGetStatus( pointer ) & CvarStatus_WasOutOfBound )
    {
        console_print( id, "[AMXX] The cvar has a min and/or a max bound and the wanted value is out of bound." );
    }
    
    /* END : Cvar Utilities Fix */
        
    log_amx( "Cmd: ^"%s<%d><%s><>^" set cvar (name ^"%s^") (value ^"%s^")", name, get_user_userid( id ), authid, arg, arg2 );
    
    new cvar_val[ 64 ];
    new playersList[ 32 ];
    new playersCount;
    new player;
    
    get_players( playersList, playersCount, "c" );
    
    new bool:hasProtectedFlag = !!( get_pcvar_flags( pointer ) & FCVAR_PROTECTED );
    new bool:isRconPassword = bool:equali( arg, "rcon_password" );
    
    for( new i = 0; i < playersCount; i++ )
    {
        player = playersList[ i ];
        
        if( hasProtectedFlag || isRconPassword )
            formatex( cvar_val, charsmax( cvar_val ), "*** %L ***", player, "PROTECTED" );
        else
            copy( cvar_val, charsmax( cvar_val ), arg2 );
        
        show_activity_id( player, id, name, "%L", player, "SET_CVAR_TO", "", arg, cvar_val );
    }

    console_print( id, "[AMXX] %L", id, "CVAR_CHANGED", arg, arg2 );
    
    return PLUGIN_HANDLED;
}

stock bool:onlyRcon( const name[] )
{
    new ptr = get_cvar_pointer( name );
    
    if( ptr && get_pcvar_flags( ptr ) & FCVAR_PROTECTED )
    {
        return true;
    }
    
    return false;
}   