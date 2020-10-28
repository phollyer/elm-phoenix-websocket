module Template.UsefulFunctions.TabletPortrait exposing (..)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Font as Font
import Template.UsefulFunctions.Common as Common
import UI


view : Common.Config -> Element msg
view { functions } =
    El.column
        [ El.spacing 5
        , El.width El.fill
        ]
    <|
        El.row
            [ Font.color Color.darkslateblue
            , Font.bold
            , El.width El.fill
            ]
            [ El.el
                []
                (El.text "Function")
            , El.el
                [ El.alignRight ]
                (El.text "Current Value")
            ]
            :: toRows functions


toRows : List ( String, String ) -> List (Element msg)
toRows rows =
    List.map toRow rows


toRow : ( String, String ) -> Element msg
toRow ( function, currentValue ) =
    El.wrappedRow
        [ El.width El.fill
        , El.spacing 5
        ]
        [ El.el [] (UI.functionLink function)
        , El.el [ El.alignRight ] (El.text currentValue)
        ]
