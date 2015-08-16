#define PLUGIN_VERSION "0.0.1"

#include "include\zm\compiler_settings.inc"

#include <amxmodx>

#include "include\zm\inc\zm_colorchat_stocks.inc"
#include "include\zm\zombiemod.inc"
#include "include\zm\zm_commandmanager.inc"

static g_szCommandListMotD[256];
static g_szCommandTable[1792];
static g_szCommandList[192];

public zm_onInit() {
	zm_registerExtension("[ZM] Command List", PLUGIN_VERSION, "Manages commands that players can use");
	register_dictionary("zombiemod.txt");
}

public zm_onRegisterCommands() {
	new ZM_CMD:commands = zm_registerCommand("commands", "displayCommandList", "abcdef", "Displays a printed list of all commands");
	zm_registerCommandAlias(commands, "cmds");
	
	new ZM_CMD:commandList = zm_registerCommand("commandlist", "displayCommandMotD", "abcdef", "Displays a detailed list of all commands");
	zm_registerCommandAlias(commandList, "cmdlist");
}

public displayCommandList(id) {
	static tempstring[sizeof g_szCommandList-2];
	add(tempstring, strlen(g_szCommandList)-2, g_szCommandList);
	zm_printColor(id, "Commands: %s", tempstring);
}

public displayCommandMotD(id) {
	static szMotDText[2048];
	new len = formatex(szMotDText, 2047, g_szCommandListMotD);
	len += formatex(szMotDText[len], 2047, "<br><br>%L:<blockquote>", LANG_SERVER, "COMMANDS");
	len += copy(szMotDText[len], 2047, "<STYLE TYPE=\"text/css\"><!--TD{color: \"FFFFFF\"}---></STYLE><table><tr><td>Command:</td><td>&nbsp;&nbsp;Description:</td></tr>");
	len += copy(szMotDText[len], 2047, g_szCommandTable);
	len += copy(szMotDText[len], 2047, "</table></blockquote></font></body></html>");
	show_motd(id, szMotDText, "Zombie Mod Commands: Command List");
}

public zm_onCommandRegistered(ZM_CMD:cmdId, const command[], const handle[], const flags[], const description[], const adminFlags) {
	new tempstring[128];
	formatex(tempstring, 127, "<tr><td>%s</td><td>: %s</td></tr>", command, description);
	add(g_szCommandTable, 1791, tempstring);
	
	formatex(tempstring, 127, "%s, ", command);
	add(g_szCommandList, 191, tempstring);
}

public zm_onPrefixesChanged(const oldValue[], const newValue[]) {
	refreshCommandMotD();
}

refreshCommandMotD() {
	new len = formatex(g_szCommandListMotD, 255, "<html><body bgcolor=\"#474642\"><font size=\"3\" face=\"courier new\" color=\"FFFFFF\">");
	len += formatex(g_szCommandListMotD[len], 255-len, "<center><h1>Zombie Mod Commands v%s</h1>By Tirant</center><br><br>", ZM_VERSION_STRING);
	len += formatex(g_szCommandListMotD[len], 255-len, "%L: ", LANG_SERVER, "COMMAND_PREFIXES");
	get_cvar_string("zm_command_prefixes", g_szCommandListMotD[len], 255-len);
}