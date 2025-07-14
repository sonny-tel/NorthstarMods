resource/ui/menus/panels/mode_select_button.res
{
	BtnMode
	{
		ControlName 			RuiButton
		InheritProperties 		RuiSmallButton
		classname 				ModButton
		labelText				"please show up"
		wide					600
		tall					45

		pin_to_sibling			ControlBox
		pin_corner_to_sibling 	LEFT
		pin_to_sibling_corner 	RIGHT
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
		"wide" "%50"
		//"tall"	"0"
		"pin_to_sibling" "Header"
		"pin_corner_to_sibling" "BOTTOM_LEFT"
		"pin_to_sibling_corner" "BOTTOM_LEFT"
	}
}
