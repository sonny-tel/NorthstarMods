global function AddDemopickerMenu
global function InitDemopickerMenu
global function GetDemoNameFromPicker
global function GetDemoFileFromPicker

const UPDATE_RATE = 1.0

struct
{
	var menu
	GridMenuData gridData
    array<string> demoNames
    array<string> demoPaths
    array<string> dateAndTime
	int selectedElemNum

    string lastPickedDemo
    string lastPickedDemoPrettyName
} file

void function AddDemopickerMenu()
{
	AddMenu( "DemopickerMenu", $"resource/ui/menus/demopicker.menu", InitDemopickerMenu )
}

void function InitDemopickerMenu()
{
	var menu = GetMenu( "DemopickerMenu" )

	file.menu = menu
	file.gridData.initCallback = DemoButton_Init
	file.gridData.clickCallback = DemoButton_Activate
	file.gridData.getFocusCallback = DemoButton_GetFocus
	file.gridData.rows = 15
	file.gridData.columns = 1
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

    file.lastPickedDemo = ""
    file.lastPickedDemoPrettyName = "?"

	Grid_AutoAspectSettings( menu, file.gridData )

	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnDemopickerMenu_Open )

    AddMenuFooterOption( menu, BUTTON_A, "#A_BUTTON_SELECT" )
	AddMenuFooterOption( menu, BUTTON_B, "#B_BUTTON_BACK", "#BACK" )
}

void function OnDemopickerMenu_Open()
{
	UI_SetPresentationType( ePresentationType.NO_MODELS )

	int numDemos = -1
	int lastNumDemos = -2

	file.gridData.currentPage = 0

    GetAndFormatDemoNames()

	while ( GetTopNonDialogMenu() == file.menu )
	{
        numDemos = file.demoNames.len()

		if ( numDemos != lastNumDemos )
		{
			file.gridData.numElements = numDemos

			int maxPageIndex = Grid_GetNumPages( file.gridData ) - 1
			if ( maxPageIndex < file.gridData.currentPage )
				file.gridData.currentPage = maxPageIndex

			GridMenuInit( file.menu, file.gridData )

			Grid_SetReadyState( file.menu, true )

			UpdateFooterOptions()
		}

		lastNumDemos = numDemos

		wait UPDATE_RATE
	}
}

bool function DemoButton_Init( var button, int elemNum )
{
	string name = file.demoNames[elemNum]

	var rui = Hud_GetRui( button )
	RuiSetString( rui, "buttonText", name )

	return true
}

void function GetAndFormatDemoNames()
{
    file.demoNames.clear()
    file.demoPaths.clear()

    //demo_2024-6-9_95-25-41_550_p2452__mp_colony02.dem
    foreach( string demo in Demo_GetDemoFiles() )
    {
		string orig = demo
		string mapName = "mp_lobby"
	
        array<string> toks = split(demo, "_")

		foreach(string map in GetPrivateMatchMaps())
		{
			if(orig.find(map))
				mapName = map
		}

        if(mapName == "mp_lobby")
            continue

        array<string> hoursMinsSecs = split( toks[2], "-" )
        string newTime = hoursMinsSecs[0] + ":" + hoursMinsSecs[1]

        file.demoNames.append( toks[1] + " " + newTime + " " + Localize( GetMapDisplayName( mapName ) ) )
        file.demoPaths.append(demo)
    }
}

void function DemoButton_Activate( var button, int elemNum )
{
	if ( Hud_IsLocked( button ) )
		return

    file.lastPickedDemo = file.demoPaths[elemNum]
    file.lastPickedDemoPrettyName = file.demoNames[elemNum]    

	file.selectedElemNum = elemNum
	ClientCommand( "stopdemo")
    ClientCommand( "playdemo " + file.demoPaths[elemNum] )
}

void function DemoButton_GetFocus( var button, int elemNum )
{
	UpdateFooterOptions()
}

string function GetDemoNameFromPicker()
{
    return file.lastPickedDemoPrettyName
}

string function GetDemoFileFromPicker()
{
    return file.lastPickedDemo
}