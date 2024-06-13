global function AddExtrasMenu
global function InitExtrasMenu

struct 
{
    var menu
	table<var,string> buttonDescriptions
} file

void function AddExtrasMenu()
{
	AddMenu( "ExtrasMenu", $"resource/ui/menus/extras.menu", InitExtrasMenu )
}

void function InitExtrasMenu()
{
	var menu = GetMenu( "ExtrasMenu" )
	file.menu = menu

	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnExtrasMenu_Open )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnExtrasMenu_Close )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnExtrasMenu_NavigateBack )

	var button = Hud_GetChild( menu, "BtnPlayerList" )
	SetupButton( button, "Player List", "View current players in server, including the lobby." )
	Hud_AddEventHandler( button, UIE_CLICK, AdvanceMenuEventHandler( GetMenu( "PlayerlistMenu" ) ) )

	button = Hud_GetChild( menu, "SwchCommunitiesEnabled" )
	SetupButton( button, "Enable Communities/Networks", "Sets whether networks and community features will be used. They are always disabled in Northstar.")

	button = Hud_GetChild( menu, "SwchFilterByRegion" )
	SetupButton( button, "Filter Network Invites By: Region", "Sets whether network invites will be filtered by region. (You can receive invites from players on different datacenters with this disabled.)")

	button = Hud_GetChild( menu, "SwchFilterByLanguage" )
	SetupButton( button, "Filter Network Invites By: Language", "Sets whether network invites will be filtered by Language. (You can receive invites from players running the game on a different language with this disabled.)")

	SetupButton( Hud_GetChild( Hud_GetChild( menu, "SldInviteDuration" ), "BtnDropButton" ), "Network Invite Duration", "Sets how long your network invite will last. Other players can see this." )
	AddButtonEventHandler( Hud_GetChild( menu, "TextEntrySldInviteDuration" ), UIE_CHANGE, TextEntrySldInviteDuration_Changed )


	SetupButton( Hud_GetChild( menu, "SwchDamageIndicators"), "Damage Indicators", "Sets whether incoming and/or outgoing damage indicators are enabled." )
	SetupButton( Hud_GetChild( menu, "SwchCoreFlyouts"), "Core Notifications", "Sets whether you'll see flyouts when someone gets core." )
	SetupButton( Hud_GetChild( menu, "SwchMedalIcons"), "Disable Medal Icons", "Hides score event medals." )

	SetupButton( Hud_GetChild( menu, "BtnPlayDemo"), "Play Demo", "Play a demo file." )
	Hud_AddEventHandler( Hud_GetChild( menu, "BtnPlayDemo"), UIE_CLICK, AdvanceMenuEventHandler( GetMenu( "DemopickerMenu" ) ) )
	SetupButton( Hud_GetChild( menu, "SwchEnableDemos"), "Enable Demos", "Sets whether demos are enabled." )
	SetupButton( Hud_GetChild( menu, "SwchDemoAutorecord"), "Automatically Record Demos", "Enables automatic recording of game matches as Demos." )
	SetupButton( Hud_GetChild( menu, "SwchDemoWriteLocalFile"), "Write Demo Files", "Sets whether demos are written to disk." )

	SetupButton( Hud_GetChild( menu, "BtnTogglePauseDemo" ), "Pause/Play Current Demo", "Will pause or play current demo, alternatively you can bind this to a key in the controls menu.\nNote: you must be in a demo for this to do anything." )
	Hud_AddEventHandler( Hud_GetChild( menu, "BtnPlayDemo"), UIE_CLICK, OnTogglePauseDemoButton_Active )
	
	SetupButton( Hud_GetChild( Hud_GetChild( menu, "SldDemoTimescale" ), "BtnDropButton" ), "Demo Timescale", "Sets the timescale of the current demo." )
	AddButtonEventHandler( Hud_GetChild( menu, "TextEntryDemoTimescale" ), UIE_CHANGE, TextEntryDemoTimescale_Changed )

    AddMenuFooterOption( menu, BUTTON_A, "#A_BUTTON_SELECT" )
	AddMenuFooterOption( menu, BUTTON_B, "#B_BUTTON_BACK", "#BACK" )
	// AddMenuFooterOption( menu, BUTTON_X, "#X_BUTTON_APPLY", "#APPLY", ApplyVideoSettingsButton_Activate, AreVideoSettingsChanged )
	// AddMenuFooterOption( menu, BUTTON_Y, "#Y_BUTTON_RESTORE_SETTINGS", "#MENU_RESTORE_SETTINGS", RestoreRecommendedDialog, ShouldEnableRestoreRecommended )
}

void function TextEntryDemoTimescale_Changed( var button )
{
    var menu = GetMenu( "DialogTextEntry" )
    var textEntry = Hud_GetChild( menu, "TextEntryBox" )

    string value = Hud_GetUTF8Text( textEntry )

    if( value == "" )
        return

    ClientCommand( "demo_timescale " + value )
}

void function OnTogglePauseDemoButton_Active( var button )
{
	ClientCommand( "demo_togglepause" )
}

void function OnPlayDemoButton_Activate( var button )
{
    DialogData dialogData
    dialogData.header = "Play Demo"
    dialogData.message = "Enter a Demo filename.\nYou can find them in your Titanfall2/r2 folder, they'll have a .dem file prefix."

    AddDialogButton( dialogData, "#OK", OnPlayDemoDialog )
    AddDialogButton( dialogData, "#CANCEL" )

    OpenTextEntryDialog( dialogData )   
}

void function OnPlayDemoDialog()
{
    var menu = GetMenu( "DialogTextEntry" )
    var textEntry = Hud_GetChild( menu, "TextEntryBox" )

    string file = Hud_GetUTF8Text( textEntry )

    if( file == "" )
        return

    ClientCommand( "playdemo " + file )
}

void function TextEntrySldInviteDuration_Changed( var button )
{
	try
	{
		int num = Hud_GetUTF8Text( Hud_GetChild( file.menu, "TextEntrySldInviteDuration" ) ).tointeger()

		if ( num >= 1 || num <= 120 )
			SetConVarInt( "openinvite_duration_default", num )
	}
	catch(ex)
	{}
}

void function SetupButton( var button, string buttonText, string description )
{
	SetButtonRuiText( button, buttonText )
	file.buttonDescriptions[ button ] <- description
	AddButtonEventHandler( button, UIE_GET_FOCUS, Button_Focused )
}

void function Button_Focused( var button )
{
	string description = file.buttonDescriptions[ button ]
	SetElementsTextByClassname( file.menu, "MenuItemDescriptionClass", description )
}

void function OnExtrasMenu_Open()
{
	UI_SetPresentationType( ePresentationType.NO_MODELS )

	if( !IsFullyConnected() )
		Hud_SetEnabled( Hud_GetChild( file.menu, "BtnPlayerList" ), false )
	else 
		Hud_SetEnabled( Hud_GetChild( file.menu, "BtnPlayerList" ), true )
}

void function OnExtrasMenu_Close()
{
	SavePlayerSettings()
}

void function OnExtrasMenu_NavigateBack()
{
	if ( uiGlobal.videoSettingsChanged )
		NavigateBackApplyVideoSettingsDialog()
	else
		CloseActiveMenu()
}