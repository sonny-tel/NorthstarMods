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
	SetupButton( Hud_GetChild( menu, "SwchMinimalOOBWarning"), "Minimal Out-Of-Bounds Warning", "Show only the timer from OOB warning." )
	SetupButton( Hud_GetChild( menu, "SwchSpeedometer"), "Show Speedometer", "Shows a speedometer in KPH or MPH. (You will need to reload the current level for this to update.)" )
	SetupButton( Hud_GetChild( menu, "SwchHealthBar"), "Show Pilot Health Indicator", "Shows a small healthbar under the crosshair.\nNote: Isn't aligned to the crosshair cockpit so it may look weird." )

	SetupButton( Hud_GetChild( menu, "BtnPlayDemo"), "Play Demo", "Play a demo file." )
	Hud_AddEventHandler( Hud_GetChild( menu, "BtnPlayDemo"), UIE_CLICK, AdvanceMenuEventHandler( GetMenu( "DemopickerMenu" ) ) )
	SetupButton( Hud_GetChild( menu, "SwchEnableDemos"), "Enable Demos", "Sets whether demos are enabled." )
	SetupButton( Hud_GetChild( menu, "SwchDemoAutorecord"), "Automatically Record Demos", "Enables automatic recording of game matches as Demos." )
	SetupButton( Hud_GetChild( menu, "SwchDemoWriteLocalFile"), "Write Demo Files", "Sets whether demos are written to disk." )
	

	SetupButton( Hud_GetChild( menu, "SwchBloom"), "Bloom", "Sets whether bloom is enabled." )
	SetupButton( Hud_GetChild( menu, "SwchDOF"), "Depth-of-field", "Sets whether DOF is enabled, can be set to only work in Lobby." )

	SetupButton( Hud_GetChild( Hud_GetChild( menu, "SldSunScale" ), "BtnDropButton" ), "Sun Scale", "Sets the size of the Sun lighting particle." )
	AddButtonEventHandler( Hud_GetChild( menu, "TextEntrySunScale" ), UIE_CHANGE, TextEntrySunScale_Changed )
	SetupButton( Hud_GetChild( Hud_GetChild( menu, "SldSkyScale" ), "BtnDropButton" ), "Sky Scale", "Sets size of the Sky lighting particle." )
	AddButtonEventHandler( Hud_GetChild( menu, "TextEntrySkyScale" ), UIE_CHANGE, TextEntrySkyScale_Changed )


    AddMenuFooterOption( menu, BUTTON_A, "#A_BUTTON_SELECT" )
	AddMenuFooterOption( menu, BUTTON_B, "#B_BUTTON_BACK", "#BACK" )
}

void function TextEntrySkyScale_Changed( var button )
{
	try
	{
		float num = Hud_GetUTF8Text( Hud_GetChild( file.menu, "TextEntrySkyScale" ) ).tofloat()
		SetConVarFloat( "mat_sky_scale", num )
	}
	catch(ex)
	{}
}

void function TextEntrySunScale_Changed( var button )
{
	try
	{
		float num = Hud_GetUTF8Text( Hud_GetChild( file.menu, "TextEntrySunScale" ) ).tofloat()
		SetConVarFloat( "mat_sun_scale", num )
	}
	catch(ex)
	{}
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
		float num = Hud_GetUTF8Text( Hud_GetChild( file.menu, "TextEntrySldInviteDuration" ) ).tofloat()

		if ( num >= 1 || num <= 120 )
			SetConVarFloat( "openinvite_duration_default", num )
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