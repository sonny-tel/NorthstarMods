untyped
globalize_all_functions

UIPresenceStruct function DiscordRPC_GenerateUIPresence( UIPresenceStruct uis )
{
	string partySub = GetConVarString( "match_partySub" )

	if ( uiGlobal.isLoading )
	{
		ClearJoinSecret()
		uis.gameState = eDiscordGameState.LOADING;
	}
	else if ( uiGlobal.loadedLevel == "" )
	{
		ClearJoinSecret()
		uis.gameState = eDiscordGameState.MAINMENU;
	}
	else if ( IsLobby() || uiGlobal.loadedLevel == "mp_lobby" )
	{
		uis.gameState = eDiscordGameState.LOBBY;
		if ( partySub == "" )
			ClientCommand( "createparty" )
		else 
			SetJoinSecret( true )
	}
	else
	{
		uis.gameState = eDiscordGameState.INGAME;
		if ( partySub == "")
			ClientCommand( "createparty" )
		else 
			SetJoinSecret( true )
	}

	if ( GetPartySize() > 1 )
		uis.in_party = true
	else
		uis.in_party = false

	uis.is_vanilla = NSIsVanilla()
	uis.party_size = GetPartySize()
	
	string playlists = GetNextAutoMatchmakingPlaylist()
	int smallestMaxplayers = 0
	array<string> playlistNames = split( playlists, "," )

	foreach( playlistName in playlistNames )
	{
		int maxPlayers = GetGamemodeVarOrUseValue( "max_players", playlistName, "16" ).tointeger()

		if ( smallestMaxplayers == 0 )
			smallestMaxplayers = maxPlayers

		if ( maxPlayers < smallestMaxplayers )
			smallestMaxplayers = maxPlayers
	}

	if ( playlists == "private_match" )
		uis.party_max_players = smallestMaxplayers
	else
		uis.party_max_players = smallestMaxplayers / 2

	return uis
}