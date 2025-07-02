global function AddFriendslistMenu
global function InitFriendslistMenu

const UPDATE_RATE = 1.0

struct
{
	var menu
	GridMenuData gridData
	FriendsData& friendsData
	int selectedElemNum
} file

void function AddFriendslistMenu()
{	
    AddMenu( "FriendslistMenu", $"resource/ui/menus/friendslist.menu", InitFriendslistMenu )
}

void function InitFriendslistMenu()
{
	RegisterSignal( "EndUpdateFriendslistMenu" )
	RegisterSignal( "EndUpdateMenuTitle" )
	RegisterSignal( "EndConfirmFriendInvite" )

	var menu = GetMenu( "FriendslistMenu" )
	file.menu = menu

	file.gridData.initCallback = FriendButton_Init
	file.gridData.clickCallback = FriendButton_Activate
	file.gridData.getFocusCallback = FriendButton_GetFocus
	file.gridData.rows = 15
	file.gridData.columns = 2
	file.gridData.pageFillDirection = eGridPageFillDirection.DOWN
	file.gridData.pageType = eGridPageType.HORIZONTAL
	file.gridData.tileWidth = 400
	file.gridData.tileHeight = 40
	file.gridData.paddingVert = 6
	file.gridData.paddingHorz = 6
	file.gridData.panelLeftPadding = 64
	file.gridData.panelRightPadding = 64
	file.gridData.panelBottomPadding = 64
	file.gridData.forceHeaderAndFooterLayoutForSinglePage = true

	Grid_AutoAspectSettings( menu, file.gridData )

	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnFriendslistMenu_Open )

	AddMenuFooterOption( menu, BUTTON_B, "#B_BUTTON_BACK", "#BACK" )
	AddMenuFooterOption( menu, BUTTON_A, "#A_BUTTON_INVITE", "#MENU_TITLE_INVITE_FRIENDS", InviteFriendsIGO, IsFriendNotFocused )
}

void function OnFriendslistMenu_Open()
{
	Signal( uiGlobal.signalDummy, "EndUpdateFriendslistMenu" )
	EndSignal( uiGlobal.signalDummy, "EndUpdateFriendslistMenu" )

	UI_SetPresentationType( ePresentationType.NO_MODELS )

	var ruiMenuTitle = Hud_GetRui( Hud_GetChild( file.menu, "RuiMenuTitle" ) )
	RuiSetString( ruiMenuTitle, "labelText", Localize( "JOIN FRIENDS" ) )

	int numFriends = -1
	int lastNumFriends = -2

	file.gridData.currentPage = 0

	while ( GetTopNonDialogMenu() == file.menu )
	{
        table< string, string> subscriptionMap = NSGetFriendSubscriptionMap()
		file.friendsData = GetFriendsData()

        for( int i = 0; i < file.friendsData.friends.len(); i++ )
        {
            Friend friend = file.friendsData.friends[i]

            if( !( friend.id in subscriptionMap ) )
                file.friendsData.friends.remove(i)
        }

		numFriends = subscriptionMap.len()

		if ( numFriends != lastNumFriends )
		{
			file.gridData.numElements = numFriends

			int maxPageIndex = Grid_GetNumPages( file.gridData ) - 1
			if ( maxPageIndex < file.gridData.currentPage )
				file.gridData.currentPage = maxPageIndex

			GridMenuInit( file.menu, file.gridData )

			if ( file.friendsData.isValid )
				Grid_SetReadyState( file.menu, true )
			else
				Grid_SetReadyState( file.menu, false )

			UpdateFooterOptions()
		}

		lastNumFriends = numFriends

		wait UPDATE_RATE
	}
}

bool function IsFriendNotFocused()
{
	var focus = GetFocus()

	if ( focus != null && file.friendsData.isValid )
	{
		table< int, var > buttons = Grid_GetActivePageButtons( file.menu )

		foreach ( button in buttons )
		{
			if ( button == focus )
				return false
		}
	}

	return true
}

bool function FriendButton_Init( var button, int elemNum )
{
	Friend friend = file.friendsData.friends[elemNum]
    table< string, string> subscriptionMap = NSGetFriendSubscriptionMap()

	var rui = Hud_GetRui( button )
	RuiSetString( rui, "buttonText", friend.name )

	return true
}

void function ConfirmFriendInvite_Final()
{
	Friend friend = file.friendsData.friends[file.selectedElemNum]
	string name = friend.name
	string id = friend.id

    table< string, string> subscriptionMap = NSGetFriendSubscriptionMap()

	printt( "Friend Name:", name, "id:", id)

	foreach( string id, string matchSub in subscriptionMap )
	{
		if ( friend.id == id )
			ClientCommand( "ns_join_room " + matchSub )
	}
}

void function ConfirmFriendInvite_Thread()
{
	Signal( uiGlobal.signalDummy, "EndConfirmFriendInvite" )
	EndSignal( uiGlobal.signalDummy, "EndConfirmFriendInvite" )

	DialogData dialogData

	Friend friend = file.friendsData.friends[file.selectedElemNum]
	string name = friend.name

	dialogData.header = Localize( "JOIN PARTY" )
	dialogData.message = Localize( "Would you like to join " + name + "'s party?" )

	AddDialogButton( dialogData, "#YES", ConfirmFriendInvite_Final )
	AddDialogButton( dialogData, "#NO" )

	AddDialogFooter( dialogData, "#A_BUTTON_SELECT" )
	AddDialogFooter( dialogData, "#B_BUTTON_BACK" )

	OpenDialog( dialogData )
}

void function FriendButton_Activate( var button, int elemNum )
{
	if ( Hud_IsLocked( button ) )
		return

	file.selectedElemNum = elemNum
	thread ConfirmFriendInvite_Thread()
}

void function FriendButton_GetFocus( var button, int elemNum )
{
	UpdateFooterOptions()
}

void function InviteFriendsIGO( var button )
{
    #if PC_PROG
		if ( !Origin_IsOverlayAvailable() )
		{
			PopUpOriginOverlayDisabledDialog()
			return
		}
	#endif

	thread CreatePartyAndInviteFriends()
}