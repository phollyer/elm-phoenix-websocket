module Template.Home.PhonePortrait exposing (view)

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
            (Font.size 18
                :: Common.headingAttrs
            )
            (El.text "Socket Examples")
        , El.column
            Common.containerAttrs
            examplePanels
        ]
