#pragma semicolon 1

#include <sourcemod>
#include <morecolors>

#define PLUGIN_NAME    "Dead Chat"
#define PLUGIN_VERSION "1.0"

enum
{
	Team_Unassigned,
	Team_Spectator,
	Team_Allies,
	Team_Axis
};

public Plugin:myinfo =
{
	name			= PLUGIN_NAME,
	author			= "Root",
	description		= "Relays chat messages of dead players to everybody",
	version			= PLUGIN_VERSION,
	url				= "http://dodsplugins.com/"
};

new Handle:allchat_enable = INVALID_HANDLE, Handle:allchat_team   = INVALID_HANDLE;


public OnPluginStart()
{
	CreateConVar("dod_allchat_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED);
	allchat_enable = CreateConVar("dod_deadchat",      "1", "Whether or not relay chat of death players to alive", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	allchat_team   = CreateConVar("dod_deadchat_team", "2", "Determines who can see team messages:\n1 = all players\n2 = only teammates", FCVAR_PLUGIN, true, 0.0, true, 2.0);

	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");

	AutoExecConfig(true, "dod_deadchat");
}

public Action:Command_Say(client, const String:command[], argc)
{
	if (GetConVarBool(allchat_enable))
	{
		if (IsValidClient(client))
		{
			decl String:message[256];
			GetCmdArgString(message, sizeof(message));
			StripQuotes(message);

			if (StrEqual(command, "say"))
			{
				if (!IsPlayerAlive(client))
				{
					CSkipNextClient(client);
					switch (GetClientTeam(client))
					{
						case Team_Spectator: CPrintToChatAll("\x07C8C8C8%N: \x01%s",        client, message);
						case Team_Allies:    CPrintToChatAll("(Dead) \x074D7942%N: \x01%s", client, message);
						case Team_Axis:      CPrintToChatAll("(Dead) \x07FF4040%N: \x01%s", client, message);
					}
				}
			}
			else
			{
				Format (message, sizeof(message), "%s", !IsPlayerAlive(client) ? NULL_STRING : "(Dead)", client);
				switch (GetConVarInt(allchat_team))
				{
					case 1:
					{
						CSkipNextClient(client);
						switch (GetClientTeam(client))
						{
							case Team_Spectator: CPrintToChatAll("\x07C8C8C8%N: \x01%s",        client, message);
							case Team_Allies:    CPrintToChatAll("(Team) \x074D7942%N: \x01%s", client, message);
							case Team_Axis:      CPrintToChatAll("(Team) \x07FF4040%N: \x01%s", client, message);
						}
					}
					case 2:
					{
						for (new enemy = 1; enemy <= MaxClients; enemy++)
						{
							if (IsValidClient(enemy) && IsValidClient(client) && GetClientTeam(enemy) != GetClientTeam(client))
							{
								CSkipNextClient(enemy);
								CSkipNextClient(client);

								switch (GetClientTeam(client))
								{
									case Team_Spectator: CPrintToChatAll("\x07C8C8C8%N: \x01%s",        client, message);
									case Team_Allies:    CPrintToChatAll("(Team) \x074D7942%N: \x01%s", client, message);
									case Team_Axis:      CPrintToChatAll("(Team) \x07FF4040%N: \x01%s", client, message);
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

bool:IsValidClient(client)
{
	return (client > 0 && IsClientInGame(client)) ? true : false;
}