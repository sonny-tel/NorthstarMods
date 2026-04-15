global function AddDialogHiddenTextEntry
global function OpenHiddenTextEntryDialog
global function InitDialogHiddenTextEntry

struct
{
	var menu = null
} file

void function AddDialogHiddenTextEntry()
{
	AddMenu( "DialogHiddenTextEntry", $"resource/ui/menus/dialog_hiddentextentry.menu", InitDialogHiddenTextEntry )
}

void function InitDialogHiddenTextEntry()
{
	file.menu = GetMenu( "DialogHiddenTextEntry" )

	InitDialogCommon( file.menu )
}

void function OpenHiddenTextEntryDialog( DialogData dialogData )
{
	// file.dialogData = dialogData
	// file.textEntryCallback = textEntryCallback
	dialogData.menu = file.menu
	OpenDialog( dialogData )

	Hud_SetFocused( Hud_GetChild( file.menu, "TextEntryBox" ) )
}
