module Template.Home.Desktop exposing (..)

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
socketExamples socketPanels =
    El.column
        [ El.width El.fill
        , El.spacing 10
        ]
        [ El.el
            [ Font.size 30
            , Font.color Color.slateblue
            ]
            (El.text "Socket")
        , El.row
            [ El.width El.fill
            , El.spacing 10
            ]
            socketPanels
        ]
