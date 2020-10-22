module Template.Home.PhonePortrait exposing (..)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Font as Font


render :
    { c
        | channels : List (Element msg)
        , presence : List (Element msg)
        , socket : List (Element msg)
    }
    -> Element msg
render { channels, presence, socket } =
    El.column
        [ El.spacing 10
        , El.width El.fill
        ]
        [ socketExamples socket ]


socketExamples : List (Element msg) -> Element msg
socketExamples examples =
    El.column
        [ El.width El.fill
        , El.spacing 10
        ]
        [ El.el
            [ Font.size 22
            , Font.color Color.slateblue
            , El.centerX
            ]
            (El.text "Socket")
        , El.column
            [ El.width El.fill
            , El.spacing 10
            ]
            examples
        ]
