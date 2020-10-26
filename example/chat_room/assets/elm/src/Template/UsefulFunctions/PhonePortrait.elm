module Template.UsefulFunctions.PhonePortrait exposing (..)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Font as Font
import Template.Example.Common exposing (functionLink)
import Template.UsefulFunctions.Common as Common


view : Common.Config -> Element msg
view { functions } =
    El.column
        (El.width El.fill
            :: Common.containerAttrs
        )
        [ El.el
            [ El.centerX
            , Font.color Color.darkslateblue
            , Font.underline
            , Font.bold
            , Font.size 16
            ]
            (El.text "Useful Functions")
        , El.column
            [ Font.size 16
            , El.spacing 5
            ]
            (List.map
                (\( func, val ) -> functionLink func)
                functions
            )
        ]
