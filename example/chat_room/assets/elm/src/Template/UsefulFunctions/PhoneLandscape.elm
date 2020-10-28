module Template.UsefulFunctions.PhoneLandscape exposing (..)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Font as Font
import Template.UsefulFunctions.Common as Common
import UI


view : Common.Config -> Element msg
view { functions } =
    El.column
        [ Font.size 16
        , El.spacing 5
        , El.width El.fill
        ]
    <|
        El.row
            [ El.width El.fill
            , Font.color Color.darkslateblue
            , Font.bold
            ]
            [ El.el
                []
                (El.text "Function")
            , El.el
                [ El.alignRight ]
                (El.text "Current Value")
            ]
            :: List.map
                (\( func, val ) ->
                    El.row
                        [ El.spacing 20
                        , El.width El.fill
                        ]
                        [ UI.functionLink func
                        , El.el
                            [ El.alignRight ]
                            (El.text val)
                        ]
                )
                functions
