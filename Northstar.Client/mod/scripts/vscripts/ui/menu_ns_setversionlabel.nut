untyped
global function NS_SetVersionLabel

void function NS_SetVersionLabel()
{
        var mainMenu = GetMenu( "MainMenu" ) //Gets main menu element
        var versionLabel = GetElementsByClassname( mainMenu, "nsVersionClass" )[0] //Gets the label from the mainMenu element.
        Hud_SetText( versionLabel, 
        "v" + NS_VERSION_MAJOR + "." + NS_VERSION_MINOR + "." + NS_VERSION_PATCH + "\n" 
        + GetPublicGameVersion()) 
}

