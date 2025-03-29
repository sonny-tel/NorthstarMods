global function AddDialogTextEntry
global function OpenTextEntryDialog
global function InitDialogTextEntry

struct 
{
    var menu = null
} file

void function AddDialogTextEntry()
{
    AddMenu( "DialogTextEntry", $"resource/ui/menus/dialog_textentry.menu", InitDialogTextEntry )   
}

void function InitDialogTextEntry()
{
    file.menu = GetMenu( "DialogTextEntry" )

	InitDialogCommon( file.menu )
}

void function OpenTextEntryDialog( DialogData dialogData )
{
    //file.dialogData = dialogData
    //file.textEntryCallback = textEntryCallback
    dialogData.menu = file.menu
    OpenDialog( dialogData )
}
