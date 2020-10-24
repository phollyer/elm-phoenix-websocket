module Template.Home.PhoneLandscape exposing (..)

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
            (Font.size 22
                :: Common.headingAttrs
            )
            (El.text "Socket Examples")
        , El.wrappedRow
            Common.containerAttrs
            examplePanels
        ]
