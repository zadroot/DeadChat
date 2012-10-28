/**
* DoD:S All Chat by Root
*
* Description:
*   Relays all chat messages, including chat of dead players, spectators or team chat.
*
* Version 1.0
* Changelog & more info at http://goo.gl/4nKhJ
*/

#pragma semicolon 1

// ====[ INCLUDES ]=====================================================
#include <sourcemod>

// ====[ CONSTANTS ]====================================================
#define PLUGIN_NAME    "DoD:S All Chat"
#define PLUGIN_VERSION "1.0"

enum
{
	Team_Unassigned,
	Team_Spectator,
	Team_Allies,
	Team_Axis
};

// ====[ VARIABLES ]====================================================
new Handle:allchat_enable = INVALID_HANDLE, Handle:allchat_team = INVALID_HANDLE;

// ====[ PLUGIN ]=======================================================
public Plugin:myinfo =
{
	name        = PLUGIN_NAME,
	author      = "Root",
	description = "Relays all chat messages",
	version     = PLUGIN_VERSION,
	url         = "http://dodsplugins.com/"
};


/* OnPluginStart()
 *
 * When the plugin starts up.
 * ---------------------------------------------------------------------- */
public OnPluginStart()
{
	// Create ConVars
	CreateConVar("dod_allchat_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED);
	allchat_enable = CreateConVar("dod_allchat",      "1", "Whether or not relay messages of death players to alive", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	allchat_team   = CreateConVar("dod_allchat_team", "2", "Determines who can see team messages:\n1 = All players\n2 = Only teammates", FCVAR_PLUGIN, true, 0.0, true, 2.0);

	// Better than RegConsoleCmd
	AddCommandListener(Command_Say,     "say");
	AddCommandListener(Command_SayTeam, "say_team");

	// Create and exec plugin's config
	AutoExecConfig(true, "dod_allchat");
}

/* Command_Say()
 *
 * When the chat message is received in global chat.
 * ------------------------------------------------------------------ */
public Action:Command_Say(client, const String:command[], argc)
{
	// Whether or not relay chat of dead players
	if (GetConVarBool(allchat_enable))
	{
		if (IsValidClient(client))
		{
			decl String:message[256];
			GetCmdArgString(message, sizeof(message));

			// Quotes are automatically creates at start and end of message - so fuck dat
			StripQuotes(message);

			// Plugin should relay messages of not alive players only
			if (!IsPlayerAlive(client))
			{
				switch (GetClientTeam(client))
				{
					// Spectators doesnt require color or prefix at all
					case Team_Spectator: PrintToChatAll("%N: %s", client, message);
					case Team_Allies:    PrintToChatAll("\x01(Dead) \x074D7942%N: \x01%s", client, message);
					case Team_Axis:      PrintToChatAll("\x01(Dead) \x07FF4040%N: \x01%s", client, message);
				}

				// Block message from being broadcasted (because it is already sent)
				return Plugin_Handled;
			}
		}
	}

	// Continue, otherwise we will block chat
	return Plugin_Continue;
}

/* Command_SayTeam()
 *
 * When the chat message is received in team chat.
 * ------------------------------------------------------------------ */
public Action:Command_SayTeam(client, const String:command[], argc)
{
	if (GetConVarInt(allchat_team) > 0)
	{
		// Check if chat messages sending by valid client(s)
		if (IsValidClient(client))
		{
			decl String:message[256], String:status[8];
			GetCmdArgString(message, sizeof(message));

			StripQuotes(message);

			// Return the value of 'team chat' cvar
			switch (GetConVarInt(allchat_team))
			{
				case 1: // Message should be sended to all players
				{
					// This function adds (Dead) prefix
					Format(status, sizeof(status), "%s", IsPlayerAlive(client) ? NULL_STRING : "(Dead)", client);

					// Checking client's team, and colorize his nickname depends on team (gray, green or red)
					switch (GetClientTeam(client))
					{
						case Team_Spectator: PrintToChatAll("%N: %s", client, message);
						case Team_Allies:    PrintToChatAll("\x01%s(Team) \x074D7942%N: \x01%s", status, client, message);
						case Team_Axis:      PrintToChatAll("\x01%s(Team) \x07FF4040%N: \x01%s", status, client, message);
					}
					return Plugin_Handled;
				}
				case 2: // Message should be send only for teammates (if client is obviously dead)
				{
					for (new mates = 1; mates <= MaxClients; mates++)
					{
						// Check all ingame players only
						if (IsClientInGame(mates))
						{
							// Make sure message will not be send to enemies and check if player is not observing
							if (!IsPlayerAlive(client) && !IsClientObserver(client) && GetClientTeam(client) == GetClientTeam(mates))
							{
								// Yea still needed to relay spectator's chat
								switch (GetClientTeam(client))
								{
									case Team_Spectator: PrintToChat(mates, "%N: %s", client, message);
									case Team_Allies:    PrintToChat(mates, "(Dead)(Team) \x074D7942%N: \x01%s", client, message);
									case Team_Axis:      PrintToChat(mates, "(Dead)(Team) \x07FF4040%N: \x01%s", client, message);
								}

								// Obviously block message to prevent double sending
								return Plugin_Handled;
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

/* IsValidClient()
 *
 * Checks if a client is valid.
 * ---------------------------------------------------------------------- */
bool:IsValidClient(client)
{
	// Check if client is ingame and not a server
	return (client > 0 && IsClientInGame(client)) ? true : false;
}