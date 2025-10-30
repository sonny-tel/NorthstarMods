global enum eDiscordGameState
{
    LOADING = 0
    MAINMENU
    LOBBY
    INGAME
}

global enum InputEventType
{
	IE_ButtonPressed = 0	// m_nData contains a ButtonCode_t
	IE_ButtonReleased		// m_nData contains a ButtonCode_t
	IE_ButtonDoubleClicked	// m_nData contains a ButtonCode_t
	IE_AnalogValueChanged	// m_nData contains an AnalogCode_t, m_nData2 contains the value

	IE_Unknown8 = 8 // Unknown what this is/does, its used in [r5apex.exe+0x297722] and [r5apex.exe+0x297ACD]

	IE_FirstSystemEvent = 100
	IE_Quit = 100
	IE_ControllerInserted	// m_nData contains the controller ID
	IE_ControllerUnplugged	// m_nData contains the controller ID
	IE_Close
	IE_WindowSizeChanged	// m_nData contains width, m_nData2 contains height, m_nData3 = 0 if not minimized, 1 if minimized
	IE_PS_CameraUnplugged // m_nData contains code for type of disconnect.
	IE_PS_Move_OutOfView   // m_nData contains bool (0, 1) for whether the move is now out of view (1) or in view (0)

	IE_FirstUIEvent = 200
	IE_LocateMouseClick = 200
	IE_SetCursor
	IE_KeyTyped
	IE_KeyCodeTyped
	IE_InputLanguageChanged
	IE_IMESetWindow
	IE_IMEStartComposition
	IE_IMEComposition
	IE_IMEEndComposition
	IE_IMEShowCandidates
	IE_IMEChangeCandidates
	IE_IMECloseCandidates
	IE_IMERecomputeModes
	IE_OverlayEvent

	IE_FirstVguiEvent = 1000	// Assign ranges for other systems that post user events here
	IE_FirstAppEvent = 2000
}

global struct InputEventCallbackStruct {
    int eventType
    void functionref(int, int, int, int, int) callbackFunc
}

global struct GameStateStruct {

    string map
    string mapDisplayname

    string playlist
    string playlistDisplayname

    int currentPlayers
    int maxPlayers
    int ownScore
    int otherHighestScore
    int maxScore
    float timeEnd
    int serverGameState
    int fd_waveNumber
    int fd_totalWaves
    bool is_vanilla
}

global struct UIPresenceStruct {
    int gameState
    bool is_vanilla
    bool in_party
    int party_size
    int party_max_players
}

global struct ModInfo
{
    string name = ""
    string description = ""
    string version = ""
    string downloadLink = ""
    int loadPriority = 0
    bool enabled = false
    bool requiredOnClient = false
    bool isRemote
    array<string> conVars = []
}

global struct RequiredModInfo
{
    string name
    string version
}

global struct ServerInfo
{
    int index
    string id
    string name
    string description
    string map
    string playlist
    int playerCount
    int maxPlayerCount
    bool requiresPassword
    string region
    array< RequiredModInfo > requiredMods
}

global struct MasterServerAuthResult
{
    bool success
    string errorCode
    string errorMessage
}

global struct ModInstallState
{
    int status
    int progress
    int total
    float ratio
}
