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
		if ( NSIsVanilla() )
		{
			if ( partySub == "")
				ClientCommand( "createparty" )
			else 
				SetJoinSecret( true )
		}
		uis.gameState = eDiscordGameState.LOBBY;
	}
	else if ( IsMultiplayer() )
	{
		if ( NSIsVanilla() )
		{
			if ( partySub == "")
				ClientCommand( "createparty" )
			else 
				SetJoinSecret( true )
		}
		uis.gameState = eDiscordGameState.INGAME;

	}

	if ( GetPartySize() > 1 )
		uis.in_party = true
	else
		uis.in_party = false

	uis.is_vanilla = NSIsVanilla()
	uis.party_size = GetPartySize()
	
	string playlists = GetNextAutoMatchmakingPlaylist()
	if( IsFullyConnected() && IsMultiplayer() )
	{
		int smallestMaxplayers = GetGamemodeVarOrUseValue( "private_match", "max_players", "16" ).tointeger()
		array<string> playlistNames = split( playlists, "," )

		foreach( playlistName in playlistNames )
		{
			int maxPlayers = GetGamemodeVarOrUseValue( playlistName, "max_players", "16" ).tointeger()

			if ( maxPlayers < smallestMaxplayers )
				smallestMaxplayers = maxPlayers
		}

		if ( playlists.len() > 0 )
			uis.party_max_players = smallestMaxplayers / 2
		else
			uis.party_max_players = GetCurrentPlaylistVarInt( "max_players", 16 )
	} else
		uis.party_max_players = GetCurrentPlaylistVarInt( "max_players", 16 )

	return uis
}