#base "vgui_fullscreen.res"
vgui_fullscreen_pilot.res
{
	Screen
	{
		ControlName			ImagePanel
		xpos				0
		ypos				0
		wide				1920
		tall				1080
		visible				1
		//image				vgui/HUD/white
		image				vgui/HUD/screen_grid_overlay
		scaleImage			1
		drawColor			"0 0 0 0"

		zpos				1
	}

    healthProgressBar
    {
        ControlName				CHudProgressBar
       	xpos					c-60
		ypos					c+170
		wide					120
		tall					7
		visible					0
		SegmentSize			5000
		enabled					1
        visible 1
		fgcolor_override		"190 100 100 255"
		bgcolor_override		"0 0 0 60"
    }

	EMPScreenFX
	{
		ControlName		ImagePanel
		xpos 			0
		ypos 			0
		zpos			-1000
		wide			1920
		tall			1080
		visible			0
		scaleImage		1
		image			vgui/HUD/pilot_flashbang_overlay
		drawColor		"255 255 255 64"

		pin_to_sibling				Screen
		pin_corner_to_sibling		CENTER
		pin_to_sibling_corner		CENTER
	}

	TitanCoreIcon
	{
		ControlName		ImagePanel
		xpos 			0
		ypos 			140
		wide			65
		tall			65
		visible			0
		scaleImage		1
		image			vgui/titan_icons/vanguard_icon

		pin_to_sibling				Screen
		pin_corner_to_sibling		CENTER
		pin_to_sibling_corner		CENTER
	}
}