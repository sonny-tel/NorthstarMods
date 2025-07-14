resource/ui/menus/panels/match_setting_item.res
{
	BtnSwch
	{
		ControlName				RuiButton
		InheritProperties		SwitchButton
		style					DialogListButton
	}

    BtnSlide
    {
		ControlName				SliderControl
		InheritProperties		SliderControl
		minValue				0
		maxValue				1
		stepSize				0.05
		inverseFill				0
		BtnDropButton
		{
			ControlName				RuiButton
			InheritProperties		WideButton
			clip 					0
			autoResize				1
			pinCorner				0
			visible					1
			enabled					1
			style					SliderButton
		}
    }

	Header
	{
		ControlName	Label
		InheritProperties		SubheaderText		
		labelText			"labelText"

		pin_to_sibling			ControlBox
		pin_corner_to_sibling 	LEFT
		pin_to_sibling_corner 	RIGHT
	}

	BottomLine
	{
		"ControlName" "ImagePanel"
		"InheritProperties" "MenuTopBar"
		"ypos" "5"
		"wide" "%100"
		//"tall"	"0"
		"pin_to_sibling" "Header"
		"pin_corner_to_sibling" "BOTTOM_LEFT"
		"pin_to_sibling_corner" "BOTTOM_LEFT"
	}
}
