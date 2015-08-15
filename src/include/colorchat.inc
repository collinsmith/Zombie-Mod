#if defined COLORCHAT_INC
  #endinput
#endif
#define COLORCHAT_INC

#pragma reqlib colorchat

/* ColorChat Support */
#define NORMAL DontChange
#define GREEN DontChange
#define TEAM_COLOR DontChange
#define RED Red
#define BLUE Blue
#define GREY Grey
#define ColorChat client_print_color
/* ColorChat Support */

enum _:Colors {
	DontChange, // use receiver team color
	Red,
	Blue,
	Grey
}

native client_print_color(id, color=DontChange, const fmt[], any:...);

native client_print_color2(id, sender, const fmt[], any:...); // set team color according to sender index

// It is not required to use this, you can directly put in a UTF-8 WITHOUT BOM file, 1 3 and 4,
// for this, use npp and hit Alt + corresponding key (1 2 or 4), you should respectively see  (SOH)  (ETX) and  (EOT).
// if you still want to use !n !g and !t, use this stock and enjoy the compiled plugin increased size :)
stock register_dictionary_colored(const filename[])
{
	if( !register_dictionary(filename) )
	{
		return 0;
	}

	new szFileName[256];
	get_localinfo("amxx_datadir", szFileName, charsmax(szFileName));
	format(szFileName, charsmax(szFileName), "%s/lang/%s", szFileName, filename);
	new fp = fopen(szFileName, "rt");
	if( !fp )
	{
		log_amx("Failed to open %s", szFileName);
		return 0;
	}

	new szBuffer[512], szLang[3], szKey[64], szTranslation[256], TransKey:iKey;

	while( !feof(fp) )
	{
		fgets(fp, szBuffer, charsmax(szBuffer));
		trim(szBuffer);

		if( szBuffer[0] == '[' )
		{
			strtok(szBuffer[1], szLang, charsmax(szLang), szBuffer, 1, ']');
		}
		else if( szBuffer[0] )
		{
			strbreak(szBuffer, szKey, charsmax(szKey), szTranslation, charsmax(szTranslation));
			iKey = GetLangTransKey(szKey);
			if( iKey != TransKey_Bad )
			{
				while( replace(szTranslation, charsmax(szTranslation), "!g", "^4") ){}
				while( replace(szTranslation, charsmax(szTranslation), "!t", "^3") ){}
				while( replace(szTranslation, charsmax(szTranslation), "!n", "^1") ){}
				AddTranslation(szLang, iKey, szTranslation[2]);
			}
		}
	}
	
	fclose(fp);
	return 1;
}