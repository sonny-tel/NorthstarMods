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
		if ( partySub == ")
			ClientCommand( "createparty" )
		else 
			SetJoinSecret( true )
	}

	uis.is_vanilla = NSIsVanilla()

	return uis
}