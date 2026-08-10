untyped

global function AddNorthstarModWorkshopMenu
global function NSUICodeCallback_ModWorkshopPageChanged
global function NSUICodeCallback_ModWorkshopDetailsChanged
global function NSUICodeCallback_ModWorkshopUpdatesChanged
global function NSUICodeCallback_ModWorkshopOperationChanged
global function NSUICodeCallback_ModWorkshopThumbnailReady

const int MWS_VISIBLE_COUNT = 18
const int MWS_BATCH_SIZE = 24
const int MWS_SCROLL_STEP = 6
const int MWS_DETAILS_LINE_WIDTH = 70
const int MWS_DETAILS_VISIBLE_LINES = 5
const float MWS_TITLE_MAX_WIDTH_MULTIPLIER = 1.6
const float MWS_SEARCH_DELAY = 0.35
const int MWS_INVENTORY_LOCAL_COMPLETE = 0
const int MWS_INVENTORY_LOCAL_REMOTE_PENDING = 1
const int MWS_INVENTORY_REMOTE_COMPLETE = 2

struct
{
	var menu
	array<var> cards
	array<var> cardButtons
	var detailsPreviewFocus
	array<var> previewElements
	array<MWSPageEntry> entries
	string search = ""
	string sort = "bumped_at"
	int filter = 0
	int page = 1
	int lastPage = 1
	int scrollOffset = 0
	int totalEntries = 0
	bool fromCache = false
	bool scrollToEnd = false
	bool loading = false
	int requestGeneration = 0
	int detailsGeneration = 0
	int selectedIndex = -1
	string selectedId = ""
	int pendingAction = eMWSInstallAction.INSTALL
	int browseOperationGeneration = 0
	int lastTerminalGeneration = 0
	bool isOpen = false
	bool previewVisible = false
	int inventoryGeneration = 0
	bool forcePageRefresh = false
	bool focusCardsOnNextRender = false
	array<string> detailsLines
	int detailsScrollOffset = 0
	bool operationDialogRunning = false
	int lastOperationDialogGeneration = 0
	int lastMigrationPromptGeneration = 0
} file

void function AddNorthstarModWorkshopMenu()
{
	RegisterSignal( "MWS_SearchChanged" )
	RegisterSignal( "MWS_OperationChanged" )
	thread ModWorkshopOperationDialog_Think()
	AddMenu( "ModWorkshopMenu", $"resource/ui/menus/modworkshop.menu", InitModWorkshopMenu )
	MWSOperationSnapshot operation = NSMWSGetOperationState()
	if ( operation.state != eMWSInstallState.IDLE )
		Signal( uiGlobal.signalDummy, "MWS_OperationChanged" )
}

void function InitModWorkshopMenu()
{
	file.menu = GetMenu( "ModWorkshopMenu" )
	file.cards = GetElementsByClassname( file.menu, "MWSCard" )
	file.cardButtons = GetElementsByClassname( file.menu, "MWSCardButton" )
	file.detailsPreviewFocus = Hud_GetChild( file.menu, "DetailsPreviewFocus" )
	file.previewElements = GetElementsByClassname( file.menu, "MWSPreviewPane" )
	Hud_EnableKeyBindingIcons( Hud_GetChild( file.menu, "PageLabel" ) )
	SetPreviewVisible( false )

	foreach ( var button in file.cardButtons )
	{
		AddButtonEventHandler( button, UIE_GET_FOCUS, OnCardFocused )
		AddButtonEventHandler( button, UIE_CLICK, OnCardActivated )
	}

	AddButtonEventHandler( Hud_GetChild( file.menu, "MwsSearch" ), UIE_CHANGE, OnSearchChanged )
	AddButtonEventHandler( Hud_GetChild( file.menu, "MwsSort" ), UIE_CHANGE, OnSortChanged )
	AddButtonEventHandler( Hud_GetChild( file.menu, "MwsFilter" ), UIE_CHANGE, OnFilterChanged )
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "MwsSort" ) ), "buttonText", "" )
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "MwsFilter" ) ), "buttonText", "" )
	AddCallback_InputEvent( InputEventType.IE_AnalogValueChanged, OnAnalogueScroll )

	AddMenuEventHandler( file.menu, eUIEvent.MENU_OPEN, OnModWorkshopOpened )
	AddMenuEventHandler( file.menu, eUIEvent.MENU_CLOSE, OnModWorkshopClosed )
	AddMenuFooterOption( file.menu, BUTTON_A, "#A_BUTTON_SELECT" )
	AddMenuFooterOption( file.menu, BUTTON_B, "#B_BUTTON_BACK", "#BACK" )
	AddMenuFooterOption( file.menu, BUTTON_X, PrependControllerPrompts( BUTTON_X, "#REFRESH_SERVERS" ), "#REFRESH_SERVERS", OnRefresh )

	Hud_SetDialogListSelectionValue( Hud_GetChild( file.menu, "MwsSort" ), file.sort )
	Hud_SetDialogListSelectionValue( Hud_GetChild( file.menu, "MwsFilter" ), string( file.filter ) )
}

void function OnModWorkshopOpened()
{
	file.isOpen = true
	file.focusCardsOnNextRender = true
	SetPreviewVisible( false )
	UI_SetPresentationType( ePresentationType.NO_MODELS )
	NSMWSInitializeThumbnailAtlas()
	ResetScroll()
	file.loading = true
	ShowGridMessage( "#MWS_LOADING" )
	Hud_SetText( Hud_GetChild( file.menu, "PageLabel" ), "#MWS_LOADING_SHORT" )
	BeginInventoryRefresh( true, false )
}

void function OnModWorkshopClosed()
{
	file.isOpen = false
	file.focusCardsOnNextRender = false
	Signal( uiGlobal.signalDummy, "MWS_SearchChanged" )
	NSMWSCancelPage()
	NSMWSCancelDetails()
}

void function ResetScroll()
{
	file.page = 1
	file.scrollOffset = 0
	file.scrollToEnd = false
}

void function BeginInventoryRefresh( bool checkRemote, bool forcePageRefresh )
{
	file.forcePageRefresh = forcePageRefresh
	file.inventoryGeneration = NSMWSRefreshTrackedMods( checkRemote )
}

void function OnRefresh( var button )
{
	if ( file.loading )
		return
	file.focusCardsOnNextRender = ModWorkshop_IsCardFocused()
	file.loading = true
	ShowGridMessage( "#MWS_LOADING" )
	Hud_SetText( Hud_GetChild( file.menu, "PageLabel" ), "#MWS_LOADING_SHORT" )
	BeginInventoryRefresh( true, true )
}



void function OnSearchChanged( var button )
{
	string value = Hud_GetUTF8Text( button )
	file.focusCardsOnNextRender = false
	Signal( uiGlobal.signalDummy, "MWS_SearchChanged" )
	thread ApplySearchAfterDelay( value )
}

void function ApplySearchAfterDelay( string value )
{
	EndSignal( uiGlobal.signalDummy, "MWS_SearchChanged" )
	wait MWS_SEARCH_DELAY
	if ( !file.isOpen )
		return
	file.focusCardsOnNextRender = false
	file.search = value
	ResetScroll()
	RequestCurrentPage( false )
}

void function OnSortChanged( var button )
{
	file.focusCardsOnNextRender = false
	file.sort = Hud_GetDialogListSelectionValue( button )
	ResetScroll()
	RequestCurrentPage( false )
}

void function OnFilterChanged( var button )
{
	file.focusCardsOnNextRender = false
	file.filter = int( Hud_GetDialogListSelectionValue( button ) )
	ResetScroll()
	if ( file.filter == 2 )
	{
		file.loading = true
		ShowGridMessage( "#MWS_LOADING" )
		Hud_SetText( Hud_GetChild( file.menu, "PageLabel" ), "#MWS_LOADING_SHORT" )
		BeginInventoryRefresh( true, false )
		return
	}
	RequestCurrentPage( false )
}

bool function ModWorkshop_IsCardFocused()
{
	var focused = GetFocus()
	foreach ( var button in file.cardButtons )
	{
		if ( focused == button )
			return true
	}
	return false
}

void function OnAnalogueScroll( int eventType, int nTick, int nData, int nData2, int nData3 )
{
	if ( !file.isOpen || uiGlobal.activeMenu != file.menu || nData != AnalogCode.MOUSE_WHEEL )
		return
	if ( GetFocus() == file.detailsPreviewFocus )
	{
		ScrollDetails( nData3 > 0 ? -1 : 1 )
		return
	}
	if ( nData3 > 0 )
		OnScrollUp()
	else if ( nData3 < 0 )
		OnScrollDown()
}

void function OnScrollDown()
{
	if ( file.loading || file.entries.len() == 0 )
		return
	int maxOffset = maxint( 0, file.entries.len() - MWS_VISIBLE_COUNT )
	int nextOffset = minint( maxOffset, file.scrollOffset + MWS_SCROLL_STEP )
	if ( nextOffset != file.scrollOffset )
	{
		file.scrollOffset = nextOffset
		RenderVisibleEntries( true )
		return
	}
	if ( file.page >= file.lastPage )
		return
	file.page++
	file.scrollOffset = 0
	file.scrollToEnd = false
	file.focusCardsOnNextRender = true
	RequestCurrentPage( false )
}

void function OnScrollUp()
{
	if ( file.loading || file.entries.len() == 0 )
		return
	int nextOffset = maxint( 0, file.scrollOffset - MWS_SCROLL_STEP )
	if ( nextOffset != file.scrollOffset )
	{
		file.scrollOffset = nextOffset
		RenderVisibleEntries( true )
		return
	}
	if ( file.page <= 1 )
		return
	file.page--
	file.scrollToEnd = true
	file.focusCardsOnNextRender = true
	RequestCurrentPage( false )
}

void function RequestCurrentPage( bool forceRefresh )
{
	if ( !file.isOpen )
		return
	file.loading = true
	file.requestGeneration = NSMWSRequestPage(
		file.search,
		file.sort,
		file.page,
		file.filter,
		forceRefresh
	)
	ShowGridMessage( "#MWS_LOADING" )
}

void function NSUICodeCallback_ModWorkshopPageChanged( int generation )
{
	if ( !file.isOpen )
		return
	MWSPageSnapshot snapshot = NSMWSGetPage()
	if ( snapshot.generation != file.requestGeneration )
		return
	RenderPage( snapshot )
}

void function RenderPage( MWSPageSnapshot snapshot )
{
	file.loading = snapshot.state == eMWSLoadState.LOADING
	if ( snapshot.state == eMWSLoadState.LOADING )
	{
		ShowGridMessage( "#MWS_LOADING" )
		Hud_SetText( Hud_GetChild( file.menu, "PageLabel" ), "#MWS_LOADING_SHORT" )
		return
	}
	if ( snapshot.state == eMWSLoadState.FAILED )
	{
		ShowGridMessage( snapshot.error == "" ? "#MWS_UNAVAILABLE" : snapshot.error )
		Hud_SetText( Hud_GetChild( file.menu, "PageLabel" ), "#MWS_SCROLL_UNAVAILABLE" )
		return
	}
	if ( snapshot.state == eMWSLoadState.CANCELLED )
		return
	if ( snapshot.state != eMWSLoadState.READY )
	{
		ShowGridMessage( "#MWS_NOT_READY" )
		return
	}

	file.entries = snapshot.entries
	file.page = snapshot.currentPage
	file.lastPage = maxint( 1, snapshot.lastPage )
	file.totalEntries = maxint( snapshot.total, file.entries.len() )
	file.fromCache = snapshot.fromCache
	int maxOffset = maxint( 0, file.entries.len() - MWS_VISIBLE_COUNT )
	if ( file.scrollToEnd )
	{
		file.scrollOffset = maxOffset
		file.scrollToEnd = false
	}
	else
	{
		file.scrollOffset = minint( file.scrollOffset, maxOffset )
	}

	if ( file.entries.len() == 0 )
	{
		file.focusCardsOnNextRender = false
		ShowGridMessage( "#MWS_NO_MODS_FOUND" )
		Hud_SetText( Hud_GetChild( file.menu, "PageLabel" ), "#NO_RESULTS" )
		ClearDetails()
		return
	}
	HideGridMessage()
	bool focusCards = file.focusCardsOnNextRender
	file.focusCardsOnNextRender = false
	RenderVisibleEntries( focusCards )
}

void function RenderVisibleEntries( bool focusCards )
{
	HideAllCards()
	int visibleCount = minint( MWS_VISIBLE_COUNT, file.entries.len() - file.scrollOffset )
	for ( int visibleIndex = 0; visibleIndex < visibleCount; visibleIndex++ )
	{
		int entryIndex = file.scrollOffset + visibleIndex
		MWSPageEntry entry = file.entries[ entryIndex ]
		var card = file.cards[ visibleIndex ]
		var button = file.cardButtons[ visibleIndex ]
		Hud_Show( card )
		Hud_Show( button )
		Hud_SetEnabled( button, true )
		RuiSetImage(
			Hud_GetRui( Hud_GetChild( card, "Thumbnail" ) ),
			"basicImage",
			GetModWorkshopThumbnail( entry.atlasSlot )
		)
		SetScaledTitle( Hud_GetChild( card, "ModName" ), entry.name, 162.0 )
		Hud_SetText( Hud_GetChild( card, "ModAuthor" ), GetAuthorText( entry.author, "" ) )
		Hud_SetText( Hud_GetChild( card, "ModStatus" ), GetCardStatus( entry ) )
	}

	int focusIndex = 0
	if ( file.selectedId != "" )
	{
		for ( int visibleIndex = 0; visibleIndex < visibleCount; visibleIndex++ )
		{
			if ( file.entries[ file.scrollOffset + visibleIndex ].id == file.selectedId )
			{
				focusIndex = visibleIndex
				break
			}
		}
	}
	if ( focusCards )
		Hud_SetFocused( file.cardButtons[ focusIndex ] )
	SelectCard( file.scrollOffset + focusIndex )
	UpdateScrollLabel( visibleCount )
}

void function UpdateScrollLabel( int visibleCount )
{
	int first = ( file.page - 1 ) * MWS_BATCH_SIZE + file.scrollOffset + 1
	int last = first + visibleCount - 1
	int total = maxint( file.totalEntries, last )
	Hud_SetText(
		Hud_GetChild( file.menu, "PageLabel" ),
		Localize(
			"#MWS_PAGE_RANGE",
			string( first ),
			string( last ),
			string( total ),
			file.fromCache ? Localize( "#MWS_CACHED_SUFFIX" ) : ""
		)
	)
}

void function HideAllCards()
{
	foreach ( var card in file.cards )
		Hud_Hide( card )
	foreach ( var button in file.cardButtons )
	{
		Hud_Hide( button )
		Hud_SetEnabled( button, false )
	}
}

void function ShowGridMessage( string message )
{
	HideAllCards()
	SetPreviewVisible( false )
	var label = Hud_GetChild( file.menu, "GridMessage" )
	Hud_SetText( label, message )
	Hud_Show( label )
}

void function HideGridMessage()
{
	Hud_Hide( Hud_GetChild( file.menu, "GridMessage" ) )
}

void function OnCardFocused( var button )
{
	SelectCard( file.scrollOffset + int( Hud_GetScriptID( button ) ) )
}

void function OnCardActivated( var button )
{
	int index = file.scrollOffset + int( Hud_GetScriptID( button ) )
	SelectCard( index )
	OpenDownloadDialog()
}

void function SelectCard( int index )
{
	if ( index < 0 || index >= file.entries.len() )
		return
	MWSPageEntry entry = file.entries[ index ]
	file.selectedIndex = index
	file.selectedId = entry.id
	SetPreviewVisible( NSMWSIsThumbnailReady( file.requestGeneration, entry.id, entry.atlasSlot ) )
	RuiSetImage(
		Hud_GetRui( Hud_GetChild( file.menu, "DetailsImage" ) ),
		"basicImage",
		GetModWorkshopThumbnail( entry.atlasSlot )
	)
	SetScaledTitle( Hud_GetChild( file.menu, "DetailsName" ), entry.name, 460.0 )
	Hud_SetText( Hud_GetChild( file.menu, "DetailsAuthor" ), GetAuthorText( entry.author, entry.version ) )
	SetDetailsDescription( entry.summary )
	Hud_SetText( Hud_GetChild( file.menu, "DetailsStatus" ), GetDownloadCountText( entry.downloads ) )
	Hud_SetText( Hud_GetChild( file.menu, "ProgressLabel" ), "" )
	file.detailsGeneration = NSMWSRequestDetails( entry.id, false )
}

void function NSUICodeCallback_ModWorkshopThumbnailReady( int generation, string modId, int atlasSlot )
{
	if ( !file.isOpen || generation != file.requestGeneration || modId != file.selectedId )
		return
	if ( file.selectedIndex < 0 || file.selectedIndex >= file.entries.len() )
		return
	MWSPageEntry entry = file.entries[ file.selectedIndex ]
	if ( entry.id != modId || entry.atlasSlot != atlasSlot )
		return
	SetPreviewVisible( true )
}

void function NSUICodeCallback_ModWorkshopDetailsChanged( string modId )
{
	if ( !file.isOpen || modId != file.selectedId )
		return
	MWSDetailsSnapshot details = NSMWSGetDetails()
	if ( details.generation != file.detailsGeneration || details.id != file.selectedId )
		return
	if ( details.state == eMWSLoadState.LOADING )
	{
		Hud_SetText( Hud_GetChild( file.menu, "ProgressLabel" ), "#MWS_LOADING_DETAILS" )
		return
	}
	if ( details.state == eMWSLoadState.FAILED )
	{
		Hud_SetText( Hud_GetChild( file.menu, "ProgressLabel" ), details.error == "" ? "#MWS_DETAILS_UNAVAILABLE" : details.error )
		return
	}
	if ( details.state != eMWSLoadState.READY )
		return

	string description = details.description
	if ( details.dependencies.len() > 0 )
	{
		string dependencies = ""
		foreach ( int index, string dependency in details.dependencies )
			dependencies += ( index == 0 ? "" : ", " ) + dependency
		description += Localize( "#MWS_REQUIRES", dependencies )
	}
	SetScaledTitle( Hud_GetChild( file.menu, "DetailsName" ), details.name, 460.0 )
	Hud_SetText( Hud_GetChild( file.menu, "DetailsAuthor" ), GetAuthorText( details.author, details.version ) )
	SetDetailsDescription( description )
	Hud_SetText(
		Hud_GetChild( file.menu, "DetailsStatus" ),
		Localize( "#MWS_DETAILS_STATS", string( details.downloads ), string( details.likes ), string( details.views ) )
	)
	Hud_SetText( Hud_GetChild( file.menu, "ProgressLabel" ), "" )
}


void function OpenDownloadDialog()
{
	if ( file.selectedIndex < 0 || file.selectedIndex >= file.entries.len() )
		return
	MWSPageEntry entry = file.entries[ file.selectedIndex ]
	MWSOperationSnapshot operation = NSMWSGetOperationState()
	if ( IsOperationBusy( operation.state ) && operation.id == entry.id )
	{
		NSMWSCancelOperation()
		return
	}
	if ( IsOperationBusy( operation.state ) )
	{
		ShowOperationError( Localize( "#MWS_ANOTHER_OPERATION_ACTIVE" ) )
		return
	}
	if ( !entry.canInstall )
	{
		DialogData unavailableDialog
		unavailableDialog.header = Localize( "#MWS_DOWNLOAD_UNAVAILABLE" )
		unavailableDialog.message = Localize( "#MWS_CANNOT_INSTALL", entry.name )
		AddDialogButton( unavailableDialog, "#OK" )
		OpenDialog( unavailableDialog )
		return
	}

	if ( entry.installed && entry.updateState != eMWSUpdateState.UPDATE_AVAILABLE )
		return

	file.pendingAction = entry.installed ? eMWSInstallAction.UPDATE : eMWSInstallAction.INSTALL
	string actionLabel = entry.installed ? "#MWS_ACTION_UPDATE" : "#MWS_ACTION_DOWNLOAD"
	string actionVerb = Localize( entry.installed ? "#MWS_ACTION_UPDATE" : "#MWS_VERB_DOWNLOAD_AND_INSTALL" )
	DialogData dialogData
	dialogData.header = Localize( entry.installed ? "#MWS_UPDATE_MOD" : "#MWS_DOWNLOAD_MOD" )
	dialogData.message = Localize( "#MWS_CONFIRM_ACTION", actionVerb, entry.name, entry.author )
	AddDialogButton( dialogData, actionLabel, ConfirmPendingAction )
	AddDialogButton( dialogData, "#CANCEL" )
	OpenDialog( dialogData )
}

void function ConfirmPendingAction()
{
	bool accepted = false
	switch ( file.pendingAction )
	{
		case eMWSInstallAction.INSTALL:
			accepted = NSMWSInstall( file.selectedId )
			break
		case eMWSInstallAction.UPDATE:
			accepted = NSMWSUpdate( file.selectedId )
			break
	}
	if ( !accepted )
	{
		ShowOperationError( Localize( "#MWS_ANOTHER_OPERATION_ACTIVE" ) )
		return
	}
	file.browseOperationGeneration = NSMWSGetOperationState().generation
}




void function ShowMigrationPrompt( MWSOperationSnapshot operation )
{
	file.lastMigrationPromptGeneration = operation.generation
	NSUISetConnectionModalChoiceActive( true )
	CloseAllDialogs()

	int generation = operation.generation
	DialogData dialogData
	dialogData.header = "#MWS_MIGRATION_TITLE"
	dialogData.message = Localize( "#MWS_MIGRATION_MESSAGE", operation.name )
	dialogData.forceChoice = true
	AddDialogButton(
		dialogData,
		"#MWS_MIGRATION_ACCEPT",
		void function() : ( generation )
		{
			NSUISetConnectionModalChoiceActive( false )
			NSMWSDecideMigration( generation, true )
		}
	)
	AddDialogButton(
		dialogData,
		"#MWS_MIGRATION_KEEP",
		void function() : ( generation )
		{
			NSUISetConnectionModalChoiceActive( false )
			NSMWSDecideMigration( generation, false )
		}
	)
	OpenDialog( dialogData )
}

void function NSUICodeCallback_ModWorkshopOperationChanged()
{
	MWSOperationSnapshot operation = NSMWSGetOperationState()
	Signal( uiGlobal.signalDummy, "MWS_OperationChanged" )
	if ( operation.state == eMWSInstallState.AWAITING_MIGRATION &&
		operation.generation != file.lastMigrationPromptGeneration )
	{
		ShowMigrationPrompt( operation )
		return
	}
	if ( operation.generation == file.lastMigrationPromptGeneration && IsOperationTerminal( operation.state ) )
		NSUISetConnectionModalChoiceActive( false )

	if ( operation.generation == file.browseOperationGeneration && IsOperationTerminal( operation.state ) )
	{
		file.browseOperationGeneration = 0
		if ( operation.state == eMWSInstallState.DONE )
		{
			ReloadMods()
			return
		}
	}

	if ( !file.isOpen )
		return
	if ( operation.id == file.selectedId )
		Hud_SetText( Hud_GetChild( file.menu, "ProgressLabel" ), GetOperationProgressText( operation ) )

	if ( IsOperationTerminal( operation.state ) && operation.generation != file.lastTerminalGeneration )
	{
		file.lastTerminalGeneration = operation.generation
		BeginInventoryRefresh( false, false )
	}
}

void function NSUICodeCallback_ModWorkshopUpdatesChanged( int generation, int updateCount, int stage )
{
	if ( !file.isOpen || generation != file.inventoryGeneration )
		return
	if ( stage == MWS_INVENTORY_REMOTE_COMPLETE && file.filter != 2 )
	{
		MWSPageSnapshot snapshot = NSMWSGetPage()
		if ( snapshot.state == eMWSLoadState.READY && snapshot.generation == file.requestGeneration )
		{
			file.focusCardsOnNextRender = file.focusCardsOnNextRender || ModWorkshop_IsCardFocused()
			RenderPage( snapshot )
		}
		return
	}
	if ( stage == MWS_INVENTORY_LOCAL_REMOTE_PENDING && file.filter == 2 )
		return
	bool forceRefresh = file.forcePageRefresh
	file.forcePageRefresh = false
	file.focusCardsOnNextRender = file.focusCardsOnNextRender || ModWorkshop_IsCardFocused()
	ResetScroll()
	RequestCurrentPage( forceRefresh )
}

void function ModWorkshopOperationDialog_Think()
{
	for ( ; ; )
	{
		WaitSignal( uiGlobal.signalDummy, "MWS_OperationChanged" )
		MWSOperationSnapshot operation = NSMWSGetOperationState()
		if ( NSUIConnectionOwnsModDownloadDialog() ||
			operation.generation == 0 ||
			operation.generation == file.lastOperationDialogGeneration ||
			file.operationDialogRunning )
		{
			continue
		}

		file.operationDialogRunning = true
		thread ModWorkshopOperationDialog_Run( operation.generation )
	}
}

void function ModWorkshopOperationDialog_Run( int generation )
{
	WaitFrame()
	MWSOperationSnapshot operation = NSMWSGetOperationState()
	if ( operation.generation != generation )
	{
		file.operationDialogRunning = false
		Signal( uiGlobal.signalDummy, "MWS_OperationChanged" )
		return
	}
	if ( IsOperationTerminal( operation.state ) )
	{
		file.lastOperationDialogGeneration = generation
		file.operationDialogRunning = false
		if ( operation.state == eMWSInstallState.FAILED )
			ShowOperationError( operation.message )
		return
	}
	if ( operation.state == eMWSInstallState.AWAITING_MIGRATION )
	{
		file.operationDialogRunning = false
		return
	}
	if ( !IsOperationBusy( operation.state ) )
	{
		file.operationDialogRunning = false
		return
	}

	DialogData dialogData
	dialogData.header = GetOperationDialogHeader( operation.action )
	dialogData.message = GetOperationProgressText( operation )
	dialogData.showSpinner = true
	dialogData.forceChoice = false
	AddDialogButton( dialogData, "#DISMISS" )
	OpenDialog( dialogData )

	var dialogMenu = GetMenu( "Dialog" )
	var header = Hud_GetChild( dialogMenu, "DialogHeader" )
	var body = GetSingleElementByClassname( dialogMenu, "DialogMessageClass" )
	for ( ; ; )
	{
		operation = NSMWSGetOperationState()
		if ( operation.generation != generation || IsOperationTerminal( operation.state ) )
			break
		if ( operation.state == eMWSInstallState.AWAITING_MIGRATION )
		{
			WaitFrame()
			continue
		}
		if ( uiGlobal.activeMenu == dialogMenu )
		{
			Hud_SetText( header, GetOperationDialogHeader( operation.action ) )
			Hud_SetText( body, GetOperationProgressText( operation ) )
		}
		WaitFrame()
	}

	if ( uiGlobal.activeMenu == dialogMenu )
		CloseAllDialogs()
	file.lastOperationDialogGeneration = generation
	file.operationDialogRunning = false
	if ( operation.generation == generation && operation.state == eMWSInstallState.FAILED )
		ShowOperationError( operation.message )
	if ( operation.generation != generation )
		Signal( uiGlobal.signalDummy, "MWS_OperationChanged" )
}

void function ShowOperationError( string message )
{
	DialogData dialogData
	dialogData.header = Localize( "#MWS_ERROR_TITLE" )
	dialogData.message = message == "" ? Localize( "#MWS_OPERATION_FAILED" ) : Localize( message )
	dialogData.image = $"ui/menu/common/dialog_error"
	AddDialogButton( dialogData, "#OK" )
	OpenDialog( dialogData )
}

void function SetPreviewVisible( bool visible )
{
	file.previewVisible = visible
	foreach ( var element in file.previewElements )
		Hud_SetVisible( element, visible )
	Hud_SetEnabled( file.detailsPreviewFocus, visible )
}

void function ClearDetails()
{
	SetPreviewVisible( false )
	file.selectedIndex = -1
	file.selectedId = ""
	SetScaledTitle( Hud_GetChild( file.menu, "DetailsName" ), Localize( "#MWS_SELECT_MOD" ), 460.0 )
	Hud_SetText( Hud_GetChild( file.menu, "DetailsAuthor" ), "" )
	SetDetailsDescription( "" )
	Hud_SetText( Hud_GetChild( file.menu, "DetailsStatus" ), "" )
	Hud_SetText( Hud_GetChild( file.menu, "ProgressLabel" ), "" )
}

string function GetDownloadCountText( int downloads )
{
	return Localize(
		downloads == 1 ? "#MWS_DOWNLOAD_COUNT_ONE" : "#MWS_DOWNLOAD_COUNT_MANY",
		string( downloads )
	)
}

string function GetCardStatus( MWSPageEntry entry )
{
	return GetDownloadCountText( entry.downloads )
}

string function GetAuthorText( string author, string version )
{
	if ( version == "" )
		return Localize( "#MWS_BY_AUTHOR", author )
	return Localize( "#MWS_BY_AUTHOR_VERSION", author, version )
}

string function GetOperationMessage( MWSOperationSnapshot operation )
{
	if ( operation.message == "" )
		return ""
	if ( operation.state == eMWSInstallState.DOWNLOADING ||
		operation.state == eMWSInstallState.VALIDATING ||
		operation.state == eMWSInstallState.STAGING ||
		operation.state == eMWSInstallState.AWAITING_MIGRATION )
	{
		return Localize( operation.message, operation.name )
	}
	return Localize( operation.message )
}

string function GetOperationProgressText( MWSOperationSnapshot operation )
{
	string progress = GetOperationMessage( operation )
	if ( operation.total > 0 )
		progress += Localize( "#MWS_PROGRESS_PERCENT", string( int( operation.ratio * 100.0 ) ) )
	if ( operation.cancellationDeferred )
		progress += Localize( "#MWS_CANCELLATION_DEFERRED_SUFFIX" )
	return progress
}

string function GetOperationDialogHeader( int action )
{
	switch ( action )
	{
		case eMWSInstallAction.UPDATE:
			return Localize( "#MWS_UPDATE_MOD" )
		case eMWSInstallAction.REPLACE:
			return Localize( "#MWS_DOWNLOAD_MOD" )
		case eMWSInstallAction.REMOVE:
			return Localize( "#MWS_REMOVE_MOD" )
	}
	return Localize( "#MWS_DOWNLOAD_MOD" )
}

bool function IsOperationBusy( int state )
{
	return ( state >= eMWSInstallState.QUEUED && state <= eMWSInstallState.RELOADING ) ||
		state == eMWSInstallState.AWAITING_MIGRATION
}

bool function IsOperationTerminal( int state )
{
	return state == eMWSInstallState.DONE || state == eMWSInstallState.FAILED || state == eMWSInstallState.CANCELLED
}


void function SetScaledTitle( var label, string text, float availableLogicalWidth )
{
	float screenScale = float( GetScreenSize()[ 0 ] ) / 1920.0
	int availableWidth = int( availableLogicalWidth * screenScale )
	label.SetScale( 1.0, 1.0 )
	Hud_SetWidth( label, int( float( availableWidth ) * MWS_TITLE_MAX_WIDTH_MULTIPLIER ) )
	Hud_SetText( label, text )
	int naturalWidth = Hud_GetTextWidth( label )
	if ( naturalWidth <= 0 )
	{
		Hud_SetWidth( label, availableWidth )
		return
	}
	Hud_SetWidth( label, naturalWidth )
	float scale = min( 1.0, float( availableWidth ) / float( naturalWidth ) )
	label.SetScale( scale, scale )
}

void function ScrollDetails( int direction )
{
	int maxOffset = maxint( 0, file.detailsLines.len() - MWS_DETAILS_VISIBLE_LINES )
	int nextOffset = minint( maxOffset, maxint( 0, file.detailsScrollOffset + direction ) )
	if ( nextOffset == file.detailsScrollOffset )
		return
	file.detailsScrollOffset = nextOffset
	RenderDetailsDescription()
}

void function SetDetailsDescription( string description )
{
	file.detailsLines = WrapDetailsText( description )
	file.detailsScrollOffset = 0
	RenderDetailsDescription()
}

array<string> function WrapDetailsText( string text )
{
	array<string> lines
	if ( text == "" )
		return lines

	array<string> paragraphs = split( text, "\n" )
	foreach ( string paragraph in paragraphs )
	{
		if ( paragraph == "" )
		{
			lines.append( "" )
			continue
		}

		array<string> words = split( paragraph, " " )
		string currentLine = ""
		foreach ( string paragraphWord in words )
		{
			if ( paragraphWord == "" )
				continue
			string word = paragraphWord
			while ( word.len() > MWS_DETAILS_LINE_WIDTH )
			{
				if ( currentLine != "" )
				{
					lines.append( currentLine )
					currentLine = ""
				}
				lines.append( word.slice( 0, MWS_DETAILS_LINE_WIDTH ) )
				word = word.slice( MWS_DETAILS_LINE_WIDTH, word.len() )
			}

			if ( currentLine == "" )
				currentLine = word
			else if ( currentLine.len() + 1 + word.len() <= MWS_DETAILS_LINE_WIDTH )
				currentLine += " " + word
			else
			{
				lines.append( currentLine )
				currentLine = word
			}
		}
		if ( currentLine != "" )
			lines.append( currentLine )
	}
	return lines
}

void function RenderDetailsDescription()
{
	string visibleText = ""
	int endLine = minint( file.detailsLines.len(), file.detailsScrollOffset + MWS_DETAILS_VISIBLE_LINES )
	for ( int lineIndex = file.detailsScrollOffset; lineIndex < endLine; lineIndex++ )
		visibleText += ( lineIndex == file.detailsScrollOffset ? "" : "\n" ) + file.detailsLines[ lineIndex ]
	Hud_SetText( Hud_GetChild( file.menu, "DetailsDescription" ), visibleText )
}

asset function GetModWorkshopThumbnail( int slot )
{
	switch ( slot )
	{
		case 0: return $"rui/ns/modworkshop/card_0"
		case 1: return $"rui/ns/modworkshop/card_1"
		case 2: return $"rui/ns/modworkshop/card_2"
		case 3: return $"rui/ns/modworkshop/card_3"
		case 4: return $"rui/ns/modworkshop/card_4"
		case 5: return $"rui/ns/modworkshop/card_5"
		case 6: return $"rui/ns/modworkshop/card_6"
		case 7: return $"rui/ns/modworkshop/card_7"
		case 8: return $"rui/ns/modworkshop/card_8"
		case 9: return $"rui/ns/modworkshop/card_9"
		case 10: return $"rui/ns/modworkshop/card_10"
		case 11: return $"rui/ns/modworkshop/card_11"
		case 12: return $"rui/ns/modworkshop/card_12"
		case 13: return $"rui/ns/modworkshop/card_13"
		case 14: return $"rui/ns/modworkshop/card_14"
		case 15: return $"rui/ns/modworkshop/card_15"
		case 16: return $"rui/ns/modworkshop/card_16"
		case 17: return $"rui/ns/modworkshop/card_17"
		case 18: return $"rui/ns/modworkshop/card_18"
		case 19: return $"rui/ns/modworkshop/card_19"
		case 20: return $"rui/ns/modworkshop/card_20"
		case 21: return $"rui/ns/modworkshop/card_21"
		case 22: return $"rui/ns/modworkshop/card_22"
		case 23: return $"rui/ns/modworkshop/card_23"
	}
	return $""
}
