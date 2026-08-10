untyped

global function AddNorthstarModMenu
global function AddNorthstarModMenu_MainMenuFooter
global function ReloadMods
global function NSUICodeCallback_ModIconReady

enum eModsMenuFilter
{
	ALL = 0,
	ENABLED,
	DISABLED,
	OPTIONAL,
	REQUIRED,
	REMOTE
}

struct ModsMenuRow
{
	int loadPriority = 0
	array<int> modIndices
}

struct
{
	var menu
	array<var> cards
	array<var> priorityHeaders
	var detailsPreviewFocus
	array<var> detailsElements
	var detailsMenu
	array<string> fullAssetLines
	array<string> fullConVarLines
	int fullDetailsScrollOffset = 0
	int fullDetailsModIndex = -1
	bool fullDetailsOpen = false
	array<bool> iconReady
	array<string> detailsLines
	int detailsScrollOffset = 0
	array<ModInfo> mods
	array<ModInfo> visibleMods
	array<ModInfo> enabledMods
	array<ModsMenuRow> rows
	int page = 0
	int selectedIndex = -1
	string selectedName = ""
	string selectedVersion = ""
	bool isOpen = false
	bool enabledStateDirty = false
	int lastInventoryGeneration = 0
	int lastOperationGeneration = 0
	int lastOperationState = eMWSInstallState.IDLE
	int iconGeneration = 0
	bool reversePriority = false
	bool rightClickHeld = false
	bool cardDialogPending = false
	int cardDialogGeneration = 0
} file

const int MODS_CARD_COLUMNS = 6
const int MODS_ROWS_PER_PAGE = 3
const int MODS_CARD_COUNT = MODS_CARD_COLUMNS * MODS_ROWS_PER_PAGE
const int MODS_DETAILS_LINE_WIDTH = 70
const int MODS_DETAILS_VISIBLE_LINES = 4
const int MODS_FULL_DETAILS_VISIBLE_LINES = 11
// Raw mouse InputEvent codes are one higher than the UI button constants in this game build.
const int MODS_MOUSE_RIGHT_INPUT = MOUSE_RIGHT + 1
const string[ 4 ] CORE_MODS = [ "Northstar.Client", "Northstar.Coop", "Northstar.CustomServers", "Northstar.Custom" ]

void function AddNorthstarModMenu()
{
	AddMenu( "ModListMenu", $"resource/ui/menus/modlist.menu", InitModMenu )
	AddMenu( "ModDetailsMenu", $"resource/ui/menus/moddetails.menu", InitModDetailsMenu, "#MODS_DETAILS_TITLE" )
}

void function AddNorthstarModMenu_MainMenuFooter()
{
	AddMenuFooterOption(
		GetMenu( "MainMenu" ),
		BUTTON_Y,
		PrependControllerPrompts( BUTTON_Y, "#AUTHENTICATION_AGREEMENT" ),
		"#AUTHENTICATION_AGREEMENT",
		OnAuthenticationAgreementButtonPressed,
		ShouldShowFooterButtons
	)
	AddMenuFooterOption( GetMenu( "MainMenu" ), BUTTON_BACK, "#BACK_BUTTON_MENU_DEMOS", "#MENU_DEMOS", OpenDemoPickerMenu, HasDemos )
}

void function AdvanceToModListMenu( var button )
{
	AdvanceMenu( GetMenu( "ModListMenu" ) )
}

bool function HasDemos()
{
	array<string> demos = Demo_GetDemoFiles()
	foreach ( string demo in Demo_GetDemoFiles() )
	{
		string mapName = "mp_lobby"
		foreach ( string map in GetPrivateMatchMaps() )
		{
			if ( demo.find( map ) != null )
				mapName = map
		}
		if ( mapName == "mp_lobby" )
			demos.remove( demos.find( demo ) )
	}
	return demos.len() != 0
}

void function OpenDemoPickerMenu( var button )
{
	AdvanceMenu( GetMenu( "DemopickerMenu" ) )
}

void function InitModMenu()

{
	file.menu = GetMenu( "ModListMenu" )
	file.cards = GetElementsByClassname( file.menu, "ModSelectorPanel" )
	file.priorityHeaders = [
		Hud_GetChild( file.menu, "PriorityHeader1" ),
		Hud_GetChild( file.menu, "PriorityHeader2" ),
		Hud_GetChild( file.menu, "PriorityHeader3" )
	]
	file.detailsPreviewFocus = Hud_GetChild( file.menu, "DetailsPreviewFocus" )
	file.detailsElements = GetElementsByClassname( file.menu, "ModDetailsPane" )
	Hud_EnableKeyBindingIcons( Hud_GetChild( file.menu, "PageLabel" ) )
	ModsMenu_SetDetailsVisible( false )

	foreach ( var card in file.cards )
	{
		var button = Hud_GetChild( card, "BtnMod" )
		AddButtonEventHandler( button, UIE_GET_FOCUS, OnModButtonFocused )
		AddButtonEventHandler( button, UIE_CLICK, OnModButtonPressed )
		RuiSetImage( Hud_GetRui( Hud_GetChild( card, "WarningImage" ) ), "basicImage", $"ui/menu/common/dialog_error" )
	}

	RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "WarningLegendImage" ) ), "basicImage", $"ui/menu/common/dialog_error" )
	RuiSetFloat( Hud_GetRui( Hud_GetChild( file.menu, "ModEnabledBar" ) ), "basicImageAlpha", 0.8 )

	AddButtonEventHandler( Hud_GetChild( file.menu, "BtnModsSearch" ), UIE_CHANGE, OnModsFilterChanged )
	AddButtonEventHandler( Hud_GetChild( file.menu, "SwtBtnShowFilter" ), UIE_CHANGE, OnModsFilterChanged )
	AddButtonEventHandler( Hud_GetChild( file.menu, "BtnListReverse" ), UIE_CHANGE, OnModsFilterChanged )
	AddButtonEventHandler( Hud_GetChild( file.menu, "BtnFiltersClear" ), UIE_CLICK, OnModsFiltersClear )

	AddCallback_InputEvent( InputEventType.IE_AnalogValueChanged, OnModsAnalogueScroll )
	AddCallback_InputEvent( InputEventType.IE_ButtonPressed, OnModsInputButtonPressed )
	AddCallback_InputEvent( InputEventType.IE_ButtonReleased, OnModsInputButtonReleased )
	AddMenuEventHandler( file.menu, eUIEvent.MENU_OPEN, OnModMenuOpened )
	AddMenuEventHandler( file.menu, eUIEvent.MENU_CLOSE, OnModMenuClosed )

	AddMenuFooterOption( file.menu, BUTTON_B, "#B_BUTTON_BACK", "#BACK" )
	AddMenuFooterOption(
		file.menu,
		BUTTON_X,
		PrependControllerPrompts( BUTTON_X, "#RELOAD_MODS" ),
		"#RELOAD_MODS",
		OnReloadModsButtonPressed
	)
	AddMenuFooterOption(
		file.menu,
		BUTTON_Y,
		PrependControllerPrompts( BUTTON_Y, "#MOD_SETTINGS" ),
		"#MOD_SETTINGS",
		OnModSettingsButtonPressed
	)

	AddMenuFooterOption(
		file.menu,
		BUTTON_A,
		"",
		"%[|MOUSE1]% Details    %[|MOUSE2]% Disable",
		null,
		ModsMenu_ShouldShowMouseFooter,
		UpdateModsInputFooter
	)

	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "SwtBtnShowFilter" ) ), "buttonText", "" )
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "BtnListReverse" ) ), "buttonText", "" )
}

void function InitModDetailsMenu()
{
	file.detailsMenu = GetMenu( "ModDetailsMenu" )
	uiGlobal.menuData[ file.detailsMenu ].isDialog = true
	Hud_EnableKeyBindingIcons( Hud_GetChild( file.detailsMenu, "DetailsScrollStatus" ) )
	AddMenuEventHandler( file.detailsMenu, eUIEvent.MENU_OPEN, OnModDetailsOpened )
	AddMenuEventHandler( file.detailsMenu, eUIEvent.MENU_CLOSE, OnModDetailsClosed )
	AddMenuEventHandler( file.detailsMenu, eUIEvent.MENU_NAVIGATE_BACK, OnModDetailsNavigateBack )

	AddMenuFooterOption( file.detailsMenu, BUTTON_B, "#B_BUTTON_BACK", "#BACK" )
	AddMenuFooterOption( file.detailsMenu, BUTTON_A, "#A_BUTTON_SELECT", "" )
	AddMenuFooterOption(
		file.detailsMenu,
		BUTTON_X,
		"%[X_BUTTON|]% " + Localize( "#MWS_ACTION_UPDATE" ),
		"#MWS_ACTION_UPDATE",
		OnUpdateModButtonPressed,
		ModsMenu_ShouldShowUpdateFooter
	)
	AddMenuFooterOption(
		file.detailsMenu,
		BUTTON_Y,
		"%[Y_BUTTON|]% " + Localize( "#MODS_UNINSTALL_MOD" ),
		"#MODS_UNINSTALL_MOD",
		OnDeleteModButtonPressed,
		ModsMenu_ShouldShowUninstallFooter
	)
	AddMenuFooterOption(
		file.detailsMenu,
		BUTTON_SHOULDER_LEFT,
		"%[L_SHOULDER|]% " + Localize( "#MODS_OPEN_WORKSHOP_PAGE" ),
		"#MODS_OPEN_WORKSHOP_PAGE",
		OnModPageButtonPressed,
		ModsMenu_ShouldShowPageFooter,
		UpdateModsPageFooter
	)
}

void function OnModDetailsOpened()
{
	file.fullDetailsOpen = true
	file.fullDetailsScrollOffset = 0
	ModsMenu_UpdateFullDetails()
}

void function OnModDetailsClosed()
{
	file.fullDetailsOpen = false
	file.fullDetailsModIndex = -1
	file.fullAssetLines.clear()
	file.fullConVarLines.clear()
}

void function OnModDetailsNavigateBack()
{
	CloseActiveMenu()
}


void function OnModMenuOpened()
{
	file.isOpen = true
	file.cardDialogGeneration++
	file.rightClickHeld = false
	file.cardDialogPending = false
	file.page = 0
	file.selectedIndex = -1
	file.selectedName = ""
	file.selectedVersion = ""
	file.enabledStateDirty = false
	file.enabledMods = GetEnabledModsArray()
	UI_SetPresentationType( ePresentationType.NO_MODELS )
	NSMWSInitializeThumbnailAtlas()

	MWSInventorySnapshot inventory = NSMWSGetInventoryState()
	file.lastInventoryGeneration = inventory.generation
	MWSOperationSnapshot operation = NSMWSGetOperationState()
	file.lastOperationGeneration = operation.generation
	file.lastOperationState = operation.state
	NSMWSRefreshTrackedMods( true )

	ModsMenu_RefreshAndRender( true )
	thread ModsMenu_PollState()
}

void function OnModMenuClosed()
{
	file.isOpen = false
	file.cardDialogGeneration++
	file.rightClickHeld = false
	file.cardDialogPending = false
	if ( !file.enabledStateDirty )
		return

	ReloadMods()
	if ( IsFullyConnected() )
		ClientCommand( "retry" )
}

void function ModsMenu_PollState()
{
	while ( file.isOpen )
	{
		WaitFrame()
		MWSInventorySnapshot inventory = NSMWSGetInventoryState()
		MWSOperationSnapshot operation = NSMWSGetOperationState()
		bool inventoryChanged = inventory.generation != file.lastInventoryGeneration
		bool operationChanged = operation.generation != file.lastOperationGeneration || operation.state != file.lastOperationState
		if ( !inventoryChanged && !operationChanged )
			continue

		file.lastInventoryGeneration = inventory.generation
		file.lastOperationGeneration = operation.generation
		file.lastOperationState = operation.state
		if ( operation.state == eMWSInstallState.DONE )
			file.enabledStateDirty = false
		ModsMenu_RefreshAndRender( false )
	}
}

void function OnModsAnalogueScroll( int eventType, int nTick, int nData, int nData2, int nData3 )
{
	if ( nData != AnalogCode.MOUSE_WHEEL )
		return
	if ( uiGlobal.activeMenu == file.detailsMenu )
	{
		ModsMenu_ScrollFullDetails( nData3 > 0 ? -1 : 1 )
		return
	}
	if ( uiGlobal.activeMenu != file.menu )
		return
	if ( GetFocus() == file.detailsPreviewFocus )
	{
		ModsMenu_ScrollDetails( nData3 > 0 ? -1 : 1 )
		return
	}
	if ( nData3 > 0 )
		ModsMenu_ChangePage( -1 )
	else if ( nData3 < 0 )
		ModsMenu_ChangePage( 1 )
}

void function OnModsFilterChanged( var unused )
{
	file.page = 0
	file.selectedIndex = -1
	file.selectedName = ""
	file.selectedVersion = ""
	ModsMenu_RefreshAndRender( false )
}

void function OnModsFiltersClear( var button )
{
	Hud_SetText( Hud_GetChild( file.menu, "BtnModsSearch" ), "" )
	SetConVarInt( "filter_mods", eModsMenuFilter.ALL )
	SetConVarInt( "modlist_reverse", 0 )
	OnModsFilterChanged( null )
}


void function ModsMenu_ChangePage( int direction )
{
	int pageCount = ModsMenu_GetPageCount()
	int nextPage = maxint( 0, minint( pageCount - 1, file.page + direction ) )
	if ( nextPage == file.page )
		return
	file.page = nextPage
	file.selectedIndex = ModsMenu_GetFirstIndexOnPage( file.page )
	ModsMenu_RenderCards( true )
}

void function ModsMenu_RefreshAndRender( bool focusSelection )
{
	ModsMenu_RefreshMods()
	ModsMenu_RenderCards( focusSelection )
	if ( file.fullDetailsOpen )
		ModsMenu_UpdateFullDetails()
}

void function ModsMenu_RefreshMods()
{
	file.mods = NSGetModsInformation()
	file.visibleMods.clear()
	string search = Hud_GetUTF8Text( Hud_GetChild( file.menu, "BtnModsSearch" ) ).tolower()
	int filter = GetConVarInt( "filter_mods" )
	file.reversePriority = GetConVarBool( "modlist_reverse" )

	foreach ( ModInfo mod in file.mods )
	{
		if ( search.len() > 0 && mod.name.tolower().find( search ) == null && mod.description.tolower().find( search ) == null )
			continue
		if ( !ModsMenu_MatchesFilter( mod, filter ) )
			continue
		file.visibleMods.append( mod )
	}
	file.visibleMods.sort( ModsMenu_CompareMods )
	ModsMenu_BuildRows()

	int pageCount = ModsMenu_GetPageCount()
	file.page = maxint( 0, minint( pageCount - 1, file.page ) )
	file.selectedIndex = -1
	if ( file.selectedName != "" )
	{
		foreach ( int index, ModInfo mod in file.visibleMods )
		{
			if ( mod.name == file.selectedName && mod.version == file.selectedVersion )
			{
				file.selectedIndex = index
				file.page = ModsMenu_GetPageForVisibleIndex( index )
				break
			}
		}
	}
	if ( file.selectedIndex < 0 && file.visibleMods.len() > 0 )
		file.selectedIndex = ModsMenu_GetFirstIndexOnPage( file.page )
}

int function ModsMenu_CompareMods( ModInfo left, ModInfo right )
{
	if ( left.loadPriority != right.loadPriority )
	{
		bool leftFirst = left.loadPriority < right.loadPriority
		if ( file.reversePriority )
			leftFirst = !leftFirst
		return leftFirst ? -1 : 1
	}
	string leftName = left.name.tolower()
	string rightName = right.name.tolower()
	if ( leftName < rightName )
		return -1
	if ( leftName > rightName )
		return 1
	return left.index < right.index ? -1 : ( left.index > right.index ? 1 : 0 )
}

void function ModsMenu_BuildRows()
{
	file.rows.clear()
	foreach ( int index, ModInfo mod in file.visibleMods )
	{
		bool needsRow = file.rows.len() == 0
		if ( !needsRow )
		{
			ModsMenuRow current = file.rows[ file.rows.len() - 1 ]
			needsRow = current.loadPriority != mod.loadPriority || current.modIndices.len() >= MODS_CARD_COLUMNS
		}
		if ( needsRow )
		{
			ModsMenuRow row
			row.loadPriority = mod.loadPriority
			file.rows.append( row )
		}
		file.rows[ file.rows.len() - 1 ].modIndices.append( index )
	}
}

int function ModsMenu_GetPageForVisibleIndex( int visibleIndex )
{
	foreach ( int rowIndex, ModsMenuRow row in file.rows )
	{
		if ( row.modIndices.contains( visibleIndex ) )
			return rowIndex / MODS_ROWS_PER_PAGE
	}
	return 0
}

int function ModsMenu_GetFirstIndexOnPage( int page )
{
	int rowIndex = page * MODS_ROWS_PER_PAGE
	if ( rowIndex < 0 || rowIndex >= file.rows.len() || file.rows[ rowIndex ].modIndices.len() == 0 )
		return -1
	return file.rows[ rowIndex ].modIndices[ 0 ]
}

int function ModsMenu_GetVisibleIndexForSlot( int slot )
{
	int displayRow = slot / MODS_CARD_COLUMNS
	int column = slot % MODS_CARD_COLUMNS
	int rowIndex = file.page * MODS_ROWS_PER_PAGE + displayRow
	if ( rowIndex < 0 || rowIndex >= file.rows.len() || column >= file.rows[ rowIndex ].modIndices.len() )
		return -1
	return file.rows[ rowIndex ].modIndices[ column ]
}

int function ModsMenu_GetSlotForVisibleIndex( int visibleIndex )
{
	int firstRow = file.page * MODS_ROWS_PER_PAGE
	for ( int displayRow = 0; displayRow < MODS_ROWS_PER_PAGE; displayRow++ )
	{
		int rowIndex = firstRow + displayRow
		if ( rowIndex >= file.rows.len() )
			break
		int column = file.rows[ rowIndex ].modIndices.find( visibleIndex )
		if ( column >= 0 )
			return displayRow * MODS_CARD_COLUMNS + column
	}
	return -1
}

int function ModsMenu_GetVisibleCountOnPage()
{
	int count = 0
	int firstRow = file.page * MODS_ROWS_PER_PAGE
	for ( int displayRow = 0; displayRow < MODS_ROWS_PER_PAGE && firstRow + displayRow < file.rows.len(); displayRow++ )
		count += file.rows[ firstRow + displayRow ].modIndices.len()
	return count
}

int function ModsMenu_GetLastIndexOnPage()
{
	int firstRow = file.page * MODS_ROWS_PER_PAGE
	int lastRow = minint( file.rows.len() - 1, firstRow + MODS_ROWS_PER_PAGE - 1 )
	if ( lastRow < 0 || file.rows[ lastRow ].modIndices.len() == 0 )
		return -1
	return file.rows[ lastRow ].modIndices[ file.rows[ lastRow ].modIndices.len() - 1 ]
}

bool function ModsMenu_MatchesFilter( ModInfo mod, int filter )
{
	switch ( filter )
	{
		case eModsMenuFilter.ENABLED:
			return mod.enabled
		case eModsMenuFilter.DISABLED:
			return !mod.enabled
		case eModsMenuFilter.OPTIONAL:
			return !mod.requiredOnClient
		case eModsMenuFilter.REQUIRED:
			return mod.requiredOnClient
		case eModsMenuFilter.REMOTE:
			return mod.isRemote
	}
	return true
}

int function ModsMenu_GetPageCount()
{
	if ( file.rows.len() == 0 )
		return 1
	return ( file.rows.len() - 1 ) / MODS_ROWS_PER_PAGE + 1
}

void function ModsMenu_RenderCards( bool focusSelection )
{
	ModsMenu_HideCards()
	array<int> iconIndices
	file.iconReady.clear()
	for ( int slot = 0; slot < MODS_CARD_COUNT; slot++ )
	{
		iconIndices.append( -1 )
		file.iconReady.append( false )
	}

	int firstRow = file.page * MODS_ROWS_PER_PAGE
	for ( int displayRow = 0; displayRow < MODS_ROWS_PER_PAGE; displayRow++ )
	{
		int rowIndex = firstRow + displayRow
		if ( rowIndex >= file.rows.len() )
			continue
		ModsMenuRow row = file.rows[ rowIndex ]
		var header = file.priorityHeaders[ displayRow ]
		Hud_SetText( header, Localize( "#MODS_LOAD_PRIORITY_HEADER", string( row.loadPriority ) ) )
		Hud_SetVisible( header, true )
		foreach ( int column, int modIndex in row.modIndices )
		{
			int slot = displayRow * MODS_CARD_COLUMNS + column
			ModInfo mod = file.visibleMods[ modIndex ]
			var card = file.cards[ slot ]
			var button = Hud_GetChild( card, "BtnMod" )
			Hud_SetVisible( card, true )
			Hud_SetVisible( button, true )
			Hud_SetEnabled( button, true )
			Hud_SetText( button, "" )
			ModsMenu_SetCardTitle( Hud_GetChild( card, "ModName" ), mod.name, 162.0 )
			ModsMenu_LayoutCardMetadata( card )
			Hud_SetText( Hud_GetChild( card, "ModVersion" ), Localize( "#MODS_VERSION_SHORT", mod.version ) )
			Hud_SetText( Hud_GetChild( card, "ModStatus" ), ModsMenu_GetStatusText( mod ) )
			RuiSetImage( Hud_GetRui( Hud_GetChild( card, "ModIcon" ) ), "basicImage", ModsMenu_GetIconAsset( slot ) )
			Hud_SetVisible( Hud_GetChild( card, "ModIcon" ), false )
			iconIndices[ slot ] = mod.index
			ModsMenu_SetCardAppearance( card, mod )
		}
	}
	file.iconGeneration = NSRequestModIconPage( iconIndices )

	bool empty = file.visibleMods.len() == 0
	Hud_SetVisible( Hud_GetChild( file.menu, "EmptyLabel" ), empty )
	if ( empty )
	{
		string search = Hud_GetUTF8Text( Hud_GetChild( file.menu, "BtnModsSearch" ) )
		Hud_SetText( Hud_GetChild( file.menu, "EmptyLabel" ), search == "" && GetConVarInt( "filter_mods" ) == eModsMenuFilter.ALL ? "#MODS_EMPTY" : "#MODS_NO_RESULTS" )
		ModsMenu_ClearDetails()
	}
	else
	{
		int selectedSlot = ModsMenu_GetSlotForVisibleIndex( file.selectedIndex )
		if ( selectedSlot < 0 )
		{
			file.selectedIndex = ModsMenu_GetFirstIndexOnPage( file.page )
			selectedSlot = ModsMenu_GetSlotForVisibleIndex( file.selectedIndex )
		}
		ModsMenu_SelectMod( file.selectedIndex )
		if ( focusSelection && selectedSlot >= 0 )
			Hud_SetFocused( Hud_GetChild( file.cards[ selectedSlot ], "BtnMod" ) )
	}
	ModsMenu_UpdatePageControls()
}

void function ModsMenu_HideCards()
{
	foreach ( var header in file.priorityHeaders )
		Hud_SetVisible( header, false )
	foreach ( var card in file.cards )
	{
		var button = Hud_GetChild( card, "BtnMod" )
		Hud_SetEnabled( button, false )
		Hud_SetVisible( button, false )
		Hud_SetVisible( Hud_GetChild( card, "ModIcon" ), false )
		Hud_SetVisible( card, false )
	}
}

void function NSUICodeCallback_ModIconReady( int generation, int atlasSlot )
{
	if ( !file.isOpen || generation != file.iconGeneration || atlasSlot < 0 || atlasSlot >= MODS_CARD_COUNT )
		return
	int modIndex = ModsMenu_GetVisibleIndexForSlot( atlasSlot )
	if ( modIndex < 0 || modIndex >= file.visibleMods.len() || !file.visibleMods[ modIndex ].hasIcon )
		return
	file.iconReady[ atlasSlot ] = true
	Hud_SetVisible( Hud_GetChild( file.cards[ atlasSlot ], "ModIcon" ), true )
	if ( modIndex == file.selectedIndex )
		Hud_SetVisible( Hud_GetChild( file.menu, "DetailsImage" ), true )
}

asset function ModsMenu_GetIconAsset( int slot )
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
	}
	return $""
}

void function ModsMenu_SetCardAppearance( var card, ModInfo mod )
{
	vector accent = ModsMenu_GetControlColor( mod )
	RuiSetFloat3( Hud_GetRui( Hud_GetChild( card, "StateBar" ) ), "basicImageColor", accent )
	RuiSetFloat( Hud_GetRui( Hud_GetChild( card, "StateBar" ) ), "basicImageAlpha", 1.0 )

	var enabledImage = Hud_GetChild( card, "EnabledImage" )
	RuiSetImage( Hud_GetRui( enabledImage ), "basicImage", mod.enabled ? $"rui/menu/common/merit_state_success" : $"rui/menu/common/merit_state_failure" )
	RuiSetFloat3( Hud_GetRui( enabledImage ), "basicImageColor", accent )
	Hud_SetVisible( enabledImage, true )
	Hud_SetVisible( Hud_GetChild( card, "WarningImage" ), mod.requiredOnClient )
	var updateBadge = Hud_GetChild( card, "UpdateBadge" )
	bool hasUpdate = mod.updateState == eMWSUpdateState.UPDATE_AVAILABLE
	Hud_SetVisible( updateBadge, hasUpdate )
}

void function ModsMenu_UpdatePageControls()
{

	if ( file.visibleMods.len() == 0 )
	{
		Hud_SetText( Hud_GetChild( file.menu, "PageLabel" ), "#NO_RESULTS" )
		return
	}
	int first = ModsMenu_GetFirstIndexOnPage( file.page ) + 1
	int last = ModsMenu_GetLastIndexOnPage() + 1
	Hud_SetText( Hud_GetChild( file.menu, "PageLabel" ), Localize( "#MODS_PAGE_RANGE", string( first ), string( last ), string( file.visibleMods.len() ) ) )
}

void function OnModButtonFocused( var button )
{
	int index = ModsMenu_GetButtonModIndex( button )
	if ( index >= 0 && index < file.visibleMods.len() )
		ModsMenu_SelectMod( index )
}

void function OnModButtonPressed( var button )
{
	ModsMenu_RequestFullDetails( ModsMenu_GetButtonModIndex( button ) )
}

void function ModsMenu_RequestFullDetails( int index )
{
	if ( !file.isOpen || uiGlobal.activeMenu != file.menu ||
		index < 0 || index >= file.visibleMods.len() )
	{
		return
	}
	ModsMenu_SelectMod( index )
	ModInfo mod = file.visibleMods[ index ]
	file.fullDetailsModIndex = mod.index
	AdvanceMenu( file.detailsMenu )
}

void function ModsMenu_WaitForCardDialogClose( int generation )
{
	while ( file.isOpen && generation == file.cardDialogGeneration &&
		uiGlobal.activeMenu == GetMenu( "Dialog" ) )
	{
		WaitFrame()
	}
	wait 0.1
	if ( file.isOpen && generation == file.cardDialogGeneration )
		file.cardDialogPending = false
}

void function OnModsInputButtonReleased( int eventType, int nTick, int nData, int nData2, int nData3 )
{
	if ( nData == MODS_MOUSE_RIGHT_INPUT )
		file.rightClickHeld = false
}

void function OnModsInputButtonPressed( int eventType, int nTick, int nData, int nData2, int nData3 )
{
	if ( nData != MODS_MOUSE_RIGHT_INPUT || !file.isOpen ||
		uiGlobal.activeMenu != file.menu || file.rightClickHeld )
		return
	file.rightClickHeld = true
	int index = ModsMenu_GetFocusedModIndex()
	if ( index < 0 || index >= file.visibleMods.len() )
		return
	ModsMenu_SelectMod( index )
	ModsMenu_RequestToggleSelectedMod()
}


void function ModsMenu_RequestToggleSelectedMod()
{
	if ( file.selectedIndex < 0 || file.selectedIndex >= file.visibleMods.len() )
		return
	int index = file.selectedIndex
	ModInfo mod = file.visibleMods[ index ]
	if ( ModsMenu_IsCoreMod( mod.name ) && mod.enabled )
	{
		if ( IsLobby() || IsLevelMultiplayer( GetActiveLevel() ) || file.cardDialogPending )
			return
		file.cardDialogPending = true
		file.cardDialogGeneration++
		thread ModsMenu_OpenCoreDisableWarning( index, mod.name, mod.version, file.cardDialogGeneration )
		return
	}
	ModsMenu_ToggleSelectedMod()
}

void function ModsMenu_OpenCoreDisableWarning( int index, string modName, string modVersion, int generation )
{
	WaitFrame()
	if ( !file.isOpen || uiGlobal.activeMenu != file.menu || generation != file.cardDialogGeneration ||
		index < 0 || index >= file.visibleMods.len() )
	{
		if ( generation == file.cardDialogGeneration )
			file.cardDialogPending = false
		return
	}
	ModInfo mod = file.visibleMods[ index ]
	if ( mod.name != modName || mod.version != modVersion || !mod.enabled || !ModsMenu_IsCoreMod( mod.name ) )
	{
		file.cardDialogPending = false
		return
	}

	DialogData dialogData
	dialogData.header = "#WARNING"
	dialogData.message = "#CORE_MOD_DISABLE_WARNING"
	AddDialogButton( dialogData, "#DISABLE", ModsMenu_ConfirmCoreDisable )
	AddDialogButton( dialogData, "#CANCEL" )
	OpenDialog( dialogData )
	ModsMenu_WaitForCardDialogClose( generation )
}

int function ModsMenu_GetFocusedModIndex()
{
	var focused = GetFocus()
	foreach ( var card in file.cards )
	{
		var button = Hud_GetChild( card, "BtnMod" )
		if ( focused == button )
			return ModsMenu_GetButtonModIndex( button )
	}
	return -1
}

bool function ModsMenu_ShouldShowMouseFooter()
{
	if ( IsControllerModeActive() || !file.isOpen || uiGlobal.activeMenu != file.menu )
		return false
	int index = ModsMenu_GetFocusedModIndex()
	return index >= 0 && index < file.visibleMods.len()
}

void function UpdateModsInputFooter( InputDef data )
{
	EndSignal( uiGlobal.signalDummy, "EndFooterUpdateFuncs" )
	int footerIndex = int( Hud_GetScriptID( data.vguiElem ) )
	while ( data.conditionCheckFunc() )
	{
		int modIndex = ModsMenu_GetFocusedModIndex()
		if ( modIndex >= 0 && modIndex < file.visibleMods.len() )
		{
			bool enabled = file.visibleMods[ modIndex ].enabled
			SetFooterText( file.menu, footerIndex, enabled ? "%[|MOUSE1]% Details    %[|MOUSE2]% Disable" : "%[|MOUSE1]% Details    %[|MOUSE2]% Enable" )
		}
		WaitFrame()
	}
}

bool function ModsMenu_IsActionFooterActive()
{
	return file.isOpen && file.fullDetailsOpen && uiGlobal.activeMenu == file.detailsMenu
}

bool function ModsMenu_ShouldShowPageFooter()
{
	if ( !ModsMenu_IsActionFooterActive() )
		return false
	int modIndex = ModsMenu_GetSelectedSourceIndex()
	if ( modIndex < 0 || modIndex >= file.mods.len() )
		return false
	ModInfo mod = file.mods[ modIndex ]
	return mod.managedId != "" || mod.downloadLink != ""
}

bool function ModsMenu_ShouldShowUpdateFooter()
{
	if ( !ModsMenu_IsActionFooterActive() )
		return false
	int modIndex = ModsMenu_GetSelectedSourceIndex()
	return modIndex >= 0 && modIndex < file.mods.len() &&
		ModsMenu_CanUpdateWorkshopMod( file.mods[ modIndex ] ) &&
		!ModsMenu_IsOperationBusy( NSMWSGetOperationState().state )
}

bool function ModsMenu_ShouldShowUninstallFooter()
{
	if ( !ModsMenu_IsActionFooterActive() )
		return false
	int modIndex = ModsMenu_GetSelectedSourceIndex()
	return modIndex >= 0 && modIndex < file.mods.len() &&
		file.mods[ modIndex ].canDelete &&
		!ModsMenu_IsOperationBusy( NSMWSGetOperationState().state )
}

void function UpdateModsPageFooter( InputDef data )
{
	EndSignal( uiGlobal.signalDummy, "EndFooterUpdateFuncs" )
	int footerIndex = int( Hud_GetScriptID( data.vguiElem ) )
	while ( data.conditionCheckFunc() )
	{
		int modIndex = ModsMenu_GetSelectedSourceIndex()
		if ( modIndex >= 0 && modIndex < file.mods.len() )
		{
			string label = file.mods[ modIndex ].managedId != "" ? "#MODS_OPEN_WORKSHOP_PAGE" : "#MODS_OPEN_DOWNLOAD_PAGE"
			SetFooterText(
				file.detailsMenu,
				footerIndex,
				IsControllerModeActive() ? "%[L_SHOULDER|]% " + Localize( label ) : Localize( label )
			)
		}
		WaitFrame()
	}
}

int function ModsMenu_GetButtonModIndex( var button )
{
	int slot = int( Hud_GetScriptID( Hud_GetParent( button ) ) ) - 1
	return ModsMenu_GetVisibleIndexForSlot( slot )
}

void function ModsMenu_SelectMod( int index )
{
	if ( index < 0 || index >= file.visibleMods.len() )
	{
		ModsMenu_ClearDetails()
		return
	}
	file.selectedIndex = index
	file.selectedName = file.visibleMods[ index ].name
	file.selectedVersion = file.visibleMods[ index ].version
	ModsMenu_UpdateDetails()
}

void function ModsMenu_UpdateDetails()
{
	if ( file.selectedIndex < 0 || file.selectedIndex >= file.visibleMods.len() )
	{
		ModsMenu_ClearDetails()
		return
	}
	ModInfo mod = file.visibleMods[ file.selectedIndex ]
	ModsMenu_SetDetailsVisible( true )

	int slot = ModsMenu_GetSlotForVisibleIndex( file.selectedIndex )
	var detailsImage = Hud_GetChild( file.menu, "DetailsImage" )
	if ( slot >= 0 && slot < MODS_CARD_COUNT )
		RuiSetImage( Hud_GetRui( detailsImage ), "basicImage", ModsMenu_GetIconAsset( slot ) )
	bool iconVisible = slot >= 0 && slot < file.iconReady.len() && mod.hasIcon && file.iconReady[ slot ]
	Hud_SetVisible( detailsImage, iconVisible )

	ModsMenu_SetCardTitle( Hud_GetChild( file.menu, "DetailsName" ), mod.name, 460.0 )
	Hud_SetText(
		Hud_GetChild( file.menu, "DetailsAuthor" ),
		Localize( "#MODS_DETAILS_VERSION", mod.version ) + "    " + Localize( "#MODS_DETAILS_SOURCE", ModsMenu_GetDetailsSource( mod ) )
	)
	ModsMenu_SetDetailsDescription( ModsMenu_FormatDetailsDescription( mod ) )
	Hud_SetText(
		Hud_GetChild( file.menu, "DetailsStatus" ),
		Localize( "#MODS_DETAILS_PRIORITY", string( mod.loadPriority ) ) + "    " + Localize( "#MODS_DETAILS_STATE", ModsMenu_GetStatusText( mod ) )
	)

	var bar = Hud_GetChild( file.menu, "ModEnabledBar" )
	RuiSetFloat3( Hud_GetRui( bar ), "basicImageColor", ModsMenu_GetControlColor( mod ) )
	Hud_SetVisible( Hud_GetChild( file.menu, "WarningLegendImage" ), mod.requiredOnClient )
	Hud_SetVisible( Hud_GetChild( file.menu, "WarningLegendLabel" ), mod.requiredOnClient )


}

void function ModsMenu_SetDetailsVisible( bool visible )
{
	foreach ( var element in file.detailsElements )
		Hud_SetVisible( element, visible )
	Hud_SetEnabled( file.detailsPreviewFocus, visible )
}

void function ModsMenu_ClearDetails()
{
	file.selectedIndex = -1
	file.selectedName = ""
	file.selectedVersion = ""
	file.detailsLines.clear()
	file.detailsScrollOffset = 0
	ModsMenu_SetDetailsVisible( false )
}

string function ModsMenu_GetDetailsSource( ModInfo mod )
{
	if ( mod.managedId != "" )
		return Localize( "#MODS_SOURCE_MODWORKSHOP" )
	if ( mod.isRemote )
		return Localize( "#MODS_SOURCE_REMOTE" )
	return Localize( "#MODS_SOURCE_LOCAL" )
}

string function ModsMenu_FormatDetailsDescription( ModInfo mod )
{
	string description = mod.description
	if ( mod.conVars.len() != 0 && GetConVarBool( "modlist_show_convars" ) )
	{
		if ( description != "" )
			description += "\n\n"
		description += Localize( "#MODS_DETAILS_CONVARS" ) + " "
		for ( int i = 0; i < mod.conVars.len(); i++ )
		{
			if ( i > 0 )
				description += ", "
			description += mod.conVars[ i ]
		}
	}
	return description
}


void function ModsMenu_SetDetailsDescription( string description )
{
	file.detailsLines = ModsMenu_WrapDetailsText( description )
	file.detailsScrollOffset = 0
	ModsMenu_RenderDetailsDescription()
}

array<string> function ModsMenu_WrapDetailsText( string text )
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
			while ( word.len() > MODS_DETAILS_LINE_WIDTH )
			{
				if ( currentLine != "" )
				{
					lines.append( currentLine )
					currentLine = ""
				}
				lines.append( word.slice( 0, MODS_DETAILS_LINE_WIDTH ) )
				word = word.slice( MODS_DETAILS_LINE_WIDTH, word.len() )
			}

			if ( currentLine == "" )
				currentLine = word
			else if ( currentLine.len() + 1 + word.len() <= MODS_DETAILS_LINE_WIDTH )
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

void function ModsMenu_RenderDetailsDescription()
{
	string visibleText = ""
	int endLine = minint( file.detailsLines.len(), file.detailsScrollOffset + MODS_DETAILS_VISIBLE_LINES )
	for ( int lineIndex = file.detailsScrollOffset; lineIndex < endLine; lineIndex++ )
		visibleText += ( lineIndex == file.detailsScrollOffset ? "" : "\n" ) + file.detailsLines[ lineIndex ]
	Hud_SetText( Hud_GetChild( file.menu, "DetailsDescription" ), visibleText )
}

void function ModsMenu_ScrollDetails( int direction )
{
	int maxOffset = maxint( 0, file.detailsLines.len() - MODS_DETAILS_VISIBLE_LINES )
	int nextOffset = minint( maxOffset, maxint( 0, file.detailsScrollOffset + direction ) )
	if ( nextOffset == file.detailsScrollOffset )
		return
	file.detailsScrollOffset = nextOffset
	ModsMenu_RenderDetailsDescription()
}

int function ModsMenu_GetSelectedSourceIndex()
{
	if ( file.fullDetailsOpen )
	{
		foreach ( int index, ModInfo mod in file.mods )
		{
			if ( mod.index == file.fullDetailsModIndex )
				return index
		}
		return -1
	}
	if ( file.selectedName == "" )
		return -1
	foreach ( int index, ModInfo mod in file.mods )
	{
		if ( mod.name == file.selectedName && mod.version == file.selectedVersion )
			return index
	}
	return -1
}

void function ModsMenu_UpdateFullDetails()
{
	if ( !file.fullDetailsOpen )
		return
	int modIndex = ModsMenu_GetSelectedSourceIndex()
	if ( modIndex < 0 || modIndex >= file.mods.len() )
		return
	ModInfo mod = file.mods[ modIndex ]

	ModsMenu_SetCardTitle( Hud_GetChild( file.detailsMenu, "DetailsName" ), mod.name, 1548.0 )
	Hud_SetText(
		Hud_GetChild( file.detailsMenu, "DetailsMeta" ),
		Localize( "#MODS_DETAILS_VERSION", mod.version ) + "    " +
			Localize( "#MODS_DETAILS_PRIORITY", string( mod.loadPriority ) ) + "    " +
			Localize( "#MODS_DETAILS_SOURCE", ModsMenu_GetDetailsSource( mod ) ) + "    " +
			Localize( "#MODS_DETAILS_STATE", ModsMenu_GetStatusText( mod ) )
	)
	Hud_SetText(
		Hud_GetChild( file.detailsMenu, "DetailsDescription" ),
		mod.description == "" ? "#MODS_DETAILS_NONE" : mod.description
	)

	file.fullAssetLines.clear()
	foreach ( string assetPath in mod.assets )
		file.fullAssetLines.extend( ModsMenu_WrapDetailsText( assetPath ) )
	if ( file.fullAssetLines.len() == 0 )
		file.fullAssetLines.append( Localize( "#MODS_DETAILS_NONE" ) )

	file.fullConVarLines.clear()
	foreach ( string conVar in mod.conVars )
		file.fullConVarLines.extend( ModsMenu_WrapDetailsText( conVar ) )
	if ( file.fullConVarLines.len() == 0 )
		file.fullConVarLines.append( Localize( "#MODS_DETAILS_NONE" ) )



	ModsMenu_RenderFullDetailsLists()
}

string function ModsMenu_GetFullDetailsVisibleText( array<string> lines )
{
	string visibleText = ""
	int endLine = minint( lines.len(), file.fullDetailsScrollOffset + MODS_FULL_DETAILS_VISIBLE_LINES )
	for ( int lineIndex = file.fullDetailsScrollOffset; lineIndex < endLine; lineIndex++ )
		visibleText += ( lineIndex == file.fullDetailsScrollOffset ? "" : "\n" ) + lines[ lineIndex ]
	return visibleText
}

void function ModsMenu_RenderFullDetailsLists()
{
	int totalLines = maxint( file.fullAssetLines.len(), file.fullConVarLines.len() )
	int maxOffset = maxint( 0, totalLines - MODS_FULL_DETAILS_VISIBLE_LINES )
	file.fullDetailsScrollOffset = minint( maxOffset, maxint( 0, file.fullDetailsScrollOffset ) )
	Hud_SetText( Hud_GetChild( file.detailsMenu, "DetailsAssets" ), ModsMenu_GetFullDetailsVisibleText( file.fullAssetLines ) )
	Hud_SetText( Hud_GetChild( file.detailsMenu, "DetailsConVars" ), ModsMenu_GetFullDetailsVisibleText( file.fullConVarLines ) )

	if ( totalLines > MODS_FULL_DETAILS_VISIBLE_LINES )
	{
		int lastLine = minint( totalLines, file.fullDetailsScrollOffset + MODS_FULL_DETAILS_VISIBLE_LINES )
		Hud_SetText(
			Hud_GetChild( file.detailsMenu, "DetailsScrollStatus" ),
			Localize( "#MODS_DETAILS_SCROLL_RANGE", string( file.fullDetailsScrollOffset + 1 ), string( lastLine ), string( totalLines ) )
		)
	}
	else
	{
		Hud_SetText( Hud_GetChild( file.detailsMenu, "DetailsScrollStatus" ), "#MODS_DETAILS_SCROLL_ALL" )
	}
}

void function ModsMenu_ScrollFullDetails( int direction )
{
	int totalLines = maxint( file.fullAssetLines.len(), file.fullConVarLines.len() )
	int maxOffset = maxint( 0, totalLines - MODS_FULL_DETAILS_VISIBLE_LINES )
	int nextOffset = minint( maxOffset, maxint( 0, file.fullDetailsScrollOffset + direction ) )
	if ( nextOffset == file.fullDetailsScrollOffset )
		return
	file.fullDetailsScrollOffset = nextOffset
	ModsMenu_RenderFullDetailsLists()
}


string function ModsMenu_GetStatusText( ModInfo mod )
{
	if ( mod.updateState == eMWSUpdateState.UPDATE_AVAILABLE )
		return Localize( "#MODS_STATUS_UPDATE_AVAILABLE" )
	return Localize( mod.enabled ? "#SHOW_ONLY_ENABLED" : "#SHOW_ONLY_DISABLED" )
}

vector function ModsMenu_GetControlColor( ModInfo mod )
{
	if ( mod.enabled )
		return < 0, 1, 0 >
	if ( GetConVarInt( "colorblind_mode" ) == 1 || GetConVarInt( "colorblind_mode" ) == 2 )
		return < 0.29, 0, 0.57 >
	return < 1, 0, 0 >
}

void function ModsMenu_SetCardTitle( var label, string text, float availableLogicalWidth )
{
	float screenScale = float( GetScreenSize()[ 0 ] ) / 1920.0
	int availableWidth = int( availableLogicalWidth * screenScale )
	label.SetScale( 1.0, 1.0 )
	Hud_SetWidth( label, int( 4096.0 * screenScale ) )
	Hud_SetText( label, text )
	int naturalWidth = Hud_GetTextWidth( label )
	if ( naturalWidth <= 0 )
	{
		Hud_SetWidth( label, availableWidth )
		return
	}
	Hud_SetWidth( label, naturalWidth )
	float titleScale = min( 1.0, float( availableWidth ) / float( naturalWidth ) )
	label.SetScale( titleScale, titleScale )
}

void function ModsMenu_LayoutCardMetadata( var card )
{
	float screenScale = float( GetScreenSize()[ 1 ] ) / 1080.0
	var title = Hud_GetChild( card, "ModName" )
	var version = Hud_GetChild( card, "ModVersion" )
	var status = Hud_GetChild( card, "ModStatus" )
	Hud_SetY( title, int( 107.0 * screenScale ) )
	Hud_SetHeight( title, int( 18.0 * screenScale ) )
	Hud_SetY( version, int( 125.0 * screenScale ) )
	Hud_SetHeight( version, int( 18.0 * screenScale ) )
	Hud_SetY( status, int( 143.0 * screenScale ) )
	Hud_SetHeight( status, int( 18.0 * screenScale ) )
}

bool function ModsMenu_IsCoreMod( string name )
{
	foreach ( string coreMod in CORE_MODS )
	{
		if ( name == coreMod )
			return true
	}
	return false
}

void function ModsMenu_ConfirmCoreDisable()
{
	ModsMenu_ToggleSelectedMod()
}

void function ModsMenu_ToggleSelectedMod()
{
	int modIndex = ModsMenu_GetSelectedSourceIndex()
	if ( modIndex < 0 || modIndex >= file.mods.len() )
		return
	ModInfo mod = file.mods[ modIndex ]
	NSSetModEnabled( mod.name, mod.version, !mod.enabled )
	file.enabledStateDirty = true
	ModsMenu_RefreshAndRender( true )
}

void function OnModPageButtonPressed( var button )
{
	int modIndex = ModsMenu_GetSelectedSourceIndex()
	if ( modIndex < 0 || modIndex >= file.mods.len() )
		return
	ModInfo mod = file.mods[ modIndex ]
	if ( mod.managedId != "" )
	{
		NSMWSOpenPage( mod.managedId )
		return
	}
	if ( mod.downloadLink == "" )
		return
	string link = mod.downloadLink
	if ( link.find( "http://" ) != 0 && link.find( "https://" ) != 0 )
		link = "http://" + link
	LaunchExternalWebBrowser( link, WEBBROWSER_FLAG_FORCEEXTERNAL )
}

void function OnUpdateModButtonPressed( var button )
{
	int modIndex = ModsMenu_GetSelectedSourceIndex()
	if ( modIndex < 0 || modIndex >= file.mods.len() )
		return
	ModInfo mod = file.mods[ modIndex ]
	if ( !ModsMenu_CanUpdateWorkshopMod( mod ) || ModsMenu_IsOperationBusy( NSMWSGetOperationState().state ) )
		return

	DialogData dialogData
	dialogData.header = "#MWS_UPDATE_MOD"
	dialogData.message = Localize( "#MODS_CONFIRM_UPDATE", mod.name )
	AddDialogButton( dialogData, "#MWS_ACTION_UPDATE", ModsMenu_ConfirmWorkshopUpdate )
	AddDialogButton( dialogData, "#CANCEL" )
	OpenDialog( dialogData )
}

void function ModsMenu_ConfirmWorkshopUpdate()
{
	int modIndex = ModsMenu_GetSelectedSourceIndex()
	if ( modIndex < 0 || modIndex >= file.mods.len() )
		return
	ModInfo mod = file.mods[ modIndex ]
	if ( !NSMWSUpdate( mod.managedId ) )
		ModsMenu_ShowActionError( "#MODS_WORKSHOP_QUEUE_FAILED" )
}

void function OnDeleteModButtonPressed( var button )
{
	int modIndex = ModsMenu_GetSelectedSourceIndex()
	if ( modIndex < 0 || modIndex >= file.mods.len() )
		return
	ModInfo mod = file.mods[ modIndex ]
	if ( !mod.canDelete || ModsMenu_IsOperationBusy( NSMWSGetOperationState().state ) )
		return
	DialogData dialogData
	dialogData.header = "#MODS_UNINSTALL_TITLE"
	dialogData.message = mod.deleteModCount > 1 ? Localize( "#MODS_CONFIRM_UNINSTALL_PACKAGE", mod.name, string( mod.deleteModCount ) ) : Localize( "#MODS_CONFIRM_UNINSTALL", mod.name )
	AddDialogButton( dialogData, "#MODS_UNINSTALL_MOD", ModsMenu_ConfirmDelete )
	AddDialogButton( dialogData, "#CANCEL" )
	OpenDialog( dialogData )
}

void function ModsMenu_ConfirmDelete()
{
	int modIndex = ModsMenu_GetSelectedSourceIndex()
	if ( modIndex < 0 || modIndex >= file.mods.len() )
		return
	ModInfo mod = file.mods[ modIndex ]
	if ( !NSRemoveMod( mod.index ) )
	{
		ModsMenu_ShowActionError( "#MODS_DELETE_QUEUE_FAILED" )
		return
	}
	thread ModsMenu_CloseFullDetailsAfterDelete()
}

void function ModsMenu_CloseFullDetailsAfterDelete()
{
	WaitFrame()
	if ( file.fullDetailsOpen && uiGlobal.activeMenu == file.detailsMenu )
		CloseActiveMenu()
}

void function ModsMenu_ShowActionError( string message )
{
	DialogData dialogData
	dialogData.header = "#MWS_ERROR_TITLE"
	dialogData.message = message
	dialogData.image = $"ui/menu/common/dialog_error"
	AddDialogButton( dialogData, "#OK" )
	OpenDialog( dialogData )
}
bool function ModsMenu_CanUpdateWorkshopMod( ModInfo mod )
{
	return mod.managedId != "" && mod.updateState == eMWSUpdateState.UPDATE_AVAILABLE
}


bool function ModsMenu_IsOperationBusy( int state )
{
	return state >= eMWSInstallState.QUEUED && state <= eMWSInstallState.RELOADING
}

bool function ModsMenu_IsOperationTerminal( int state )
{
	return state == eMWSInstallState.DONE || state == eMWSInstallState.FAILED || state == eMWSInstallState.CANCELLED
}

array<ModInfo> function GetEnabledModsArray()
{
	array<ModInfo> enabledMods
	foreach ( ModInfo mod in NSGetModsInformation() )
	{
		if ( mod.enabled )
			enabledMods.append( mod )
	}
	return enabledMods
}

void function OnReloadModsButtonPressed( var button )
{
	ReloadMods()
	if ( IsFullyConnected() )
		ClientCommand( "retry" )
}

void function OpenModWorkshopMenu( var button )
{
	AdvanceMenu( GetMenu( "ModWorkshopMenu" ) )
}

void function OnModSettingsButtonPressed( var button )
{
	AdvanceMenu( GetMenu( "ModSettings" ) )
}

void function OnAuthenticationAgreementButtonPressed( var button )
{
	NorthstarMasterServerAuthDialog()
}

bool function ShouldShowFooterButtons()
{
	if ( IsLevelMultiplayer( GetActiveLevel() ) )
		return false
	return !IsLobby()
}

void function ReloadMods()
{
	NSReloadMods()
	ClientCommand( "reload_localization" )
	ClientCommand( "loadPlaylists" )
	ClientCommand( "weapon_reparse" )
	ClientCommand( "playerSettings_reparse" )
	if ( IsFullyConnected() )
	{
		ClientCommand( "aisettings_reparse_client" )
		ClientCommand( "damagedefs_reparse_client" )
	}
	ClientCommand( "uiscript_reset" )
}
