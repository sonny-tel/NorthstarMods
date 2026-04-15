untyped
global function NS_SetVersionLabel

void function NS_SetVersionLabel()
{
	var mainMenu = GetMenu( "MainMenu" ) // Gets main menu element
	var versionLabel = GetElementsByClassname( mainMenu, "nsVersionClass" )[
		0
	] // Gets the label from the mainMenu element.

	if ( NS_VERSION_DEV )
		Hud_SetText( versionLabel, Localize( "#DEVELOPMENT_VERSION" ) + "\n" + GetPublicGameVersion() )
	else
		Hud_SetText(
			versionLabel,
			"v" + NS_VERSION_MAJOR + "." + NS_VERSION_MINOR + "." + NS_VERSION_PATCH + " " + Localize( "#ION_PATCH" ) + ION_PATCH + "\n" + GetPublicGameVersion()
		)

	Hud_SetVisible( versionLabel, !GetConVarBool( "hide_version" ) ) // Sets the label to visible.
}

