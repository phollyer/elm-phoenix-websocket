module Template.Home.Desktop exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Font as Font
import Template.Home.Common as Common


view : Common.Config msg c -> Element msg
view { channels, presence, socket } =
    El.column
        Common.containerAttrs
        [ socketExamples socket ]


socketExamples : List (Element msg) -> Element msg
socketExamples examplePanels =
    El.column
        Common.containerAttrs
        [ El.el
            (Font.size 30
                :: Common.headingAttrs
            )
            (El.text "Socket Examples")
        , El.row
            Common.containerAttrs
            examplePanels
        ]
